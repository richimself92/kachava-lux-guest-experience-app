import 'package:flutter/material.dart';
import '../../core/i18n/guest_feedback_i18n.dart';
import '../../core/i18n/guest_i18n.dart';
import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';

/// Shown when the magic link is missing, malformed, or rejected by the server
/// (HTTP 401/403/404).
class AccessRestrictedScreen extends StatelessWidget {
  const AccessRestrictedScreen({
    super.key,
    required this.i18n,
    this.isLinkInvalid = false,
    this.isLinkExpired = false,
  });

  final GuestI18n i18n;

  /// True when a link was given but is malformed, revoked, or expired.
  final bool isLinkInvalid;

  /// True when the server rejected the link this device remembered.
  final bool isLinkExpired;

  String get _message {
    if (isLinkExpired) return i18n.accessLinkExpired;
    return isLinkInvalid ? i18n.accessLinkInvalid : i18n.accessLinkMissing;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KachavaColors.surfaceContainerLow,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _buildRestrictedCardBody(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestrictedCardBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.support_agent, size: 44, color: KachavaColors.primary),
        const SizedBox(height: 12),
        Text(
          i18n.accessRestrictedTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: KachavaTheme.serifFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: KachavaColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _message,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 13, color: KachavaColors.onSurfaceVariant),
        ),
      ],
    );
  }
}
