# ADR-007: Guest-Safe Stay View

- **Status**: Accepted
- **Date**: 2026-11-02

## Context
`GET /api/v1/stays/:guestUuid` returns the full stay aggregate. Phase E adds staff-only data to stays
(assigned Resort Host internals, internal notes, operational status). Anyone holding a guest link must
never see staff-only data.

## Decision
- The guest endpoint returns a projection built by a pure function `toGuestStayView(stay)`.
- The projection is an explicit **allow-list**: new stay fields are hidden from guests by default until
  added to the projection on purpose.
- Excluded: internal notes, staff ids/emails, host workload, audit fields, token rotation history,
  operational villa status (housekeeping/maintenance), provider contact details not yet confirmed to the guest.
- Included for the assigned Resort Host: display name and photo only.
- Admin endpoints keep returning the full aggregate behind `AdminAuthGuard` + role checks.

## Consequences
- Positive: least-privilege by construction; one place to review what guests can see.
- Negative: adding a guest-visible field requires touching the projection and its test.

## Verification
- Jest: projection test asserting internal notes and staff fields are absent; Supertest on the guest route.
