import 'dart:convert';

import '../domain/admin_trip.dart';
import '../domain/list_query.dart';
import '../domain/paged_result.dart';
import '../domain/trip_repository.dart';
import 'admin_api_client.dart';
import 'admin_http_resource.dart';

/// `/admin/trips` (contract in `doc/kachava-command-center/adr-010`).
class HttpTripRepository implements TripRepository {
  HttpTripRepository(this._client)
      : _trips = AdminHttpResource(_client, _path, AdminTrip.fromJson);

  static const String _path = '/trips';

  final AdminApiClient _client;
  final AdminHttpResource<AdminTrip> _trips;

  @override
  Future<PagedResult<AdminTrip>> list(ListQuery query) => _guard(() async {
        final qs = Uri(queryParameters: wireParameters(query)).query;
        final raw = await _client.getJson('$_path?$qs');
        return PagedResult.fromEnvelope(raw, AdminTrip.fromJson);
      });

  @override
  Future<AdminTrip> get(String id) => _guard(() => _trips.get(id));

  @override
  Future<AdminTrip> create(NewTripRequest request) =>
      _guard(() => _trips.create(request.toJson()));

  @override
  Future<AdminTrip> transition(String id, TripTransition move) =>
      _guard(() async {
        final raw = await _client.postJson(
            '$_path/${Uri.encodeComponent(id)}/transition', move.toJson());
        final inner = raw['data'];
        return AdminTrip.fromJson(
            inner is Map ? Map<String, dynamic>.from(inner) : raw);
      });

  /// The list query on the wire: the [TripDateRange] filter becomes
  /// `from`/`to` resort days.
  static Map<String, String> wireParameters(ListQuery query) {
    final params = query.toQueryParameters();
    final range = TripDateRange.parse(params.remove(TripDateRange.filterKey));
    if (range != null) {
      params['from'] = range.from;
      params['to'] = range.to;
    }
    return params;
  }

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on AdminApiException catch (error) {
      final details = settingsRequiredDetails(error);
      if (details != null) throw SettingsRequiredException(details);
      rethrow;
    }
  }

  /// `details` of a 422 `{code: SETTINGS_REQUIRED}` answer, else `null`.
  /// The client keeps the raw body in the exception message.
  static List<String>? settingsRequiredDetails(AdminApiException error) {
    if (error.statusCode != 422) return null;
    final start = error.message.indexOf('{');
    if (start < 0) return null;
    try {
      final body = jsonDecode(error.message.substring(start));
      if (body is! Map || body['code'] != 'SETTINGS_REQUIRED') return null;
      final details = body['details'];
      return [
        if (details is List)
          for (final d in details) '$d'
      ];
    } on FormatException {
      return null;
    }
  }
}
