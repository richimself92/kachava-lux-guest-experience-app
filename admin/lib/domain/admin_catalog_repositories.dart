import 'admin_service.dart';
import 'admin_settings.dart';
import 'admin_villa.dart';
import 'list_query.dart';
import 'paged_result.dart';
import 'reservation.dart';
import 'transport_provider.dart';

/// Resort settings (`GET/PATCH /admin/settings`).
abstract interface class AdminSettingsRepository {
  Future<AdminSettings> fetch();

  /// Saves and returns the server-confirmed settings.
  Future<AdminSettings> update(AdminSettings settings);
}

/// Villas (`GET/POST/PATCH/DELETE /admin/villas`). Filters: `isActive`,
/// `operationalStatus`, `category`; sortable by `name`, `category`,
/// `capacity`, `operationalStatus`.
abstract interface class VillaRepository {
  Future<PagedResult<AdminVilla>> list(ListQuery query);

  /// In-service villas with no open stay on the nights `checkIn`..`checkOut`
  /// (ISO dates, departure day free): `GET /admin/villas/available`.
  Future<List<AdminVilla>> available(String checkIn, String checkOut);
  Future<AdminVilla> create(AdminVilla villa);
  Future<AdminVilla> update(AdminVilla villa);

  /// Deactivates (`false`) or reactivates a villa; sends only `isActive`.
  Future<AdminVilla> setActive(String id, bool isActive);

  /// Throws [VillaHasStaysException] when stays reference the villa.
  Future<void> delete(String id);
}

/// The villa has stays, so the backend keeps it (HTTP 409): deactivate it.
class VillaHasStaysException implements Exception {
  const VillaHasStaysException(this.villaId);

  final String villaId;

  @override
  String toString() => 'VillaHasStaysException($villaId)';
}

/// Repositories of the resort configuration screens (Settings, Villas).
class AdminResortRepositories {
  const AdminResortRepositories({required this.settings, required this.villas});

  final AdminSettingsRepository settings;
  final VillaRepository villas;
}

/// External transport providers (`/admin/transport-providers`).
abstract interface class TransportProviderRepository {
  Future<PagedResult<TransportProvider>> list(ListQuery query);
  Future<TransportProvider> create(TransportProvider provider);
  Future<TransportProvider> update(TransportProvider provider);
}

/// The single service catalog and its items (`/admin/services`,
/// `/admin/services/:id/items`).
abstract interface class ServiceCatalogRepository {
  Future<PagedResult<AdminService>> list(ListQuery query);
  Future<AdminService> get(String id);
  Future<AdminService> create(AdminService service);
  Future<AdminService> update(AdminService service);
  Future<PagedResult<ServiceItem>> listItems(String serviceId, ListQuery query);
  Future<ServiceItem> createItem(String serviceId, ServiceItem item);
  Future<ServiceItem> updateItem(String serviceId, ServiceItem item);
}

/// Paginated stay rows (`GET /admin/stays`).
abstract interface class StayListRepository {
  Future<PagedResult<ReservationRow>> list(ListQuery query);
}
