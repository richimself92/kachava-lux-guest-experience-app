import 'package:flutter/material.dart';
import '../application/admin_dashboard_controller.dart';
import '../core/admin_i18n.dart';
import '../core/admin_theme.dart';
import '../core/responsive_breakpoints.dart';
import '../domain/admin_enums.dart';
import 'widgets/admin_navigation_bars.dart';
import 'widgets/slide_over_inspector_drawer.dart';
import 'widgets/top_command_bar.dart';
import 'workspaces/concierge_workspace.dart';
import 'workspaces/experiences_workspace.dart';
import 'workspaces/folio_workspace.dart';
import 'workspaces/larder_workspace.dart';
import 'workspaces/overview_workspace.dart';
import 'workspaces/stays_workspace.dart';

/// 3-Breakpoint Responsive Browser & Mobile-Adaptive Command Shell.
class AdminCommandShell extends StatelessWidget {
  const AdminCommandShell({super.key, required this.controller});

  final AdminDashboardController controller;

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
              backgroundColor: KachavaAdminColors.canvasLow,
              bottomNavigationBar: viewport == AdminViewportSize.mobile
                  ? MobileCommandBottomNav(controller: controller)
                  : null,
              body: Column(
                children: [
                  if (controller.lastToastMessage != null)
                    _buildToastBanner(controller.lastToastMessage!),
                  Expanded(
                    child: _buildViewportBody(viewport),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildViewportBody(AdminViewportSize viewport) {
    final selection = controller.inspectorSelection;
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
              TopCommandBar(controller: controller),
              Expanded(
                child: Stack(
                  children: [
                    _buildActiveWorkspace(),
                    if (selection != null &&
                        viewport != AdminViewportSize.desktop)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 380,
                            maxWidth: 600,
                          ),
                          child: Material(
                            elevation: 12,
                            child: SingleChildScrollView(
                              child: SlideOverInspectorDrawer(
                                controller: controller,
                                selection: selection,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (selection != null && viewport == AdminViewportSize.desktop)
          SingleChildScrollView(
            child: SlideOverInspectorDrawer(
              controller: controller,
              selection: selection,
            ),
          ),
      ],
    );
  }

  Widget _buildActiveWorkspace() {
    switch (controller.activeTab) {
      case AdminWorkspaceTab.adminOverview:
        return OverviewWorkspace(controller: controller);
      case AdminWorkspaceTab.adminStays:
        return StaysWorkspace(controller: controller);
      case AdminWorkspaceTab.adminExperiences:
        return ExperiencesWorkspace(controller: controller);
      case AdminWorkspaceTab.adminLarder:
        return LarderWorkspace(controller: controller);
      case AdminWorkspaceTab.adminConcierge:
        return ConciergeWorkspace(controller: controller);
      case AdminWorkspaceTab.adminFolio:
        return FolioWorkspace(controller: controller);
    }
  }

  Widget _buildToastBanner(String message) {
    final isEs = controller.isEs;
    final ringing = controller.isChimeRinging;
    final headerText = isEs
        ? (ringing
            ? 'ALERTA ENTRANTE · NUEVA ACTUALIZACIÓN (SONANDO 10S)'
            : 'NOTIFICACIÓN DE OPERACIONES · HOST ADMIN')
        : (ringing
            ? 'INCOMING GUEST UPDATE · LIVE ALERT (10S CHIME ACTIVE)'
            : 'OPERATIONS NOTIFICATION · HOST ADMIN');
    return Container(
      key: const Key('admin-toast-banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: KachavaAdminColors.obsidian,
        border: Border.all(color: KachavaAdminColors.copalGold, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active,
            size: 18,
            color: KachavaAdminColors.copalGold,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  headerText,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: KachavaAdminColors.copalGold,
                  ),
                ),
                SelectableText(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            key: const Key('dismiss-alert-chime-btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: KachavaAdminColors.copalGold,
              foregroundColor: KachavaAdminColors.obsidian,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            onPressed: controller.dismissToastAndStopChime,
            icon: const Icon(Icons.volume_off, size: 14),
            label: Text(
              isEs ? 'Silenciar / Cerrar' : 'Mute / Dismiss',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
