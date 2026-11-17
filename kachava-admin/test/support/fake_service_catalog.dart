import 'dart:convert';

import 'package:kachava_admin_dashboard/application/service_catalog_deps.dart';
import 'package:kachava_admin_dashboard/data/admin_api_client.dart';
import 'package:kachava_admin_dashboard/domain/admin_catalog_repositories.dart';
import 'package:kachava_admin_dashboard/domain/admin_service.dart';
import 'package:kachava_admin_dashboard/domain/catalog_values.dart';
import 'package:kachava_admin_dashboard/domain/list_query.dart';
import 'package:kachava_admin_dashboard/domain/paged_result.dart';
import 'package:kachava_admin_dashboard/domain/transport_provider.dart';

import 'fake_uploads.dart';
import 'in_memory_paged_source.dart';

/// The 422 the backend sends when a record cannot be ACTIVE.
AdminApiException ruleViolation(String message, List<String> problems) =>
    AdminApiException(
      statusCode: 422,
      message: 'Admin API HTTP 422: ${jsonEncode({
            'statusCode': 422,
            'message': '$message: ${problems.join('; ')}',
          })}',
    );

/// Test-only in-memory catalog that applies the backend list rules and the
/// ADR-009 activation rule. Records every write body.
class FakeServiceCatalogRepository implements ServiceCatalogRepository {
  final List<AdminService> services = [];
  final Map<String, List<ServiceItem>> items = {};
  final List<Map<String, dynamic>> creates = [];
  final List<Map<String, dynamic>> patches = [];
  final List<Map<String, dynamic>> itemWrites = [];
  final List<ListQuery> queries = [];
  Object? failListWith;
  int _ids = 0;

  void seed(Iterable<AdminService> values) => services.addAll(values);

  @override
  Future<PagedResult<AdminService>> list(ListQuery query) async {
    queries.add(query);
    if (failListWith != null) throw failListWith!;
    return InMemoryPagedSource<AdminService>(
      items: services,
      searchText: (s) => [s.name.en, s.name.es, s.category ?? ''],
      sortValue: (s, field) => field == 'name' ? s.name.en : s.order,
      filterValue: (s, key) => switch (key) {
        'section' => s.section.wire,
        'status' => s.status.wire,
        'usageType' => s.usageType.wire,
        _ => null,
      },
    ).page(
        query.sort == null ? query.withSort(const ListSort('order')) : query);
  }

  @override
  Future<AdminService> get(String id) async =>
      services.firstWhere((s) => s.id == id);

  @override
  Future<AdminService> create(AdminService service) async {
    creates.add(service.toCreateJson());
    return _store(service, 'svc-${++_ids}');
  }

  @override
  Future<AdminService> update(AdminService service) async {
    patches.add(service.toPatchJson());
    return _store(service, service.id);
  }

  AdminService _store(AdminService service, String id) {
    _checkActivation(service);
    final saved = AdminService.fromJson({...service.toDraftJson(), 'id': id});
    services.removeWhere((s) => s.id == id);
    services.add(saved);
    return saved;
  }

  void _checkActivation(AdminService s) {
    if (s.status != CatalogStatus.active) return;
    final problems = [
      if (s.cover == null) 'cover image is required',
      for (final (field, text) in [
        ('name', s.name),
        ('shortDescription', s.shortDescription)
      ]) ...[
        if (text.en.trim().isEmpty) '$field.en is required',
        if (text.es.trim().isEmpty) '$field.es is required',
      ],
    ];
    if (problems.isNotEmpty) {
      throw ruleViolation('Service cannot be active', problems);
    }
  }

  @override
  Future<PagedResult<ServiceItem>> listItems(
          String serviceId, ListQuery query) async =>
      InMemoryPagedSource<ServiceItem>(
        items: items[serviceId] ?? const [],
        searchText: (i) => [i.name.en],
        sortValue: (i, field) => field == 'name' ? i.name.en : i.order,
      ).page(query);

  @override
  Future<ServiceItem> createItem(String serviceId, ServiceItem item) async =>
      _storeItem(serviceId, item, 'item-${++_ids}');

  @override
  Future<ServiceItem> updateItem(String serviceId, ServiceItem item) async =>
      _storeItem(serviceId, item, item.id);

  ServiceItem _storeItem(String serviceId, ServiceItem item, String id) {
    itemWrites.add(item.toWriteJson());
    if (item.status == CatalogStatus.active && !item.name.isComplete) {
      throw ruleViolation('Item cannot be active', ['name.es is required']);
    }
    final saved = ServiceItem.fromJson({...item.toDraftJson(), 'id': id});
    final list = items.putIfAbsent(serviceId, () => []);
    list.removeWhere((i) => i.id == id);
    list.add(saved);
    return saved;
  }
}

/// Test-only provider list.
class FakeTransportProviderRepository implements TransportProviderRepository {
  FakeTransportProviderRepository([this.providers = const []]);

  final List<TransportProvider> providers;

  @override
  Future<PagedResult<TransportProvider>> list(ListQuery query) async =>
      PagedResult(
          items: providers,
          page: 1,
          pageSize: query.pageSize,
          total: providers.length);

  @override
  Future<TransportProvider> create(TransportProvider provider) async =>
      provider;

  @override
  Future<TransportProvider> update(TransportProvider provider) async =>
      provider;
}

/// A ready [ServiceCatalogDeps] made of fakes.
ServiceCatalogDeps fakeCatalogDeps(
  FakeServiceCatalogRepository repo, {
  FakeImageFilePicker? picker,
  FakeSignedUploadTransport? transport,
  List<TransportProvider> providers = const [],
}) =>
    ServiceCatalogDeps(
      services: repo,
      providers: FakeTransportProviderRepository(providers),
      signer: FakeUploadSigner(),
      transport: transport ?? FakeSignedUploadTransport(),
      picker: picker ?? FakeImageFilePicker(pickedImage()),
    );

/// A generated catalog row (no business data).
AdminService testService(
  int n, {
  ServiceKind kind = ServiceKind.experience,
  ServiceSection? section,
  CatalogStatus status = CatalogStatus.disabled,
  bool withCover = false,
}) =>
    AdminService(
      id: 's$n',
      kind: kind,
      section: section ?? kind.defaultSection,
      usageType: kind.defaultUsage,
      name: LocalizedText(
          en: 'Service ${'$n'.padLeft(3, '0')}', es: 'Servicio $n'),
      shortDescription: const LocalizedText(en: 'Short', es: 'Corto'),
      order: n,
      status: status,
      cover: withCover
          ? const CatalogImage(
              storagePath: 'catalog/services/c.png',
              url: 'https://cdn.test/c.png',
              usageRightsConfirmed: true)
          : null,
      pricing: const ServicePricing(mode: PricingMode.fixed, amount: 50),
    );
