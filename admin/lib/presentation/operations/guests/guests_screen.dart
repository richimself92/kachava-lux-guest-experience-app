import 'package:flutter/material.dart';

import '../../../application/list_query_store.dart';
import '../../../core/stay_strings.dart';
import '../../../core/resort_time.dart';
import '../../../core/theme/kachava_tokens.dart';
import '../../../domain/conversation.dart';
import '../../../domain/guest_profile.dart';
import 'guest_list_tab.dart';
import 'messages_tab.dart';

/// GUEST OPERATIONS › Guests: tabs Guests (profiles per stay) and Messages
/// (the inbox). [section] `messages` opens the inbox, [openId] a stay.
class GuestsScreen extends StatefulWidget {
  const GuestsScreen({
    super.key,
    required this.guests,
    required this.conversations,
    required this.queries,
    required this.resortTime,
    required this.isEs,
    this.section,
    this.openId,
    this.onMessagesRead,
  });

  static const String messagesSection = 'messages';

  final GuestRepository guests;
  final ConversationRepository conversations;
  final ListQueryStore queries;
  final ResortTime resortTime;
  final bool isEs;
  final String? section;
  final String? openId;

  /// A conversation was read or answered (refresh the bell).
  final VoidCallback? onMessagesRead;

  @override
  State<GuestsScreen> createState() => _GuestsScreenState();
}

class _GuestsScreenState extends State<GuestsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.section == GuestsScreen.messagesSection ? 1 : 0)
    ..addListener(_onTab);

  /// The stay whose profile / conversation opens first.
  late final String? _openId = widget.openId;
  late String? _openChatId =
      widget.section == GuestsScreen.messagesSection ? widget.openId : null;

  StayStrings get _s => StayStrings(widget.isEs);

  void _onTab() {
    if (!_tabs.indexIsChanging) setState(() {});
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _openChat(String stayId) => setState(() {
        _openChatId = stayId;
        _tabs.index = 1;
      });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('workspace-admin-guests'),
      color: KachavaTokens.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: KachavaTokens.text,
            unselectedLabelColor: KachavaTokens.textSecondary,
            indicatorColor: KachavaTokens.primary,
            dividerColor: KachavaTokens.border,
            tabs: [
              Tab(key: const Key('guests-tab-guests'), text: _s.guestsTitle),
              Tab(key: const Key('guests-tab-messages'), text: _s.messages),
            ],
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_tabs.index == 1) {
      final open = _openChatId;
      return MessagesTab(
        key: ValueKey('messages-$open'),
        repository: widget.conversations,
        queries: widget.queries,
        resortTime: widget.resortTime,
        isEs: widget.isEs,
        openStayId: open,
        onRead: widget.onMessagesRead,
      );
    }
    final open = widget.section == null ? _openId : null;
    return GuestListTab(
      repository: widget.guests,
      queries: widget.queries,
      isEs: widget.isEs,
      openId: open,
      onOpenChat: _openChat,
    );
  }
}
