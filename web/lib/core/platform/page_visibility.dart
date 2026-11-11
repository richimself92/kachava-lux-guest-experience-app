import 'page_visibility_stub.dart'
    if (dart.library.js_interop) 'page_visibility_web.dart';

/// Emits each time the browser tab becomes visible again
/// (`visibilitychange`); never emits on headless platforms.
Stream<void> pageVisibleAgain() => platformPageVisibleAgain();
