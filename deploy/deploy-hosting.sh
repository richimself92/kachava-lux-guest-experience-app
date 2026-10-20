#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:-kavacha-app}"
GUEST_SITE="kavacha-app-guest-portal"
ADMIN_SITE="kavacha-app-admin-dashboard"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

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
