import 'package:flutter/foundation.dart';

import '../domain/conversation.dart';
import '../domain/inbox_item.dart';
import '../domain/list_query.dart';
import 'request_inbox_source.dart';

/// Something a guest just did: the one-line toast and the chime.
sealed class GuestArrival {
  const GuestArrival();
}

final class RequestArrival extends GuestArrival {
  const RequestArrival(this.item);
  final InboxItem item;
}

final class MessageArrival extends GuestArrival {
  const MessageArrival(this.conversation);
  final ConversationRow conversation;
}

/// Detects new guest activity on every sync tick (first load, real-time
/// signals, Refresh): a new guest request (received request or guest-made
/// trip whose id was never seen) or a new guest message (a conversation
/// whose last guest message is newer than the one seen).
///
/// The first successful check is a silent baseline, so page loads and
/// refreshes of already-seen items never chime; staff actions never create
/// new guest items. Each arrival calls [onArrival] (the chime) and becomes
/// [arrival] (the toast). Also holds the menu badges and which new requests
/// staff opened in this session (unread rows). A failed check keeps the
/// last state and never throws.
class GuestActivityWatcher extends ChangeNotifier {
  GuestActivityWatcher({this.inbox, this.conversations, this.onArrival});

  final RequestInboxSource? inbox;
  final ConversationRepository? conversations;
  final VoidCallback? onArrival;

  final Set<String> _seenRequests = {};
  final Map<String, DateTime> _seenMessages = {};
  final Set<String> _opened = {};
  final Map<String, InboxItem> _fresh = {};
  bool _requestsBaseline = false;
  bool _messagesBaseline = false;
  bool _disposed = false;
  int _requestCount = 0;
  int _messageCount = 0;
  GuestArrival? _arrival;

  /// New guest requests (badge of Requests).
  int get requestCount => _requestCount;

  /// Conversations awaiting a reply (badge of Messages).
  int get messageCount => _messageCount;

  /// The latest arrival not dismissed yet.
  GuestArrival? get arrival => _arrival;

  /// A new request staff has not opened in this session.
  bool isUnread(InboxItem item) =>
      item.stage == InboxStage.fresh && !_opened.contains(item.rowId);

  /// The new request [rowId] as last read (toast "Open").
  InboxItem? itemFor(String rowId) => _fresh[rowId];

  void markOpened(String rowId) {
    if (_opened.add(rowId)) _notify();
  }

  void dismiss() {
    if (_arrival == null) return;
    _arrival = null;
    _notify();
  }

  /// One check of requests and messages; never throws.
  Future<void> check() async {
    final arrivals = <GuestArrival>[
      ...await _checkRequests(),
      ...await _checkMessages(),
    ];
    if (_disposed) return;
    if (arrivals.isNotEmpty) {
      _arrival = arrivals.first;
      onArrival?.call();
    }
    _notify();
  }

  Future<List<GuestArrival>> _checkRequests() async {
    final source = inbox;
    if (source == null) return const [];
    try {
      final fresh = await source.fresh();
      final newOnes = [
        for (final item in fresh.items)
          if (_requestsBaseline &&
              !_seenRequests.contains(item.rowId) &&
              (item is! TripInboxItem || item.guestAsked))
            RequestArrival(item),
      ];
      _requestCount = fresh.count;
      _fresh
        ..clear()
        ..addEntries(fresh.items.map((i) => MapEntry(i.rowId, i)));
      _seenRequests.addAll(_fresh.keys);
      _requestsBaseline = true;
      return newOnes;
    } catch (error) {
      debugPrint('New requests check failed: $error');
      return const [];
    }
  }

  Future<List<GuestArrival>> _checkMessages() async {
    final repo = conversations;
    if (repo == null) return const [];
    try {
      final page = await repo.list(
          const ListQuery(filters: {'awaitingReply': 'true'}, pageSize: 50));
      final newOnes = <GuestArrival>[];
      for (final row in page.items) {
        final at = row.lastAt;
        if (!row.lastFromGuest || at == null) continue;
        final seen = _seenMessages[row.stayId];
        if (_messagesBaseline && (seen == null || at.isAfter(seen))) {
          newOnes.add(MessageArrival(row));
        }
        if (seen == null || at.isAfter(seen)) _seenMessages[row.stayId] = at;
      }
      _messageCount = page.total;
      _messagesBaseline = true;
      return newOnes;
    } catch (error) {
      debugPrint('New messages check failed: $error');
      return const [];
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
