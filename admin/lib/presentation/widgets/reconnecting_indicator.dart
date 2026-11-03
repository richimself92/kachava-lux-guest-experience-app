import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../application/admin_live_sync.dart';
import '../../core/admin_i18n.dart';
import '../../core/admin_theme.dart';

/// Small one-line status shown while the live sync is not healthy.
///
/// "Reconnecting…" keeps the last good data on screen and only signals that it
/// may be stale; "No access" means the staff role may not read the feed.
class ReconnectingIndicator extends StatelessWidget {
  const ReconnectingIndicator(
      {super.key, required this.status, required this.isEs});

  final ValueListenable<AdminSyncStatus> status;
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AdminSyncStatus>(
      valueListenable: status,
      builder: (context, value, _) => switch (value) {
        AdminSyncStatus.live => const SizedBox.shrink(),
        AdminSyncStatus.reconnecting => _buildLine(
            const Key('sync-reconnecting-indicator'),
            Icons.sync_problem,
            AdminI18n.tr(isEs, 'Reconnecting…', 'Reconectando…')),
        AdminSyncStatus.noAccess => _buildLine(
            const Key('sync-no-access-indicator'),
            Icons.lock_outline,
            AdminI18n.tr(isEs, 'No access', 'Sin acceso')),
      },
    );
  }

  Widget _buildLine(Key key, IconData icon, String text) {
    return Semantics(
      key: key,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        color: KachavaAdminColors.surfaceContainer,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: KachavaAdminColors.obsidian),
            const SizedBox(width: 8),
            Text(text,
                style: const TextStyle(
                    fontSize: 12, color: KachavaAdminColors.obsidian)),
          ],
        ),
      ),
    );
  }
}
