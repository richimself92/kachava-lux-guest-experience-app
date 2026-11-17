import '../domain/uploads.dart';
import 'image_file_picker_stub.dart'
    if (dart.library.js_interop) 'image_file_picker_web.dart';

/// The platform [ImageFilePicker]: a browser file dialog on web, a no-op
/// (always cancelled) elsewhere. Tests inject a fake instead.
ImageFilePicker createImageFilePicker() => createPlatformImageFilePicker();
