import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Browser `visibilitychange` filtered to "visible"; the listener lives only
/// while someone listens.
Stream<void> platformPageVisibleAgain() {
  late final StreamController<void> out;
  final listener = ((web.Event _) {
    if (web.document.visibilityState == 'visible') out.add(null);
  }).toJS;
  out = StreamController<void>(
    onListen: () => web.document.addEventListener('visibilitychange', listener),
    onCancel: () =>
        web.document.removeEventListener('visibilitychange', listener),
  );
  return out.stream;
}
