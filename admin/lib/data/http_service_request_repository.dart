import '../domain/list_query.dart';
import '../domain/paged_result.dart';
import '../domain/service_catalog_enums.dart';
import '../domain/service_request.dart';
import 'admin_api_client.dart';
import 'admin_http_resource.dart';
import 'http_trip_repository.dart';

/// `GET /admin/requests?section=` and `POST /admin/requests/:id/transition`.
class HttpServiceRequestRepository implements ServiceRequestRepository {
  HttpServiceRequestRepository(this._client);

  static const String _path = '/requests';

  final AdminApiClient _client;

  /// The day-range filter goes on the wire as `from`/`to` resort days.
  @override
  Future<PagedResult<ServiceRequest>> list(
      ServiceSection section, ListQuery query) async {
    final params = HttpTripRepository.wireParameters(query)
      ..['section'] = section.wire;
    final qs = Uri(queryParameters: params).query;
    return PagedResult.fromEnvelope(
        await _client.getJson('$_path?$qs'), ServiceRequest.fromJson);
  }

  @override
  Future<ServiceRequest> transition(String id, RequestAction action,
      {String? reason}) async {
    final raw =
        await _client.postJson('$_path/${Uri.encodeComponent(id)}/transition', {
      'action': action.wire,
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    });
    return ServiceRequest.fromJson(unwrapRecord(raw));
  }
}
