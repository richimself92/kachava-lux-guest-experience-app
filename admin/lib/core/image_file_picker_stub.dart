import '../domain/uploads.dart';

/// Non-web builds have no file dialog: picking is always cancelled.
class _NoImageFilePicker implements ImageFilePicker {
  const _NoImageFilePicker();

  @override
  Future<PickedImageFile?> pickImage() async => null;
}

ImageFilePicker createPlatformImageFilePicker() => const _NoImageFilePicker();
