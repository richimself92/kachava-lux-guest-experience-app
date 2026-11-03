#!/usr/bin/env bash
# ==============================================================================
# Kachava Lux — local stack launcher (run-local.sh)
#
#   1. Firebase emulators: Firestore + Storage (project demo-kachava; nothing reaches Google)
#      Data persists between runs in .local-data/emulator (--import / --export-on-exit).
#   2. NestJS backend (backend/)                -> http://localhost:${BACKEND_PORT}/api/v1
#   3. Guest portal (web/, Flutter Web)          -> http://localhost:${GUEST_WEB_PORT}
#   4. Admin console (admin/, Flutter Web)       -> http://localhost:${ADMIN_WEB_PORT}
#
# Usage:
#   BACKEND_PORT=3011 ./run-local.sh                 # full stack (prebuilt web apps if present)
#   BACKEND_PORT=3011 ./run-local.sh --dev           # full stack, `flutter run` for both apps
#   BACKEND_PORT=3011 ./run-local.sh --backend-only  # emulators + backend only
#
# The database starts EMPTY: there is no seed and no demo data. Create everything from the admin.
# The live Firestore/bucket are never used: the backend refuses to start without the emulators.
#
# Overridable: BACKEND_PORT (default 3001; use 3011 when 3001 is taken), GUEST_WEB_PORT,
# ADMIN_WEB_PORT, FIRESTORE_EMULATOR_PORT (8085), STORAGE_EMULATOR_PORT (9199),
# EMULATOR_UI_PORT (4005), ADMIN_SERVICE_EMAIL (admin@kachava.local), LOCAL_DATA_DIR.
# ==============================================================================

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_MODE="${1:---prebuilt}"
BACKEND_PORT="${BACKEND_PORT:-3001}"
GUEST_WEB_PORT="${GUEST_WEB_PORT:-3000}"
ADMIN_WEB_PORT="${ADMIN_WEB_PORT:-3002}"
FIRESTORE_EMULATOR_PORT="${FIRESTORE_EMULATOR_PORT:-8085}"
STORAGE_EMULATOR_PORT="${STORAGE_EMULATOR_PORT:-9199}"
EMULATOR_UI_PORT="${EMULATOR_UI_PORT:-4005}"
EMULATOR_HUB_PORT="${EMULATOR_HUB_PORT:-4405}"
EMULATOR_LOGGING_PORT="${EMULATOR_LOGGING_PORT:-4505}"
FLUTTER_DEVICE="${FLUTTER_DEVICE:-web-server}"
LOCAL_DATA_DIR="${LOCAL_DATA_DIR:-${ROOT_DIR}/.local-data}"
EMULATOR_DATA_DIR="${LOCAL_DATA_DIR}/emulator"
EMULATOR_CONFIG="${LOCAL_DATA_DIR}/firebase.emulators.json"
SECRETS_FILE="${LOCAL_DATA_DIR}/backend-secrets.env"
LOCAL_PROJECT_ID="demo-kachava"

EMULATOR_PID=""
PIDS=()

cleanup() {
  echo ""
  echo "Shutting down Kachava Lux local services..."
  for pid in "${PIDS[@]:-}"; do
    [[ -n "${pid}" ]] && kill "${pid}" 2>/dev/null || true
  done
  if [[ -n "${EMULATOR_PID}" ]] && kill -0 "${EMULATOR_PID}" 2>/dev/null; then
    echo "Exporting emulator data to ${EMULATOR_DATA_DIR} ..."
    kill -INT "${EMULATOR_PID}" 2>/dev/null || true
    wait "${EMULATOR_PID}" 2>/dev/null || true
  fi
  wait 2>/dev/null || true
  echo "All services stopped."
}
trap cleanup EXIT
trap 'exit 130' INT TERM

require_command() {
  command -v "$1" >/dev/null 2>&1 || { echo "Error: '$1' is required but not in PATH." >&2; exit 1; }
}

java_major() {
  "$1" -version 2>&1 | awk -F '"' '/version/ { split($2, v, "."); print (v[1] == "1" ? v[2] : v[1]); exit }'
}

# firebase-tools needs Java 21+; prefer the PATH java, else a Homebrew or java_home JDK.
ensure_java21() {
  local candidate
  for candidate in "$(command -v java || true)" /opt/homebrew/opt/openjdk/bin/java /usr/local/opt/openjdk/bin/java \
    "$(/usr/libexec/java_home -v 21+ 2>/dev/null)/bin/java"; do
    if [[ -x "${candidate}" && "$(java_major "${candidate}")" -ge 21 ]]; then
      export PATH="$(dirname "${candidate}"):${PATH}"
      return 0
    fi
  done
  echo "Error: the Firebase emulators need Java 21+ (e.g. brew install openjdk)." >&2
  exit 1
}

# Stable local HMAC secrets so staff sessions survive backend restarts (gitignored).
ensure_local_secrets() {
  if [[ ! -f "${SECRETS_FILE}" ]]; then
    {
      echo "STAFF_JWT_SECRET=$(openssl rand -hex 32)"
      echo "STEPUP_HMAC_SECRET=$(openssl rand -hex 32)"
    } > "${SECRETS_FILE}"
    chmod 600 "${SECRETS_FILE}"
  fi
  set -a
  # shellcheck disable=SC1090
  source "${SECRETS_FILE}"
  set +a
}

# Effective emulator config: firebase.json with the requested ports and absolute rule paths.
write_emulator_config() {
  node -e '
    const fs = require("fs"); const path = require("path");
    const [root, out, fsPort, stPort, uiPort, hubPort, logPort] = process.argv.slice(1);
    const cfg = JSON.parse(fs.readFileSync(path.join(root, "firebase.json"), "utf8"));
    const config = {
      firestore: { rules: path.join(root, cfg.firestore.rules), indexes: path.join(root, cfg.firestore.indexes) },
      storage: { rules: path.join(root, cfg.storage.rules) },
      emulators: { ...cfg.emulators,
        firestore: { ...cfg.emulators.firestore, port: Number(fsPort) },
        storage: { ...cfg.emulators.storage, port: Number(stPort) },
        ui: { ...cfg.emulators.ui, port: Number(uiPort) },
        hub: { ...cfg.emulators.hub, port: Number(hubPort) },
        logging: { ...cfg.emulators.logging, port: Number(logPort) } },
    };
    fs.writeFileSync(out, JSON.stringify(config, null, 2));
  ' "${ROOT_DIR}" "${EMULATOR_CONFIG}" "${FIRESTORE_EMULATOR_PORT}" "${STORAGE_EMULATOR_PORT}" \
    "${EMULATOR_UI_PORT}" "${EMULATOR_HUB_PORT}" "${EMULATOR_LOGGING_PORT}"
}

wait_for_port() {
  local port="$1" label="$2" tries=0
  until nc -z 127.0.0.1 "${port}" >/dev/null 2>&1; do
    tries=$((tries + 1))
    if [[ ${tries} -gt 120 ]]; then echo "Error: ${label} did not start on port ${port}." >&2; exit 1; fi
    sleep 1
  done
}

start_emulators() {
  mkdir -p "${EMULATOR_DATA_DIR}"
  write_emulator_config
  local import_args=()
  if [[ -f "${EMULATOR_DATA_DIR}/firebase-export-metadata.json" ]]; then
    import_args=(--import "${EMULATOR_DATA_DIR}")
  fi
  echo "[1/4] Firebase emulators (Firestore :${FIRESTORE_EMULATOR_PORT}, Storage :${STORAGE_EMULATOR_PORT}, UI :${EMULATOR_UI_PORT})"
  firebase emulators:start --only firestore,storage --project "${LOCAL_PROJECT_ID}" \
    --config "${EMULATOR_CONFIG}" "${import_args[@]+"${import_args[@]}"}" \
    --export-on-exit "${EMULATOR_DATA_DIR}" > "${LOCAL_DATA_DIR}/emulators.log" 2>&1 &
  EMULATOR_PID=$!
  wait_for_port "${FIRESTORE_EMULATOR_PORT}" "Firestore emulator"
  wait_for_port "${STORAGE_EMULATOR_PORT}" "Storage emulator"
}

start_backend() {
  echo "[2/4] Backend on :${BACKEND_PORT} (Firestore emulator, admin identity ${ADMIN_SERVICE_EMAIL})"
  [[ -d "${ROOT_DIR}/backend/node_modules" ]] || (cd "${ROOT_DIR}/backend" && npm install)
  (cd "${ROOT_DIR}/backend" && npm run build >/dev/null)
  # The emulator only exports/imports the "(default)" database, so local data lives there.
  (
    cd "${ROOT_DIR}/backend"
    NODE_ENV=development PORT="${BACKEND_PORT}" USE_FIRESTORE=true \
      FIRESTORE_EMULATOR_HOST="127.0.0.1:${FIRESTORE_EMULATOR_PORT}" \
      FIREBASE_STORAGE_EMULATOR_HOST="127.0.0.1:${STORAGE_EMULATOR_PORT}" \
      FIREBASE_PROJECT_ID="${LOCAL_PROJECT_ID}" GOOGLE_CLOUD_PROJECT="${LOCAL_PROJECT_ID}" \
      FIRESTORE_DATABASE_ID="(default)" \
      FIREBASE_STORAGE_BUCKET="${LOCAL_PROJECT_ID}.appspot.com" \
      ADMIN_SERVICE_EMAIL="${ADMIN_SERVICE_EMAIL}" \
      GUEST_PORTAL_URL="${GUEST_PORTAL_URL:-http://localhost:${GUEST_WEB_PORT}}" \
      exec node dist/main.js
  ) &
  PIDS+=($!)
  wait_for_port "${BACKEND_PORT}" "Backend"
}

start_flutter_app() {
  local dir="$1" port="$2" label="$3"
  echo "${label} on :${port}"
  if [[ "${RUN_MODE}" != "--dev" && -f "${ROOT_DIR}/${dir}/build/web/index.html" ]]; then
    (cd "${ROOT_DIR}/${dir}/build/web" && exec python3 -m http.server "${port}" --bind 127.0.0.1 >/dev/null 2>&1) &
  else
    (
      cd "${ROOT_DIR}/${dir}"
      flutter pub get >/dev/null
      exec flutter run -d "${FLUTTER_DEVICE}" --web-hostname 127.0.0.1 --web-port "${port}" \
        --dart-define-from-file=config/dev.json
    ) &
  fi
  PIDS+=($!)
}

export ADMIN_SERVICE_EMAIL="${ADMIN_SERVICE_EMAIL:-admin@kachava.local}"
for cmd in node npm firebase openssl nc; do require_command "${cmd}"; done
ensure_java21
mkdir -p "${LOCAL_DATA_DIR}"
ensure_local_secrets

echo "=============================================================================="
echo "  KACHAVA LUX — LOCAL STACK (emulators only; the live database is never used)"
echo "=============================================================================="
start_emulators
start_backend
if [[ "${RUN_MODE}" != "--backend-only" ]]; then
  for cmd in flutter python3; do require_command "${cmd}"; done
  start_flutter_app web "${GUEST_WEB_PORT}" "[3/4] Guest portal"
  start_flutter_app admin "${ADMIN_WEB_PORT}" "[4/4] Admin console"
fi

echo "------------------------------------------------------------------------------"
echo "  Backend API:     http://localhost:${BACKEND_PORT}/api/v1"
echo "  Emulator UI:     http://127.0.0.1:${EMULATOR_UI_PORT}"
[[ "${RUN_MODE}" == "--backend-only" ]] || {
  echo "  Guest portal:    http://localhost:${GUEST_WEB_PORT}/?guestId=<link from a reservation>"
  echo "  Admin console:   http://localhost:${ADMIN_WEB_PORT}"
}
echo "  Data directory:  ${EMULATOR_DATA_DIR} (exported on Ctrl+C)"
echo "  Press Ctrl+C to stop everything."
echo "=============================================================================="
wait
