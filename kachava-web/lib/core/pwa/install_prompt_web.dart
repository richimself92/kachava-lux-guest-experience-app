import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'install_prompt_port.dart';

/// Bridge installed by the boot script in `web/index.html`.
@JS('kachavaInstall')
external _InstallBridge? get _bridge;

extension type _InstallBridge._(JSObject _) implements JSObject {
  external bool isStandalone();
  external bool isIos();
  external bool canPrompt();
  external JSPromise<JSString> prompt();
}

/// Browser implementation: reads the bridge and remembers a dismissal in
/// `localStorage`. Every call fails soft when the bridge or storage is absent.
class WebInstallPrompt extends ChangeNotifier implements InstallPromptPort {
  WebInstallPrompt() {
    web.window.addEventListener(_changedEvent, _onChanged);
  }

  static const String _changedEvent = 'kachava-install-changed';
  static const String _dismissedKey = 'kachava_install_dismissed';

  late final JSFunction _onChanged = ((web.Event _) => notifyListeners()).toJS;

  bool _ask(bool Function(_InstallBridge b) query) {
    try {
      final bridge = _bridge;
      return bridge != null && query(bridge);
    } catch (_) {
      return false;
    }
  }

  @override
  bool get isStandalone => _ask((b) => b.isStandalone());

  @override
  bool get isIos => _ask((b) => b.isIos());

  @override
  bool get canPromptNative => _ask((b) => b.canPrompt());

  @override
  bool get isDismissed {
    try {
      return web.window.localStorage.getItem(_dismissedKey) == '1';
    } catch (_) {
      return false;
    }
  }

  @override
  void dismiss() {
    try {
      web.window.localStorage.setItem(_dismissedKey, '1');
    } catch (_) {}
    notifyListeners();
  }

  @override
  Future<bool> promptNative() async {
    final bridge = _bridge;
    if (bridge == null) return false;
    try {
      final outcome = await bridge.prompt().toDart;
      return outcome.toDart == 'accepted';
    } catch (_) {
      return false;
    } finally {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    web.window.removeEventListener(_changedEvent, _onChanged);
    super.dispose();
  }
}

InstallPromptPort createPlatformInstallPrompt() => WebInstallPrompt();
