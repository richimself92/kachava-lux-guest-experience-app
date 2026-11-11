import 'package:flutter/material.dart';

import '../../../application/list_query_store.dart';
import '../../../application/paged_list_controller.dart';
import '../../../core/ops_strings.dart';
import '../../../core/resort_time.dart';
import '../../../core/stay_strings.dart';
import '../../../core/theme/kachava_tokens.dart';
import '../../../domain/conversation.dart';
import '../../../domain/list_query.dart';
import '../../../domain/paged_result.dart';
import '../../components/components.dart';
import 'conversation_panel.dart';

/// Messages inbox: unread conversations first, search, filters unread /
/// awaiting reply, pages; a row opens the chat in the side panel.
class MessagesTab extends StatefulWidget {
  const MessagesTab({
    super.key,
    required this.repository,
    required this.queries,
    required this.resortTime,
    required this.isEs,
    this.openStayId,
    this.onRead,
  });

  static const String storeKey = 'conversations';

  final ConversationRepository repository;
  final ListQueryStore queries;
  final ResortTime resortTime;
  final bool isEs;

  /// A conversation to open on arrival (notification, guest profile).
  final String? openStayId;
  final VoidCallback? onRead;

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  late final PagedListController<ConversationRow> _list = PagedListController(
    fetch: _fetch,
    initialQuery:
        const ListQuery(sort: ListSort('lastMessageAt', SortDirection.desc)),
    store: widget.queries,
    storeKey: MessagesTab.storeKey,
  );

  OpsStrings get _s => OpsStrings(widget.isEs);

  /// The server orders by last message; unread ones go first on the page.
  Future<PagedResult<ConversationRow>> _fetch(ListQuery query) async {
    final page = await widget.repository.list(query);
    return PagedResult(
      items: ConversationRow.unreadFirst(page.items),
      page: page.page,
      pageSize: page.pageSize,
      total: page.total,
    );
  }

  @override
  void dispose() {
    _list.dispose();
    super.dispose();
  }

  void _changed() {
    _list.load();
    widget.onRead?.call();
  }

  /// A deep link may name a stay without a row on this page.
  ConversationRow? get _initial {
    final id = widget.openStayId;
    if (id == null) return null;
    return ConversationRow(
      stayId: id,
      guestName: '',
      villaName: '',
      lastText: '',
      lastAt: null,
      lastFromGuest: false,
      lastHasPhoto: false,
      unreadCount: 0,
      awaitingReply: false,
    );
  }

  @override
  Widget build(BuildContext context) => AdminListScreen<ConversationRow>(
        entity: 'conversations',
        title: _s.messages,
        controller: _list,
        columns: _columns(),
        rowId: (c) => c.stayId,
        compactTitle: (c) => c.guestName,
        compactSubtitle: _preview,
        compactTrailing: _unreadCell,
        filters: [
          AdminListFilter(
              key: 'unread',
              label: _s.unreadOnly,
              options: [AdminFilterOption('true', _s.yes)]),
          AdminListFilter(
              key: 'awaitingReply',
              label: _s.awaitingReply,
              options: [AdminFilterOption('true', _s.yes)]),
        ],
        emptyMessage: _s.noConversations,
        detailBuilder: (context, row, close) => ConversationPanel(
          stayId: row!.stayId,
          title: row.guestName,
          repository: widget.repository,
          resortTime: widget.resortTime,
          onClose: close,
          onChanged: _changed,
          isEs: widget.isEs,
        ),
        initialDetail: _initial,
        isEs: widget.isEs,
      );

  String _preview(ConversationRow c) {
    final text = c.lastHasPhoto && c.lastText.isEmpty ? _s.photo : c.lastText;
    return [c.villaName, text].where((t) => t.isNotEmpty).join(' · ');
  }

  Widget? _unreadCell(ConversationRow c) => c.hasUnread
      ? StatusChip(
          key: Key('conversation-unread-${c.stayId}'),
          label: '${c.unreadCount}',
          tone: StatusTone.info)
      : null;

  List<AdminTableColumn<ConversationRow>> _columns() => [
        AdminTableColumn(
            label: StayStrings(widget.isEs).guest,
            flex: 2,
            cell: (c) => Text(c.guestName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight:
                        c.hasUnread ? FontWeight.w700 : FontWeight.w400))),
        AdminTableColumn(
            label: StayStrings(widget.isEs).villa, text: (c) => c.villaName),
        AdminTableColumn(
            label: _s.lastMessage,
            flex: 4,
            cell: (c) => Row(children: [
                  if (c.lastHasPhoto)
                    const Padding(
                      padding: EdgeInsets.only(right: KachavaTokens.space1),
                      child: Icon(Icons.photo_outlined, size: 16),
                    ),
                  Expanded(
                    child: Text(c.lastText,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ])),
        AdminTableColumn(
            label: _s.time,
            text: (c) => widget.resortTime.label(c.lastAt, isEs: widget.isEs),
            sortField: 'lastMessageAt'),
        AdminTableColumn(
            label: _s.status,
            cell: (c) => Wrap(spacing: KachavaTokens.space1, children: [
                  if (_unreadCell(c) case final chip?) chip,
                  if (c.awaitingReply)
                    StatusChip(
                        label: _s.awaitingReply, tone: StatusTone.warning),
                ])),
      ];
}
