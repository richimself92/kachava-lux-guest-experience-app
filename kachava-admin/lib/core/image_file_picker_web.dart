import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import '../domain/uploads.dart';

@JS('document')
external _JsDocument get _document;

extension type _JsDocument._(JSObject _) implements JSObject {
  external _JsInput createElement(String tag);
}

extension type _JsInput._(JSObject _) implements JSObject {
  external set type(String value);
  external set accept(String value);
  external _JsFileList? get files;
  external void click();
  external void addEventListener(String type, JSFunction listener);
}

extension type _JsFileList._(JSObject _) implements JSObject {
  external int get length;
  external _JsFile? item(int index);
}

extension type _JsFile._(JSObject _) implements JSObject {
  external String get name;
  external String get type;
  external JSPromise<JSArrayBuffer> arrayBuffer();
}

/// Opens the browser file dialog (`<input type=file>`) for one image.
class _WebImageFilePicker implements ImageFilePicker {
  const _WebImageFilePicker();

  @override
  Future<PickedImageFile?> pickImage() {
    final completer = Completer<PickedImageFile?>();
    final input = _document.createElement('input')
      ..type = 'file'
      ..accept = ImageUploadPolicy.contentTypes.join(',');
    input.addEventListener(
        'change',
        ((JSAny? _) {
          completer.complete(_read(input));
        }).toJS);
    input.addEventListener(
        'cancel',
        ((JSAny? _) {
          if (!completer.isCompleted) completer.complete(null);
        }).toJS);
    input.click();
    return completer.future;
  }

  static Future<PickedImageFile?> _read(_JsInput input) async {
    final files = input.files;
    final file = files == null || files.length == 0 ? null : files.item(0);
    if (file == null) return null;
    final buffer = await file.arrayBuffer().toDart;
    return PickedImageFile(
      name: file.name,
      contentType: file.type,
      bytes: Uint8List.view(buffer.toDart),
    );
  }
}

ImageFilePicker createPlatformImageFilePicker() => const _WebImageFilePicker();
