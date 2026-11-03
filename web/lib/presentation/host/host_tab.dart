import 'package:flutter/material.dart';

import '../../application/portal_controller.dart';
import '../../core/i18n/l10n.dart';
import '../../core/platform/photo_picker.dart';
import '../../core/theme/kachava_colors.dart';
import '../../data/guest_api.dart';
import '../../domain/stay.dart';
import '../common/widgets.dart';

/// Resort Host: chat plus a real photo attachment (signed upload).
class HostTab extends StatefulWidget {
  const HostTab({
    super.key,
    required this.controller,
    required this.photoPicker,
    this.prefill,
  });

  final PortalController controller;
  final PhotoPicker photoPicker;

  /// Text placed in the composer by "Ask Host".
  final String? prefill;

  @override
  State<HostTab> createState() => _HostTabState();
}

class _HostTabState extends State<HostTab> {
  final TextEditingController _text = TextEditingController();
  PickedPhoto? _photo;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.prefill != null) _text.text = widget.prefill!;
  }

  @override
  void didUpdateWidget(covariant HostTab old) {
    super.didUpdateWidget(old);
    if (widget.prefill != null && widget.prefill != old.prefill) {
      _text.text = widget.prefill!;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final photo = await widget.photoPicker.pick();
    if (!mounted || photo == null) return;
    setState(() => _photo = photo);
  }

  Future<void> _send() async {
    final l10n = widget.controller.l10n;
    if (_text.text.trim().isEmpty && _photo == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result =
        await widget.controller.sendToHost(_text.text, photo: _photo);
    if (!mounted) return;
    switch (result) {
      case ApiOk():
        setState(() {
          _busy = false;
          _photo = null;
          _text.clear();
        });
        showPortalToast(context, l10n.messageSent);
      case ApiFailed():
        setState(() {
          _busy = false;
          _error = failureMessage(l10n, result);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final l10n = c.l10n;
    final messages = c.chatMessages;
    final hostName = c.stay?.hostName ?? '';
    return Column(
      key: const Key('screen-host'),
      children: [
        Expanded(
          child: PageWidth(
            maxWidth: 720,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              children: [
                Text(l10n.resortHost,
                    style: Theme.of(context).textTheme.titleLarge),
                if (hostName.isNotEmpty)
                  Text(hostName,
                      style: const TextStyle(
                          fontSize: 15, color: KachavaColors.onSurfaceVariant)),
                const SizedBox(height: 12),
                if (messages.isEmpty)
                  OneLineState(
                      key: const Key('host-empty'), message: l10n.noMessages)
                else
                  for (final m in messages) _bubble(l10n, m),
              ],
            ),
          ),
        ),
        _composer(l10n),
      ],
    );
  }

  Widget _bubble(L10n l10n, ChatMessage m) {
    final mine = m.sender == MessageSender.guest;
    final time = m.sentAt == null
        ? ''
        : l10n.clock(m.sentAt!.toUtc().add(const Duration(hours: -5)));
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: mine
                ? KachavaColors.surfaceContainerHigh
                : KachavaColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: KachavaColors.surfaceContainerHighest),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (m.hasPhoto)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.photo_outlined,
                      size: 18, color: KachavaColors.primary),
                  const SizedBox(width: 4),
                  Text(l10n.photo,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ]),
              Text(m.text,
                  style: const TextStyle(
                      fontSize: 16, color: KachavaColors.onSurface)),
              Text(
                [
                  mine
                      ? l10n.you
                      : (m.senderName.isEmpty ? l10n.resortHost : m.senderName),
                  time
                ].where((s) => s.isNotEmpty).join(' · '),
                style: const TextStyle(
                    fontSize: 14, color: KachavaColors.tertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _composer(L10n l10n) {
    return StickyAction(
      top: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null)
            InlineError(
                message: _error!, onRetry: _send, retryLabel: l10n.retry),
          if (_photo != null)
            Align(
              alignment: Alignment.centerLeft,
              child: InputChip(
                key: const Key('host-photo-chip'),
                avatar: const Icon(Icons.photo_outlined, size: 18),
                label: Text(_photo!.fileName,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                deleteButtonTooltipMessage: l10n.removePhoto,
                onDeleted: _busy ? null : () => setState(() => _photo = null),
              ),
            ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            key: const Key('host-attach'),
            tooltip: l10n.attachPhoto,
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.add_a_photo_outlined),
          ),
          Expanded(
            child: TextField(
              key: const Key('host-input'),
              controller: _text,
              enabled: !_busy,
              minLines: 1,
              maxLines: 4,
              maxLength: 2000,
              decoration: InputDecoration(
                hintText: l10n.message,
                labelText: l10n.message,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                counterText: '',
              ),
            ),
          ),
          IconButton(
            key: const Key('host-send'),
            tooltip: _busy ? l10n.sending : l10n.send,
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            onPressed: _busy ? null : _send,
            icon: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send, color: KachavaColors.primary),
          ),
        ],
      ),
    );
  }
}
