import 'package:flutter/foundation.dart';

import 'install_prompt_stub.dart'
    if (dart.library.js_interop) 'install_prompt_web.dart';

/// Port over the browser's "install this app" capabilities. Notifies its
/// listeners when the native prompt becomes available or is consumed.
abstract interface class InstallPromptPort implements Listenable {
  /// Already running as an installed app (`display-mode: standalone`).
  bool get isStandalone;

  /// iPhone/iPad: no native prompt, only Share → Add to Home Screen.
  bool get isIos;

  /// Chromium deferred `beforeinstallprompt` is ready to be shown.
  bool get canPromptNative;

  /// The guest closed the install hint on this device.
  bool get isDismissed;

  void dismiss();

  /// Shows the native prompt; true when the guest accepted it.
  Future<bool> promptNative();

  /// Releases browser event listeners.
  void dispose();
}

/// What the Home screen offers to install the app.
enum InstallBannerMode {
  hidden,
  nativePrompt,
  iosGuide;

  static InstallBannerMode of(InstallPromptPort port) {
    if (port.isStandalone || port.isDismissed) return hidden;
    if (port.canPromptNative) return nativePrompt;
    if (port.isIos) return iosGuide;
    return hidden;
  }
}

/// Factory returning the platform-appropriate [InstallPromptPort].
InstallPromptPort createInstallPromptPort() => createPlatformInstallPrompt();
