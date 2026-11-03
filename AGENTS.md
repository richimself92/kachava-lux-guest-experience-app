# AGENTS.md — Kachava Lux Guest Experience & Command Center

## 1. Project overview and stack
Monorepo for a boutique villa resort (Kachava Lux, 8 villas):
- `backend/` — NestJS 10 REST API (`/api/v1`) on Cloud Run; Firestore named DB `kavacha-db` is the single
  source of truth (ADR-008); Cloud Storage `kavacha-store` for signed uploads.
- `web/` — Flutter Web guest portal (magic link `?guestId=<uuid>`, installable PWA).
- `admin/` — Flutter Web staff "Command Center" (HOST_ADMIN / CONCIERGE_STAFF roles).
- `e2e/` — Playwright suites against the local stack.
- `doc/` — specs, ADRs (`doc/adr/`), client inputs (`doc/improvements/`: spec + mockups, read-only), feature docs (`doc/kachava-command-center/`).

## 2. Executable commands
```bash
cd backend && npm run typecheck && npm test        # Jest unit + Supertest e2e (in-memory adapters)
cd admin   && dart analyze && flutter test
cd web     && dart analyze && flutter test
./run-local.sh                                     # backend :3001, guest :3000, admin :3002 (in-memory by default)
cd e2e && npx playwright test                      # requires run-local.sh running
```
Flutter builds use `--dart-define-from-file=config/<env>.json` in `web/` and `admin/`.

## 3. Safety rules
- Never deploy from an agent (`firebase deploy`, `gcloud run deploy`, `deploy/*.sh`, Cloud Build) without the
  owner's explicit approval. Never change live Cloud Run settings.
- Google ADC credentials may exist on dev machines: run the backend with `USE_FIRESTORE=false` or with
  `FIRESTORE_EMULATOR_HOST` set. Never run `npm run seed:firestore` or migration/cleanup scripts against
  production; every such script must support `--dry-run`.
- Never commit secrets (`.env*`, service accounts, keys). Stage files selectively; never `git add .`.
- Never push to `main`; work on feature branches; conventional commits in English.

## 4. Architecture and coding conventions
- Strict TDD (red -> green -> refactor). Functions < 30 lines, classes < 300 lines, nesting <= 3.
- DIP via ports: repositories, clocks (`ResortClockPort`, America/Cancun), storage, audio, browser storage.
  Web-only APIs use the conditional-import pattern of `admin/lib/core/alert_chime_port.dart`.
- English-only code, comments, commits. User strings EN/ES via `AdminI18n` / `GuestI18n`.
- No fake fallback data: API failures show errors; success only after the server confirms.
  Only HTTP 401/404 means an invalid guest link; 5xx/429/timeouts keep last data and show "Reconnecting".
- Guests receive a guest-safe projection of the stay (ADR-007); internal notes never leave admin routes.
- Hospitality services come from one admin-configurable catalog (ADR-004); no hardcoded service lists.
- Keep admin widget keys `nav-tab-<id>` / `workspace-<id>` stable for tests.

## 5. Design and memory
- Admin UI/UX: [`DESIGN.md`](DESIGN.md) is **owned by the client — agents must NEVER edit it**; implementation notes go in `doc/kachava-command-center/`. Client mockups in `doc/improvements/*.jpeg` define only menu/dashboard structure and order; colors, radii and type always come from DESIGN.md (e.g. selected nav = restrained brown, radii 4–12px).
- Clean UI principle for both apps: minimal text, explanations in `InfoTooltip`, one-line empty states.
- ADRs: [`doc/adr/`](doc/adr/) (001-003) and [`doc/kachava-command-center/`](doc/kachava-command-center/) (adr-004+). Persistent agent memory: `context/memory/MEMORY.md` (local, gitignored).
