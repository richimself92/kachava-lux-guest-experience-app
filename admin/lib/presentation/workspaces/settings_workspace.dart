import 'package:flutter/material.dart';

import '../../core/admin_i18n.dart';
import '../../core/theme/kachava_tokens.dart';
import '../components/components.dart';

/// Settings workspace (opened from the top bar gear). Phase 3 adds the
/// check-in/out times, time zone, airports and alert lead time; until then
/// it shows one empty-state line.
class SettingsWorkspace extends StatelessWidget {
  const SettingsWorkspace({super.key, required this.isEs});

  final bool isEs;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('workspace-admin-settings'),
      padding: const EdgeInsets.all(KachavaTokens.space6),
      children: [
        PageHeader(title: AdminI18n.tr(isEs, 'Settings', 'Ajustes')),
        AdminStateLine(
          key: const Key('settings-empty'),
          message: AdminI18n.tr(
              isEs, 'Nothing to configure yet', 'Nada que configurar aún'),
        ),
      ],
    );
  }
}
