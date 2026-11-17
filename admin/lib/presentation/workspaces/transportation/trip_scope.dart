import 'package:flutter/widgets.dart';

import '../../../domain/admin_catalog_repositories.dart';
import '../../../domain/trip_repository.dart';

/// Ports only the Transportation screen needs beyond the service catalog
/// ([ServiceCatalogScope] already provides services and providers).
class TripDeps {
  const TripDeps({required this.trips, required this.stays});

  final TripRepository trips;

  /// Stays to pick the guest of a new trip.
  final StayListRepository stays;
}

/// Provides [TripDeps] (wired once in `main.dart`, faked in tests).
class TripScope extends InheritedWidget {
  const TripScope({super.key, required this.deps, required super.child});

  final TripDeps deps;

  /// `null` when trips are not wired (the screen shows one error line).
  static TripDeps? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TripScope>()?.deps;

  @override
  bool updateShouldNotify(TripScope oldWidget) => oldWidget.deps != deps;
}
