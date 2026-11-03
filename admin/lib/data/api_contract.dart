/// JSON contract of the admin endpoints, reconciled with `backend/` (commit
/// 94d8838, the authoritative names). Adapter tests answer with recorded
/// shapes of this contract (`test/support/recorded_contract.dart`).
///
/// All paths are under `/api/v1/admin` and use the silent staff bearer token
/// of `AdminApiClient` (`POST /auth/login {email}` -> `{token, staff}`).
/// Field names are camelCase. Every response is wrapped as
/// `{ success, data, meta }`.
///
/// **Lists** (`GET`): `?q=&page=&pageSize=&sort=field:asc|desc&<filter>=`
/// (page 1-based, pageSize 10/25/50 in the UI, backend max 100). Response:
/// `{ success, data: [ ...items ], meta: { page, pageSize, total } }`.
/// A missing `meta` is an error; totals are never inferred.
///
/// **Single records** (`GET /:id`, `POST`, `PATCH /:id`): `{ data: {..., id} }`.
/// Writes send only editable fields; a response without `id` is treated as
/// unconfirmed (FormatException), never invented.
///
/// **Errors**: 400 validation, 403 role, 404 not found, 409 conflict,
/// 422 business rule. 401 re-authenticates once.
///
/// | Endpoint | Fields |
/// |---|---|
/// | `GET/PATCH /settings` | `checkInTime` "HH:mm", `checkOutTime`, `timeZone` (IANA), `airports[] {code (IATA), name, departureBufferHours (0-24), isActive}`, `transportAlertLeadHours` (1-168), `updatedAt`, `updatedBy`. Everything is `null`/`[]` until configured; PATCH with `null` clears a value. |
/// | `GET/POST /villas`, `GET/PATCH/DELETE /villas/:id` | `id, name, category, capacity (1-50), wifi {ssid, password}, operationalStatus (AVAILABLE/OCCUPIED/CLEANING/MAINTENANCE/BLOCKED), housekeepingStatus (CLEAN/DIRTY/IN_PROGRESS), maintenanceStatus (OK/ISSUE_REPORTED/IN_MAINTENANCE), maintenanceNote, isActive, currentGuestName` (read-only), audit. Filters `isActive`, `operationalStatus`, `category`; sort `name`, `category`, `capacity`, `operationalStatus`. DELETE answers 409 when stays reference the villa (deactivate instead). |
/// | `GET/POST /transport-providers`, `PATCH /:id` | `id, name, phone, email, isActive`, audit |
/// | `GET/POST /services`, `GET/PATCH /services/:id` | `id, kind (BAR/BREAKFAST/SPECIAL_MENU/VILLA_STOCKING/EXPERIENCE/WELLNESS/PREFERENCE/TRANSPORT, immutable), section (IN_VILLA/DINING/EXPERIENCES/WELLNESS/TRANSPORTATION), category, usageType (ORDER/BOOKING/PREFERENCE/TRIP), name{en,es}, shortDescription{en,es}, description{en,es}, tags[], order, featured, cover{storagePath, alt{en,es}, usageRightsConfirmed, url (read-only)}, gallery[] (<= 8), pricing{mode, amount, currency USD, chargeToFolio, note{en,es}}, availability{weekdays [MON..SUN], timeSlots [{start, end}], blockedDates [YYYY-MM-DD], minLeadHours, cancellationHours, minGuests, maxGuests, durationMinutes, offeredWhen (BEFORE_ARRIVAL/DURING_STAY/BOTH)}, guestInfo{includes, excludes, whatToBring, location, restrictions, cancellationPolicy} ({en,es} each), guestForm{date, time, guests, notes, dietary, health}, operation{providerId, responsibleDepartment, responsibleStaffId, requiresConfirmation, internalInstructions}, status (ACTIVE/DISABLED)`, audit, plus ONE type block for the kind: `bar` / `dining` (BREAKFAST, SPECIAL_MENU) / `stocking` / `experience` / `wellness` / `preference` / `transport`. Filters `section`, `status`, `usageType`, `kind`, `featured`; sort `order`, `name`. |
/// | `GET/POST /services/:id/items`, `PATCH /services/:id/items/:itemId` | `id, name{en,es}, description{en,es}, category, image{...}, priceUSD, tags[], dietaryTags[], allergens[], origin, unit, storage, capacity{passengers, luggage}, order, status (ACTIVE/DISABLED)`, audit |
/// | `POST /uploads/sign` | request `{fileName?, folder, contentType (image/jpeg, image/png, image/webp), sizeBytes (<= 5 MB)}`; response `{uploadUrl, method, headers, storagePath, publicUrl, expiresAt, maxBytes}`; then send the bytes to `uploadUrl` with the returned `method` (PUT on Cloud Storage, POST on the emulator) and `headers` |
/// | `GET /sync` | `{stays, alerts {alerts, unreadCount}, bookings, larderOrders, conciergeRequests, midstayFeedback}` (polled every 5 s) |
/// | `GET/POST /staff`, `GET/PATCH /staff/:id` | `id, staffId, fullName, shortName, role (job title), rbacRole (HOST_ADMIN/CONCIERGE_STAFF/DEPARTMENT_COORDINATOR), department, email (unique, 409), phone, isActive`. Filters `isActive`, `rbacRole`, `department`; sort `fullName`, `department`, `rbacRole`, `email`. Owner pickers read `isActive=true`. |
/// | `GET /requests?section=`, `POST /requests/:id/transition` | `id, kind (BOOKING/ORDER), guestName, villaName, serviceName{en,es}, section, at (resort YYYY-MM-DDTHH:mm), quantity, status (RECEIVED/CONFIRMED/PREPARING/DONE/CANCELLED), lines[{name, quantity}], totalUSD, cancellationReason`. Filters `status` (or OPEN), `from`/`to` days; sort `at`. Transition `{action: CONFIRM/START/COMPLETE/CANCEL, reason (CANCEL)}`, 422 when not allowed. |
/// | `GET /stays` (paged) | existing stay wire shape (`stayId`, `guestName`, `villaId`, `checkIn`, `checkOut`, `status`, ...) |
///
/// Removed (never call): `/catalog/*` (legacy experiences/larder catalog)
/// and `/reset`.
///
/// Audit fields (read-only): `createdAt, createdBy, updatedAt, updatedBy`.
library;
