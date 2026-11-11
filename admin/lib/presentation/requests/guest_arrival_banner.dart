import 'package:flutter/material.dart';

import '../../application/admin_shell_controller.dart';
import '../../application/guest_activity_watcher.dart';
import '../../application/notification_bell_controller.dart';
import '../../core/inbox_strings.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../domain/admin_enums.dart';
import 'inbox_parts.dart';
import 'request_inbox_scope.dart';

/// One line for the latest guest arrival: "New request · Villa Coral ·
/// Villa stocking" or "New message · Villa Coral · Valeria: ..." with
/// "Open" (that request / conversation) and a close button (stops the
/// chime).
class GuestArrivalBanner extends StatelessWidget {
  const GuestArrivalBanner(
      {super.key, required this.controller, required this.bell});

  final AdminShellController controller;
  final NotificationBellController bell;

  @override
  Widget build(BuildContext context) {
    final watcher = RequestInboxScope.maybeOf(context)?.watcher;
    if (watcher == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: watcher,
      builder: (context, _) {
        final arrival = watcher.arrival;
        if (arrival == null) return const SizedBox.shrink();
        return _line(context, watcher, arrival);
      },
    );
  }

  String _text(GuestArrival arrival, InboxStrings s) => switch (arrival) {
        RequestArrival(:final item) =>
          s.newRequest(item.villaName, inboxTitle(item, s.isEs)),
        MessageArrival(:final conversation) => s.newMessage(
            conversation.villaName,
            conversation.guestName,
            conversation.lastText),
      };

  void _open(GuestActivityWatcher watcher, GuestArrival arrival) {
    bell.silence();
    watcher.dismiss();
    switch (arrival) {
      case RequestArrival(:final item):
        controller.openRecord(AdminWorkspaceTab.adminRequests, item.rowId);
      case MessageArrival(:final conversation):
        controller.openRecord(
            AdminWorkspaceTab.adminMessages, conversation.stayId);
    }
  }

  Widget _line(
      BuildContext context, GuestActivityWatcher watcher, GuestArrival a) {
    final s = InboxStrings(controller.isEs);
    const onDark = TextStyle(
        fontSize: 14, height: 20 / 14, color: KachavaTokens.onPrimary);
    final button =
        TextButton.styleFrom(foregroundColor: KachavaTokens.onPrimary);
    return Container(
      key: const Key('guest-arrival-toast'),
      width: double.infinity,
      color: KachavaTokens.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        Icon(
            a is MessageArrival
                ? Icons.chat_bubble_outline
                : Icons.inbox_outlined,
            size: 18,
            color: KachavaTokens.onPrimary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(_text(a, s),
              maxLines: 1, overflow: TextOverflow.ellipsis, style: onDark),
        ),
        TextButton(
          key: const Key('guest-arrival-open'),
          style: button,
          onPressed: () => _open(watcher, a),
          child: Text(s.openAction),
        ),
        IconButton(
          key: const Key('guest-arrival-dismiss'),
          tooltip: s.dismiss,
          color: KachavaTokens.onPrimary,
          onPressed: () {
            bell.silence();
            watcher.dismiss();
          },
          icon: const Icon(Icons.close, size: 18),
        ),
      ]),
    );
  }
}
