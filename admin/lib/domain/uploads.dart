import 'dart:typed_data';

/// A file the staff member picked (bytes stay in memory until uploaded).
class PickedImageFile {
  const PickedImageFile({
    required this.name,
    required this.contentType,
    required this.bytes,
  });

  final String name;
  final String contentType;
  final Uint8List bytes;

  int get sizeBytes => bytes.lengthInBytes;
}

/// How to send the bytes: the signed URL plus the HTTP method and headers
/// the backend chose (`PUT` on Cloud Storage, `POST` on the emulator).
class SignedUploadRequest {
  const SignedUploadRequest({
    required this.url,
    required this.method,
    required this.headers,
  });

  static const Set<String> methods = {'PUT', 'POST'};

  final Uri url;
  final String method;
  final Map<String, String> headers;
}

/// Server answer of `POST /admin/uploads/sign`.
class SignedUpload {
  const SignedUpload({
    required this.request,
    required this.storagePath,
    required this.publicUrl,
  });

  final SignedUploadRequest request;

  /// Save this as the image `storagePath`.
  final String storagePath;
  final String publicUrl;

  Uri get uploadUrl => request.url;
  String get method => request.method;
  Map<String, String> get headers => request.headers;
}

/// An image already stored in Cloud Storage.
class UploadedImage {
  const UploadedImage({required this.storagePath, required this.publicUrl});

  final String storagePath;
  final String publicUrl;
}

/// Port: asks the backend for a signed upload URL.
abstract interface class UploadSigner {
  Future<SignedUpload> sign({
    required String fileName,
    required String contentType,
    required int sizeBytes,
    required String folder,
  });
}

/// Port: sends the bytes to the signed URL with its method and headers.
abstract interface class SignedUploadTransport {
  Future<void> send(SignedUploadRequest request, Uint8List bytes);
}

/// Port: lets staff pick one image file; `null` when cancelled.
abstract interface class ImageFilePicker {
  Future<PickedImageFile?> pickImage();
}

/// Why a picked file was refused before uploading.
enum ImageRejection { unsupportedType, tooLarge }

/// Client-side upload policy: JPEG, PNG or WebP up to 5 MB (the backend
/// enforces the same limits when signing).
abstract final class ImageUploadPolicy {
  static const int maxBytes = 5 * 1024 * 1024;
  static const Set<String> contentTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
  };

  static ImageRejection? check(PickedImageFile file) {
    if (!contentTypes.contains(file.contentType.toLowerCase())) {
      return ImageRejection.unsupportedType;
    }
    if (file.sizeBytes > maxBytes) return ImageRejection.tooLarge;
    return null;
  }
}
