#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:-kavacha-app}"
REGION="${GCP_REGION:-us-central1}"
AR_REPO="${AR_REPO:-cloud-run-source-deploy}"
SERVICE_NAME="${SERVICE_NAME:-kachava-backend}"
GUEST_PORTAL_URL="${GUEST_PORTAL_URL:-https://kavacha-app-guest-portal.web.app}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "==> [1/4] Enabling required Google Cloud APIs & IAM permissions on project ${PROJECT_ID}..."
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  --project="${PROJECT_ID}"

PROJECT_NUMBER="$(gcloud projects describe "${PROJECT_ID}" --format='value(projectNumber)')"
for SA in "${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" "${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"; do
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" --member="serviceAccount:${SA}" --role="roles/run.admin" --quiet >/dev/null 2>&1 || true
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" --member="serviceAccount:${SA}" --role="roles/iam.serviceAccountUser" --quiet >/dev/null 2>&1 || true
done

echo "==> [2/4] Ensuring Artifact Registry repository '${AR_REPO}' exists in ${REGION}..."
if ! gcloud artifacts repositories describe "${AR_REPO}" \
  --location="${REGION}" \
  --project="${PROJECT_ID}" >/dev/null 2>&1; then
  gcloud artifacts repositories create "${AR_REPO}" \
    --repository-format=docker \
    --location="${REGION}" \
    --description="Docker repository for Kachava Cloud Run services" \
    --project="${PROJECT_ID}"
fi

echo "==> [3/4] Submitting Cloud Build to build & deploy ${SERVICE_NAME}..."
cd "${REPO_ROOT}"
gcloud builds submit \
  --config=deploy/cloudbuild.yaml \
  --project="${PROJECT_ID}" \
  .

echo "==> [4/4] Resolving deployed Cloud Run URL & updating web/admin prod.json..."
CLOUD_RUN_URL="$(gcloud run services describe "${SERVICE_NAME}" \
  --region="${REGION}" \
  --project="${PROJECT_ID}" \
  --format='value(status.url)')"

if [[ -z "${CLOUD_RUN_URL}" ]]; then
  echo "ERROR: Could not retrieve Cloud Run service URL for ${SERVICE_NAME}." >&2
  exit 1
fi

API_BASE_URL="${CLOUD_RUN_URL%/}/api/v1"

cat > "${REPO_ROOT}/web/config/prod.json" <<EOF
{
  "APP_ENV": "production",
  "API_BASE_URL": "${API_BASE_URL}",
  "GUEST_PORTAL_URL": "${GUEST_PORTAL_URL}",
  "SANCTUARY_PORTAL_URL": "${GUEST_PORTAL_URL}"
}
EOF

cat > "${REPO_ROOT}/admin/config/prod.json" <<EOF
{
  "APP_ENV": "production",
  "API_BASE_URL": "${API_BASE_URL}",
  "GUEST_PORTAL_URL": "${GUEST_PORTAL_URL}",
  "SANCTUARY_PORTAL_URL": "${GUEST_PORTAL_URL}"
}
EOF

echo "Backend deployed at: ${CLOUD_RUN_URL}"
echo "Updated web/config/prod.json and admin/config/prod.json with API_BASE_URL=${API_BASE_URL}"
