import 'package:flutter/material.dart';

import '../../core/theme/kachava_tokens.dart';

/// One line that leads to Settings when a screen needs a value that is not
/// configured yet: "Time zone not set · Set up in Settings".
class SettingsSetupLink extends StatelessWidget {
  const SettingsSetupLink({
    super.key,
    required this.message,
    required this.linkLabel,
    required this.onOpenSettings,
  });

  final String message;
  final String linkLabel;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(color: KachavaTokens.textSecondary);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: KachavaTokens.space2,
      children: [
        const Icon(Icons.settings_outlined,
            size: 18, color: KachavaTokens.textSecondary),
        Text(message, style: style),
        TextButton(
          key: const Key('setup-in-settings'),
          onPressed: onOpenSettings,
          child: Text(linkLabel),
        ),
      ],
    );
  }
}
