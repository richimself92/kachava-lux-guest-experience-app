import '../domain/dashboard_view.dart';
import '../domain/guest_profile.dart';
import '../domain/list_query.dart';
import '../domain/paged_result.dart';
import '../domain/reservation.dart';
import '../domain/staff_member.dart';
import '../domain/trip_repository.dart';
import 'admin_api_client.dart';
import 'admin_http_resource.dart';
import 'admin_staff_mapper.dart';
import 'http_trip_repository.dart';

/// `GET /admin/dashboard` (ADR-011). A 422 `SETTINGS_REQUIRED` becomes
/// [SettingsRequiredException].
class HttpDashboardRepository implements DashboardRepository {
  HttpDashboardRepository(this._client);

  final AdminApiClient _client;

  @override
  Future<DashboardView> fetch() async {
    try {
      return DashboardView.fromJson(
          unwrapRecord(await _client.getJson('/dashboard')));
    } on AdminApiException catch (error) {
      final details = HttpTripRepository.settingsRequiredDetails(error);
      if (details != null) throw SettingsRequiredException(details);
      rethrow;
    }
  }
}

/// `/admin/stays` reservations: rows, detail, edits, creation and folio.
class HttpReservationRepository implements ReservationRepository {
  HttpReservationRepository(this._client)
      : _detail = AdminHttpResource(_client, _path, StayDetail.fromJson);

  static const String _path = '/stays';

  final AdminApiClient _client;
  final AdminHttpResource<StayDetail> _detail;

  /// The date range filter becomes `from`/`to` on the sort date.
  @override
  Future<PagedResult<ReservationRow>> list(ListQuery query) async {
    final qs =
        Uri(queryParameters: HttpTripRepository.wireParameters(query)).query;
    return PagedResult.fromEnvelope(
        await _client.getJson('$_path?$qs'), ReservationRow.fromJson);
  }

  @override
  Future<StayDetail> get(String id) => _detail.get(id);

  @override
  Future<StayDetail> update(String id, ReservationPatch patch) =>
      _detail.update(id, patch.toJson());

  /// `POST /admin/stays` answers `{ stay: {stayId, ...}, magicLinkUrl }`.
  @override
  Future<String> create(NewReservation reservation) async {
    final record =
        unwrapRecord(await _client.postJson(_path, reservation.toJson()));
    final stay = record['stay'];
    final id = stay is Map ? '${stay['stayId'] ?? ''}' : '';
    if (id.isEmpty) throw const FormatException('Created stay without id.');
    return id;
  }

  @override
  Future<StayFolio> folio(String id) async => StayFolio.fromJson(unwrapRecord(
      await _client.getJson('$_path/${Uri.encodeComponent(id)}/folio')));
}

/// `/admin/guests`: one row per stay and the staff-only profile.
class HttpGuestRepository implements GuestRepository {
  HttpGuestRepository(AdminApiClient client)
      : _rows = AdminHttpResource(client, '/guests', GuestRow.fromJson),
        _profiles = AdminHttpResource(client, '/guests', GuestProfile.fromJson);

  final AdminHttpResource<GuestRow> _rows;
  final AdminHttpResource<GuestProfile> _profiles;

  @override
  Future<PagedResult<GuestRow>> list(ListQuery query) => _rows.list(query);

  @override
  Future<GuestProfile> get(String stayId) => _profiles.get(stayId);
}

/// `GET /admin/staff` (the whole roster, one page of up to 100).
class HttpStaffDirectoryRepository implements StaffDirectoryRepository {
  HttpStaffDirectoryRepository(this._client);

  final AdminApiClient _client;

  @override
  Future<List<StaffMember>> list() async => AdminStaffMapper.parseDirectory(
      await _client.getJson('/staff?pageSize=100'));
}
