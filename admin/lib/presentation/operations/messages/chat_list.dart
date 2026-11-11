import 'package:flutter/material.dart';

import '../../../core/inbox_strings.dart';
import '../../../core/ops_strings.dart';
import '../../../core/resort_time.dart';
import '../../../core/theme/kachava_tokens.dart';
import '../../../domain/conversation.dart';
import '../../../domain/list_query.dart';
import '../../../domain/realtime_change.dart';
import '../../components/components.dart';

/// Chat order: awaiting reply first (oldest waiting first), then the rest
/// by newest message.
List<ConversationRow> chatOrder(List<ConversationRow> rows) {
  int byTime(ConversationRow a, ConversationRow b, {bool oldestFirst = false}) {
    final x = a.lastAt, y = b.lastAt;
    if (x == null || y == null) return x == null ? 1 : -1;
    return oldestFirst ? x.compareTo(y) : y.compareTo(x);
  }

  final waiting = rows.where((r) => r.awaitingReply).toList()
    ..sort((a, b) => byTime(a, b, oldestFirst: true));
  final rest = rows.where((r) => !r.awaitingReply).toList()..sort(byTime);
  return [...waiting, ...rest];
}

/// "VG" from "Valeria Gómez".
String initialsOf(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  return words.take(2).map((w) => w[0].toUpperCase()).join();
}

/// Left pane of Messages: conversations with avatar, name, villa, preview,
/// time and unread bubble; search; reloads on real-time message signals.
class ChatList extends StatefulWidget {
  const ChatList({
    super.key,
    required this.repository,
    required this.resortTime,
    required this.isEs,
    required this.selectedStayId,
    required this.onSelect,
    this.now,
    this.reloadToken = 0,
  });

  static const ListQuery query = ListQuery(
      sort: ListSort('lastMessageAt', SortDirection.desc), pageSize: 50);

  final ConversationRepository repository;
  final ResortTime resortTime;
  final bool isEs;
  final String? selectedStayId;
  final ValueChanged<ConversationRow> onSelect;
  final DateTime Function()? now;

  /// Bumped by the parent to force a reload (after read / reply).
  final int reloadToken;

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList>
    with AdminRealtimeRefresh<ChatList> {
  List<ConversationRow>? _rows;
  Object? _error;
  String _q = '';

  OpsStrings get _s => OpsStrings(widget.isEs);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ChatList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadToken != widget.reloadToken) _load();
  }

  @override
  void onRealtimeInvalidation(RealtimeInvalidation change) {
    if (change.touches(const {RealtimeTopic.messages, RealtimeTopic.stay})) {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final page = await widget.repository.list(ChatList.query.withSearch(_q));
      if (mounted) {
        setState(() {
          _rows = chatOrder(page.items);
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  /// Opening reads the conversation: the bubble clears right away.
  void _open(ConversationRow row) {
    setState(() => _rows = [
          for (final r in _rows ?? const <ConversationRow>[])
            r.stayId == row.stayId ? r.asRead() : r
        ]);
    widget.onSelect(row);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('chat-list'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(KachavaTokens.space3),
          child: TextField(
            key: const Key('chat-search'),
            decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 20),
                hintText: _s.messages),
            onChanged: (v) {
              _q = v;
              _load();
            },
          ),
        ),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_error != null && _rows == null) {
      return Align(
        alignment: Alignment.topLeft,
        child: AdminStateLine(
            message: _s.noMessages, isError: true, onAction: _load),
      );
    }
    final rows = _rows;
    if (rows == null) return const LinearProgressIndicator();
    if (rows.isEmpty) {
      return Align(
          alignment: Alignment.topLeft,
          child: AdminStateLine(message: _s.noConversations));
    }
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (context, i) => ChatRow(
        row: rows[i],
        selected: rows[i].stayId == widget.selectedStayId,
        resortTime: widget.resortTime,
        isEs: widget.isEs,
        now: (widget.now ?? DateTime.now)().toUtc(),
        onTap: () => _open(rows[i]),
      ),
    );
  }
}

/// One conversation row; unread = bold + accent stripe + count bubble.
class ChatRow extends StatelessWidget {
  const ChatRow({
    super.key,
    required this.row,
    required this.selected,
    required this.resortTime,
    required this.isEs,
    required this.now,
    required this.onTap,
  });

  final ConversationRow row;
  final bool selected;
  final ResortTime resortTime;
  final bool isEs;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final unread = row.hasUnread;
    final s = OpsStrings(isEs);
    final preview =
        row.lastHasPhoto && row.lastText.isEmpty ? s.photo : row.lastText;
    final at = row.lastAt;
    final when = at == null
        ? ''
        : row.awaitingReply
            ? InboxStrings(isEs).ago(now.difference(at))
            : resortTime.label(at, isEs: isEs);
    return Material(
      color: selected ? KachavaTokens.primarySelected : Colors.transparent,
      child: InkWell(
        key: Key('chat-row-${row.stayId}'),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: KachavaTokens.space3, vertical: KachavaTokens.space2),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                  width: 3,
                  color: unread ? KachavaTokens.primary : Colors.transparent),
              bottom: const BorderSide(color: KachavaTokens.border),
            ),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: KachavaTokens.surface,
              foregroundColor: KachavaTokens.text,
              child: Text(initialsOf(row.guestName),
                  style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: KachavaTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: TruncatedText(row.guestName,
                          style: text.bodyMedium?.copyWith(
                              fontWeight:
                                  unread ? FontWeight.w700 : FontWeight.w400)),
                    ),
                    Text(when,
                        key: Key('chat-when-${row.stayId}'),
                        style: text.bodySmall?.copyWith(
                            color: row.awaitingReply
                                ? KachavaTokens.warningForeground
                                : KachavaTokens.textSecondary)),
                  ]),
                  TruncatedText(row.villaName,
                      style: text.bodySmall
                          ?.copyWith(color: KachavaTokens.textSecondary)),
                  Row(children: [
                    Expanded(
                      child: TruncatedText(preview,
                          style: text.bodySmall
                              ?.copyWith(color: KachavaTokens.textSecondary)),
                    ),
                    if (unread)
                      StatusChip(
                          key: Key('chat-unread-${row.stayId}'),
                          label: '${row.unreadCount}',
                          tone: StatusTone.warning),
                  ]),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
