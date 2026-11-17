import '../core/platform/photo_picker.dart';
import '../domain/catalog.dart';
import '../domain/json_read.dart';
import '../domain/stay.dart';
import '../domain/trip.dart';

/// Why a call did not succeed. Only [linkRejected] ends the session.
enum FailureKind {
  /// 401/403 (and 404 on the stay itself): the guest link is no longer valid.
  linkRejected,

  /// 422 `SETTINGS_REQUIRED`: the resort has not configured this yet.
  notConfigured,

  /// Other 4xx: the server refused the details.
  invalid,

  /// Network, timeout, 5xx, bad payload: keep data, show Retry.
  unreachable,
}

sealed class ApiResult<T> {
  const ApiResult();
}

final class ApiOk<T> extends ApiResult<T> {
  const ApiOk(this.value);
  final T value;
}

final class ApiFailed<T> extends ApiResult<T> {
  const ApiFailed(this.kind, [this.message = '']);
  final FailureKind kind;
  final String message;
}

/// Guest endpoints (`/api/v1`). Every write is awaited: the UI shows success
/// only after an [ApiOk].
abstract interface class GuestApi {
  Future<ApiResult<GuestStay>> fetchStay(String guestUuid);
  Future<ApiResult<List<CatalogService>>> fetchCatalog();
  Future<ApiResult<List<GuestTrip>>> fetchTrips(String guestUuid);

  /// `PUT /stays/:uuid/orders/:serviceId` with `{items}` from a
  /// `{serviceId, items}` payload; other services' orders are kept.
  Future<ApiResult<void>> saveOrder(String guestUuid, Json payload);

  /// `PUT /stays/:uuid/journey`: replaces only the lists that are given.
  Future<ApiResult<void>> saveJourney(String guestUuid,
      {Set<String>? skippedTaskIds, Set<String>? completedTaskIds});

  /// `POST /stays/:uuid/bookings/:id/cancel` (only while REQUESTED).
  Future<ApiResult<void>> cancelBooking(String guestUuid, String bookingId);

  /// `PATCH /stays/:uuid/bookings/:id` with date, time and/or party size.
  Future<ApiResult<void>> changeBooking(
      String guestUuid, String bookingId, Json change);

  /// `POST /stays/:uuid/trips/:id/cancel` (only while REQUESTED).
  Future<ApiResult<void>> cancelTrip(String guestUuid, String tripId);

  /// `POST /stays/:uuid/bookings` (BOOKING and PREFERENCE services).
  Future<ApiResult<void>> createBooking(String guestUuid, Json payload);

  /// `POST /stays/:uuid/trips`.
  Future<ApiResult<GuestTrip>> createTrip(String guestUuid, Json payload);

  /// `PATCH /stays/:uuid/personalization` (diet & allergies).
  Future<ApiResult<void>> savePreferences(String guestUuid,
      {required String dietary, required List<String> allergies});

  /// `POST /stays/:uuid/midstay-checkin` (Rate stay).
  Future<ApiResult<void>> sendRating(String guestUuid, int rating, String note);

  /// Opens a Resort Host thread; returns its id.
  Future<ApiResult<String>> startHostThread(String guestUuid,
      {required String text, String? photoStoragePath});

  /// Appends text and/or a photo (storage path from [uploadPhoto]).
  Future<ApiResult<void>> sendHostMessage(
      String guestUuid, String threadId, String text,
      {String? photoStoragePath});

  /// Signed upload of a real photo (into [threadId]'s folder when given);
  /// returns its storage path.
  Future<ApiResult<String>> uploadPhoto(String guestUuid, PickedPhoto photo,
      {String? threadId});

  void dispose();
}
