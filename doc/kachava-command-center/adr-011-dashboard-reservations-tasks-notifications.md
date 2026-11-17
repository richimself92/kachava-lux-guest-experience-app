# ADR-011: Dashboard, Reservations/Guests, Tasks, Notifications and Messages on real data

- **Status**: Accepted
- **Date**: 2026-11-03
- **Extends**: ADR-006 (tasks), ADR-008 (stay document), ADR-010 (trips, computed alerts)

## Context
Plan v2 phases 6–8 need a dashboard, paged reservations/guests, operational tasks, a notification
feed and (owner-approved addition) a guest Messages inbox. Everything starts empty, no scans before
paging, the resort day comes from Settings `timeZone`.

## Decision
1. **Resort day.** `resortDate(now, timeZone)`; missing zone → 422 `SETTINGS_REQUIRED` (dashboard).
2. **Dashboard** = pure `computeDashboardKpis` + `deriveActivityStatus` over one bounded query of open
   stays (`status in [PRE_ARRIVAL, ACTIVE_STAY]`, 1 000-doc cap → 422), active villas and two `count()`
   aggregates (open trips, open tasks). Departure beats Arrival; overstay = In-house + `overdue`;
   available = active − occupied − free villas in MAINTENANCE/BLOCKED; ≤ 8 rows + `total`.
3. **No full scans.** Stay docs carry derived storage-only fields: `childRefIds` (booking, larder and
   request ids → `array-contains` owner lookup) and `conversation` (inbox summary). Cross-stay queues
   (bookings, larder, requests, feedback) now cover **open stays only**; lookups by id cover all stays.
4. **Reservations.** `pageStays` orders/ranges on `checkInDate` or `checkOutDate` (`sort=checkIn|checkOut`;
   `from`/`to` apply to the sort date) with `count()` + offset. Rows are a projection; the magic link
   is rebuilt from the current token. Staff moves: CHECK_IN, CHECK_OUT, CANCEL (reason) with
   `statusHistory`; host, `internalNotes`, `language`, Wi-Fi override only on open stays.
5. **Tasks** live in `tasks/{id}` behind `TaskRepositoryPort`; filters/search/`dueAt` order run in
   Firestore (single-field + status-pair composites; Firestore merges equality indexes). Pure
   `transitionTask`: ASSIGNED+ needs `ownerStaffId`, COMPLETED needs a note (`completion{at,by,note}`).
   `overdue` is derived on read. Auto tasks (preference choice, stocking order, booking with
   `requiresConfirmation`, every trip) use id `task_<source>_<refId>` and `createIfAbsent`, written right
   after the source commits (idempotent; a crash between both writes loses only the task).
6. **Notifications** = newest 500 stored alerts in the window + computed events (arrival today,
   overdue task, trip unconfirmed within lead time). Level: NORMAL→INFO, HIGH→ACTION, URGENT→URGENT;
   `playSound` only URGENT. Stored alerts carry `event` and `targetRef`; older ones derive them from
   `category`/`sourceDocumentPath`. Read state: alerts are acknowledged; computed ids
   (`arrival_…`, `task-overdue_…`, `trip-unconfirmed_…`) get markers in `notification_reads/{id}`.
   New reservations commit a RESERVATION alert in the stay-creation transaction.
7. **Messages inbox.** One conversation per stay merged from `conciergeRequests[].messages`; staff
   replies append to the thread the guest last wrote in (or open a closed "Resort Host" thread), so
   guests read them through the existing `GET /stays/:guestUuid/concierge-requests`. Unread = guest
   messages after `conversationReadAt`. Each guest chat message commits a HIGH (ACTION) alert with
   `targetRef {type: CONVERSATION, id: stayId}`.

## Consequences
- Positive: every list pages in Firestore or over a bounded read; one source of truth per record.
- Negative: more composite indexes (`firestore.indexes.json`); historical queues need a stay filter;
  stays written before this change lack derived fields until their next write (DB starts empty).

## Verification
Jest: `dashboard-rules`, `resort-day`, `task-transitions`, `task-sources`, `notification-rules`,
`stay-admin`, `conversation-rules`, `stay-repository-queries`, `firestore-task.repository`,
`alert-window`; supertest: `command-center.e2e`, `stay-operations.e2e`.
