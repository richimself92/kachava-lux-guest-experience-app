import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';
import '../domain/admin_access_denied.dart';
import 'admin_session.dart';
import 'admin_staff_mapper.dart';

/// REST API client for `/api/v1/admin/*` protected by `AdminAuthGuard`.
///
/// Every call carries `Authorization: Bearer <token>` from [session]; without a
/// session no request is sent. A 401 expires the session so the app can return
/// to the sign-in screen.
class AdminApiClient {
  AdminApiClient({
    this.baseUrl = AdminAppConfig.apiBaseUrl,
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
  final AdminSession session;
  final Duration timeout;
  final bool _ownsClient;
  final http.Client _client;

  String get _adminBaseUrl {
    var trimmed = baseUrl.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed.endsWith('/admin') ? trimmed : '$trimmed/admin';
  }

  Map<String, String> _authorizedHeaders() {
    final token = session.token;
    if (token == null) {
      throw const AdminUnauthorizedException(
          'No staff session: sign in first.');
    }
    return {..._jsonHeaders, 'Authorization': 'Bearer $token'};
  }

  Uri _resolveUri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_adminBaseUrl$normalizedPath');
  }

  /// Exchanges staff credentials for a session token (`POST /admin/auth/login`).
  Future<void> signIn(String email) async {
    final response = await _client
        .post(_resolveUri('/auth/login'),
            headers: _jsonHeaders, body: jsonEncode({'email': email.trim()}))
        .timeout(timeout);
    final body = _decodeResponse(response);
    final token = body['token'];
    if (token is! String || token.isEmpty) {
      throw AdminApiException(
          statusCode: response.statusCode,
          message: 'Admin API login response carried no token.');
    }
    session.open(token, staff: AdminStaffMapper.tryMap(body['staff']));
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final response = await _client
        .get(_resolveUri(path), headers: _authorizedHeaders())
        .timeout(timeout);
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client
        .post(_resolveUri(path),
            headers: _authorizedHeaders(), body: jsonEncode(body))
        .timeout(timeout);
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client
        .patch(_resolveUri(path),
            headers: _authorizedHeaders(), body: jsonEncode(body))
        .timeout(timeout);
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> deleteJson(String path) async {
    final response = await _client
        .delete(_resolveUri(path), headers: _authorizedHeaders())
        .timeout(timeout);
    return _decodeResponse(response);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.statusCode == 401) {
      session.expire();
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

/// The staff role is not allowed to use the resource (HTTP 403).
class AdminForbiddenException extends AdminApiException
    implements AdminAccessDenied {
  const AdminForbiddenException(String message)
      : super(statusCode: 403, message: message);
}
