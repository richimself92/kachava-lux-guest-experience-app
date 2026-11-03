import '../domain/list_query.dart';
import '../domain/paged_result.dart';
import 'admin_api_client.dart';

/// Maps one JSON record into an entity.
typedef JsonMapper<T> = T Function(Map<String, dynamic> json);

/// REST collection under `/api/v1/admin/<path>` following `api_contract.dart`.
class AdminHttpResource<T> {
  const AdminHttpResource(this._client, this.path, this._map);

  final AdminApiClient _client;
  final String path;
  final JsonMapper<T> _map;

  Future<PagedResult<T>> list(ListQuery query) async {
    final qs = query.toQueryString();
    final raw = await _client.getJson(qs.isEmpty ? path : '$path?$qs');
    return PagedResult.fromEnvelope(raw, _map);
  }

  Future<T> get(String id) async =>
      _map(_record(await _client.getJson(_item(id))));

  Future<T> create(Map<String, dynamic> body) async =>
      _map(_record(await _client.postJson(path, body)));

  Future<T> update(String id, Map<String, dynamic> body) async {
    if (id.isEmpty) throw ArgumentError.value(id, 'id', 'Not saved yet');
    return _map(_record(await _client.patchJson(_item(id), body)));
  }

  String _item(String id) => '$path/${Uri.encodeComponent(id)}';

  /// `{ data: {...} }` (the client already merges `data` into the root).
  static Map<String, dynamic> _record(Map<String, dynamic> raw) {
    final inner = raw['data'];
    return inner is Map ? Map<String, dynamic>.from(inner) : raw;
  }
}
