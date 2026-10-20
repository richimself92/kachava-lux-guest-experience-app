# Kachava Lux — Digital Sanctuary Guest Experience & Operations Command Center

**Kachava Lux** is an ultra-luxury, bilingual (`ES / EN`) digital hospitality ecosystem and architectural sanctuary platform. It connects private villa guests—authenticated seamlessly via passwordless UUID v4 Magic Links—with the Host Admin & Concierge team in real time.

Built with a custom biophilic design system (*Travertine Limestone, Raw Silk, Obsidian Stone, Brushed Gold, and Terracotta Clay*), Kachava Lux orchestrates every touchpoint of the guest journey: from pre-arrival private aviation and airport transfers to bespoke stay personalization, villa larder provisioning, yacht charters, private chef dining, 24/7 concierge dispatch, and non-billing stay activity summaries.

---

## Live Cloud Environments (`kavacha-app` on Google Cloud & Firebase)

| Service / Portal | Platform | Live Production URL |
| :--- | :--- | :--- |
| **Guest Sanctuary Portal** | Firebase Hosting (`web/`) | [https://kavacha-app-guest-portal.web.app](https://kavacha-app-guest-portal.web.app) |
| **Admin & Concierge Command Center** | Firebase Hosting (`admin/`) | [https://kavacha-app-admin-dashboard.web.app](https://kavacha-app-admin-dashboard.web.app) |
| **Backend REST API** | Google Cloud Run (`us-central1`) | [https://kachava-backend-dwapx2x7fa-uc.a.run.app](https://kachava-backend-dwapx2x7fa-uc.a.run.app) |
| **API Health & Base Endpoint** | NestJS 11 (`api/v1`) | [https://kachava-backend-dwapx2x7fa-uc.a.run.app/api/v1/health](https://kachava-backend-dwapx2x7fa-uc.a.run.app/api/v1/health) |

---

## System Architecture

```mermaid
flowchart LR
    subgraph Clients["Frontend Portals (Firebase Hosting CDN)"]
        Guest["Guest Sanctuary Portal (Flutter 3.x Web)"]
        Admin["Admin & Concierge Command Center (Flutter 3.x Web)"]
    end

    subgraph CloudRun["Google Cloud Run (us-central1 | FinOps 0..2 Instances)"]
        API["Shared NestJS 11 REST API (/api/v1)"]
        Hex["Clean / Hexagonal Domain & Application Use Cases"]
    end

    subgraph Persistence["Google Cloud Persistence"]
        Firestore["Cloud Firestore (kavacha-db)"]
        Storage["Cloud Storage (kavacha-store)"]
    end

    Guest <-->|"2s Polling & REST Sync (?guestId=UUID)"| API
    Admin <-->|"Real-Time Dispatch & Operations"| API
    API --> Hex
    Hex <-->|"State Hydration & Dual-Write"| Firestore
    Hex <-->|"Photo & Media Assets"| Storage
```

---

## Current Features (`Funcionalidades Actuales`)

### 1. Guest Sanctuary Portal (`web/`)

- **Unified Responsive Mobile & Desktop Experience (`SanctuaryShell`)**:
  - **Mobile-Native Sanctuary (`< 768px`)**: Exact mobile-first experience with tactile bottom navigation bar (`SanctuaryBottomNav`: `Inicio`, `Explorar`, `Concierge`, `Estancia`), quick-access `todas las pantallas` (`All Sanctuary Screens`) modal drawer covering all `1..11` sanctuary modules, and floating action bar.
  - **Widescreen Desktop Sanctuary (`>= 768px`)**: Centered sanctuary container (`maxWidth: 960px`) with proportional typography scaling (`TextScaler.linear(1.18)`), preserving the exact same `1..11` options, bottom navigation bar (`SanctuaryBottomNav`), and `todas las pantallas` drawer without introducing a separate sidebar.
- **Mandatory Passwordless Magic Link Gate & Real-Time Sync**:
  - **Strict `?guestId=<uuid-v4>` Gate**: Accessing the root URL without a valid `?guestId=<uuid>` query parameter displays the **`Acceso Restringido — ID de Huésped Obligatorio`** security screen; valid links bind the guest session immediately with automatic 2-second bi-directional state synchronization and read-only lock upon Host Check-Out (`CHECK-OUT COMPLETADO`).
  - Instant language toggle (`ES / EN`) across all guest screens.
- **Step 1 — Private Aviation & Airport Transfer (`transport`)**:
  - Stay-bounded calendar date picker (`checkInDate .. checkOutDate`), airline, flight number, airport, terminal, estimated arrival time, and transfer notes.
  - Live synchronization of the assigned chauffeur name, vehicle, and airport meeting point dispatched by the Host Admin.
- **Step 2 — Stay Personalization (`personalize`)**:
  - Room climate temperature (`18°C – 26°C`), pillow atelier selection, welcome botanical scent, preferred daily housekeeping schedule (`Horario de Limpieza`), dietary profile, critical allergy alerts, and special occasion notes.
- **Step 3 — Minibar & Villa Larder (`stock-villa`)**:
  - Curated drinks, organic snacks, and gourmet pantry ordering with search and category filtering.
  - **Instant Stepper Reset on Order Confirmation**: Clicking `Confirmar Pedido` (`Confirm Order`) immediately resets all product steppers (`- 0 +`) back to `0` so guests can place additional replenishment orders at any time, while the top status banner tracks the active order (`⏳ Pedido Enviado · Pendiente` → `🛠️ En Preparación` → `✅ Entregado en Villa`) along with the exact ordered item quantities (`2x ...`).
- **Curated Experiences (`explore`), Private Yacht Charter (`yacht`) & In-Villa Chef Dining (`dining`)**:
  - Stay-bounded calendar date validation (`checkInDate .. checkOutDate`) preventing out-of-stay bookings.
  - Preset service time chips plus custom time picker (`⏰ Hora personalizada` via `showTimePicker`).
  - Clean dietary/table preference input fields with non-intrusive placeholder hints (`hintText`).
  - Locked reservation state upon submission with real-time Host Admin approval (`✅ Aprobado / Confirmado`) or cancellation with explicit reason (`❌ Cancelado + Motivo`).
- **24/7 Concierge & Live Chat (`concierge`)**:
  - 4-stage service & maintenance ticket tracker (`Requested → Assigned → In Progress → Completed`) with optional photo attachments.
  - Real-time bi-directional chat with the Host & Concierge team featuring `15px` high-legibility typography and `Enter`-to-send keyboard support.
- **Stay Feedback Survey (`midstay`)**:
  - Interactive 5-star rating (`1–5 ★`), sentiment selector, and open comment box with persistent submitted state.
- **Stay & Departure Summary (`departure`), Biophilic Architecture (`philosophy`) & Guest Profile / Wi-Fi (`profile`)**:
  - Dynamic per-villa/per-stay Wi-Fi SSID and passcode with one-tap copy, emergency contacts, architectural philosophy gallery, and a transparent non-billing summary of acquired stay experiences and minibar orders.

---

### 2. Admin & Concierge Command Center (`admin/`)

- **1. Live Summary & Alerts (`OverviewWorkspace`)**:
  - Real-time operational alert feed with unread badge counters across navigation tabs.
  - **10-Second WebAudio Synthesis Chime**: Triggered exclusively by incoming guest actions (flight updates, stay preferences, minibar orders, experience/yacht/dining bookings, survey submissions, and guest chat messages).
- **2. Villas, Guests, Magic Links & Transfers (`StaysWorkspace`)**:
  - **8-Villa Visual Occupancy Board**: Live status badges (`🟢 LIBRE` / `🔴 OCUPADA`) for Villas 101–108.
  - **Stay Creation & Magic Link Generator**: Create new guest stays on available villas with automatic nights calculation (`checkOut - checkIn`), configurable per-villa/per-stay Wi-Fi credentials, and one-click Magic Link copying.
  - **Guest Preferences & Flight Dispatch Panel**: Framed summary of guest comfort, scent, cleaning schedule, diet, and critical allergies alongside full flight metadata and Chauffeur / Meeting Point assignment.
  - **Host-Only Check-Out Confirmation Modal**: Dedicated confirmation dialog displaying the complete stay summary (stay dates, acquired experiences, minibar orders, and concierge activity) before executing check-out and releasing the villa back to `🟢 LIBRE`.
- **3. Pre-Arrival Minibar & Pantry (`LarderWorkspace`)**:
  - Dynamic product catalog management (create and delete minibar/pantry SKUs with bilingual titles, categories, and prices).
  - Per-stay order fulfillment cards displaying exact requested item quantities (`Cantidad: Nx`) and 3-stage status progression (`Pending → Assigned → Stocked in Villa`).
- **4. Yacht, Private Dining & Tours (`ExperiencesWorkspace`)**:
  - Dynamic experience catalog management (create and delete curated experiences across Yacht, Dining, Wellness, and Excursions).
  - Real-time guest booking management with one-click approval (`Aprobar / Confirmar`) or cancellation with mandatory reason modal (`Cancelar con Motivo`), syncing immediately to the guest's portal.
- **5. 24/7 Chat & Concierge Dispatch (`ConciergeWorkspace`)**:
  - 4-stage ticket lifecycle control (`Requested → Assigned → In Progress → Completed`), staff assignment, maintenance photo attachment lightbox preview, and real-time bi-directional Host chat.
- **6. Stay Summary & Guest Feedback (`FolioWorkspace`)**:
  - Consolidated dashboard of guest feedback surveys (`¿Cómo va tu estancia?` star ratings, sentiment, and comments) and complete per-stay activity summaries without credit card billing or guest self-checkout.

---

## Technology Stack & FinOps Cloud Architecture

| Layer | Technology | Highlights |
| :--- | :--- | :--- |
| **Guest & Admin Frontends** | `Flutter 3.x Web` (`Dart 3`) | Material 3 custom biophilic design system (`Travertine`, `Obsidian`, `Brushed Gold`), custom SVG favicons, responsive mobile & desktop layouts. |
| **Backend API** | `NestJS 11` (`Node.js 22 Alpine`, `TypeScript`) | Clean / Hexagonal Architecture (Ports & Adapters), strict DTO validation, REST `/api/v1` endpoints, and real-time polling state sync. |
| **Database & Storage** | `Google Cloud Firestore` (`kavacha-db`) & `Cloud Storage` (`kavacha-store`) | Automatic cold-start state hydration from Firestore with resilient dual-write persistence and media storage bucket. |
| **Cloud Infrastructure & FinOps** | `Google Cloud Run` + `Cloud Build` + `Firebase Hosting` | Serverless container scaling (`--min-instances=0`, `--max-instances=2`, `1 vCPU`, `512Mi RAM`, `--cpu-throttling`, `--concurrency=80`) achieving **$0 idle compute cost**, paired with global Firebase Hosting multi-site CDN. |
| **Quality Assurance & Testing** | `Jest`, `Flutter Test`, `Playwright` | Backend unit & integration tests (`backend/`), Flutter widget & controller tests (`web/`, `admin/`), and automated Playwright Chromium E2E test suites (`e2e/`). |

---

## Repository Structure

```text
kachava-lux-guest-experience-app/
├── web/                        # Guest Sanctuary Portal (Flutter 3.x Web)
│   ├── config/                 # Environment configs (dev.json, prod.json)
│   ├── lib/
│   │   ├── application/        # SanctuaryController & state orchestration
│   │   ├── core/               # Biophilic theme, typography, i18n, audio
│   │   ├── data/               # Remote API client, wire mapper, seed data
│   │   ├── domain/             # Immutable domain entities & repositories
│   │   └── presentation/       # Responsive SanctuaryShell & 12 sanctuary screens
│   └── test/                   # Unit & widget test suites
├── admin/                      # Admin & Concierge Command Center (Flutter 3.x Web)
│   ├── config/                 # Environment configs (dev.json, prod.json)
│   ├── lib/                    # 6 operational workspaces & WebAudio alert engine
│   └── test/                   # Admin dashboard widget tests
├── backend/                    # Shared NestJS 11 REST API (Clean/Hexagonal)
│   ├── src/
│   │   ├── modules/            # Auth, Stays, Larder, Experiences, Concierge, Folio, Sync
│   │   └── shared/             # Firestore & Storage infrastructure adapters
│   ├── test/                   # Jest unit & E2E API specifications
│   └── Dockerfile              # Multi-stage Node 22 Alpine production container
├── deploy/                     # Cloud Run & Firebase Hosting deployment automation
│   ├── cloudbuild.yaml         # Google Cloud Build pipeline specification
│   ├── deploy-backend.sh       # Cloud Build + Cloud Run deployment & prod.json sync
│   ├── deploy-hosting.sh       # Flutter Web release builds + Firebase multi-site deploy
│   └── deploy-all.sh           # One-command full-stack cloud deployment
├── e2e/                        # Playwright Chromium End-to-End validation suites
├── firebase.json               # Firebase Hosting multi-site & Firestore/Storage rules config
└── run-local.sh                # Unified local full-stack launcher (ports 3000, 3001, 3002)
```

---

## Local Development & Execution (`./run-local.sh`)

### Prerequisites

- **Node.js** `>= 22.x` & **npm**
- **Flutter SDK** `>= 3.x` (with Web support enabled)
- **Python 3** (used by `run-local.sh` to serve prebuilt static bundles rapidly)

### Launch the Full Local Ecosystem

Run the unified launcher from the repository root to start the NestJS Backend, Guest Sanctuary Portal, and Admin Command Center concurrently:

```bash
# Default mode (serves prebuilt web/build/web & admin/build/web if present, or runs flutter)
./run-local.sh

# Live development mode (forces live `flutter run -d web-server` compilation)
./run-local.sh --dev
```

Once started, the local services are available at:

- **Guest Sanctuary Portal (with Demo Magic Link)**: `http://localhost:3000/?guestId=550e8400-e29b-41d4-a716-446655440000`
- **Admin & Concierge Command Center**: `http://localhost:3002`
- **Shared NestJS Backend API**: `http://localhost:3001/api/v1`

---

## Guía Paso a Paso de Prueba End-to-End (End-to-End Testing Walkthrough)

Follow this 4-step walkthrough to validate the complete real-time bi-directional flow between the **Host Admin** and the **Guest**:

### Paso 1 — Crear la Estancia y Generar el Magic Link (Host Admin)

1. Open the Admin Command Center at [https://kavacha-app-admin-dashboard.web.app](https://kavacha-app-admin-dashboard.web.app) and navigate to **`2. Villas, Huéspedes, Links y Traslados`** (`2. Villas, Guests, Links & Transfers`).
2. Verify that all 8 Villas display **`🟢 LIBRE`** (`🟢 FREE`). Click **`+ Nueva Estancia / Generar Magic Link`**, enter the Guest Name (`Familia Gómez`), select **`Villa 102 — Ceiba Suite`**, and pick the Check-In / Check-Out dates (`19 Oct` to `22 Oct` → automatically calculates `3 noches`).
3. Click **`Crear y Generar Link`**: `Villa 102` immediately transitions to **`🔴 OCUPADA`** (`🔴 OCCUPIED`). Copy the generated Magic Link (`https://kavacha-app-guest-portal.web.app/?guestId=<uuid>`).
4. **Security Gate Validation**: Open [https://kavacha-app-guest-portal.web.app](https://kavacha-app-guest-portal.web.app) *without* `?guestId=...` and confirm that the portal blocks access with the **`Acceso Restringido — ID de Huésped Obligatorio`** screen.

### Paso 2 — Pre-Llegada del Huésped: Vuelo, Confort y Minibar (Huésped)

1. Open the copied Magic Link (`?guestId=<uuid>`) on Mobile (`< 768px`) or Desktop (`>= 768px`) and toggle `EN | ES` in the top header as desired.
2. **`1. Registrar Vuelo y Transporte`**: Pick the arrival date from the stay-bounded calendar, enter the airline (`Aeroméxico`), flight number (`AM 542`), airport (`CUN`), terminal (`T2`), and arrival time (`2:30 PM`), then click **`Guardar y Sincronizar Vuelo`**.
3. **`2. Confort, Aroma, Dieta y Alergias`**: Select your pillow preference, welcome botanical scent, **`Horario de Limpieza`** (`Mañana (09:00 - 11:00)`), dietary profile, and allergy notes, then click **`Guardar Preferencias`**.
4. **`3. Pedir Bebidas y Minibar`**: Increment product quantities (`+`, e.g., `2`) and click **`Confirmar Pedido`**. Verify that all product steppers (`- 0 +`) **immediately reset to `0`** so you can place additional orders anytime, while the top status banner displays **`⏳ Pedido Enviado · Pendiente`** along with the ordered items (`2x ...`).

### Paso 3 — Recepción de Alertas en Vivo y Atención (Host Admin)

1. Return to the Host Admin console: verify the **10-second WebAudio chime** and the real-time operational notifications in **`1. Resumen y Alertas en Vivo`**.
2. In **`2. Villas, Huéspedes, Links y Traslados`**, inspect the guest's complete flight details and housekeeping schedule; assign the chauffeur name and airport meeting point, then click **`Guardar y Enviar al Huésped`** (reflected live on the guest's screen `1`).
3. In **`3. Minibar y Despensa Pre-Llegada`**, verify the exact item count (`Cantidad: 2x`), advance the order status to **`En Preparación`**, and then to **`Entregado en Villa`** (the guest's top banner updates live to **`✅ Entregado en Villa`**).

### Paso 4 — Cena con Chef Privado, Encuesta y Check-Out Final (Ambos Roles)

1. **Huésped** → **`6. Cena con Chef Privado en Villa`**: Select a tasting menu, pick a stay-bounded date, choose a preset chip or custom time (**`⏰ Hora personalizada`**), enter an optional dietary note over the clean placeholder, and submit (**`⏳ Pendiente de Aprobación`**).
2. **Host Admin** → **`4. Yate, Cena Privada y Tours`**: Click **`Aprobar / Confirmar`** (or **`Cancelar con Motivo`** to verify real-time cancellation reason synchronization on the guest portal).
3. **Huésped** → **`8. ¿Cómo va tu estancia?`**: Select **`5 ★`**, choose a sentiment tag, add a comment, and submit.
4. **Host Admin** → Open **`6. Resumen de Estancia y Calificación`** to review the 5-star feedback and full stay summary, then in **`2. Villas, Huéspedes, Links y Traslados`** click **`Dar Salida / Liberar Villa`** and confirm inside the Stay Summary modal (**`Confirmar Check-Out y Liberar Villa`**). Verify that `Villa 102` returns to **`🟢 LIBRE`** and the guest's Magic Link locks into read-only mode (**`CHECK-OUT COMPLETADO`**).

---

## Running Tests & Static Analysis

```bash
# 1. Guest Sanctuary Portal (web/) — Static Analysis & Widget/Unit Tests
cd web && flutter analyze && flutter test

# 2. Admin Command Center (admin/) — Static Analysis & Widget Tests
cd admin && flutter analyze && flutter test

# 3. Shared NestJS Backend (backend/) — Unit & API Integration Tests
cd backend && npm test

# 4. End-to-End Browser Verification (e2e/) — Playwright Chromium Suite
cd e2e && npx playwright test
```

---

## Cloud Deployment (`./deploy/deploy-all.sh`)

The production environment is hosted on Google Cloud Platform (`PROJECT_ID=kavacha-app`, region `us-central1`) and Firebase Hosting.

```bash
# Full-stack deployment (Cloud Run Backend + Both Firebase Hosting Portals)
./deploy/deploy-all.sh

# Or deploy individual tiers:
./deploy/deploy-backend.sh   # Builds Docker image via Cloud Build, deploys Cloud Run, updates config/prod.json
./deploy/deploy-hosting.sh   # Compiles Flutter Web release bundles and deploys to Firebase Hosting
```
