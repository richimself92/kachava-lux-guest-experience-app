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

/// Server answer of `POST /admin/uploads/sign`.
class SignedUpload {
  const SignedUpload({
    required this.uploadUrl,
    required this.storagePath,
    required this.publicUrl,
  });

  /// Short-lived signed `PUT` URL.
  final Uri uploadUrl;
  final String storagePath;
  final String publicUrl;
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

/// Port: `PUT`s the bytes to the signed URL.
abstract interface class SignedUploadTransport {
  Future<void> put(Uri uploadUrl, Uint8List bytes, String contentType);
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
