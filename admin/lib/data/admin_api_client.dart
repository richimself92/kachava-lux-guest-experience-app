import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';
import '../domain/admin_access_denied.dart';
import 'admin_session.dart';
import 'admin_staff_mapper.dart';
import 'admin_write_gateway.dart';

/// REST API client for `/api/v1/admin/*` protected by `AdminAuthGuard`.
///
/// Authentication is silent: before the first call (and whenever [session]
/// holds no token) it logs in as [staffEmail] via `POST /admin/auth/login`,
/// then sends `Authorization: Bearer <token>`. Concurrent callers share one
/// in-flight login. A 401 expires the token, logs in again and retries the
/// call once; a second 401 surfaces as [AdminUnauthorizedException]. A
/// rejected login (401/403) is terminal and surfaces as [AdminAccessDenied].
class AdminApiClient implements AdminWriteGateway {
  AdminApiClient({
    this.baseUrl = AdminAppConfig.apiBaseUrl,
    this.staffEmail = AdminAppConfig.adminStaffEmail,
    AdminSession? session,
    Duration? timeout,
    http.Client? httpClient,
  })  : session = session ?? AdminSession(),
        timeout = timeout ??
            (httpClient == null
                ? const Duration(seconds: 8)
                : const Duration(milliseconds: 900)),
        _ownsClient = httpClient == null,
        _client = httpClient ?? http.Client();

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  final String baseUrl;
  final String staffEmail;
  final AdminSession session;
  final Duration timeout;
  final bool _ownsClient;
  final http.Client _client;
  Future<String>? _loginInFlight;

  /// `realtime.adminChannel` of the last login, and the session token when
  /// the channel was last handed to the listener.
  String? _realtimeChannel;
  String? _channelToken;

  String get _adminBaseUrl {
    var trimmed = baseUrl.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed.endsWith('/admin') ? trimmed : '$trimmed/admin';
  }

  Uri _resolveUri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_adminBaseUrl$normalizedPath');
  }

  /// The current token, logging in first when there is none. Every caller
  /// waiting on a login shares the same request.
  Future<String> _ensureToken() {
    final token = session.token;
    if (token != null) return Future.value(token);
    return _loginInFlight ??=
        _login().whenComplete(() => _loginInFlight = null);
  }

  Future<String> _login() async {
    final response = await _client
        .post(_resolveUri('/auth/login'),
            headers: _jsonHeaders, body: jsonEncode({'email': staffEmail}))
        .timeout(timeout);
    if (response.statusCode == 401) {
      // The configured staff identity itself is refused: retrying won't help.
      throw AdminLoginRejectedException(
          'Admin staff login rejected (HTTP 401): ${response.body}');
    }
    final body = _decodeResponse(response);
    final token = body['token'];
    if (token is! String || token.isEmpty) {
      throw AdminApiException(
          statusCode: response.statusCode,
          message: 'Admin API login response carried no token.');
    }
    _realtimeChannel = switch (body['realtime']) {
      {'adminChannel': final String channel} when channel.isNotEmpty => channel,
      _ => null,
    };
    session.open(token, staff: AdminStaffMapper.tryMap(body['staff']));
    return token;
  }

  /// Sends an authorized request; on a 401 re-authenticates and retries once.
  Future<Map<String, dynamic>> _send(
      Future<http.Response> Function(Map<String, String> headers)
          request) async {
    var token = await _ensureToken();
    var response = await request(_bearer(token)).timeout(timeout);
    if (response.statusCode == 401) {
      // Only drop the token this call used; a concurrent re-login may have
      // already replaced it.
      if (session.token == token) session.expire();
      token = await _ensureToken();
      response = await request(_bearer(token)).timeout(timeout);
      if (response.statusCode == 401 && session.token == token) {
        session.expire();
      }
    }
    return _decodeResponse(response);
  }

  /// The staff's real-time channel (ADR-012) from the silent login, or
  /// null when the backend sends none. [renew] logs in again when the
  /// session still holds the token the channel came with (the listener was
  /// refused); a session the API already renewed is reused.
  Future<String?> realtimeChannel({bool renew = false}) async {
    if (renew && session.token != null && session.token == _channelToken) {
      session.expire();
    }
    _channelToken = await _ensureToken();
    return _realtimeChannel;
  }

  Map<String, String> _bearer(String token) =>
      {..._jsonHeaders, 'Authorization': 'Bearer $token'};

  Future<Map<String, dynamic>> getJson(String path) =>
      _send((headers) => _client.get(_resolveUri(path), headers: headers));

  @override
  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) =>
      _send((headers) => _client.post(_resolveUri(path),
          headers: headers, body: jsonEncode(body)));

  @override
  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body,
  ) =>
      _send((headers) => _client.patch(_resolveUri(path),
          headers: headers, body: jsonEncode(body)));

  @override
  Future<Map<String, dynamic>> deleteJson(String path) =>
      _send((headers) => _client.delete(_resolveUri(path), headers: headers));

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.statusCode == 401) {
      throw AdminUnauthorizedException('Admin API HTTP 401: ${response.body}');
    }
    if (response.statusCode == 403) {
      throw AdminForbiddenException('Admin API HTTP 403: ${response.body}');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AdminApiException(
        statusCode: response.statusCode,
        message: 'Admin API HTTP ${response.statusCode}: ${response.body}',
      );
    }
    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final inner = decoded['data'];
      if (inner is Map<String, dynamic>) {
        return <String, dynamic>{
          ...inner,
          ...decoded,
        };
      }
      return decoded;
    }
    return <String, dynamic>{'data': decoded};
  }

  @override
  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}

/// Explicit exception raised on Admin API transport or status failures.
class AdminApiException implements Exception {
  const AdminApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => 'AdminApiException($statusCode): $message';
}

/// The staff session is missing, expired or rejected (HTTP 401).
class AdminUnauthorizedException extends AdminApiException {
  const AdminUnauthorizedException(String message)
      : super(statusCode: 401, message: message);
}

/// The silent staff login itself was refused (HTTP 401). Terminal: the live
/// sync shows "No access" and stops polling instead of reconnecting forever.
/// (A 403 login surfaces as [AdminForbiddenException], also terminal.)
class AdminLoginRejectedException extends AdminUnauthorizedException
    implements AdminAccessDenied {
  const AdminLoginRejectedException(super.message);
}

/// The staff role is not allowed to use the resource (HTTP 403).
class AdminForbiddenException extends AdminApiException
    implements AdminAccessDenied {
  const AdminForbiddenException(String message)
      : super(statusCode: 403, message: message);
}
