import 'json_read.dart';
import 'list_query.dart';
import 'paged_result.dart';

/// One inbox row: a stay's conversation with the Resort Host.
class ConversationRow {
  const ConversationRow({
    required this.stayId,
    required this.guestName,
    required this.villaName,
    required this.lastText,
    required this.lastAt,
    required this.lastFromGuest,
    required this.lastHasPhoto,
    required this.unreadCount,
    required this.awaitingReply,
  });

  factory ConversationRow.fromJson(Map<String, dynamic> json) {
    final last = JsonRead.object(json, 'lastMessage');
    return ConversationRow(
      stayId: JsonRead.requireId(json, 'stayId'),
      guestName: JsonRead.text(json, 'guestName'),
      villaName: JsonRead.text(json, 'villaName'),
      lastText: JsonRead.text(last, 'text'),
      lastAt: DateTime.tryParse(JsonRead.text(last, 'at'))?.toUtc(),
      lastFromGuest: JsonRead.text(last, 'from') == 'GUEST',
      lastHasPhoto: JsonRead.flag(last, 'hasPhoto'),
      unreadCount: JsonRead.intOrNull(json, 'unreadCount') ?? 0,
      awaitingReply: JsonRead.flag(json, 'awaitingReply'),
    );
  }

  final String stayId;
  final String guestName;
  final String villaName;
  final String lastText;
  final DateTime? lastAt;
  final bool lastFromGuest;
  final bool lastHasPhoto;
  final int unreadCount;
  final bool awaitingReply;

  bool get hasUnread => unreadCount > 0;

  /// The same row once staff opened it (no unread messages).
  ConversationRow asRead() => ConversationRow(
        stayId: stayId,
        guestName: guestName,
        villaName: villaName,
        lastText: lastText,
        lastAt: lastAt,
        lastFromGuest: lastFromGuest,
        lastHasPhoto: lastHasPhoto,
        unreadCount: 0,
        awaitingReply: awaitingReply,
      );

  /// Unread conversations first; otherwise the server order is kept.
  static List<ConversationRow> unreadFirst(List<ConversationRow> rows) => [
        ...rows.where((r) => r.hasUnread),
        ...rows.where((r) => !r.hasUnread),
      ];
}

/// One message of a conversation; [photoUrl] is a signed URL.
class ConversationMessage {
  const ConversationMessage({
    required this.id,
    required this.fromGuest,
    required this.senderName,
    required this.text,
    required this.at,
    this.photoUrl,
  });

  factory ConversationMessage.fromJson(Map<String, dynamic> json) =>
      ConversationMessage(
        id: JsonRead.requireId(json),
        fromGuest: JsonRead.text(json, 'from') == 'GUEST',
        senderName: JsonRead.text(json, 'senderName'),
        text: JsonRead.text(json, 'text'),
        at: DateTime.tryParse(JsonRead.text(json, 'at'))?.toUtc(),
        photoUrl: JsonRead.textOrNull(json, 'photoUrl'),
      );

  final String id;
  final bool fromGuest;
  final String senderName;
  final String text;
  final DateTime? at;
  final String? photoUrl;
}

/// Messages inbox (`/admin/conversations`). Filters `unread=true`,
/// `awaitingReply=true`; `q` searches the guest name.
abstract interface class ConversationRepository {
  Future<PagedResult<ConversationRow>> list(ListQuery query);

  /// Page 1 holds the newest messages, oldest → newest inside the page.
  Future<PagedResult<ConversationMessage>> messages(
      String stayId, ListQuery query);
  Future<ConversationMessage> reply(String stayId, String text);
  Future<void> markRead(String stayId);
}
