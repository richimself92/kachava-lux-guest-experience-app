import 'dart:typed_data';

import 'photo_picker_stub.dart'
    if (dart.library.js_interop) 'photo_picker_web.dart';

/// A photo chosen by the guest (camera or gallery).
class PickedPhoto {
  const PickedPhoto({
    required this.fileName,
    required this.contentType,
    required this.bytes,
  });

  final String fileName;
  final String contentType;
  final Uint8List bytes;
}

/// Opens the device photo chooser; null when the guest cancels.
abstract interface class PhotoPicker {
  Future<PickedPhoto?> pick();
}

PhotoPicker createPhotoPicker() => createPlatformPhotoPicker();
