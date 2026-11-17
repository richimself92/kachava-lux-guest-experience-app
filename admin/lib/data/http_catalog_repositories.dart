import '../domain/admin_catalog_repositories.dart';
import '../domain/admin_settings.dart';
import '../domain/admin_villa.dart';
import '../domain/json_read.dart';
import '../domain/list_query.dart';
import '../domain/paged_result.dart';
import '../domain/reservation.dart';
import '../domain/transport_provider.dart';
import 'admin_api_client.dart';
import 'admin_http_resource.dart';

/// `GET/PATCH /admin/settings`.
class HttpSettingsRepository implements AdminSettingsRepository {
  HttpSettingsRepository(this._client);

  final AdminApiClient _client;

  @override
  Future<AdminSettings> fetch() async =>
      AdminSettings.fromJson(_record(await _client.getJson('/settings')));

  @override
  Future<AdminSettings> update(AdminSettings settings) async =>
      AdminSettings.fromJson(
          _record(await _client.patchJson('/settings', settings.toJson())));

  static Map<String, dynamic> _record(Map<String, dynamic> raw) {
    final inner = raw['data'];
    return inner is Map ? Map<String, dynamic>.from(inner) : raw;
  }
}

/// `/admin/villas`.
class HttpVillaRepository implements VillaRepository {
  HttpVillaRepository(this._client)
      : _villas = AdminHttpResource(_client, '/villas', AdminVilla.fromJson);

  final AdminApiClient _client;
  final AdminHttpResource<AdminVilla> _villas;

  @override
  Future<PagedResult<AdminVilla>> list(ListQuery query) => _villas.list(query);

  @override
  Future<List<AdminVilla>> available(String checkIn, String checkOut) async {
    final qs = Uri(queryParameters: {'checkIn': checkIn, 'checkOut': checkOut});
    final raw = await _client.getJson('/villas/available?${qs.query}');
    return [
      for (final v in JsonRead.objects(raw, 'data')) AdminVilla.fromJson(v)
    ];
  }

  @override
  Future<AdminVilla> create(AdminVilla villa) =>
      _villas.create(villa.toWriteJson());

  @override
  Future<AdminVilla> update(AdminVilla villa) =>
      _villas.update(villa.id, villa.toWriteJson());

  @override
  Future<AdminVilla> setActive(String id, bool isActive) =>
      _villas.update(id, {'isActive': isActive});

  /// A 409 means stays reference the villa: it can only be deactivated.
  @override
  Future<void> delete(String id) async {
    try {
      await _villas.delete(id);
    } on AdminApiException catch (error) {
      if (error.statusCode == 409) throw VillaHasStaysException(id);
      rethrow;
    }
  }
}

/// `/admin/transport-providers`.
class HttpTransportProviderRepository implements TransportProviderRepository {
  HttpTransportProviderRepository(AdminApiClient client)
      : _providers = AdminHttpResource(
            client, '/transport-providers', TransportProvider.fromJson);

  final AdminHttpResource<TransportProvider> _providers;

  @override
  Future<PagedResult<TransportProvider>> list(ListQuery query) =>
      _providers.list(query);

  @override
  Future<TransportProvider> create(TransportProvider provider) =>
      _providers.create(provider.toWriteJson());

  @override
  Future<TransportProvider> update(TransportProvider provider) =>
      _providers.update(provider.id, provider.toWriteJson());
}

/// Paginated `GET /admin/stays` rows (ADR-011 projection).
class HttpStayListRepository implements StayListRepository {
  HttpStayListRepository(AdminApiClient client)
      : _stays = AdminHttpResource(client, '/stays', ReservationRow.fromJson);

  final AdminHttpResource<ReservationRow> _stays;

  @override
  Future<PagedResult<ReservationRow>> list(ListQuery query) =>
      _stays.list(query);
}
