import 'package:flutter/widgets.dart';

import '../../domain/admin_notification.dart';
import '../../domain/admin_task.dart';
import '../../domain/conversation.dart';
import '../../domain/dashboard_view.dart';
import '../../domain/guest_profile.dart';
import '../../domain/reservation.dart';

/// Ports of Dashboard, Reservations, Guests (+ Messages), Tasks and
/// Notifications (ADR-011), wired once in `main.dart` and faked in tests.
class OperationsDeps {
  const OperationsDeps({
    required this.dashboard,
    required this.reservations,
    required this.guests,
    required this.tasks,
    required this.notifications,
    required this.conversations,
  });

  final DashboardRepository dashboard;
  final ReservationRepository reservations;
  final GuestRepository guests;
  final TaskRepository tasks;
  final NotificationRepository notifications;
  final ConversationRepository conversations;
}

/// Provides [OperationsDeps]; screens without it show one error line.
class OperationsScope extends InheritedWidget {
  const OperationsScope({super.key, required this.deps, required super.child});

  final OperationsDeps deps;

  static OperationsDeps? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OperationsScope>()?.deps;

  @override
  bool updateShouldNotify(OperationsScope oldWidget) => oldWidget.deps != deps;
}

/// Builds [builder] at once with `null`, then again with the record [load]
/// returns (keyed by [id], so a list re-opens with it as its initial
/// detail). A failed load keeps the plain list.
class OpenRecordLoader<T> extends StatefulWidget {
  const OpenRecordLoader({
    super.key,
    required this.id,
    required this.load,
    required this.builder,
  });

  /// `null` when nothing has to be opened.
  final String? id;
  final Future<T> Function(String id) load;
  final Widget Function(BuildContext context, T? initial) builder;

  @override
  State<OpenRecordLoader<T>> createState() => _OpenRecordLoaderState<T>();
}

class _OpenRecordLoaderState<T> extends State<OpenRecordLoader<T>> {
  T? _record;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(OpenRecordLoader<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) _fetch();
  }

  Future<void> _fetch() async {
    final id = widget.id;
    if (id == null) return;
    try {
      final record = await widget.load(id);
      if (mounted && widget.id == id) setState(() => _record = record);
    } catch (error) {
      debugPrint('Open record $id failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) => KeyedSubtree(
        key: ValueKey(_record == null ? 'list' : 'open-${widget.id}'),
        child: widget.builder(context, _record),
      );
}
