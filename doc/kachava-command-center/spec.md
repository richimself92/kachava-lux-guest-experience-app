# Kachava Command Center — Feature Spec
Inputs (read-only): client spec [`../improvements/spec.md`](../improvements/spec.md) and mockups
`../improvements/*.jpeg`. Approved delivery plan (phases A-K, Spanish): [`plan.md`](plan.md).

## Product
- US-01 Guest opens a magic link and always sees their own stay, on any backend instance.
  - AC-01 No demo guest ("Alex & Sarah Miller", Villa 102) ever renders; loading state until the server answers.
  - AC-02 Only 401/403/404 show "link invalid/expired"; 5xx/429/timeouts keep last data + "Reconnecting".
  - AC-03 Success messages only after the server confirms.
- US-02 Staff create a stay and share a working link.
  - AC-04 On API failure the admin shows an error; never a locally invented UUID/link.
- US-03 Guest installs the portal (Android/iOS) and reopens it without the link.
  - AC-05 Installed app opens with the stored `guestId`; a newer link replaces it; 401/404 clears it.
- US-04 Staff navigate a sectioned Command Center matching the client mockup (Villas; no Folio, no TEAM).
- US-05 Staff see today's overview: 6 KPIs + guest activity (Guest, Villa, Status); row -> detail with
  Resort Host, internal notes and Stay summary (folio).
- US-06 Staff configure every hospitality service (create/edit/disable; ORDER/BOOKING/PREFERENCE/TRIP).
  - AC-06 Guests only see ACTIVE services; missing Spanish shows "translation pending"; no invented prices.
- US-07 Staff manage transportation trips (ARRIVAL/DEPARTURE/LOCAL) with an external provider.
- US-08 Guest uses a simple 4-tab portal: Home, Services, My requests, Resort Host.
- US-09 Staff track tasks (Pending -> Assigned -> In Progress -> Completed) and notifications by severity.
- US-10 Staff manage Reservations, Guests and Villas (housekeeping/maintenance).
Pending from Kachava: service copy/prices/photos, real villa names, Spanish copy approval.

## Design
- Admin follows root [`DESIGN.md`](../../DESIGN.md); mockups win on conflict. List/screen rules live in [`ux-patterns.md`](ux-patterns.md) and are mandatory.
- Sidebar: "KACHAVA LUX" + gray "COMMAND CENTER" pill; selected = restrained brown tint + bold brown text; uppercase gray section labels; items without icons + chevron.
- Dashboard: "Kachava Lux · Overview" + "Today" pill; 3x2 KPI tiles; 3-column activity table (max 8 rows + "View all"); no alerts.
- Lists: header (title + 1 primary action) > toolbar (debounced search, <= 3 filter chips, active-filter summary + "Clear") > sortable table with sticky header.
- Pagination 10/25/50 (default 25), "1-25 of N"; one `ListQuery {page,pageSize,sort,q,filters}` (client-side now, API-ready); filters persist per screen.
- Row click: right panel (desktop) / full-screen sheet (mobile). Mobile: compact rows (2-3 fields), filters in bottom sheet.
- States: skeleton, one-line empty + action, "No results" + clear filters, error + retry. Toasts one line, auto-dismiss.
- No global top-bar search/filter chips; each screen owns its toolbar. No debug controls ("Test 10s") in production UI.
- Chips use the shared vocabulary (no raw enums). Dates in America/Cancun. Destructive actions use `ConfirmDialog`.
- Both apps: minimal text, `InfoTooltip` for explanations. Breakpoints reviewed at 1440, 800, 375 px; focus ring + AA contrast.
- Phase D (admin): tokens in `core/theme/kachava_tokens.dart`; menu from `presentation/navigation/admin_nav_model.dart`; shared components in `presentation/components/`.

### Guest
Full rules and wireframes: [`guest-ux.md`](guest-ux.md). Brand look kept (not root `DESIGN.md`); text >= 14px, 48px targets, AA contrast.
- 4 bottom tabs: Home (guided journey) · Services · Requests · Host. No "all screens" drawer.
- Home = numbered journey built from the catalog: Step 1 Before arrival, 2 During stay, 3 Departure; tasks 1.1, 1.2... (core tasks in fixed slots, then one task per catalog section by `offeredWhen`).
- Current step open by resort date, others collapsed (headers are buttons); "2 of 4" progress, ✓ per task; sticky "Next" + "Not now" for skippable tasks.
- Steps with 10+ services show sections (max 5 rows, then "See all"); long forms (flight/TRIP) are wizards.
- Services: search + section chips, photo cards (name, one line, price or "Included", lead time), detail sheet with gallery, form by usage type.
- Requests: one list, Received → Confirmed → Preparing / On the way → Done; change/cancel while Received.
- Success only after server confirmation; one-line toasts; skeleton, error + Retry and one-line empty states.

## Architecture
- Firestore is the single source of truth, per-request reads, awaited writes ([adr-008](adr-008-firestore-single-source-of-truth.md)).
- Guests get an allow-list projection of the stay ([adr-007](adr-007-guest-safe-stay-view.md)).
- Resort clock `America/Cancun`, ISO `YYYY-MM-DD` dates ([adr-005](adr-005-resort-clock-america-cancun.md)).
- One configurable catalog `catalog_services` ([adr-004](adr-004-unified-service-catalog.md)).
- Tasks are their own collection with a pure transition function ([adr-006](adr-006-tasks-as-entity.md)).
- Admin polls one `GET /admin/sync` every 5 s; guest polls every 10 s; never overlapping.
- Throttling per guest/admin token (300/min) plus per IP (1500/min) behind `trust proxy`.
- Admin requires a staff bearer token (no fallback identity); production secrets fail fast if missing.
- Web-only APIs (localStorage, install prompt) behind ports with conditional imports.
- Migration/cleanup scripts: `--dry-run`, export first, production only with owner approval.
