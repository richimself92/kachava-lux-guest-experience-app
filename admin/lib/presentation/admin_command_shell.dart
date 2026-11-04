import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../application/admin_live_sync.dart';
import '../application/admin_shell_controller.dart';
import '../application/notification_bell_controller.dart';
import '../application/resort_settings_controller.dart';
import '../core/admin_i18n.dart';
import '../core/ops_strings.dart';
import '../core/responsive_breakpoints.dart';
import '../core/resort_time.dart';
import '../core/time_zone_catalog.dart';
import '../core/theme/kachava_tokens.dart';
import '../domain/admin_catalog_repositories.dart';
import '../domain/admin_enums.dart';
import 'admin_workspace_switcher.dart';
import 'requests/guest_arrival_banner.dart';
import 'widgets/admin_navigation_bars.dart';
import 'widgets/reconnecting_indicator.dart';
import 'widgets/top_command_bar.dart';

/// Responsive shell: sidebar (desktop), icon rail (tablet), drawer (mobile),
/// the top bar (title, EN/ES, bell, Settings) and the active workspace.
class AdminCommandShell extends StatelessWidget {
  const AdminCommandShell({
    super.key,
    required this.controller,
    required this.bell,
    required this.resortSettings,
    required this.villas,
    required this.timeZones,
    this.syncStatus,
    this.zoneResolver,
    this.onRefresh,
  });

  final AdminShellController controller;
  final NotificationBellController bell;

  /// Shared resort settings (Settings screen + "Set up in Settings" links).
  final ResortSettingsController resortSettings;
  final VillaRepository villas;
  final TimeZoneCatalog timeZones;

  /// Bell sync health; unhealthy states show one small status line.
  final ValueListenable<AdminSyncStatus>? syncStatus;

  /// Resort wall time of the Settings zone (browser `Intl` by default).
  final ZoneOffsetResolver? zoneResolver;

  /// Top-bar Refresh: the bell and every open screen.
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        AdminI18n.currentIsEs = controller.isEs;
        return LayoutBuilder(
          builder: (context, constraints) {
            final viewport = AdminBreakpoints.resolve(constraints.maxWidth);
            return Scaffold(
              drawer: viewport == AdminViewportSize.mobile
                  ? AdminMobileNavDrawer(controller: controller)
                  : null,
              body: Column(
                children: [
                  if (syncStatus != null)
                    ReconnectingIndicator(
                        status: syncStatus!, isEs: controller.isEs),
                  _UrgentBanner(controller: controller, bell: bell),
                  GuestArrivalBanner(controller: controller, bell: bell),
                  Expanded(child: _body(viewport)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _body(AdminViewportSize viewport) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (viewport == AdminViewportSize.desktop)
          DesktopCommandSidebar(controller: controller)
        else if (viewport == AdminViewportSize.tablet)
          TabletCompactRail(controller: controller),
        Expanded(
          child: Column(
            children: [
              TopCommandBar(
                controller: controller,
                bell: bell,
                showMenuButton: viewport == AdminViewportSize.mobile,
                onRefresh: onRefresh,
              ),
              Expanded(
                child: AdminWorkspaceSwitcher(
                  controller: controller,
                  bell: bell,
                  resortSettings: resortSettings,
                  villas: villas,
                  timeZones: timeZones,
                  zoneResolver: zoneResolver ?? createZoneOffsetResolver(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One dark line while a new URGENT notification rings: Open / Mute.
class _UrgentBanner extends StatelessWidget {
  const _UrgentBanner({required this.controller, required this.bell});

  final AdminShellController controller;
  final NotificationBellController bell;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: bell,
        builder: (context, _) {
          if (!bell.hasUrgentAlert) return const SizedBox.shrink();
          final s = OpsStrings(controller.isEs);
          const onDark = TextStyle(
              fontSize: 14, height: 20 / 14, color: KachavaTokens.onPrimary);
          final button =
              TextButton.styleFrom(foregroundColor: KachavaTokens.onPrimary);
          return Container(
            key: const Key('admin-toast-banner'),
            width: double.infinity,
            color: KachavaTokens.text,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(children: [
              const Icon(Icons.notifications_active_outlined,
                  size: 18, color: KachavaTokens.onPrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(s.urgentArrived,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: onDark),
              ),
              TextButton(
                key: const Key('urgent-banner-open'),
                style: button,
                onPressed: () {
                  bell.silence();
                  controller.selectTab(AdminWorkspaceTab.adminNotifications);
                },
                child: Text(s.open),
              ),
              TextButton.icon(
                key: const Key('dismiss-alert-chime-btn'),
                style: button,
                onPressed: bell.silence,
                icon: const Icon(Icons.volume_off_outlined, size: 18),
                label: Text(s.mute),
              ),
            ]),
          );
        },
      );
}
