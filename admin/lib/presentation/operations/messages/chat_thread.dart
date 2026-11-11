import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/ops_strings.dart';
import '../../../core/resort_time.dart';
import '../../../core/stay_strings.dart';
import '../../../core/theme/kachava_tokens.dart';
import '../../../domain/conversation.dart';
import '../../../domain/realtime_change.dart';
import '../../components/components.dart';
import '../guests/conversation_panel.dart' show ConversationPanel;

/// Right pane of Messages: header (guest, villa, "Open stay"), bubbles with
/// day separators and the time under each, photos inline, newest at the
/// bottom, and the composer pinned below (Enter sends, Shift+Enter adds a
/// line). Real-time reloads replace only the messages: the draft is kept.
class ChatThread extends StatefulWidget {
  const ChatThread({
    super.key,
    required this.row,
    required this.repository,
    required this.resortTime,
    required this.isEs,
    required this.onChanged,
    this.onBack,
    this.onOpenStay,
  });

  final ConversationRow row;
  final ConversationRepository repository;
  final ResortTime resortTime;
  final bool isEs;

  /// Read or answered (reload the list, badges and bell).
  final VoidCallback onChanged;

  /// Narrow layout: back to the list.
  final VoidCallback? onBack;
  final ValueChanged<String>? onOpenStay;

  @override
  State<ChatThread> createState() => _ChatThreadState();
}

class _ChatThreadState extends State<ChatThread>
    with AdminRealtimeRefresh<ChatThread> {
  final TextEditingController _draft = TextEditingController();
  late final FocusNode _focus = FocusNode(onKeyEvent: _onKey);
  List<ConversationMessage>? _messages;
  Object? _error;
  bool _sending = false;

  OpsStrings get _s => OpsStrings(widget.isEs);
  String get _stayId => widget.row.stayId;

  @override
  void initState() {
    super.initState();
    _load(markRead: true);
  }

  @override
  void dispose() {
    _draft.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Enter sends; Shift+Enter falls through (new line).
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.enter ||
        HardwareKeyboard.instance.isShiftPressed) {
      return KeyEventResult.ignored;
    }
    _send();
    return KeyEventResult.handled;
  }

  @override
  void onRealtimeInvalidation(RealtimeInvalidation change) {
    if (change.touchesStay(_stayId, const {RealtimeTopic.messages})) {
      _load(markRead: false);
    }
  }

  /// Marks read on open, and later only when a new guest message arrived
  /// (marking read is itself a change: an unconditional mark would loop).
  Future<void> _load({required bool markRead}) async {
    try {
      final page = await widget.repository
          .messages(_stayId, ConversationPanel.messagesQuery);
      if (!mounted) return;
      final before = _messages?.lastOrNull?.id;
      setState(() {
        _messages = page.items;
        _error = null;
      });
      final newest = page.items.lastOrNull;
      final fresh = newest != null && newest.id != before && newest.fromGuest;
      if (markRead || fresh) {
        await widget.repository.markRead(_stayId);
        widget.onChanged();
      }
    } catch (error) {
      if (mounted && _messages == null) setState(() => _error = error);
    }
  }

  Future<void> _send() async {
    final text = _draft.text.trim();
    if (text.isEmpty || _sending) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _sending = true);
    try {
      final sent = await widget.repository.reply(_stayId, text);
      if (!mounted) return;
      setState(() => _messages = [...?_messages, sent]);
      _draft.clear();
      widget.onChanged();
    } catch (_) {
      showAdminToastOn(messenger, _s.sendFailed,
          isError: true, isEs: widget.isEs);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: Key('chat-thread-$_stayId'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(),
        const Divider(height: 1),
        Expanded(child: _body()),
        const Divider(height: 1),
        _composer(),
      ],
    );
  }

  Widget _header() {
    final text = Theme.of(context).textTheme;
    final open = widget.onOpenStay;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: KachavaTokens.space3, vertical: KachavaTokens.space2),
      child: Row(children: [
        if (widget.onBack case final back?)
          IconButton(
              key: const Key('chat-back'),
              tooltip: _s.messages,
              onPressed: back,
              icon: const Icon(Icons.arrow_back)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TruncatedText(widget.row.guestName, style: text.titleMedium),
              TruncatedText(widget.row.villaName,
                  style: text.bodySmall
                      ?.copyWith(color: KachavaTokens.textSecondary)),
            ],
          ),
        ),
        if (open != null)
          TextButton(
            key: const Key('chat-open-stay'),
            onPressed: () => open(_stayId),
            child: Text(_s.openStay),
          ),
      ]),
    );
  }

  Widget _body() {
    if (_error != null) {
      final s = StayStrings(widget.isEs);
      return Align(
        alignment: Alignment.topLeft,
        child: AdminStateLine(
            message: s.loadFailed,
            actionLabel: s.retry,
            onAction: () => _load(markRead: true),
            isError: true),
      );
    }
    final messages = _messages;
    if (messages == null) {
      return const Align(
          alignment: Alignment.topCenter, child: LinearProgressIndicator());
    }
    if (messages.isEmpty) {
      return Align(
          alignment: Alignment.topLeft,
          child: AdminStateLine(message: _s.noMessages));
    }
    final children = <Widget>[];
    String? day;
    for (final m in messages) {
      final d = m.at == null
          ? null
          : widget.resortTime.dayOf(m.at!) ?? ResortTime.isoDay(m.at!);
      if (d != null && d != day) {
        day = d;
        children.add(
            _DaySeparator(label: ResortTime.dayLabel(d, isEs: widget.isEs)));
      }
      children.add(ChatBubble(
          message: m, resortTime: widget.resortTime, isEs: widget.isEs));
    }
    // Reversed: the newest message sits at the bottom (auto-scroll).
    return ListView(
      key: const Key('conversation-messages'),
      reverse: true,
      padding: const EdgeInsets.all(KachavaTokens.space4),
      children: children.reversed.toList(),
    );
  }

  Widget _composer() => Padding(
        padding: const EdgeInsets.all(KachavaTokens.space3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Semantics(
              label: _s.reply,
              child: TextField(
                key: const Key('conversation-reply'),
                controller: _draft,
                focusNode: _focus,
                minLines: 1,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(isDense: true, hintText: _s.reply),
              ),
            ),
          ),
          const SizedBox(width: KachavaTokens.space2),
          IconButton.filled(
            key: const Key('conversation-send'),
            tooltip: _s.send,
            onPressed: _sending ? null : _send,
            icon: const Icon(Icons.send, size: 20),
          ),
        ]),
      );
}

class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: KachavaTokens.space2),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: KachavaTokens.space3, vertical: 2),
            decoration: BoxDecoration(
              color: KachavaTokens.neutralBackground,
              borderRadius: BorderRadius.circular(KachavaTokens.radiusPill),
            ),
            child: Text(label, style: Theme.of(context).textTheme.labelSmall),
          ),
        ),
      );
}

/// Guest bubbles on the left (surface), staff on the right (restrained
/// brown tint); the time sits under each bubble.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.resortTime,
    required this.isEs,
  });

  final ConversationMessage message;
  final ResortTime resortTime;
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    final m = message;
    final theme = Theme.of(context).textTheme;
    final at = m.at;
    final time = at == null ? '' : ResortTime.hhmm(resortTime.wall(at) ?? at);
    return Align(
      alignment: m.fromGuest ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          crossAxisAlignment:
              m.fromGuest ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Container(
              key: Key('message-${m.id}'),
              padding: const EdgeInsets.all(KachavaTokens.space3),
              decoration: BoxDecoration(
                color: m.fromGuest
                    ? KachavaTokens.surface
                    : KachavaTokens.primarySelected,
                borderRadius: BorderRadius.circular(KachavaTokens.radiusLg),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (m.photoUrl case final url?)
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(KachavaTokens.radiusSm),
                        child: Image.network(url,
                            key: Key('message-photo-${m.id}'),
                            height: 180,
                            cacheHeight: 360,
                            fit: BoxFit.cover,
                            errorBuilder: (context, _, __) =>
                                Text(OpsStrings(isEs).photoUnavailable)),
                      ),
                    if (m.text.isNotEmpty)
                      Text(m.text, style: theme.bodyMedium),
                  ]),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  top: 2, bottom: KachavaTokens.space2, left: 4, right: 4),
              child: Text(m.fromGuest ? time : '${m.senderName} · $time',
                  style: theme.labelSmall
                      ?.copyWith(color: KachavaTokens.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
