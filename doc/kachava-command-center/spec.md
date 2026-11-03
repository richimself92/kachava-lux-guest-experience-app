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
- Admin follows root [`DESIGN.md`](../../DESIGN.md); mockups win on conflict.
- Sidebar: "KACHAVA LUX" + gray "COMMAND CENTER" pill; selected = gray bg + bold; uppercase gray section
  labels; items without icons + gray chevron; scroll-down button on overflow.
- Dashboard: "Kachava Lux · Overview" + "Today" pill; 3x2 gray KPI tiles (radius 16, ~40px number);
  3-column activity table; chips In-house green / Arrival blue / Departure gray / overstay red; no alerts.
- Guest portal: brand look kept; 4 bottom tabs; min 14px text (12px labels); no jargon or numbered titles.
- Both apps: minimal text, `InfoTooltip` for explanations, one-line empty states and confirmations.
- Breakpoints reviewed at 1440, 800, 375 px; keyboard focus ring and AA contrast.
- Phase D (admin): tokens in `core/theme/kachava_tokens.dart`, full ThemeData (Roboto bundled); menu driven by
  `presentation/navigation/admin_nav_model.dart` (unbuilt modules hidden; Folio reached from stay detail);
  shared components in `presentation/components/`. Overview only restyled; KPI dashboard lands in Phase F.

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
