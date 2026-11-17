#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:-kavacha-app}"
GUEST_SITE="kavacha-app-guest-portal"
ADMIN_SITE="kavacha-app-admin-dashboard"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Empty Firebase keys silently disable real time; an empty staff email breaks admin sign-in.
node -e '
  const fs = require("fs");
  const required = ["API_BASE_URL", "FIREBASE_API_KEY", "FIREBASE_APP_ID", "FIREBASE_PROJECT_ID",
    "FIREBASE_MESSAGING_SENDER_ID", "FIRESTORE_DATABASE_ID"];
  const check = (file, keys) => {
    const config = JSON.parse(fs.readFileSync(file, "utf8"));
    const missing = keys.filter((key) => !config[key]);
    if (missing.length) throw new Error(`${file} is missing: ${missing.join(", ")}`);
  };
  check(process.argv[1] + "/web/config/prod.json", required);
  check(process.argv[1] + "/admin/config/prod.json", [...required, "ADMIN_STAFF_EMAIL"]);
' "${REPO_ROOT}"

echo "==> [1/4] Ensuring Firebase Hosting sites exist in project ${PROJECT_ID}..."
npx -y firebase-tools hosting:sites:create "${GUEST_SITE}" --project "${PROJECT_ID}" --non-interactive >/dev/null 2>&1 || true
npx -y firebase-tools hosting:sites:create "${ADMIN_SITE}" --project "${PROJECT_ID}" --non-interactive >/dev/null 2>&1 || true

echo "==> [2/4] Applying Firebase Hosting target mappings..."
cd "${REPO_ROOT}"
npx -y firebase-tools target:apply hosting guest-portal "${GUEST_SITE}" --project "${PROJECT_ID}" --non-interactive
npx -y firebase-tools target:apply hosting admin-dashboard "${ADMIN_SITE}" --project "${PROJECT_ID}" --non-interactive

echo "==> [3/4] Building Flutter Web Guest Portal (web/) and Admin Dashboard (admin/)..."
(
  cd "${REPO_ROOT}/web"
  flutter build web --release --pwa-strategy=none --dart-define-from-file=config/prod.json
)
(
  cd "${REPO_ROOT}/admin"
  flutter build web --release --pwa-strategy=none --dart-define-from-file=config/prod.json
)

echo "==> [4/4] Deploying Guest Portal & Admin Dashboard to Firebase Hosting..."
cd "${REPO_ROOT}"
npx -y firebase-tools deploy --only hosting --project "${PROJECT_ID}" --non-interactive

echo "Guest Portal Live:    https://${GUEST_SITE}.web.app"
echo "Admin Dashboard Live: https://${ADMIN_SITE}.web.app"
