import 'package:flutter/material.dart';
import '../../application/sanctuary_controller.dart';
import '../../core/i18n/guest_feedback_i18n.dart';
import '../../core/theme/kachava_colors.dart';
import 'reconnecting_indicator.dart';

/// Shown until the server answers for the first time; never shows guest data.
class SanctuaryLoadingScreen extends StatelessWidget {
  const SanctuaryLoadingScreen({super.key, required this.controller});

  final SanctuaryController controller;

  @override
  Widget build(BuildContext context) {
    final i18n = controller.i18n;
    return Scaffold(
      key: const Key('sanctuary-loading-screen'),
      backgroundColor: KachavaColors.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: KachavaColors.primary),
            const SizedBox(height: 16),
            Text(
              i18n.loadingSanctuary,
              style: const TextStyle(
                  fontSize: 14, color: KachavaColors.onSurfaceVariant),
            ),
            if (controller.isReconnecting)
              ReconnectingIndicator(label: i18n.reconnecting),
          ],
        ),
      ),
    );
  }
}
