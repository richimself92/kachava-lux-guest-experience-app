import 'package:flutter/material.dart';

import '../../application/list_query_store.dart';
import '../../application/paged_list_controller.dart';
import '../../core/ops_strings.dart';
import '../../core/resort_time.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../domain/admin_notification.dart';
import '../../domain/list_query.dart';
import '../components/components.dart';

/// OPERATIONS › Notifications: level chip, message, villa / guest, time and
/// read state; filters level / read (unread by default) / category;
/// "Mark all read"; "Open" marks it read and goes to its record.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.repository,
    required this.queries,
    required this.resortTime,
    required this.isEs,
    required this.onOpenTarget,
    required this.onReadChanged,
  });

  static const String storeKey = 'notifications';

  final NotificationRepository repository;
  final ListQueryStore queries;
  final ResortTime resortTime;
  final bool isEs;

  /// Navigates to the notification's record.
  final ValueChanged<NotificationTarget> onOpenTarget;

  /// The unread count changed (refresh the bell).
  final VoidCallback onReadChanged;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final PagedListController<AdminNotification> _list = PagedListController(
    fetch: widget.repository.list,
    initialQuery: const ListQuery(
        sort: ListSort('createdAt', SortDirection.desc),
        filters: {'read': 'false'}),
    store: widget.queries,
    storeKey: NotificationsScreen.storeKey,
  );

  OpsStrings get _s => OpsStrings(widget.isEs);

  @override
  void dispose() {
    _list.dispose();
    super.dispose();
  }

  /// Marks it read (best effort) and opens its record.
  Future<void> _open(AdminNotification n) async {
    if (!n.read) {
      try {
        await widget.repository.markRead(n.id);
        widget.onReadChanged();
      } catch (error) {
        debugPrint('Mark read failed: $error');
      }
    }
    if (!mounted) return;
    widget.onOpenTarget(n.target);
  }

  Future<void> _markAll() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await widget.repository.markAllRead();
      widget.onReadChanged();
      await _list.load();
      showAdminToastOn(messenger, _s.allMarked);
    } catch (_) {
      showAdminToastOn(messenger, _s.actionFailed,
          isError: true, isEs: widget.isEs);
    }
  }

  @override
  Widget build(BuildContext context) => AdminListScreen<AdminNotification>(
        key: const Key('workspace-admin-notifications'),
        entity: 'notifications',
        title: _s.notifications,
        info: _s.notificationsInfo,
        controller: _list,
        columns: _columns(),
        rowId: (n) => n.id,
        compactTitle: (n) => n.title,
        compactSubtitle: (n) => [
          _where(n),
          widget.resortTime.label(n.createdAt, isEs: widget.isEs),
        ].where((t) => t.isNotEmpty).join(' · '),
        compactTrailing: _level,
        filters: _filters(),
        emptyMessage: _s.noNotifications,
        primaryActionLabel: _s.markAllRead,
        onPrimaryAction: _markAll,
        onRowTap: _open,
        isEs: widget.isEs,
      );

  String _where(AdminNotification n) =>
      [n.villaName, n.guestName].whereType<String>().join(' · ');

  Widget _level(AdminNotification n) => StatusChip(
        key: Key('notification-level-${n.id}'),
        label: _s.levelLabel(n.level),
        tone: switch (n.level) {
          NotificationValues.urgent => StatusTone.error,
          NotificationValues.action => StatusTone.warning,
          _ => StatusTone.neutral,
        },
      );

  List<AdminTableColumn<AdminNotification>> _columns() => [
        AdminTableColumn(label: _s.level, cell: _level, flex: 1),
        AdminTableColumn(label: _s.message, text: (n) => n.title, flex: 4),
        AdminTableColumn(label: _s.villaGuest, text: _where, flex: 2),
        AdminTableColumn(
            label: _s.time,
            text: (n) =>
                widget.resortTime.label(n.createdAt, isEs: widget.isEs),
            sortField: 'createdAt'),
        AdminTableColumn(
            label: _s.status,
            flex: 1,
            cell: (n) => StatusChip(
                label: n.read ? _s.read : _s.unread,
                tone: n.read ? StatusTone.neutral : StatusTone.info)),
        AdminTableColumn(
            label: _s.open,
            flex: 1,
            cell: (n) => TextButton(
                key: Key('notification-open-${n.id}'),
                onPressed: () => _open(n),
                child: Text(_s.open))),
      ];

  List<AdminListFilter> _filters() => [
        AdminListFilter(key: 'level', label: _s.level, options: [
          for (final l in NotificationValues.levels)
            AdminFilterOption(l, _s.levelLabel(l)),
        ]),
        AdminListFilter(key: 'read', label: _s.status, options: [
          AdminFilterOption('false', _s.unread),
          AdminFilterOption('true', _s.read),
        ]),
        AdminListFilter(key: 'category', label: _s.category, options: [
          for (final c in NotificationValues.categories)
            AdminFilterOption(c, _s.categoryLabel(c)),
        ]),
      ];
}
