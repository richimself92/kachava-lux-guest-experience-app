import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../domain/json_read.dart';
import '../domain/uploads.dart';
import 'admin_api_client.dart';

/// `POST /admin/uploads/sign` -> `{ uploadUrl, method, headers, storagePath,
/// publicUrl, expiresAt, maxBytes }`.
class HttpUploadSigner implements UploadSigner {
  HttpUploadSigner(this._client);

  final AdminApiClient _client;

  @override
  Future<SignedUpload> sign({
    required String fileName,
    required String contentType,
    required int sizeBytes,
    required String folder,
  }) async {
    final raw = await _client.postJson('/uploads/sign', {
      'fileName': fileName,
      'contentType': contentType,
      'sizeBytes': sizeBytes,
      'folder': folder,
    });
    final data = JsonRead.object(raw, 'data').isEmpty
        ? raw
        : JsonRead.object(raw, 'data');
    final url = Uri.tryParse(JsonRead.text(data, 'uploadUrl'));
    final method = JsonRead.text(data, 'method').toUpperCase();
    final path = JsonRead.text(data, 'storagePath');
    final publicUrl = JsonRead.text(data, 'publicUrl');
    if (url == null ||
        !url.hasScheme ||
        !SignedUploadRequest.methods.contains(method) ||
        path.isEmpty ||
        publicUrl.isEmpty) {
      throw const FormatException('Upload sign response is incomplete.');
    }
    final headers = JsonRead.object(data, 'headers');
    return SignedUpload(
      request: SignedUploadRequest(url: url, method: method, headers: {
        for (final e in headers.entries) e.key: '${e.value}',
      }),
      storagePath: path,
      publicUrl: publicUrl,
    );
  }
}

/// Sends the bytes straight to Storage (no admin token) with the signed
/// method and headers.
class HttpSignedUploadTransport implements SignedUploadTransport {
  HttpSignedUploadTransport([http.Client? client])
      : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<void> send(SignedUploadRequest request, Uint8List bytes) async {
    final outgoing = http.Request(request.method, request.url)
      ..headers.addAll(request.headers)
      ..bodyBytes = bytes;
    final response =
        await http.Response.fromStream(await _client.send(outgoing));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SignedUploadException(response.statusCode);
    }
  }
}

/// Storage refused the upload.
class SignedUploadException implements Exception {
  const SignedUploadException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'SignedUploadException(HTTP $statusCode)';
}
