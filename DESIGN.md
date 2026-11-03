# Kachava Lux — DESIGN.md (Staff Command Center)
Version: 1.1 | 2 November 2026
Scope: look and feel of the **admin** Flutter Web app (`admin/`). Functional scope lives in
[`doc/improvements/spec.md`](doc/improvements/spec.md); the delivery plan in [`doc/kachava-command-center/plan.md`](doc/kachava-command-center/plan.md).
The guest portal (`web/`) keeps its brand-led direction (Libre Baskerville / Libre Franklin) but follows the
clean-UI principle below. Precedence: security and accessibility > working functionality > client mockups
(`doc/improvements/*.jpeg`) > this file > Material Design 3.

## Design philosophy
Calm, efficient operations tool inspired by Google Workspace: white canvas, subtle gray surfaces, restrained
Kachava identity, high information clarity and low visual noise.

## Clean UI principle (admin and guest portal)
- Nothing should feel overwhelming: one primary goal and one primary action per screen.
- Minimal on-screen text: short titles, 1-3 word labels. No explanatory paragraphs, instruction banners,
  decorative subtitles or eyebrows.
- Explanations go in an `InfoTooltip` (ⓘ) next to the value: hover/keyboard focus on desktop, tap on mobile,
  exposed to screen readers via `Tooltip`/`Semantics`.
- Empty states are one line plus an action. Confirmations are one line and dismiss themselves.
- Generous whitespace, few cards, no extra borders or colors. Icons always have labels.

## Design tokens
```css
:root {
  --kl-color-background: #FFFFFF;   --kl-color-surface: #F3F3F1;
  --kl-color-primary: #6D4627;      --kl-color-accent: #989166;
  --kl-color-text: #202124;         --kl-color-text-secondary: #5F6368;
  --kl-color-border: #DADCE0;       --kl-color-input-border: #80868B;
  --kl-color-on-primary: #FFFFFF;   --kl-color-focus: #1A73E8;
  --kl-radius-sm: 4px; --kl-radius-md: 8px; --kl-radius-lg: 12px; --kl-radius-tile: 16px;
  --kl-space-1: 4px; --kl-space-2: 8px; --kl-space-3: 12px; --kl-space-4: 16px;
  --kl-space-6: 24px; --kl-space-8: 32px;
  --kl-font-ui: "Roboto", Arial, sans-serif;
}
```
Status chips (light background + dark text, AA contrast): In-house green, Arrival blue, Departure gray,
overstay / urgent red. Semantic colors are defined and contrast-tested in code; never brown/olive for errors.

### Color roles
- White: page background and tables. Soft gray `#F3F3F1`: selected nav item, KPI tiles, filters, hover.
- Brown: primary buttons and restrained brand emphasis (white text). **Not** used for selected navigation.
- Olive: rare accent, never text and never the only carrier of status.
- Input borders `#80868B` (3:1 non-text contrast); hairline `#DADCE0` for separators only.
- Focus: double ring (2px `#1A73E8` + 2px white) always visible on keyboard focus.

## Typography
Roboto (bundled) with Arial fallback. Page title 24/32 w500; section 18/26 w500; body and table cells
14/20 w400; labels and nav 14/20 w500 (selected nav w700); supporting 12/16, only where legible; KPI value
~40px w400. No Libre Baskerville in admin tables or controls.

## Navigation (client mockup is binding)
- Header: "KACHAVA LUX" left, gray pill "COMMAND CENTER" right, hairline divider below.
- Dashboard item with a grid icon. Selected item: light gray rounded background + bold text.
- Section labels: small, uppercase, gray, not clickable.
- Items: no icons, regular weight, gray chevron ">" right, generous vertical spacing. When the list
  overflows, a circular "scroll down" button appears at the bottom.
- Information architecture, no numeric prefixes:
  - Dashboard
  - GUEST OPERATIONS: Reservations, Guests, Villas
  - HOSPITALITY: Services, Experiences, Dining, Transportation, Wellness
  - OPERATIONS: Tasks, Notifications
- TEAM (Resort Hosts, Staff) is deferred. Folio is not a menu item: it is the "Stay summary" tab inside
  Guest / Reservation detail. Modules not yet built are hidden, never shown disabled.
- Desktop: persistent sidebar. Tablet: navigation rail. Mobile: drawer. Keep keys `nav-tab-<id>` / `workspace-<id>`.

## Dashboard (client mockup is binding)
1. Title "Kachava Lux · Overview" with a "Today" pill (resort date, America/Cancun).
2. 3x2 grid of light-gray `KpiTile`s (radius 16, big number, gray label): Occupied villas, Available villas,
   Occupancy, Arrivals, Departures, Open requests. Formulas in an ⓘ tooltip.
3. "Today's guest activity": table with exactly 3 columns — Guest, Villa, Status — thin separators, no card
   border. A row opens the detail (assigned Resort Host, internal notes, Stay summary tab).
4. No alerts on the dashboard: they live in Notifications. Unavailable data shows `UnavailableValue` ("—" with
   tooltip), never simulated numbers.

## Module responsibilities
Reservations (table + villa x day calendar; origin and payments show "No PMS integration"), Guests (profile
per stay, preferences, allergies, request history, internal notes, chat), Villas (eight units, occupancy,
housekeeping, maintenance), Services (master catalog: EN/ES copy, pricing, lead time, provider, status
DRAFT/ACTIVE/DISABLED, request type ORDER/BOOKING/PREFERENCE/TRIP), Experiences / Dining / Transportation /
Wellness (one `ServiceCategoryWorkspace(category)`: filtered catalog on top, its requests below; Transportation
adds providers and trips ARRIVAL/DEPARTURE/LOCAL), Tasks (owner, villa, priority, due, state, completion),
Notifications (Info / Action needed / Urgent, "Open record" link; sound only for urgent).

## Components
`AdminDataTable`, `StatusChip`, `KpiTile`, `AsyncStateView` (loading/empty/error), `ConfirmDialog` for
destructive actions, `UnavailableValue`, `InfoTooltip`. Tables over cards for dense data; radii 4-16px;
borders over shadows; Material Symbols icons only. Never show fake success.

## Content and terminology
- "Resort Host", never "Concierge"; "Villas", never "Residences".
- EN/ES via `AdminI18n`; never machine-invent Spanish, names, prices, providers, amenities or lead times.
  Missing Spanish catalog copy shows "translation pending".
- Everything hospitality-related is configured in the admin; no hardcoded service lists in either app.

## Roles and security
Role-based access (Master Admin, Resort Host, Housekeeping). Guest profiles and internal notes are visible
only to HOST_ADMIN and CONCIERGE_STAFF. Guests receive a guest-safe stay projection (ADR-007).

## Acceptance checklist
- [ ] Navigation hierarchy and visuals match the client mockup; no numeric prefixes
- [ ] Roboto bundled; tokens applied by role; AA contrast and visible focus
- [ ] Dashboard: 6 KPI tiles + 3-column activity table, no alerts
- [ ] Loading / empty / error states; no fabricated data or success
- [ ] Screenshots at 1440, 800 and 375 px reviewed ("is any text unnecessary?")
