import '../domain/admin_catalog_repositories.dart';
import '../domain/admin_service.dart';
import '../domain/list_query.dart';
import '../domain/paged_result.dart';
import 'admin_api_client.dart';
import 'admin_http_resource.dart';

/// `/admin/services` and `/admin/services/:id/items` (backend
/// `modules/catalog`). A 422 (activation rules) is an `AdminApiException`;
/// read it with `CatalogRuleViolation.tryParse`.
class HttpServiceCatalogRepository implements ServiceCatalogRepository {
  HttpServiceCatalogRepository(this._client)
      : _services =
            AdminHttpResource(_client, '/services', AdminService.fromJson);

  final AdminApiClient _client;
  final AdminHttpResource<AdminService> _services;

  AdminHttpResource<ServiceItem> _items(String serviceId) => AdminHttpResource(
      _client,
      '/services/${Uri.encodeComponent(serviceId)}/items',
      ServiceItem.fromJson);

  @override
  Future<PagedResult<AdminService>> list(ListQuery query) =>
      _services.list(query);

  @override
  Future<AdminService> get(String id) => _services.get(id);

  @override
  Future<AdminService> create(AdminService service) =>
      _services.create(service.toCreateJson());

  @override
  Future<AdminService> update(AdminService service) =>
      _services.update(service.id, service.toPatchJson());

  @override
  Future<PagedResult<ServiceItem>> listItems(
          String serviceId, ListQuery query) =>
      _items(serviceId).list(query);

  @override
  Future<ServiceItem> createItem(String serviceId, ServiceItem item) =>
      _items(serviceId).create(item.toWriteJson());

  @override
  Future<ServiceItem> updateItem(String serviceId, ServiceItem item) =>
      _items(serviceId).update(item.id, item.toWriteJson());
}
