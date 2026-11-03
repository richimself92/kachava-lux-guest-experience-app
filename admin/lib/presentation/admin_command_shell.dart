import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../application/admin_dashboard_controller.dart';
import '../application/admin_live_sync.dart';
import '../application/resort_settings_controller.dart';
import '../core/admin_i18n.dart';
import '../core/theme/kachava_tokens.dart';
import '../core/responsive_breakpoints.dart';
import '../core/time_zone_catalog.dart';
import '../domain/admin_catalog_repositories.dart';
import '../domain/admin_enums.dart';
import '../domain/service_catalog_enums.dart';
import 'services/services_workspace.dart';
import 'widgets/admin_navigation_bars.dart';
import 'widgets/reconnecting_indicator.dart';
import 'widgets/slide_over_inspector_drawer.dart';
import 'widgets/top_command_bar.dart';
import 'workspaces/concierge_workspace.dart';
import 'workspaces/experiences_workspace.dart';
import 'workspaces/folio_workspace.dart';
import 'workspaces/larder_workspace.dart';
import 'workspaces/overview_workspace.dart';
import 'workspaces/settings_workspace.dart';
import 'workspaces/stays_workspace.dart';
import 'workspaces/transportation/transportation_screen.dart';
import 'workspaces/villas_workspace.dart';

/// Responsive shell: sidebar (desktop), icon rail (tablet), drawer (mobile).
class AdminCommandShell extends StatelessWidget {
  const AdminCommandShell({
    super.key,
    required this.controller,
    required this.resortSettings,
    required this.villas,
    required this.timeZones,
    this.syncStatus,
  });

  final AdminDashboardController controller;

  /// Shared resort settings (Settings screen + "Set up in Settings" links).
  final ResortSettingsController resortSettings;
  final VillaRepository villas;
  final TimeZoneCatalog timeZones;

  /// Live sync health; unhealthy states show one small status line.
  final ValueListenable<AdminSyncStatus>? syncStatus;

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
              TopCommandBar(
                controller: controller,
                showMenuButton: viewport == AdminViewportSize.mobile,
              ),
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
        return OverviewWorkspace(
            controller: controller, resortSettings: resortSettings);
      case AdminWorkspaceTab.adminStays:
        return StaysWorkspace(controller: controller);
      case AdminWorkspaceTab.adminVillas:
        return VillasWorkspace(
            repository: villas,
            queries: controller.listQueries,
            isEs: controller.isEs);
      case AdminWorkspaceTab.adminExperiences:
        return ExperiencesWorkspace(controller: controller);
      case AdminWorkspaceTab.adminLarder:
        return LarderWorkspace(controller: controller);
      case AdminWorkspaceTab.adminServices:
        return ServicesWorkspace(
            queryStore: controller.listQueries,
            staff: controller.staffDirectory,
            isEs: controller.isEs);
      case AdminWorkspaceTab.adminSectionExperiences:
        return _section(ServiceSection.experiences);
      case AdminWorkspaceTab.adminSectionDining:
        return _section(ServiceSection.dining);
      case AdminWorkspaceTab.adminSectionWellness:
        return _section(ServiceSection.wellness);
      case AdminWorkspaceTab.adminTransportation:
        return TransportationScreen(
          resortSettings: resortSettings,
          queries: controller.listQueries,
          isEs: controller.isEs,
          onOpenSettings: () =>
              controller.selectTab(AdminWorkspaceTab.adminSettings),
          onOpenServicesTab: () =>
              controller.selectTab(AdminWorkspaceTab.adminServices),
        );
      case AdminWorkspaceTab.adminConcierge:
        return ConciergeWorkspace(controller: controller);
      case AdminWorkspaceTab.adminFolio:
        return FolioWorkspace(controller: controller);
      case AdminWorkspaceTab.adminSettings:
        return SettingsWorkspace(
            settings: resortSettings,
            timeZones: timeZones,
            isEs: controller.isEs);
    }
  }

  Widget _section(ServiceSection section) => ServiceSectionWorkspace(
        key: ValueKey(section),
        section: section,
        queryStore: controller.listQueries,
        staff: controller.staffDirectory,
        isEs: controller.isEs,
      );

  /// One-line neutral banner; the chime state only adds a short prefix.
  Widget _buildToastBanner(String message) {
    final isEs = controller.isEs;
    final header = controller.isChimeRinging
        ? AdminI18n.tr(isEs, 'New guest update', 'Nueva actualización')
        : null;
    const onDark = TextStyle(
        fontSize: 14, height: 20 / 14, color: KachavaTokens.onPrimary);
    return Container(
      key: const Key('admin-toast-banner'),
      width: double.infinity,
      color: KachavaTokens.text,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.notifications_none,
              size: 18, color: KachavaTokens.onPrimary),
          const SizedBox(width: 12),
          if (header != null) ...[
            Text(header, style: onDark.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(message,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: onDark),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            key: const Key('dismiss-alert-chime-btn'),
            style:
                TextButton.styleFrom(foregroundColor: KachavaTokens.onPrimary),
            onPressed: controller.dismissToastAndStopChime,
            icon: const Icon(Icons.volume_off_outlined, size: 18),
            label: Text(isEs ? 'Silenciar / Cerrar' : 'Mute / Dismiss'),
          ),
        ],
      ),
    );
  }
}
