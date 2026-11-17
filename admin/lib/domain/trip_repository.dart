import 'admin_catalog_repositories.dart';
import 'admin_trip.dart';
import 'list_query.dart';
import 'paged_result.dart';

/// Transport trips (`/admin/trips`, ADR-010). Filters `status`, `type`,
/// `providerId`, `villaId` and the [TripDateRange] window; search matches
/// guest name or flight number; sortable by `pickupAt`.
abstract interface class TripRepository {
  Future<PagedResult<AdminTrip>> list(ListQuery query);
  Future<AdminTrip> get(String id);

  /// Staff create on behalf of a guest; returns the server-confirmed trip
  /// (with the suggested pickup when none was sent).
  Future<AdminTrip> create(NewTripRequest request);

  /// One status step (or a cancel); returns the server-confirmed trip.
  Future<AdminTrip> transition(String id, TripTransition move);
}

/// The backend needs values that are not configured in Settings yet (HTTP
/// 422 `code: SETTINGS_REQUIRED`), e.g. `timeZone` or `airports.CUN`.
class SettingsRequiredException implements Exception {
  const SettingsRequiredException(this.details);

  final List<String> details;

  @override
  String toString() => 'SettingsRequiredException($details)';
}

/// Everything the Transportation screen reads and writes.
class TransportRepositories {
  const TransportRepositories({
    required this.trips,
    required this.providers,
    required this.services,
    required this.stays,
  });

  final TripRepository trips;
  final TransportProviderRepository providers;

  /// Transport services and their vehicle items (`kind=TRANSPORT`).
  final ServiceCatalogRepository services;

  /// Stays to pick the guest of a new trip.
  final StayListRepository stays;
}
