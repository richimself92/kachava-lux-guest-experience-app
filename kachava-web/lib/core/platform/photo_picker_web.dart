import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'photo_picker.dart';

/// `<input type="file" accept="image/*">`: real camera/gallery on phones.
class WebPhotoPicker implements PhotoPicker {
  @override
  Future<PickedPhoto?> pick() {
    final done = Completer<PickedPhoto?>();
    void finish(PickedPhoto? photo) {
      if (!done.isCompleted) done.complete(photo);
    }

    final input = web.HTMLInputElement()
      ..type = 'file'
      ..accept = 'image/jpeg,image/png,image/webp';
    input.onchange = ((web.Event _) {
      final file = input.files?.item(0);
      if (file == null) return finish(null);
      file.arrayBuffer().toDart.then(
            (buffer) => finish(PickedPhoto(
              fileName: file.name,
              contentType: file.type,
              bytes: buffer.toDart.asUint8List(),
            )),
            onError: (Object _) => finish(null),
          );
    }).toJS;
    input.oncancel = ((web.Event _) => finish(null)).toJS;
    input.click();
    return done.future;
  }
}

PhotoPicker createPlatformPhotoPicker() => WebPhotoPicker();
