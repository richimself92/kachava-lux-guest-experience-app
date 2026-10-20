#!/usr/bin/env bash
# ==============================================================================
# Kachava Lux Digital Hospitality Ecosystem — Local Stack Launcher (run-local.sh)
# Launches all 3 services concurrently for local development & E2E testing:
#   1. Shared NestJS Backend API (backend/)        -> http://localhost:3001/api/v1
#   2. Guest Experience Portal (web/ Flutter Web)  -> http://localhost:3000
#   3. Admin Operations Dashboard (admin/ Flutter) -> http://localhost:3002
#
# Modes:
#   ./run-local.sh          (Default: serves compiled web/build/web & admin/build/web
#                            instantly if present, or falls back to flutter run)
#   ./run-local.sh --dev    (Forces live `flutter run -d web-server` compilation)
# ==============================================================================

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_PORT="${BACKEND_PORT:-3001}"
GUEST_WEB_PORT="${GUEST_WEB_PORT:-3000}"
ADMIN_WEB_PORT="${ADMIN_WEB_PORT:-3002}"
DEMO_GUEST_UUID="550e8400-e29b-41d4-a716-446655440000"
FLUTTER_DEVICE="${FLUTTER_DEVICE:-web-server}"
RUN_MODE="${1:---prebuilt}"

export GOOGLE_CLOUD_PROJECT="${GOOGLE_CLOUD_PROJECT:-kavacha-app}"
export FIREBASE_PROJECT_ID="${FIREBASE_PROJECT_ID:-kavacha-app}"
export FIRESTORE_DATABASE_ID="${FIRESTORE_DATABASE_ID:-kavacha-db}"
export FIREBASE_STORAGE_BUCKET="${FIREBASE_STORAGE_BUCKET:-kavacha-store}"
export USE_FIRESTORE="${USE_FIRESTORE:-true}"

PIDS=()

cleanup() {
  echo ""
  echo "------------------------------------------------------------------------------"
  echo "Shutting down Kachava Lux local services..."
  for pid in "${PIDS[@]:-}"; do
    if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
      kill "${pid}" 2>/dev/null || true
    fi
  done
  wait 2>/dev/null || true
  echo "All services stopped cleanly."
}

trap cleanup EXIT INT TERM

echo "=============================================================================="
echo "  KACHAVA LUX — LOCAL FULL-STACK ECOSYSTEM LAUNCHER"
echo "  GCP Project: ${FIREBASE_PROJECT_ID} | Firestore DB: ${FIRESTORE_DATABASE_ID} | Bucket: ${FIREBASE_STORAGE_BUCKET}"
echo "=============================================================================="

# 1. Verify required CLI tools
for cmd in node npm flutter python3; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Error: Required command '${cmd}' is not installed or not in PATH." >&2
    exit 1
  fi
done

# 2. Ensure Backend dependencies & start NestJS API
echo "[1/3] Starting Shared NestJS Backend (backend/ on port ${BACKEND_PORT})..."
if [[ ! -d "${ROOT_DIR}/backend/node_modules" ]]; then
  (cd "${ROOT_DIR}/backend" && npm install)
fi

(
  cd "${ROOT_DIR}/backend"
  PORT="${BACKEND_PORT}" \
  GOOGLE_CLOUD_PROJECT="${GOOGLE_CLOUD_PROJECT}" \
  FIREBASE_PROJECT_ID="${FIREBASE_PROJECT_ID}" \
  FIRESTORE_DATABASE_ID="${FIRESTORE_DATABASE_ID}" \
  FIREBASE_STORAGE_BUCKET="${FIREBASE_STORAGE_BUCKET}" \
  USE_FIRESTORE="${USE_FIRESTORE}" \
  npm run start
) &
PIDS+=($!)

# 3. Launch Guest Experience Portal (Flutter Web in web/)
echo "[2/3] Starting Guest Experience Portal (web/ on port ${GUEST_WEB_PORT})..."
if [[ "${RUN_MODE}" != "--dev" && -f "${ROOT_DIR}/web/build/web/index.html" ]]; then
  (
    cd "${ROOT_DIR}/web/build/web"
    python3 -m http.server "${GUEST_WEB_PORT}" --bind 127.0.0.1 >/dev/null 2>&1
  ) &
  PIDS+=($!)
else
  (
    cd "${ROOT_DIR}/web"
    flutter pub get >/dev/null
    flutter run -d "${FLUTTER_DEVICE}" \
      --web-hostname 127.0.0.1 \
      --web-port "${GUEST_WEB_PORT}" \
      --dart-define-from-file=config/dev.json
  ) &
  PIDS+=($!)
fi

# 4. Launch Administrative & Concierge Operations Dashboard (Flutter Web in admin/)
echo "[3/3] Starting Admin Operations Dashboard (admin/ on port ${ADMIN_WEB_PORT})..."
if [[ "${RUN_MODE}" != "--dev" && -f "${ROOT_DIR}/admin/build/web/index.html" ]]; then
  (
    cd "${ROOT_DIR}/admin/build/web"
    python3 -m http.server "${ADMIN_WEB_PORT}" --bind 127.0.0.1 >/dev/null 2>&1
  ) &
  PIDS+=($!)
else
  (
    cd "${ROOT_DIR}/admin"
    flutter pub get >/dev/null
    flutter run -d "${FLUTTER_DEVICE}" \
      --web-hostname 127.0.0.1 \
      --web-port "${ADMIN_WEB_PORT}" \
      --dart-define-from-file=config/dev.json
  ) &
  PIDS+=($!)
fi

echo "------------------------------------------------------------------------------"
echo "  Services running:"
echo "  - Backend REST API:       http://localhost:${BACKEND_PORT}/api/v1/stays/${DEMO_GUEST_UUID}"
echo "  - Guest Portal (Villa 102 Magic Link):"
echo "                            http://localhost:${GUEST_WEB_PORT}/?guestId=${DEMO_GUEST_UUID}"
echo "  - Admin Operations Panel: http://localhost:${ADMIN_WEB_PORT}"
echo ""
echo "  Press Ctrl+C at any time to stop all 3 services."
echo "=============================================================================="

wait
