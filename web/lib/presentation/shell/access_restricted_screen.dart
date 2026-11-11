import 'package:flutter/material.dart';

import '../../application/portal_controller.dart';
import '../../core/i18n/l10n.dart';
import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';

/// Missing, malformed or rejected guest link (HTTP 401/403/404): one line
/// that tells the guest to ask the Resort Host.
class AccessRestrictedScreen extends StatelessWidget {
  const AccessRestrictedScreen(
      {super.key, required this.l10n, required this.phase});

  final L10n l10n;
  final PortalPhase phase;

  String get _message => switch (phase) {
        PortalPhase.linkExpired => l10n.linkExpired,
        PortalPhase.linkInvalid => l10n.linkInvalid,
        _ => l10n.linkMissing,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('access-restricted'),
      backgroundColor: KachavaColors.surfaceContainerLow,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.support_agent,
                        size: 44, color: KachavaColors.primary),
                    const SizedBox(height: 12),
                    Text(
                      l10n.accessTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: KachavaTheme.serifFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: KachavaColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16, color: KachavaColors.onSurface),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
