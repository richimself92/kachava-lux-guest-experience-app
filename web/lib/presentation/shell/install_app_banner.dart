import 'package:flutter/material.dart';

import '../../core/i18n/l10n.dart';
import '../../core/pwa/install_prompt_port.dart';
import '../../core/theme/kachava_colors.dart';

/// One-line, dismissible hint to install the portal: a native "Install app"
/// button on Chromium, a Share guide on iOS, nothing when already installed.
class InstallAppBanner extends StatelessWidget {
  const InstallAppBanner({super.key, required this.port, required this.i18n});

  final InstallPromptPort port;
  final L10n i18n;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: port,
      builder: (context, _) {
        final mode = InstallBannerMode.of(port);
        if (mode == InstallBannerMode.hidden) return const SizedBox.shrink();
        return _buildBanner(mode);
      },
    );
  }

  Widget _buildBanner(InstallBannerMode mode) {
    final isNative = mode == InstallBannerMode.nativePrompt;
    return Container(
      key: const Key('install-app-banner'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.only(left: 14),
      decoration: BoxDecoration(
        color: KachavaColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KachavaColors.outline),
      ),
      child: Row(
        children: [
          Icon(isNative ? Icons.install_mobile : Icons.ios_share,
              size: 18, color: KachavaColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isNative ? i18n.installAppHint : i18n.installIosGuide,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: KachavaColors.onSurface,
              ),
            ),
          ),
          if (isNative) _buildInstallButton(),
          _buildDismissButton(),
        ],
      ),
    );
  }

  Widget _buildInstallButton() {
    return TextButton(
      key: const Key('install-app-btn'),
      style: TextButton.styleFrom(
        foregroundColor: KachavaColors.primary,
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      onPressed: port.promptNative,
      child: Text(i18n.installAppAction),
    );
  }

  Widget _buildDismissButton() {
    return IconButton(
      key: const Key('install-app-dismiss'),
      tooltip: i18n.dismiss,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      onPressed: port.dismiss,
      icon: const Icon(Icons.close,
          size: 16, color: KachavaColors.onSurfaceVariant),
    );
  }
}
