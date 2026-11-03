import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../domain/json_read.dart';
import '../domain/uploads.dart';
import 'admin_api_client.dart';

/// `POST /admin/uploads/sign` -> `{ uploadUrl, storagePath, publicUrl }`.
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
    final data = raw['data'] is Map
        ? Map<String, dynamic>.from(raw['data'] as Map)
        : raw;
    final url = Uri.tryParse(JsonRead.text(data, 'uploadUrl'));
    final path = JsonRead.text(data, 'storagePath');
    final publicUrl = JsonRead.text(data, 'publicUrl');
    if (url == null || !url.hasScheme || path.isEmpty || publicUrl.isEmpty) {
      throw const FormatException('Upload sign response is incomplete.');
    }
    return SignedUpload(
        uploadUrl: url, storagePath: path, publicUrl: publicUrl);
  }
}

/// `PUT`s the bytes to the signed Cloud Storage URL (no admin token).
class HttpSignedUploadTransport implements SignedUploadTransport {
  HttpSignedUploadTransport([http.Client? client])
      : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<void> put(Uri uploadUrl, Uint8List bytes, String contentType) async {
    final response = await _client.put(uploadUrl,
        headers: {'Content-Type': contentType}, body: bytes);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SignedUploadException(response.statusCode);
    }
  }
}

/// The storage `PUT` was refused.
class SignedUploadException implements Exception {
  const SignedUploadException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'SignedUploadException(HTTP $statusCode)';
}
