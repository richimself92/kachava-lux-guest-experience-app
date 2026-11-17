import 'package:flutter/material.dart';

import '../../application/guest_activity_watcher.dart';
import '../../application/list_query_store.dart';
import '../../application/paged_list_controller.dart';
import '../../application/request_inbox_source.dart';
import '../../core/inbox_strings.dart';
import '../../core/resort_time.dart';
import '../../domain/inbox_item.dart';
import '../../domain/realtime_change.dart';
import '../components/components.dart';
import 'inbox_detail_panel.dart';
import 'inbox_parts.dart';
import 'request_inbox_scope.dart';

/// Builds the optional extras of a request detail (linked task section).
typedef InboxTaskSectionBuilder = Widget? Function(InboxItem item);

/// One "Requests" inbox: every guest request of every section (orders,
/// bookings, preferences, trips). New first (oldest waiting first), then in
/// progress; done/cancelled only when the status filter is cleared. New
/// rows stay bold with an accent stripe until opened.
class RequestsInboxScreen extends StatefulWidget {
  const RequestsInboxScreen({
    super.key,
    required this.deps,
    required this.watcher,
    required this.isEs,
    this.queries,
    this.resortTime,
    this.now,
    this.initialItem,
    this.taskSection,
    this.onMessageGuest,
  });

  static const String entity = 'requests-inbox';
  static const String storeKey = entity;

  final RequestInboxDeps deps;
  final GuestActivityWatcher watcher;
  final bool isEs;
  final ListQueryStore? queries;
  final ResortTime? resortTime;
  final DateTime Function()? now;

  /// Opened right away (the toast's "Open").
  final InboxItem? initialItem;
  final InboxTaskSectionBuilder? taskSection;
  final ValueChanged<InboxItem>? onMessageGuest;

  static const Set<String> realtimeTopics = {
    RealtimeTopic.requests,
    RealtimeTopic.bookings,
    RealtimeTopic.orders,
    RealtimeTopic.trips,
    RealtimeTopic.stay,
  };

  @override
  State<RequestsInboxScreen> createState() => _RequestsInboxScreenState();
}

class _RequestsInboxScreenState extends State<RequestsInboxScreen> {
  late final RequestInboxSource _source = widget.deps.source;
  late final PagedListController<InboxItem> _list = PagedListController(
    fetch: _source.list,
    initialQuery: RequestInboxSource.initialQuery,
    store: widget.queries,
    storeKey: widget.queries == null ? null : RequestsInboxScreen.storeKey,
  );

  InboxStrings get _s => InboxStrings(widget.isEs);
  DateTime get _now => (widget.now ?? DateTime.now)().toUtc();

  @override
  void initState() {
    super.initState();
    widget.watcher.addListener(_onWatcher);
  }

  @override
  void dispose() {
    widget.watcher.removeListener(_onWatcher);
    _list.dispose();
    super.dispose();
  }

  void _onWatcher() {
    if (mounted) setState(() {});
  }

  void _changed() {
    _list.refresh();
    widget.watcher.check();
  }

  Widget _status(InboxItem i) =>
      InboxStatusChip(item: i, isEs: widget.isEs, overdue: i.isOverdue(_now));

  String _waiting(InboxItem i) {
    final at = i.askedAt;
    return at == null ? '' : _s.ago(_now.difference(at));
  }

  Widget _guest(InboxItem i) => InboxGuestCell(
      item: i, unread: widget.watcher.isUnread(i), isEs: widget.isEs);

  String _summary(InboxItem i) =>
      inboxSummary(i, widget.isEs, widget.resortTime);

  @override
  Widget build(BuildContext context) {
    return AdminListScreen<InboxItem>(
      entity: RequestsInboxScreen.entity,
      title: _s.title,
      info: _s.info,
      controller: _list,
      realtimeTopics: RequestsInboxScreen.realtimeTopics,
      columns: [
        AdminTableColumn(label: _s.guestVilla, cell: _guest, flex: 3),
        AdminTableColumn(label: _s.asked, text: _summary, flex: 4),
        AdminTableColumn(label: _s.waiting, text: _waiting, flex: 2),
        AdminTableColumn(label: _s.status, cell: _status, flex: 2),
      ],
      rowId: (i) => i.rowId,
      compactTitle: (i) => '${i.guestName} · ${i.villaName}',
      compactContent: (i) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _guest(i),
          TruncatedText('${_summary(i)} · ${_waiting(i)}'),
        ],
      ),
      compactTrailing: _status,
      filters: _filters(),
      emptyMessage: _s.empty,
      initialDetail: widget.initialItem,
      detailBuilder: (context, item, close) =>
          item == null ? const SizedBox.shrink() : _detail(item, close),
      isEs: widget.isEs,
    );
  }

  Widget _detail(InboxItem item, VoidCallback close) {
    if (widget.watcher.isUnread(item)) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => widget.watcher.markOpened(item.rowId));
    }
    return InboxDetailPanel(
      item: item,
      deps: widget.deps,
      onClose: close,
      onChanged: _changed,
      isEs: widget.isEs,
      resortTime: widget.resortTime,
      now: widget.now,
      taskSection: widget.taskSection?.call(item),
      onMessageGuest: widget.onMessageGuest,
    );
  }

  List<AdminListFilter> _filters() => [
        AdminListFilter(key: 'status', label: _s.status, options: [
          for (final v in InboxStatusFilter.all)
            AdminFilterOption(v, _s.statusFilter(v)),
        ]),
        AdminListFilter(key: 'section', label: _s.section, options: [
          for (final v in const [
            'IN_VILLA',
            'DINING',
            'EXPERIENCES',
            'WELLNESS',
            'TRANSPORTATION'
          ])
            AdminFilterOption(v, _s.sectionLabel(v)),
        ]),
        AdminListFilter(key: 'type', label: _s.type, options: [
          for (final t in InboxType.values)
            AdminFilterOption(t.wire, _s.typeLabel(t)),
        ]),
      ];
}
