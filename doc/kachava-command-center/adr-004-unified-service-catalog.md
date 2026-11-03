# ADR-004: Unified, Admin-Configurable Service Catalog

- **Status**: Accepted
- **Date**: 2026-11-02

## Context
Services were spread across hardcoded seeds (`sanctuary-catalog.seed.ts`, `sanctuary-yacht.seed.ts`,
`web/lib/data/seed/villa_102_*`) and fixed prices in code (`guest-booking.service.ts`). The spec requires
`Services` to be the master catalog and Experiences, Dining, Transportation and Wellness to be views of it,
all editable by staff without code changes.

## Decision
- One collection `catalog_services` of `ServiceItem`:
  - `category`: VILLA_STOCKING | DINING | WELLNESS | IN_VILLA_COMFORT | TRANSPORTATION | EXPERIENCE
  - `requestMode`: ORDER | BOOKING | PREFERENCE | TRIP (decides the guest form)
  - `name`, `description`: `{ en, es? }`; missing Spanish renders "translation pending"; never auto-translated
  - `pricing`: INCLUDED | FIXED | PER_PERSON | PER_UNIT | ON_REQUEST, amount only when applicable
  - `options[]`, `capacity`, `leadTimeMinutes`, `provider`, `status`: DRAFT | ACTIVE | DISABLED
- Admin: `GET/POST/PATCH /admin/services` (role-guarded). Guest: `GET /catalog/services?category=` returns
  ACTIVE items only.
- `quoteService()` computes prices from the item; DISABLED/unknown items are rejected, never priced by default.
- Legacy services and seeds are removed. Historical bookings keep a copy of the service title so folios render.
- The nine client-confirmed services are preloaded as DRAFT with names only; no invented prices or copy.
- Category workspaces in the admin are one component parameterised by category.

## Consequences
- Positive: no hardcoded service lists in either UI; one data model and one form per request mode.
- Negative: production cleanup is destructive; the script exports first, supports `--dry-run`, and needs
  explicit owner approval before touching `kavacha-db`.

## Verification
- Jest: guest endpoint never returns DRAFT/DISABLED; `quoteService` per pricing type; disabled -> error.
