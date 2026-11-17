import 'package:flutter/widgets.dart';

import '../../application/guest_activity_watcher.dart';
import '../../application/request_inbox_source.dart';
import '../../domain/admin_catalog_repositories.dart';
import '../../domain/service_request.dart';
import '../../domain/trip_repository.dart';

/// Ports of the Requests inbox (wired once in `main.dart`, faked in tests).
class RequestInboxDeps {
  const RequestInboxDeps({
    required this.requests,
    this.trips,
    this.providers,
  });

  final ServiceRequestRepository requests;
  final TripRepository? trips;

  /// Active providers for "Send to provider".
  final TransportProviderRepository? providers;

  RequestInboxSource get source =>
      RequestInboxSource(requests: requests, trips: trips);
}

/// Provides the inbox ports and the [GuestActivityWatcher] (badges, unread
/// rows, arrivals) to the menu, the inbox and the shell toast.
class RequestInboxScope extends InheritedWidget {
  const RequestInboxScope({
    super.key,
    required this.deps,
    required this.watcher,
    required super.child,
  });

  final RequestInboxDeps? deps;
  final GuestActivityWatcher watcher;

  static RequestInboxScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RequestInboxScope>();

  @override
  bool updateShouldNotify(RequestInboxScope oldWidget) =>
      deps != oldWidget.deps || watcher != oldWidget.watcher;
}
