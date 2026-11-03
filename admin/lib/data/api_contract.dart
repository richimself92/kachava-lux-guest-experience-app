/// Assumed JSON contract of the phase-1 admin endpoints consumed by the
/// HTTP repositories in this folder. Reconcile with `backend/` and update
/// this block plus the `fromJson`/`toWriteJson` methods if names differ.
///
/// All paths are under `/api/v1/admin` and use the silent staff bearer token
/// of `AdminApiClient`. Field names are camelCase.
///
/// **Lists** (`GET`): `?q=&page=&pageSize=&sort=field:asc|desc&<filter>=`
/// (pageSize 10/25/50, page 1-based). Response:
/// `{ "data": [ ...items ], "meta": { "page": 1, "pageSize": 25, "total": 132 } }`.
/// A missing `meta` is an error; totals are never inferred.
///
/// **Single records** (`GET /:id`, `POST`, `PATCH /:id`): `{ "data": {...} }`.
/// Writes send only editable fields; a response without `id` is treated as
/// unconfirmed (FormatException), never invented.
///
/// | Endpoint | Item fields |
/// |---|---|
/// | `GET/PATCH /settings` | `checkInTime` "HH:mm", `checkOutTime`, `timeZone` (IANA), `airports[] {code, name, departureMarginMinutes, isActive}`, `tripAlertLeadMinutes`, audit |
/// | `GET/POST /villas`, `PATCH /villas/:id` | `id, name, category, capacity, operationalStatus (AVAILABLE/OCCUPIED/CLEANING/MAINTENANCE/BLOCKED), housekeepingStatus (CLEAN/DIRTY/IN_PROGRESS), maintenanceNote, isActive, currentGuestName` (read-only), audit |
/// | `GET/POST /transport-providers`, `PATCH /:id` | `id, name, phone, email, isActive`, audit |
/// | `GET/POST /services`, `GET/PATCH /services/:id` | `id, name{en,es}, shortDescription{en,es}, description{en,es}, section, type, tags[], sortOrder, featured, cover{storagePath,url,alt{en,es},usageRightsConfirmed}, gallery[] (<= 8), usage (ORDER/BOOKING/PREFERENCE/TRIP), pricing{mode, amount, currency, chargeToFolio, note{en,es}}, availability{daysOfWeek[1-7], timeSlots["HH:mm-HH:mm"], blockedDates["YYYY-MM-DD"], leadTimeHours, cancellationHours, minGuests, maxGuests, durationMinutes, offeredWhen (BEFORE_STAY/DURING_STAY/BOTH)}, guestInfo{includes, excludes, whatToBring, location, restrictions, cancellationPolicy} ({en,es} each), guestForm{askDate, askTime, askGuests, askNotes, askDiet, askHealth}, operation{providerId, internalOwner, requiresConfirmation, internalNotes}, status (ACTIVE/DISABLED), details{}` (type-specific), audit |
/// | `GET/POST /services/:id/items`, `PATCH /services/:id/items/:itemId` | `id, name{en,es}, description{en,es}, image{...}, price, category, tags[], isAvailable, sortOrder, details{}` |
/// | `POST /uploads/sign` | request `{fileName, contentType, sizeBytes, folder}`; response `{uploadUrl, storagePath, publicUrl}`; then `PUT uploadUrl` with the bytes and `Content-Type` |
/// | `GET /stays` (paged) | existing stay wire shape (`stayId`, `guestName`, `villaId`, `checkIn`, `checkOut`, `status`, ...) |
///
/// Audit fields (read-only): `createdAt, createdBy, updatedAt, updatedBy`.
library;
