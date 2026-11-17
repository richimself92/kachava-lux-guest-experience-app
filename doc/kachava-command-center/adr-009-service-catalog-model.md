# ADR-009: Service → Items catalog model, order snapshots and image storage

- **Status**: Accepted
- **Date**: 2026-11-02
- **Supersedes**: ADR-004 (DRAFT status, preloaded services, `options[]`, `leadTimeMinutes`)

## Context
Plan v2 requires one admin-managed catalog where every service has its own items (menu, products,
options, vehicles), bilingual texts, photos, pricing, availability and type-specific fields. The
database starts empty: nothing is preloaded, no prices or staff live in code, there is no draft state.

## Decision
1. **Two collections.** `catalog_services/{serviceId}` and `catalog_items/{itemId}` (with `serviceId`).
   A service has `kind` (BAR, BREAKFAST, SPECIAL_MENU, VILLA_STOCKING, EXPERIENCE, WELLNESS, PREFERENCE,
   TRANSPORT), `section` (IN_VILLA, DINING, EXPERIENCES, WELLNESS, TRANSPORTATION), `usageType`
   (ORDER, BOOKING, PREFERENCE, TRIP), `{en,es}` texts, `pricing{mode, amount, currency, chargeToFolio,
   note}`, `availability`, `guestInfo`, `guestForm`, staff-only `operation` and `status` ACTIVE | DISABLED.
2. **Type-specific block.** Exactly one of `bar | dining | stocking | experience | wellness | preference |
   transport` is set, chosen by `kind`; sending another block is 422. `kind` is immutable.
3. **Empty template, no business defaults.** New services/items start DISABLED with blank texts and null
   prices/limits; PATCH merges nested objects one level at a time (arrays and `null` replace).
4. **Activation rule.** ACTIVE requires a cover image and EN+ES `name` and `shortDescription`; ACTIVE
   items require EN+ES `name`. Violations are 422 with the list of missing fields. Audit fields
   (`createdAt/By`, `updatedAt/By`) come from the staff session.
5. **Snapshot on order.** Bookings and stocking orders reference `serviceId`/`itemId` and copy a
   `ServiceSnapshot` (bilingual names, pricing mode, unit price, quantity, line totals, total,
   `chargeToFolio`, `capturedAt`). Prices are computed only from the catalog (item price wins over the
   service amount; PER_PERSON × party, PER_HOUR × duration). Unknown service/item → 404; DISABLED,
   wrong usage type, blocked date or guest limits → 422. Catalog edits never change past orders.
6. **Images.** `POST /admin/uploads/sign` validates JPEG/PNG/WebP and ≤ 5 MB and returns a signed
   upload to `catalog/{folder}/{uuid}.{ext}` (V4 PUT with content type and
   `x-goog-content-length-range` on Cloud Storage; POST media upload on the local emulator).
   Services/items store `{storagePath, alt{en,es}, usageRightsConfirmed}`; only `catalog/` paths are
   accepted. `storage.rules` makes `catalog/**` publicly readable, so responses add a download `url`.
7. **Guest projection.** `GET /catalog/services` returns ACTIVE services with ACTIVE items only, without
   `operation` or audit fields.
8. **Lists.** Catalog and configuration collections are small and admin-made: one equality-filtered read
   (hard cap 1 000 docs, 422 beyond) then search/sort/page in memory. Stays page in Firestore
   (`count()` + offset, `checkInDate` order, `guestSearchKeywords` array-contains) with composite indexes.

## Consequences
- Positive: one model and one form per kind; historical folios stay correct; no code change per service.
- Negative: `count()` + offset reads are billed per skipped document (acceptable at boutique scale);
  uploads happen before the service exists, so orphaned images are possible (cleanup is a later task).

## Verification
- Jest `catalog-rules.spec.ts`; supertest `service-catalog.e2e.spec.ts`, `stay-operations.e2e.spec.ts`.
