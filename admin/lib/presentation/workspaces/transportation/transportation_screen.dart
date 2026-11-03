import 'package:flutter/material.dart';

import '../../../application/list_query_store.dart';
import '../../../application/resort_settings_controller.dart';
import '../../../core/admin_list_strings.dart';
import '../../../core/resort_time.dart';
import '../../../domain/service_catalog_enums.dart';
import '../../../domain/trip_repository.dart';
import '../../components/components.dart';
import '../../services/service_catalog_scope.dart';
import 'transportation_workspace.dart';
import 'trip_scope.dart';

/// Shell entry of HOSPITALITY › Transportation: joins the catalog ports
/// ([ServiceCatalogScope]: services, providers) with [TripScope] (trips,
/// stays). Without them it shows one error line, never invented data.
class TransportationScreen extends StatelessWidget {
  const TransportationScreen({
    super.key,
    required this.resortSettings,
    required this.queries,
    required this.isEs,
    required this.onOpenSettings,
    required this.onOpenServicesTab,
    this.openTripId,
    ZoneOffsetResolver? zoneResolver,
  }) : _zoneResolver = zoneResolver;

  /// [ListQueryStore] key and filter of the Services catalog list.
  static const String servicesStoreKey = 'services';

  final ResortSettingsController resortSettings;
  final ListQueryStore queries;
  final bool isEs;
  final VoidCallback onOpenSettings;

  /// Selects the Services workspace.
  final VoidCallback onOpenServicesTab;

  /// A trip to open (notification "Open", reservation Trips tab).
  final String? openTripId;
  final ZoneOffsetResolver? _zoneResolver;

  /// Services opens filtered by the Transportation section.
  void _openServices() {
    final current = queries.read(servicesStoreKey);
    queries.write(servicesStoreKey,
        current.withFilter('section', ServiceSection.transportation.wire));
    onOpenServicesTab();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ServiceCatalogScope.maybeOf(context);
    final trips = TripScope.maybeOf(context);
    if (catalog == null || trips == null) {
      return Align(
        alignment: Alignment.topLeft,
        child: AdminStateLine(
          key: const Key('workspace-admin-transportation'),
          message: AdminListStrings(isEs).loadError,
          isError: true,
        ),
      );
    }
    return TransportationWorkspace(
      repositories: TransportRepositories(
        trips: trips.trips,
        providers: catalog.providers,
        services: catalog.services,
        stays: trips.stays,
      ),
      resortSettings: resortSettings,
      queries: queries,
      zoneResolver: _zoneResolver ?? createZoneOffsetResolver(),
      isEs: isEs,
      onOpenSettings: onOpenSettings,
      onOpenServices: _openServices,
      openTripId: openTripId,
    );
  }
}
