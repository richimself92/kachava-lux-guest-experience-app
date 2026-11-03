import '../domain/admin_catalog_repositories.dart';
import '../domain/admin_settings.dart';
import '../domain/admin_stay_entities.dart';
import '../domain/admin_villa.dart';
import '../domain/list_query.dart';
import '../domain/paged_result.dart';
import '../domain/transport_provider.dart';
import 'admin_api_client.dart';
import 'admin_http_resource.dart';
import 'admin_stay_wire_mapper.dart';

/// `GET/PATCH /admin/settings` (contract in `api_contract.dart`).
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
  HttpVillaRepository(AdminApiClient client)
      : _villas = AdminHttpResource(client, '/villas', AdminVilla.fromJson);

  final AdminHttpResource<AdminVilla> _villas;

  @override
  Future<PagedResult<AdminVilla>> list(ListQuery query) => _villas.list(query);

  @override
  Future<AdminVilla> create(AdminVilla villa) =>
      _villas.create(villa.toWriteJson());

  @override
  Future<AdminVilla> update(AdminVilla villa) =>
      _villas.update(villa.id, villa.toWriteJson());
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

/// Paginated `GET /admin/stays`.
class HttpStayListRepository implements StayListRepository {
  HttpStayListRepository(AdminApiClient client)
      : _stays = AdminHttpResource(client, '/stays', AdminStayWireMapper.map);

  final AdminHttpResource<AdminStayRecord> _stays;

  @override
  Future<PagedResult<AdminStayRecord>> list(ListQuery query) =>
      _stays.list(query);
}
