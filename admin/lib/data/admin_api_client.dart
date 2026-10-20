import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';

/// REST API client for `/api/v1/admin/*` protected by `AdminAuthGuard`.
class AdminApiClient {
  AdminApiClient({
    this.baseUrl = AdminAppConfig.apiBaseUrl,
    this.staffJwt = 'eyJhbGciOiJSUzI1NiIsImtpZCI6ImthY2hhdmEtbHV4LXN0YWZmIn0',
    this.staffEmail = 'eduardo.rivera@kachavalux.com',
    Duration? timeout,
    bool? autoAuthenticate,
    http.Client? httpClient,
  })  : timeout = timeout ??
            (httpClient == null
                ? const Duration(seconds: 8)
                : const Duration(milliseconds: 900)),
        _ownsClient = httpClient == null,
        _autoAuthenticate = autoAuthenticate ?? (httpClient == null),
        _client = httpClient ?? http.Client();

  final String baseUrl;
  final String staffJwt;
  final String staffEmail;
  final Duration timeout;
  final bool _ownsClient;
  final bool _autoAuthenticate;
  final http.Client _client;
  String? _sessionToken;
  Future<void>? _loginFuture;

  String get _adminBaseUrl {
    var trimmed = baseUrl.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed.endsWith('/admin') ? trimmed : '$trimmed/admin';
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${_sessionToken ?? staffJwt}',
      };

  Uri _resolveUri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_adminBaseUrl$normalizedPath');
  }

  Future<void> _ensureAuthenticated(String path) async {
    if (!_autoAuthenticate || _sessionToken != null || path == '/auth/login') {
      return;
    }
    _loginFuture ??= _performLogin();
    await _loginFuture;
  }

  Future<void> _performLogin() async {
    try {
      final response = await _client
          .post(
            _resolveUri('/auth/login'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': staffEmail}),
          )
          .timeout(timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = _decodeResponse(response);
        final token = decoded['token'] as String?;
        if (token != null && token.isNotEmpty) {
          _sessionToken = token;
        }
      }
    } catch (_) {
      // Offline or test environment: allow subsequent request to trigger fallback.
    } finally {
      _loginFuture = null;
    }
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    await _ensureAuthenticated(path);
    final response = await _client
        .get(_resolveUri(path), headers: _headers)
        .timeout(timeout);
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    await _ensureAuthenticated(path);
    final response = await _client
        .post(_resolveUri(path), headers: _headers, body: jsonEncode(body))
        .timeout(timeout);
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    await _ensureAuthenticated(path);
    final response = await _client
        .patch(_resolveUri(path), headers: _headers, body: jsonEncode(body))
        .timeout(timeout);
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> deleteJson(String path) async {
    await _ensureAuthenticated(path);
    final response = await _client
        .delete(_resolveUri(path), headers: _headers)
        .timeout(timeout);
    return _decodeResponse(response);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
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
