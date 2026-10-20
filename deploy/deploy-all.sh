#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:-kavacha-app}"
REGION="${GCP_REGION:-us-central1}"
SERVICE_NAME="${SERVICE_NAME:-kachava-backend}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================================="
echo "  Kachava Sanctuary Luxury Guest Experience Deployment"
echo "  GCP Project: ${PROJECT_ID} (${REGION})"
echo "=========================================================="

"${SCRIPT_DIR}/deploy-backend.sh"
"${SCRIPT_DIR}/deploy-hosting.sh"

CLOUD_RUN_URL="$(gcloud run services describe "${SERVICE_NAME}" \
  --region="${REGION}" \
  --project="${PROJECT_ID}" \
  --format='value(status.url)' 2>/dev/null || echo 'https://kachava-backend-us-central1.run.app')"

echo ""
echo "=========================================================="
echo "  Deployment Complete"
echo "=========================================================="
echo "  Backend API (Cloud Run): ${CLOUD_RUN_URL}"
echo "  Guest Portal (Hosting):  https://kavacha-app-guest-portal.web.app"
echo "  Admin Portal (Hosting):  https://kavacha-app-admin-dashboard.web.app"
echo "=========================================================="
