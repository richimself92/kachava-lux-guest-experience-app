import 'dart:typed_data';

import 'package:kachava_admin_dashboard/domain/uploads.dart';

/// Test double for the `POST /admin/uploads/sign` port.
class FakeUploadSigner implements UploadSigner {
  FakeUploadSigner({this.failWith});

  final Object? failWith;
  final List<Map<String, Object>> calls = [];

  @override
  Future<SignedUpload> sign({
    required String fileName,
    required String contentType,
    required int sizeBytes,
    required String folder,
  }) async {
    calls.add({
      'fileName': fileName,
      'contentType': contentType,
      'sizeBytes': sizeBytes,
      'folder': folder,
    });
    if (failWith != null) throw failWith!;
    return SignedUpload(
      uploadUrl: Uri.parse('https://storage.test/put/$folder/$fileName'),
      storagePath: '$folder/$fileName',
      publicUrl: 'https://cdn.test/$folder/$fileName',
    );
  }
}

/// Records signed PUTs instead of sending them.
class FakeSignedUploadTransport implements SignedUploadTransport {
  final List<(Uri, int, String)> puts = [];

  @override
  Future<void> put(Uri uploadUrl, Uint8List bytes, String contentType) async =>
      puts.add((uploadUrl, bytes.length, contentType));
}

/// Returns a preset file (or `null` = cancelled).
class FakeImageFilePicker implements ImageFilePicker {
  FakeImageFilePicker(this.file);

  PickedImageFile? file;

  @override
  Future<PickedImageFile?> pickImage() async => file;
}

PickedImageFile pickedImage(
        {String name = 'cover.png',
        String contentType = 'image/png',
        int size = 1024}) =>
    PickedImageFile(
        name: name, contentType: contentType, bytes: Uint8List(size));
