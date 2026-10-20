# Kachava Luxury Guest Experience — GCP Cloud Run & Firebase Hosting Deployment

This directory contains the production deployment configuration for the `kavacha-app` Google Cloud & Firebase project, engineered for **ultra-low cost** (scale-to-zero when idle) and high concurrency.

---

## Architecture & Cost Profile

| Component | Target Resource | Configuration | Cost Optimization |
| :--- | :--- | :--- | :--- |
| **Backend API (`backend/`)** | Cloud Run (`kachava-backend`, `us-central1`) | `1 vCPU`, `512Mi RAM`, `concurrency=80` | `min-instances=0`, `max-instances=2`, `--cpu-throttling` (Request-based billing; $0 when idle) |
| **Database** | Cloud Firestore (`kavacha-db`) | Named database in `us-central1` | Automatic cold-start hydration on first request after scale-to-zero |
| **Object Storage** | Cloud Storage (`kavacha-store`) | Signed V4 PUT/GET URLs | Direct browser-to-GCS uploads |
| **Guest Portal (`web/`)** | Firebase Hosting (`kavacha-app-guest-portal`) | Static Flutter Web SPA (`web/build/web`) | Global CDN with immutable asset caching |
| **Admin Dashboard (`admin/`)** | Firebase Hosting (`kavacha-app-admin-dashboard`) | Static Flutter Web SPA (`admin/build/web`) | Global CDN with immutable asset caching |

---

## Files in `deploy/`

- **`cloudbuild.yaml`**: Cloud Build pipeline that builds `backend/Dockerfile`, pushes the image to Artifact Registry (`us-central1-docker.pkg.dev/kavacha-app/cloud-run-source-deploy/kachava-backend`), and deploys `kachava-backend` to Cloud Run with `--min-instances=0`.
- **`cloudrun-service.yaml`**: Declarative Knative `serving.knative.dev/v1` Service manifest matching the Cloud Run runtime settings.
- **`deploy-backend.sh`**: Enables required GCP APIs, provisions the Artifact Registry repository if needed, triggers Cloud Build, resolves the live Cloud Run URL, and writes `"API_BASE_URL": "<CLOUD_RUN_URL>/api/v1"` into `web/config/prod.json` and `admin/config/prod.json`.
- **`deploy-hosting.sh`**: Ensures both Firebase Hosting sites (`kavacha-app-guest-portal` and `kavacha-app-admin-dashboard`) exist, compiles both Flutter Web apps using `--dart-define-from-file=config/prod.json`, and deploys them to Firebase Hosting.
- **`deploy-all.sh`**: End-to-end orchestrator that runs `./deploy/deploy-backend.sh` followed by `./deploy/deploy-hosting.sh`.

---

## Usage

### 1. Deploy Everything (Backend + Both Portals)
```bash
./deploy/deploy-all.sh
```

### 2. Deploy Only the Backend (Cloud Build -> Cloud Run)
```bash
./deploy/deploy-backend.sh
```

### 3. Deploy Only the Frontends (Flutter Web -> Firebase Hosting)
```bash
./deploy/deploy-hosting.sh
```
