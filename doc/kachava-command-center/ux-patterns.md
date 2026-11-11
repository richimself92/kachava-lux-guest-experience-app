# Admin UX patterns (Command Center)
Applies to every admin list/screen. Colors, radii, type and states come from root [`DESIGN.md`](../../DESIGN.md); never hardcode. Style: Material 3 data tables / Google Workspace admin. Clean-UI rule: minimal text, explanations in `InfoTooltip` (ⓘ).

## 1. Data list pattern (desktop >= 840px)
1. **Page header**: title (24/32) + one primary action (brown button, right). No subtitle, no section counts in prose; the count lives in the footer.
2. **Toolbar** (one row under the header, replaces the global top-bar search/chips, which are removed):
   - Search field (left, 320px, debounce 300 ms, clear "x", `/` focuses it). Searches the entity's text columns only.
   - Filter controls: <= 3 inline dropdown chips (status, category, ...); extra filters in a "Filters" menu with an active-count badge.
   - Active-filter summary: removable chips + "Clear all" text button; visible only when something is active.
3. **Table** (`AdminDataTable`): white, hairline row separators, 14/20 cells, row height 48 (dense 40 allowed), sticky header (12/16 w500 gray), sortable columns (header button, arrow icon, `aria-sort`; click cycles asc, desc, none; one active sort), numeric columns right-aligned, text truncated with ellipsis + tooltip. Max 6 columns; status uses `StatusChip`; row actions only as a trailing "more" menu (3 dots) plus the main inline action if any.
4. **Pagination footer**: "Rows per page" 10 / 25 (default) / 50, "1-25 of 132", prev/next icon buttons (44px targets, labelled, keyboard + `PageUp/PageDown`). Page resets to 1 when search/filter/sort changes. Client-side now; keep state in one `ListQuery {page, pageSize, sort, q, filters}` so the repository can later take `?page&pageSize&sort&q&filters` with no UI change.
5. **Row click** opens the detail: right side panel 420px (desktop, list stays visible, Esc closes, focus returns to the row) / full-screen sheet (mobile). Rows are focusable (Enter opens).
6. **States** (`AsyncStateView`): loading = skeleton rows (same column grid, no spinner-only); empty (no data) = one line + action ("No villas yet" + "New villa"); no results = "No results" + "Clear filters"; error = one line + "Retry"; refresh keeps old rows dimmed.

## 2. Mobile (< 840px)
- Table becomes compact list rows (min 64px): line 1 = primary field (bold) + trailing `StatusChip`; line 2 = 1-2 secondary fields (gray 12/16 only if legible, else 14). Tap opens a full-screen sheet.
- Toolbar: search icon expands to a field; a single "Filters" button opens a bottom sheet (Apply / Clear); sort is a "Sort" option inside that sheet. Active filters show as a one-line scrollable chip row.
- Pagination: "Load more" is NOT used; keep prev/next + range, pageSize fixed 25. Primary action = extended FAB or header button. No horizontal scroll at 320px.

## 3. Filter persistence
Per-screen `ListQuery` survives navigation between workspaces (controller-level, not widget state) and resets on sign-out. Later mirrored in the URL (`/reservations?status=in-house&sort=arrival&page=2`) so views are linkable and Back works.

## 4. Forms, dialogs, toasts
- Create/edit in a right-side panel (desktop) or sheet (mobile); short dialogs only for 1-2 fields. Labels above fields, required marked once, inline error text + icon (not color only), primary button disabled while saving with spinner label; unsaved-changes confirm on close.
- Destructive actions (delete, check-out, cancel, rotate link): `ConfirmDialog`, names the object, destructive verb on the button, default focus on Cancel.
- Toasts: one line, bottom-start, auto-dismiss 4 s (errors 8 s with "Retry"), `aria-live` polite; never fake success (show after the awaited write).

## 5. Status chips vocabulary (light bg + dark text + label; never color only)
Stay: Pre-arrival (blue), In house (green), Departing today (gray), Checked out (gray outline), Overstay (red). Villa: Available (green), Occupied (gray), Cleaning (blue), Maintenance (amber), Blocked (red). Catalog: Draft (gray outline), Active (green), Disabled (gray). Requests/Tasks: Requested (blue), Assigned (gray), In progress (blue strong), Completed (green), Cancelled (gray outline), Overdue (red). Severity: Info (gray), Action needed (amber), Urgent (red). Labels are Title case, never raw enums (`CHECKED_OUT`).

## 6. Tooltips
ⓘ only for: formulas, definitions, "why unavailable", icon-only buttons. <= 1 sentence, no essential info (must not be the only place a required fact appears), hover + keyboard focus + tap, `Semantics` label. Never a tooltip on a disabled control without saying why.

## 7. Formats
Resort time `America/Cancun` (UTC-5, no DST) for every date. Dates `Nov 2, 2026` (EN) / `2 nov 2026` (ES); with time `Nov 2, 4:30 PM` / `2 nov, 16:30`; ranges `Nov 2 - Dec 15 (43 nights)`; relative ("in 2 h") only in tooltips. Money `$1,234.50 USD` (currency from data; unknown = `UnavailableValue` "-"). Counts with thousands separators; occupancy `75%`. Never show raw URLs/IDs in rows (copy button instead).

## 8. Per-entity defaults (columns | filters | default sort)
- **Reservations / Stays**: Guest, Villa, Arrival, Departure, Status, Resort Host | status, villa, arrival range, "Needs attention" | arrival asc (today first). Search guest/villa. Detail panel tabs: Overview, Stay summary (folio), Requests, Notes; magic link, Wi-Fi, comfort prefs, transfer live in the panel, not the row. Calendar view toggle (villa x day) beside the table.
- **Villas**: Villa, Status, Current guest, Next arrival, Housekeeping | status, housekeeping | name asc. (8 units: no pagination footer if <= 10, keep sort.)
- **Services (catalog)**: Name, Category, Request type, Price, Lead time, Status | category, status, type | name asc. Row click edits in panel.
- **Experiences / Dining / Transportation / Wellness**: one workspace with two tabs "Catalog" and "Requests". Catalog columns as Services minus Category. Requests: Guest, Villa, Item, Date/time, Status, Assignee | status, date (Today / Next 7 days), assignee | date asc. Transportation adds Trip type (Arrival/Departure/Local) and Provider.
- **Tasks**: Title, Villa, Owner, Priority, Due, State | state (default: open), owner, priority, "Mine" | due asc, then priority. Overdue rows get red chip.
- **Notifications**: Severity, Message, Source, Time, Read | severity, read/unread (default: unread), category | time desc. Row action "Open record"; bulk "Mark all read".
- **Folio summary (tab in stay panel)**: Charges table: Date, Item, Qty, Amount, Status | none (<= 25 rows, no pagination) | date desc; total in sticky footer row. Mid-stay pulse and payments are separate collapsed sections; "No PMS integration" shown as `UnavailableValue`.
- **Dashboard** per DESIGN.md: 6 KPI tiles + 3-column activity table (Guest, Villa, Status), max 8 rows + "View all" link to Reservations (pre-filtered).

## 9. Accessibility checklist
Visible focus ring on rows, headers, chips, pager; touch targets >= 40px web / 48px mobile; tab order toolbar > table > pager; live region announces "N results" after filtering; contrast AA; keys `list-<entity>`, `search-<entity>`, `row-<entity>-<id>`, `pager-<entity>` for e2e.
