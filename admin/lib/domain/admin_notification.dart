import 'json_read.dart';
import 'list_query.dart';
import 'paged_result.dart';

/// Notification levels (ADR-011 §6); only URGENT plays a sound.
abstract final class NotificationValues {
  static const String info = 'INFO';
  static const String action = 'ACTION';
  static const String urgent = 'URGENT';
  static const List<String> levels = [info, action, urgent];
  static const List<String> categories = [
    'RESERVATION',
    'ARRIVAL',
    'CONCIERGE',
    'BOOKING',
    'LARDER',
    'TRANSFER',
    'TASK',
    'MIDSTAY',
    'CHECKOUT',
    'DIETARY',
  ];
}

/// The record a notification opens.
class NotificationTarget {
  const NotificationTarget({required this.type, required this.id, this.stayId});

  factory NotificationTarget.fromJson(Map<String, dynamic> json) =>
      NotificationTarget(
        type: JsonRead.text(json, 'type'),
        id: JsonRead.text(json, 'id'),
        stayId: JsonRead.textOrNull(json, 'stayId'),
      );

  /// `TRIP`, `CONVERSATION`, `STAY`, `TASK`, `REQUEST`, `BOOKING`, ...
  final String type;
  final String id;
  final String? stayId;
}

/// One notification (`GET /admin/notifications`).
class AdminNotification {
  const AdminNotification({
    required this.id,
    required this.level,
    required this.category,
    required this.title,
    required this.summary,
    required this.createdAt,
    required this.read,
    required this.playSound,
    required this.target,
    this.villaName,
    this.guestName,
  });

  factory AdminNotification.fromJson(Map<String, dynamic> json) =>
      AdminNotification(
        id: JsonRead.requireId(json),
        level: JsonRead.text(json, 'level'),
        category: JsonRead.text(json, 'category'),
        title: JsonRead.text(json, 'title'),
        summary: JsonRead.text(json, 'summary'),
        createdAt: DateTime.tryParse(JsonRead.text(json, 'createdAt'))?.toUtc(),
        read: JsonRead.flag(json, 'read'),
        playSound: JsonRead.flag(json, 'playSound'),
        target: NotificationTarget.fromJson(JsonRead.object(json, 'targetRef')),
        villaName: JsonRead.textOrNull(json, 'villaName'),
        guestName: JsonRead.textOrNull(json, 'guestName'),
      );

  final String id;
  final String level;
  final String category;
  final String title;
  final String summary;
  final DateTime? createdAt;
  final bool read;
  final bool playSound;
  final NotificationTarget target;
  final String? villaName;
  final String? guestName;

  AdminNotification asRead() => AdminNotification(
        id: id,
        level: level,
        category: category,
        title: title,
        summary: summary,
        createdAt: createdAt,
        read: true,
        playSound: playSound,
        target: target,
        villaName: villaName,
        guestName: guestName,
      );
}

/// Bell counters (`GET /admin/notifications/unread-count`).
class UnreadCounts {
  const UnreadCounts({required this.unread, required this.urgentUnread});

  factory UnreadCounts.fromJson(Map<String, dynamic> json) => UnreadCounts(
        unread: JsonRead.intOrNull(json, 'unreadCount') ??
            (throw const FormatException('unreadCount is missing.')),
        urgentUnread: JsonRead.intOrNull(json, 'urgentUnreadCount') ?? 0,
      );

  static const UnreadCounts none = UnreadCounts(unread: 0, urgentUnread: 0);

  final int unread;
  final int urgentUnread;
}

/// Notifications (`/admin/notifications`). Filters `level`, `read`,
/// `category`, `from`/`to`; `q` searches.
abstract interface class NotificationRepository {
  Future<PagedResult<AdminNotification>> list(ListQuery query);
  Future<AdminNotification> markRead(String id);

  /// Returns how many were marked.
  Future<int> markAllRead();
  Future<UnreadCounts> unreadCounts();
}
