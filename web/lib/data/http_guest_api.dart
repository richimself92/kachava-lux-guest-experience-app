import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/platform/photo_picker.dart';
import '../domain/catalog.dart';
import '../domain/json_read.dart';
import '../domain/stay.dart';
import '../domain/trip.dart';
import 'guest_api.dart';

/// REST client for the guest routes. The guest link UUID is the bearer
/// credential (`Authorization: Bearer <guestUuid>`); responses arrive in the
/// `{success, data, meta}` envelope.
class HttpGuestApi implements GuestApi {
  HttpGuestApi({
    this.baseUrl = AppConfig.apiBaseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 12),
  })  : _ownsClient = client == null,
        _client = client ?? http.Client();

  final String baseUrl;
  final Duration timeout;
  final bool _ownsClient;
  final http.Client _client;

  static const int _catalogPageSize = 100;
  static const int _catalogMaxPages = 10;
  static const String chatCategory = HostThread.chatCategory;

  Map<String, String> _headers(String? guestUuid) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (guestUuid != null) 'Authorization': 'Bearer $guestUuid',
      };

  Future<ApiResult<Object?>> _send(
    String method,
    String path, {
    String? guestUuid,
    Object? body,
    bool rejectOn404 = false,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/$path');
      final request = http.Request(method, uri)
        ..headers.addAll(_headers(guestUuid));
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _client.send(request).timeout(timeout);
      final response =
          await http.Response.fromStream(streamed).timeout(timeout);
      final status = response.statusCode;
      final decoded = _decode(response);
      if (status >= 200 && status < 300) {
        return ApiOk(decoded is Map ? decoded['data'] : decoded);
      }
      if (status == 401 || status == 403 || (rejectOn404 && status == 404)) {
        return const ApiFailed(FailureKind.linkRejected);
      }
      if (status >= 400 && status < 500 && status != 408 && status != 429) {
        final error = asJson(asJson(decoded)['error']);
        final code = asString(error['code']).isNotEmpty
            ? asString(error['code'])
            : asString(asJson(decoded)['code']);
        final message = asString(error['message']).isNotEmpty
            ? asString(error['message'])
            : asString(asJson(decoded)['message']);
        return ApiFailed(
          code == 'SETTINGS_REQUIRED'
              ? FailureKind.notConfigured
              : FailureKind.invalid,
          message,
        );
      }
      return const ApiFailed(FailureKind.unreachable);
    } on TimeoutException {
      return const ApiFailed(FailureKind.unreachable);
    } on http.ClientException {
      return const ApiFailed(FailureKind.unreachable);
    } on FormatException {
      return const ApiFailed(FailureKind.unreachable);
    }
  }

  static Object? _decode(http.Response response) {
    final text = utf8.decode(response.bodyBytes, allowMalformed: true);
    if (text.trim().isEmpty) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }

  ApiResult<T> _map<T>(ApiResult<Object?> r, T Function(Object? data) parse) =>
      switch (r) {
        ApiOk(:final value) => ApiOk(parse(value)),
        ApiFailed(:final kind, :final message) => ApiFailed(kind, message),
      };

  @override
  Future<ApiResult<GuestStay>> fetchStay(String guestUuid) async {
    final r = await _send('GET', 'stays/$guestUuid',
        guestUuid: guestUuid, rejectOn404: true);
    if (r is ApiOk<Object?> && r.value is! Map) {
      return const ApiFailed(FailureKind.unreachable);
    }
    return _map(r, (data) => GuestStay.fromJson(guestUuid, asJson(data)));
  }

  @override
  Future<ApiResult<List<CatalogService>>> fetchCatalog() async {
    final all = <CatalogService>[];
    for (var page = 1; page <= _catalogMaxPages; page++) {
      final r = await _send(
          'GET', 'catalog/services?page=$page&pageSize=$_catalogPageSize');
      switch (r) {
        case ApiFailed(:final kind, :final message):
          return ApiFailed(kind, message);
        case ApiOk(:final value):
          final rows = asJsonList(value);
          all.addAll(
              rows.map(CatalogService.fromJson).where((s) => s.id.isNotEmpty));
          if (rows.length < _catalogPageSize) return ApiOk(all);
      }
    }
    return ApiOk(all);
  }

  @override
  Future<ApiResult<List<GuestTrip>>> fetchTrips(String guestUuid) async => _map(
        await _send('GET', 'stays/$guestUuid/trips', guestUuid: guestUuid),
        (data) => asJsonList(data).map(GuestTrip.fromJson).toList(),
      );

  Future<ApiResult<void>> _command(String method, String path,
          {required String guestUuid, Object? body}) async =>
      _map(await _send(method, path, guestUuid: guestUuid, body: body), (_) {});

  @override
  Future<ApiResult<void>> saveOrder(String guestUuid, Json payload) {
    final serviceId = Uri.encodeComponent(asString(payload['serviceId']));
    return _command('PUT', 'stays/$guestUuid/orders/$serviceId',
        guestUuid: guestUuid, body: {'items': payload['items'] ?? const []});
  }

  @override
  Future<ApiResult<void>> saveJourney(String guestUuid,
          {Set<String>? skippedTaskIds, Set<String>? completedTaskIds}) =>
      _command('PUT', 'stays/$guestUuid/journey', guestUuid: guestUuid, body: {
        if (skippedTaskIds != null) 'skippedTaskIds': skippedTaskIds.toList(),
        if (completedTaskIds != null)
          'completedTaskIds': completedTaskIds.toList(),
      });

  @override
  Future<ApiResult<void>> cancelBooking(String guestUuid, String bookingId) =>
      _command('POST',
          'stays/$guestUuid/bookings/${Uri.encodeComponent(bookingId)}/cancel',
          guestUuid: guestUuid);

  @override
  Future<ApiResult<void>> changeBooking(
          String guestUuid, String bookingId, Json change) =>
      _command('PATCH',
          'stays/$guestUuid/bookings/${Uri.encodeComponent(bookingId)}',
          guestUuid: guestUuid, body: change);

  @override
  Future<ApiResult<void>> cancelTrip(String guestUuid, String tripId) =>
      _command('POST',
          'stays/$guestUuid/trips/${Uri.encodeComponent(tripId)}/cancel',
          guestUuid: guestUuid);

  @override
  Future<ApiResult<void>> createBooking(String guestUuid, Json payload) async =>
      _map(
          await _send('POST', 'stays/$guestUuid/bookings',
              guestUuid: guestUuid, body: payload),
          (_) {});

  @override
  Future<ApiResult<GuestTrip>> createTrip(
          String guestUuid, Json payload) async =>
      _map(
        await _send('POST', 'stays/$guestUuid/trips',
            guestUuid: guestUuid, body: payload),
        (data) => GuestTrip.fromJson(asJson(data)),
      );

  @override
  Future<ApiResult<void>> savePreferences(String guestUuid,
          {required String dietary, required List<String> allergies}) async =>
      _map(
        await _send('PATCH', 'stays/$guestUuid/personalization',
            guestUuid: guestUuid,
            body: {'dietary': dietary, 'dietaryAllergies': allergies}),
        (_) {},
      );

  @override
  Future<ApiResult<void>> sendRating(
          String guestUuid, int rating, String note) async =>
      _map(
        await _send('POST', 'stays/$guestUuid/midstay-checkin',
            guestUuid: guestUuid,
            body: {
              'rating': rating,
              if (note.trim().isNotEmpty) 'note': note.trim()
            }),
        (_) {},
      );

  @override
  Future<ApiResult<String>> startHostThread(String guestUuid,
      {required String text, String? photoStoragePath}) async {
    final withPhoto = photoStoragePath != null;
    final r = await _send('POST', 'stays/$guestUuid/concierge-requests',
        guestUuid: guestUuid,
        body: {
          'type': 'ask',
          'category': withPhoto ? HostThread.photoCategory : chatCategory,
          'title': withPhoto ? 'Photo' : 'Message',
          'details': text,
          if (withPhoto) 'photoStoragePath': photoStoragePath,
        });
    return _map(r, (data) => asString(asJson(data)['requestId']));
  }

  @override
  Future<ApiResult<void>> sendHostMessage(
          String guestUuid, String threadId, String text,
          {String? photoStoragePath}) =>
      _command('POST', 'stays/$guestUuid/concierge-requests/$threadId/messages',
          guestUuid: guestUuid,
          body: {
            if (text.isNotEmpty) 'text': text,
            if (photoStoragePath != null) 'photoStoragePath': photoStoragePath,
          });

  @override
  Future<ApiResult<String>> uploadPhoto(String guestUuid, PickedPhoto photo,
      {String? threadId}) async {
    final signed = await _send(
        'POST', 'stays/$guestUuid/concierge-requests/upload-url',
        guestUuid: guestUuid,
        body: {
          'fileName': photo.fileName,
          'contentType': photo.contentType,
          'fileSizeBytes': photo.bytes.length,
          if (threadId != null) 'requestId': threadId,
        });
    if (signed is ApiFailed<Object?>) {
      return ApiFailed(signed.kind, signed.message);
    }
    final ticket = UploadTicket.fromJson(asJson((signed as ApiOk).value));
    if (ticket == null) return const ApiFailed(FailureKind.unreachable);
    if (photo.bytes.length > ticket.maxBytes) {
      return const ApiFailed(FailureKind.invalid);
    }
    return _putBytes(ticket, photo);
  }

  /// Sends the bytes exactly as signed: the ticket's method and headers.
  Future<ApiResult<String>> _putBytes(
      UploadTicket ticket, PickedPhoto photo) async {
    try {
      final request = http.Request(ticket.method, Uri.parse(ticket.uploadUrl))
        ..headers.addAll(ticket.headers)
        ..bodyBytes = photo.bytes;
      final response = await _client.send(request).timeout(timeout);
      await response.stream.drain<void>();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const ApiFailed(FailureKind.unreachable);
      }
      return ApiOk(ticket.storagePath);
    } on TimeoutException {
      return const ApiFailed(FailureKind.unreachable);
    } on http.ClientException {
      return const ApiFailed(FailureKind.unreachable);
    }
  }

  @override
  void dispose() {
    if (_ownsClient) _client.close();
  }
}

/// Signed direct-to-Storage upload returned by `upload-url`.
class UploadTicket {
  const UploadTicket({
    required this.uploadUrl,
    required this.method,
    required this.headers,
    required this.storagePath,
    required this.maxBytes,
  });

  /// Null when the server ticket is incomplete (nothing is guessed).
  static UploadTicket? fromJson(Json json) {
    final method = asString(json['method']).toUpperCase();
    final uploadUrl = asString(json['uploadUrl']);
    final storagePath = asString(json['storagePath']);
    final maxBytes = asInt(json['maxBytes']);
    if (uploadUrl.isEmpty || storagePath.isEmpty || maxBytes == null) {
      return null;
    }
    if (method != 'PUT' && method != 'POST') return null;
    return UploadTicket(
      uploadUrl: uploadUrl,
      method: method,
      headers: {
        for (final e in asJson(json['headers']).entries) e.key: '${e.value}'
      },
      storagePath: storagePath,
      maxBytes: maxBytes,
    );
  }

  final String uploadUrl;
  final String method;
  final Map<String, String> headers;
  final String storagePath;
  final int maxBytes;
}
