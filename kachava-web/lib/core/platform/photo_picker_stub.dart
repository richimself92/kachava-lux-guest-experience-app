import 'photo_picker.dart';

class _NoPhotoPicker implements PhotoPicker {
  @override
  Future<PickedPhoto?> pick() async => null;
}

PhotoPicker createPlatformPhotoPicker() => _NoPhotoPicker();
