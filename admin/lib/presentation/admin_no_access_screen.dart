import 'package:flutter/material.dart';
import '../core/admin_i18n.dart';
import '../core/admin_theme.dart';

/// Shown instead of the Command Center while the signed-in staff role may not
/// read the admin sync feed (HTTP 403). It renders no operational data.
class AdminNoAccessScreen extends StatelessWidget {
  const AdminNoAccessScreen({super.key, required this.isEs, this.onSignOut});

  final bool isEs;

  /// Ends the staff session so another member can sign in; hidden when null.
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('admin-no-access-screen'),
      backgroundColor: KachavaAdminColors.canvasLow,
      body: Center(
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline,
                  size: 32, color: KachavaAdminColors.obsidian),
              const SizedBox(height: 12),
              Text(AdminI18n.tr(isEs, 'No access', 'Sin acceso'),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: KachavaAdminColors.obsidian)),
              if (onSignOut != null) ...[
                const SizedBox(height: 16),
                _buildSignOutButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return FilledButton(
      key: const Key('admin-no-access-sign-out'),
      style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: KachavaAdminColors.zapotePrimary),
      onPressed: onSignOut,
      child: Text(AdminI18n.tr(isEs, 'Sign out', 'Cerrar sesión')),
    );
  }
}
