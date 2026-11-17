# Kachava Lux — DESIGN.md
Version: 2.0 | 16 November 2026
Status: Visual layer replaced by the client's MUJI Design Implementation Guide (13 Nov 2026), adopted by the owner for both apps. Navigation, modules, content and roles from v1.0 are unchanged.

## Scope and precedence
This file governs the **Staff Command Center** and, for the visual layer (tokens, type, edges, motion), the **Guest Experience App**. The guest app keeps its own information architecture and numbered journey. Source of the visual layer: `MUJI Design Implementation Guide.md` (repo root); where v1.0 and the guide differed, the guide wins. Material Design 3 is the reference for interaction, accessibility, states, navigation and components; this file defines Kachava-specific choices. Do not assume this is a Google-authored specification or that Google Labs DESIGN.md mandates this schema.

Priority: security and accessibility > existing working functionality > this file > design references. The approved Digital Product Library governs names, copy, photography and operational facts. If sources conflict, stop and ask the product owner.

## Design philosophy
MUJI / Kenya Hara: a calm, efficient tool with high information clarity and low visual noise. When in doubt, remove rather than add. Seven rules:

1. **Paper, never white.** Warm off-white page; pure #FFFFFF is not used for app surfaces.
2. **One accent.** Kachava brown is the only decorative color; status colors only carry meaning and are muted.
3. **Rules, not boxes.** Separate content with 1px hairlines and top rules instead of cards, fills and shadows.
4. **Square edges.** 2px radius everywhere; no pills or rounded cards (only genuinely round things: dots, avatars, step numbers).
5. **No shadows.** Depth comes from a lighter surface and a hairline.
6. **Quiet type.** Two families, weights 400 and 500, small letter-spaced uppercase labels for hierarchy.
7. **Imperceptible motion.** ~220ms fades only; no slides, bounces or scale.

## Design tokens (both apps)
Define every color once as a token; never write a hex value in a widget.

```css
:root {
  --kl-color-paper: #F4F2EC;       /* page background, browser theme-color */
  --kl-color-surface: #FAF9F5;     /* tables, dialogs, inputs, sheets */
  --kl-color-wash: #ECE9E1;        /* hover, quiet fills, selected nav */
  --kl-color-ink: #2A2A28;         /* primary text, focus outline */
  --kl-color-muted: #6B6A65;       /* secondary text, labels */
  --kl-color-faint: #A3A097;       /* placeholder, disabled */
  --kl-color-line: #D9D6CD;        /* hairlines */
  --kl-color-line-strong: #C2BEB2; /* button and input outlines */
  --kl-color-brand: #6D4627;       /* the single accent */
  --kl-color-brand-deep: #55361D;  /* primary hover */
  --kl-color-pending: #8F611A;     /* ochre: unreviewed / high priority */
  --kl-color-info: #3F5A7A;        /* ink blue: acknowledged / in progress */
  --kl-color-ok: #4F6B3A;          /* moss: completed */
  --kl-color-danger: #A8322D;      /* brick: urgent, overdue, errors */
  --kl-color-plum: #6E4E6B;        /* on hold */
  --kl-radius: 2px;
  --kl-motion: 220ms cubic-bezier(0.2, 0, 0, 1);
  --kl-font-display: "Zen Kaku Gothic New", "Noto Sans", sans-serif;
  --kl-font-body: "Noto Sans", "Helvetica Neue", Arial, sans-serif;
}
```

### Color roles
- Paper: page background. Surface: tables, dialogs, inputs. Wash: hover and quiet fills.
- Brown: primary buttons (one per screen) and the active-navigation marker. Light text on brown.
- Each status color has a `-wash` background and `-line` border; a status label always uses all three (text, wash, line). Status text on its wash meets WCAG AA.
- Never use a cool grey next to the warm accent; never substitute brown for an error state.
- Focus: 1.5px ink outline with 2px offset, always visible.

## Typography
Both apps: **Zen Kaku Gothic New** for titles and labels, **Noto Sans** for body text (OFL, bundled as assets, subset to Latin incl. Spanish).
- Weights 400 for text and 500 for emphasis; no 600/700 (600 only for bold inside rich text).
- Headings: display font, weight 500, letter-spacing 0.02em.
- Page titles: 26px on phones, 32px from 600px wide. Body and table cells 14px; supporting text 12px minimum.
- Signature label (`klLabel`): display font, 11px, weight 500, letter-spacing 0.14em, uppercase, muted. Used for section eyebrows ("02 — Status"), form labels, table headers and metric labels; never as numeric prefixes in the navigation.
- Tabular figures wherever numbers sit in columns or update live (counts, prices, dates, times).
- Inputs use 16px text on touch screens (no iOS zoom).

## Navigation
Use this exact information architecture; no numeric prefixes:

- Dashboard
- GUEST OPERATIONS: Reservations, Guests, Residences
- HOSPITALITY: Services, Experiences, Dining, Transportation, Wellness
- OPERATIONS: Tasks, Notifications
- TEAM: Resort Hosts, Staff

Use a persistent desktop sidebar and an accessible compact/mobile navigation pattern. Selected item: wash background plus a 1px brown rule on its left edge. Counts are plain tabular numbers (ochre when actionable), not pills. Section headings are labels, not clickable duplicate destinations. Badges only for actionable counts.

## Dashboard
Place operational overview first, then activity and exceptions:
1. Current local property date and selected reporting period.
2. Arrivals, Departures, In House, Villa Nights, Reservations, Cancellations, Overbookings.
3. Occupancy %, Available Units, Reserved Units, Out of Service and Blocked Dates.
4. Today's guest activity table: Guest, Residence, Stay, Status, Assigned Resort Host, Notes.
5. Open Requests and Tasks, then Notifications and urgent Alerts.

Do not fabricate metrics. Use existing verified data sources; if Cloudbeds integration is unavailable, label metrics unavailable rather than simulating live production values. Clearly define metric formulas and date boundaries with Juan.

## Module responsibilities
**Reservations:** search, filter, arrival/departure, reservation state, assigned Resort Host; source of truth must be confirmed before editing.
**Guests:** guest profile, communication, language, approved preferences, linked stays and requests; protect sensitive information.
**Residences:** eight-unit inventory, category, occupancy, housekeeping status, out-of-service/blocked periods.
**Services:** shared catalog, approval/visibility, bilingual copy, inclusion/pricing and request rules.
**Experiences:** guest-facing curated experiences and operational bookings.
**Dining:** breakfast and special dining requests, scheduling and dietary needs with appropriate access controls.
**Transportation:** airport/local transfers, timing, flight details where needed, assigned driver and status.
**Wellness:** treatment requests, practitioners, availability and confirmation.
**Tasks:** owner, residence, priority, due time, state, completion evidence.
**Notifications:** event-driven alerts with links to originating records; sound reserved for genuinely urgent guest actions.
**Resort Hosts:** assignment, availability, workload, linked guest conversations.
**Staff:** role and access administration, active status, assigned operational tasks.

Services/Experiences/Dining/Transportation/Wellness should share a coherent service/request data model rather than duplicate unrelated catalogs.

## Interaction and components
- Prefer existing React/UI infrastructure and reusable components. Do not install a new Material UI library without an impact estimate.
- Use consistent top app bar, sidebar, tables, search, filters, dialogs, forms, tabs, buttons, menus and status chips.
- Favor tables for dense operational information. KPI summaries sit in a hairline grid (cells on a line-colored background with 1px gaps), not separate cards.
- Section blocks use a 1px top rule; callouts use a 2px left rule in the status color. Tabs and segmented switches are text-only (selected = ink with a bottom rule).
- Buttons: primary filled brown (one per screen), secondary outlined, quiet underlined text action, 40px square icon buttons. Tap targets 44px primary / 40px secondary.
- Radius 2px everywhere, elevation 0, no shadows. Dialogs become full-screen sheets on phones with a sticky footer above the safe area.
- Provide loading, empty, success, error and disabled states; never show fake success.
- Confirm destructive actions. Support keyboard focus and navigation.
- Meet WCAG 2.2 AA where applicable; test contrast, focus visibility, keyboard operation, zoom and mobile responsiveness.
- Use the project's existing icon set (Material) consistently with a light stroke; never inside filled circles; do not mix unrelated icon families. Icons must have accessible labels when used without text.

## Content and terminology
- Use **Resort Host**, not **Concierge**, throughout guest- and staff-facing product UI.
- Use approved EN/ES strings; do not machine-invent Spanish translations or copy.
- Do not invent residence names, amenities, guest profiles, providers, service inclusions, prices, lead times or booking guarantees.
- Photography and logos must come from the approved Digital Product Library with confirmed usage rights.
- Display only production-approved catalog items to guests.

## Roles and security
Preserve role-based access: Master Admin, Resort Host and Housekeeping for current scope. Resort Host assignment may use round-robin among available hosts, subject to backend design and admin override. This is a **functional requirement**, not a styling change. Do not expose all guest data to every staff user.

## Engineering workflow for Juan
1. Audit frontend stack, current tokens/components, existing data sources and deployment architecture.
2. Create a dedicated branch (suggested `feature/kachava-command-center-design`) and add this file at repository root.
3. Map these tokens to the existing styling solution; do not create competing token systems.
4. Implement a narrow pilot: sidebar and Dashboard visual structure using existing functionality.
5. Share desktop/mobile screenshots and a concise list of changed files for approval.
6. After approval, extend reusable components to other modules. Estimate backend-dependent work separately.

### Explicit non-goals
Do not migrate Firebase/GCP, alter IAM/security rules, change API contracts, rewrite reservation logic, change database schema, or deploy to production as part of a design-only pull request. These require separate scoped approval.

## Acceptance checklist
- [ ] Exact navigation hierarchy and no numeric prefixes
- [ ] Zen Kaku Gothic New + Noto Sans, weights 400/500 only
- [ ] Paper canvas, one brown accent, muted status colors with wash/line
- [ ] Hairlines instead of cards, 2px radius, no shadows, fades only
- [ ] Resort Host terminology in UI
- [ ] EN/ES strings preserve approved wording
- [ ] Keyboard, contrast, mobile and empty/error states reviewed
- [ ] Existing business logic and production configuration unchanged
- [ ] Before/after screenshots approved by Kachava

## References
- Material Design 3: https://m3.material.io/
- Google Labs design.md: https://github.com/google-labs-code/design.md
- Kachava Lux Digital Product Library: company-controlled Google Drive folder (link to be added by owner)
