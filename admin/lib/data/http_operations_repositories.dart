import '../domain/admin_notification.dart';
import '../domain/admin_task.dart';
import '../domain/conversation.dart';
import '../domain/list_query.dart';
import '../domain/paged_result.dart';
import 'admin_api_client.dart';
import 'admin_http_resource.dart';

String _id(String id) => Uri.encodeComponent(id);

/// `/admin/tasks` (ADR-011 §5).
class HttpTaskRepository implements TaskRepository {
  HttpTaskRepository(this._client)
      : _tasks = AdminHttpResource(_client, _path, AdminTask.fromJson);

  static const String _path = '/tasks';

  final AdminApiClient _client;
  final AdminHttpResource<AdminTask> _tasks;

  @override
  Future<PagedResult<AdminTask>> list(ListQuery query) => _tasks.list(query);

  @override
  Future<AdminTask> get(String id) => _tasks.get(id);

  @override
  Future<AdminTask> create(NewTask task) => _tasks.create(task.toJson());

  @override
  Future<AdminTask> transition(String id, TaskTransition move) async =>
      AdminTask.fromJson(unwrapRecord(await _client.postJson(
          '$_path/${_id(id)}/transition', move.toJson())));
}

/// `/admin/notifications` (ADR-011 §6).
class HttpNotificationRepository implements NotificationRepository {
  HttpNotificationRepository(this._client)
      : _items = AdminHttpResource(_client, _path, AdminNotification.fromJson);

  static const String _path = '/notifications';

  final AdminApiClient _client;
  final AdminHttpResource<AdminNotification> _items;

  @override
  Future<PagedResult<AdminNotification>> list(ListQuery query) =>
      _items.list(query);

  @override
  Future<AdminNotification> markRead(String id) async =>
      AdminNotification.fromJson(unwrapRecord(
          await _client.postJson('$_path/${_id(id)}/read', const {})));

  @override
  Future<int> markAllRead() async {
    final record =
        unwrapRecord(await _client.postJson('$_path/read-all', const {}));
    final marked = record['marked'];
    return marked is num ? marked.toInt() : 0;
  }

  @override
  Future<UnreadCounts> unreadCounts() async => UnreadCounts.fromJson(
      unwrapRecord(await _client.getJson('$_path/unread-count')));
}

/// `/admin/conversations`: the Guests › Messages inbox (ADR-011 §7).
class HttpConversationRepository implements ConversationRepository {
  HttpConversationRepository(this._client)
      : _rows = AdminHttpResource(_client, _path, ConversationRow.fromJson);

  static const String _path = '/conversations';

  final AdminApiClient _client;
  final AdminHttpResource<ConversationRow> _rows;

  @override
  Future<PagedResult<ConversationRow>> list(ListQuery query) =>
      _rows.list(query);

  @override
  Future<PagedResult<ConversationMessage>> messages(
      String stayId, ListQuery query) async {
    final qs = query.toQueryString();
    return PagedResult.fromEnvelope(
        await _client.getJson('$_path/${_id(stayId)}/messages?$qs'),
        ConversationMessage.fromJson);
  }

  @override
  Future<ConversationMessage> reply(String stayId, String text) async =>
      ConversationMessage.fromJson(unwrapRecord(await _client
          .postJson('$_path/${_id(stayId)}/messages', {'text': text.trim()})));

  @override
  Future<void> markRead(String stayId) =>
      _client.postJson('$_path/${_id(stayId)}/read', const {});
}
