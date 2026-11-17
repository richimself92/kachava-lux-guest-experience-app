import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../domain/realtime_change.dart';

/// Hands the debounced real-time invalidations (ADR-012) to every screen
/// below it. Without a scope (tests, no stream) screens simply never get
/// realtime refreshes and rely on their own loads.
class AdminRealtimeScope extends InheritedWidget {
  const AdminRealtimeScope({
    super.key,
    required this.invalidations,
    required super.child,
  });

  final Stream<RealtimeInvalidation>? invalidations;

  static Stream<RealtimeInvalidation>? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<AdminRealtimeScope>()
      ?.invalidations;

  @override
  bool updateShouldNotify(AdminRealtimeScope oldWidget) =>
      !identical(invalidations, oldWidget.invalidations);
}

/// Subscribes a [State] to the nearest [AdminRealtimeScope] for as long as
/// it is mounted; [onRealtimeInvalidation] runs once per debounced batch.
mixin AdminRealtimeRefresh<W extends StatefulWidget> on State<W> {
  Stream<RealtimeInvalidation>? _realtimeStream;
  StreamSubscription<RealtimeInvalidation>? _realtimeSub;

  /// Reload what this screen shows if [change] concerns it.
  void onRealtimeInvalidation(RealtimeInvalidation change);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = AdminRealtimeScope.maybeOf(context);
    if (identical(stream, _realtimeStream)) return;
    _realtimeSub?.cancel();
    _realtimeStream = stream;
    _realtimeSub = stream?.listen((change) {
      if (mounted) onRealtimeInvalidation(change);
    });
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }
}

/// Topics that may change the rows of the admin list [entity]
/// (`AdminListScreen.entity`); null means "any topic".
Set<String>? realtimeTopicsForList(String entity) {
  if (entity.startsWith('requests')) return _requestTopics;
  return _listTopics[entity];
}

const Set<String> _requestTopics = {
  RealtimeTopic.requests,
  RealtimeTopic.bookings,
  RealtimeTopic.orders,
  RealtimeTopic.stay,
};

const Map<String, Set<String>> _listTopics = {
  'staff': {RealtimeTopic.staff},
  'providers': {RealtimeTopic.providers},
  'villas': {RealtimeTopic.villas, RealtimeTopic.stay},
  'trips': {RealtimeTopic.trips, RealtimeTopic.stay, RealtimeTopic.providers},
  'notifications': {RealtimeTopic.notifications},
  'tasks': {RealtimeTopic.tasks, RealtimeTopic.staff},
  'reservations': {
    RealtimeTopic.stay,
    RealtimeTopic.trips,
    RealtimeTopic.bookings,
    RealtimeTopic.orders,
    RealtimeTopic.requests,
    RealtimeTopic.villas,
  },
  'conversations': {RealtimeTopic.messages, RealtimeTopic.stay},
  'guests': {
    RealtimeTopic.stay,
    RealtimeTopic.requests,
    RealtimeTopic.bookings,
    RealtimeTopic.orders,
    RealtimeTopic.trips,
  },
  'services': {RealtimeTopic.catalog},
  'items': {RealtimeTopic.catalog},
};
