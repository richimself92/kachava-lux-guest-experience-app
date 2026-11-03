import 'package:flutter/material.dart';

import '../../application/portal_controller.dart';
import '../../core/theme/kachava_colors.dart';

/// App bar action that reads the server again; shows a small spinner while
/// the guest's refresh runs.
class RefreshButton extends StatelessWidget {
  const RefreshButton({super.key, required this.controller});
  final PortalController controller;

  @override
  Widget build(BuildContext context) {
    final busy = controller.isRefreshing;
    return IconButton(
      key: const Key('guest-refresh-button'),
      tooltip: controller.l10n.refresh,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      color: KachavaColors.onSurfaceVariant,
      onPressed: busy ? null : controller.refreshNow,
      icon: busy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: KachavaColors.primary),
            )
          : const Icon(Icons.refresh),
    );
  }
}
