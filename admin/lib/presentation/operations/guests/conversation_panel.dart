import 'package:flutter/material.dart';

import '../../../core/ops_strings.dart';
import '../../../core/resort_time.dart';
import '../../../core/stay_strings.dart';
import '../../../core/theme/kachava_tokens.dart';
import '../../../domain/conversation.dart';
import '../../../domain/list_query.dart';
import '../../components/components.dart';

/// One conversation: the newest messages (guest left, staff right, photos
/// inline) and a reply box. Opening it marks the conversation read.
class ConversationPanel extends StatefulWidget {
  const ConversationPanel({
    super.key,
    required this.stayId,
    required this.title,
    required this.repository,
    required this.resortTime,
    required this.onClose,
    required this.onChanged,
    required this.isEs,
  });

  /// Messages shown at once (the newest page).
  static const ListQuery messagesQuery = ListQuery(pageSize: 50);

  final String stayId;

  /// Guest name; empty for a deep link (the messages name the guest).
  final String title;
  final ConversationRepository repository;
  final ResortTime resortTime;
  final VoidCallback onClose;

  /// Read or answered (reload the inbox and the bell).
  final VoidCallback onChanged;
  final bool isEs;

  @override
  State<ConversationPanel> createState() => _ConversationPanelState();
}

class _ConversationPanelState extends State<ConversationPanel> {
  final TextEditingController _reply = TextEditingController();
  List<ConversationMessage>? _messages;
  Object? _error;
  bool _sending = false;

  OpsStrings get _s => OpsStrings(widget.isEs);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final page = await widget.repository
          .messages(widget.stayId, ConversationPanel.messagesQuery);
      if (!mounted) return;
      setState(() => _messages = page.items);
      await widget.repository.markRead(widget.stayId);
      widget.onChanged();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _send() async {
    final text = _reply.text.trim();
    if (text.isEmpty || _sending) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _sending = true);
    try {
      final sent = await widget.repository.reply(widget.stayId, text);
      if (!mounted) return;
      setState(() => _messages = [...?_messages, sent]);
      _reply.clear();
      widget.onChanged();
    } catch (_) {
      showAdminToastOn(messenger, _s.sendFailed,
          isError: true, isEs: widget.isEs);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String get _title {
    if (widget.title.isNotEmpty) return widget.title;
    final guest = _messages?.where((m) => m.fromGuest).firstOrNull;
    return guest?.senderName ?? _s.messages;
  }

  @override
  Widget build(BuildContext context) => AdminDetailPanel(
        key: const Key('conversation-panel'),
        title: _title,
        onClose: widget.onClose,
        isEs: widget.isEs,
        body: _body(),
        footer: _composer(),
      );

  Widget _body() {
    if (_error != null) {
      final s = StayStrings(widget.isEs);
      return Align(
        alignment: Alignment.topLeft,
        child: AdminStateLine(
            message: s.loadFailed,
            actionLabel: s.retry,
            onAction: _load,
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
    return ListView(
      key: const Key('conversation-messages'),
      reverse: true,
      padding: const EdgeInsets.all(KachavaTokens.space4),
      children: [
        for (final m in messages.reversed)
          MessageBubble(
              message: m, resortTime: widget.resortTime, isEs: widget.isEs),
      ],
    );
  }

  Widget _composer() => Row(children: [
        Expanded(
          child: TextField(
            key: const Key('conversation-reply'),
            controller: _reply,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(isDense: true, hintText: _s.reply),
          ),
        ),
        const SizedBox(width: KachavaTokens.space2),
        IconButton.filled(
          key: const Key('conversation-send'),
          tooltip: _s.send,
          onPressed: _sending ? null : _send,
          icon: const Icon(Icons.send, size: 20),
        ),
      ]);
}

/// One message: guest on the left (surface), staff on the right (brown
/// tint); the sender and time on a small line.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
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
    return Align(
      alignment: m.fromGuest ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        key: Key('message-${m.id}'),
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.only(bottom: KachavaTokens.space2),
        padding: const EdgeInsets.all(KachavaTokens.space3),
        decoration: BoxDecoration(
          color: m.fromGuest
              ? KachavaTokens.surface
              : KachavaTokens.primarySelected,
          borderRadius: BorderRadius.circular(KachavaTokens.radiusMd),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${m.senderName} · ${resortTime.label(m.at, isEs: isEs)}',
              style: theme.labelSmall
                  ?.copyWith(color: KachavaTokens.textSecondary)),
          if (m.photoUrl case final url?) ...[
            const SizedBox(height: KachavaTokens.space1),
            ClipRRect(
              borderRadius: BorderRadius.circular(KachavaTokens.radiusSm),
              child: Image.network(url,
                  key: Key('message-photo-${m.id}'),
                  height: 160,
                  cacheHeight: 320,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, __) =>
                      Text(OpsStrings(isEs).photoUnavailable)),
            ),
          ],
          if (m.text.isNotEmpty) ...[
            const SizedBox(height: KachavaTokens.space1),
            Text(m.text, style: theme.bodyMedium),
          ],
        ]),
      ),
    );
  }
}
