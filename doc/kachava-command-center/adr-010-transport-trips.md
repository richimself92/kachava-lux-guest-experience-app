# ADR-010: Transport trips, status flow, alerts and resort-time filters

- **Status**: Accepted
- **Date**: 2026-11-02
- **Supersedes**: the embedded per-stay `flightTransfer` as the transport record (kept read-only for legacy UIs)

## Context
Plan v2 (Transporte) needs arrival, departure and local trips requested by guests or staff, sent to
external providers, confirmed with a driver, and an urgent signal when a near trip is still
unconfirmed. Airports, departure buffers, alert lead time and time zone live only in Settings.

## Decision
1. **Collection** `trips/{tripId}` behind `TripRepositoryPort` (`FirestoreTripRepository`). A trip keeps
   denormalized `stayId`, `villaId`, `villaName`, `guestName`; `serviceId`, `itemId` and a snapshot
   (ADR-009 `ServiceSnapshot` + `vehicleCapacity`); `createdBy` GUEST | STAFF; audit `createdAt`,
   `createdByActor`, `updatedAt`, `updatedBy`; `statusHistory[]`. `notes` is staff-only, `guestNotes` is guest-visible.
2. **Status flow** (pure `transitionTrip`): REQUESTED → SENT_TO_PROVIDER → CONFIRMED → EN_ROUTE → COMPLETED,
   one step at a time; CANCELLED from any non-final status with a non-blank reason. SENT_TO_PROVIDER and
   later need `providerId`; CONFIRMED and later need driver name and phone. Edits keep these invariants.
3. **Schedule.** ARRIVAL/DEPARTURE need an active Settings airport and `flight`; arrivals default to pickup at
   landing, departures to flight − `departureBufferHours`. Staff may override `pickupAt`; when staff change the
   airport or flight without a pickup, the suggestion is recomputed. LOCAL needs origin, destination, pickup.
4. **Time.** Instants are stored as UTC ISO. Inputs accept an offset (`…Z`, `…-05:00`) or a resort wall time
   (`YYYY-MM-DDTHH:mm`) read in Settings `timeZone`. List `from`/`to` are inclusive resort days on
   `dateField=pickupAt|flightAt`.
5. **Guest rules.** Service must exist (404), be TRANSPORT and ACTIVE (422); the vehicle must be an ACTIVE item
   of it; passengers/luggage fit its capacity; pickup ≥ `minLeadHours` ahead; airport pickups are never
   guest-set. A guest request commits a TRANSFER/HIGH alert with `targetRef {type: TRIP, id}` in the same
   transaction; so does any flight change. Staff-created trips skip lead time and raise no alert.
6. **Missing Settings** → 422 with `code: SETTINGS_REQUIRED` and `details` (`timeZone`, `airports.CUN`,
   `airports.CUN.departureBufferHours`, `transportAlertLeadHours`). An inactive airport is a plain 422.
7. **Unconfirmed-due** is computed on read (no scheduler): REQUESTED/SENT_TO_PROVIDER with
   pickup ≤ now + `transportAlertLeadHours` (past pickups included). Lists carry `unconfirmedDue`
   (null when lead hours are unset); `GET /admin/trips/unconfirmed-due` uses the (status, pickupAt) index.
8. **Lists** read a bounded window (range on the date field, single-field index, 1 000-doc cap → 422) and
   filter/search/page in memory; search matches guest name (accent-free) or flight number (spaces ignored).
9. **Guest projection** is an allow-list: no `notes`, `providerId`, provider contact, history or actors.
10. **Migration** `npm run migrate:flight-transfers -- --dry-run`: requested legacy transfers become ARRIVAL
    trips with id `trip_legacy_arrival_<stayId>` (idempotent), `serviceId: null`; stays are untouched.
    Same live-guard as the runtime plus `--allow-production`; unknown flags abort.

## Consequences
- Positive: one transport record for guest, admin and alerts; no composite-index explosion for filters.
- Negative: unbounded date windows hit the 1 000-doc cap as history grows (clients send a window);
  migrated trips have no price snapshot and may need a provider before further edits.

## Verification
- Jest: `trip-transitions`, `trip-rules`, `trip-assembly`, `zoned-time`, `firestore-trip.repository`,
  `legacy-transfer-migration`; supertest: `trips-guest.e2e`, `trips-admin.e2e`.
