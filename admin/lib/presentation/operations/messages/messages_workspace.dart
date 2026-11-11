import 'package:flutter/material.dart';

import '../../../application/list_query_store.dart';
import '../../../core/ops_strings.dart';
import '../../../core/resort_time.dart';
import '../../../core/theme/kachava_tokens.dart';
import '../../../domain/conversation.dart';
import '../../components/components.dart';
import 'chat_list.dart';
import 'chat_thread.dart';

/// Messages (menu): a chat. Wide: the conversation list and the open
/// conversation side by side. Narrow: the list, then the conversation full
/// screen with a back arrow.
class MessagesWorkspace extends StatefulWidget {
  const MessagesWorkspace({
    super.key,
    required this.repository,
    required this.resortTime,
    required this.isEs,
    this.queries,
    this.openStayId,
    this.onRead,
    this.onOpenStay,
    this.now,
  });

  static const double twoPaneBreakpoint = 840;
  static const double listWidth = 360;

  final ConversationRepository repository;
  final ResortTime resortTime;
  final bool isEs;
  final ListQueryStore? queries;

  /// A conversation to open on arrival (toast, request, dashboard).
  final String? openStayId;

  /// Read or answered (refresh the bell and badges).
  final VoidCallback? onRead;
  final ValueChanged<String>? onOpenStay;
  final DateTime Function()? now;

  @override
  State<MessagesWorkspace> createState() => _MessagesWorkspaceState();
}

class _MessagesWorkspaceState extends State<MessagesWorkspace> {
  late ConversationRow? _open = widget.openStayId == null
      ? null
      : ConversationRow(
          stayId: widget.openStayId!,
          guestName: '',
          villaName: '',
          lastText: '',
          lastAt: null,
          lastFromGuest: false,
          lastHasPhoto: false,
          unreadCount: 0,
          awaitingReply: false,
        );
  int _reload = 0;

  void _changed() {
    setState(() => _reload++);
    widget.onRead?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: KachavaTokens.background,
      child: LayoutBuilder(builder: (context, constraints) {
        final wide =
            constraints.maxWidth >= MessagesWorkspace.twoPaneBreakpoint;
        final list = ChatList(
          repository: widget.repository,
          resortTime: widget.resortTime,
          isEs: widget.isEs,
          selectedStayId: _open?.stayId,
          onSelect: (row) => setState(() => _open = row),
          reloadToken: _reload,
          now: widget.now,
        );
        final open = _open;
        if (!wide) {
          return open == null ? list : _thread(open, back: true);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(width: MessagesWorkspace.listWidth, child: list),
          const VerticalDivider(width: 1),
          Expanded(
            child: open == null
                ? Center(
                    child: AdminStateLine(
                        key: const Key('chat-empty'),
                        message: OpsStrings(widget.isEs).messages))
                : _thread(open, back: false),
          ),
        ]);
      }),
    );
  }

  Widget _thread(ConversationRow row, {required bool back}) => ChatThread(
        key: ValueKey('thread-${row.stayId}'),
        row: row,
        repository: widget.repository,
        resortTime: widget.resortTime,
        isEs: widget.isEs,
        onChanged: _changed,
        onBack: back ? () => setState(() => _open = null) : null,
        onOpenStay: widget.onOpenStay,
      );
}
