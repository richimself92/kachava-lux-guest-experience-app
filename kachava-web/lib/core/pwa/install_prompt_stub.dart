import 'package:flutter/foundation.dart';

import 'install_prompt_port.dart';

/// Headless platforms (`flutter test`) never offer installation.
class NoInstallPrompt extends ChangeNotifier implements InstallPromptPort {
  @override
  bool get isStandalone => false;

  @override
  bool get isIos => false;

  @override
  bool get canPromptNative => false;

  @override
  bool get isDismissed => true;

  @override
  void dismiss() {}

  @override
  Future<bool> promptNative() async => false;
}

InstallPromptPort createPlatformInstallPrompt() => NoInstallPrompt();
