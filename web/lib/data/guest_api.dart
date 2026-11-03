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

  /// `PUT /stays/:uuid/larder` with `{serviceId, items}`.
  Future<ApiResult<void>> saveOrder(String guestUuid, Json payload);

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

  Future<ApiResult<void>> sendHostMessage(
      String guestUuid, String threadId, String text);

  /// Signed upload of a real photo; returns its storage path.
  Future<ApiResult<String>> uploadPhoto(String guestUuid, PickedPhoto photo);

  void dispose();
}
