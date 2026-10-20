import 'package:flutter/material.dart';
import '../../application/admin_dashboard_controller.dart';
import '../../core/admin_i18n.dart';
import '../../core/admin_theme.dart';
import '../../core/responsive_breakpoints.dart';
import '../../domain/admin_enums.dart';
export 'admin_mobile_tablet_nav.dart';

/// Resolves the Material icon for each of the 6 Admin workspace tabs.
IconData iconForWorkspaceTab(AdminWorkspaceTab tab) {
  switch (tab) {
    case AdminWorkspaceTab.adminOverview:
      return Icons.notifications_active_outlined;
    case AdminWorkspaceTab.adminStays:
      return Icons.vpn_key_outlined;
    case AdminWorkspaceTab.adminExperiences:
      return Icons.sailing_outlined;
    case AdminWorkspaceTab.adminLarder:
      return Icons.kitchen_outlined;
    case AdminWorkspaceTab.adminConcierge:
      return Icons.support_agent_outlined;
    case AdminWorkspaceTab.adminFolio:
      return Icons.receipt_long_outlined;
  }
}

/// Resolves the live badge counter for each workspace tab.
int badgeCountForTab(
  AdminDashboardController controller,
  AdminWorkspaceTab tab,
) {
  switch (tab) {
    case AdminWorkspaceTab.adminOverview:
      return controller.unreadAlertsCount;
    case AdminWorkspaceTab.adminStays:
      return controller.stays.length;
    case AdminWorkspaceTab.adminExperiences:
      return controller.bookings.where((b) => b.status == 'Requested').length;
    case AdminWorkspaceTab.adminLarder:
      return controller.larderOrders
          .where((o) => o.status != 'Stocked in Villa')
          .length;
    case AdminWorkspaceTab.adminConcierge:
      return controller.openConciergeCount;
    case AdminWorkspaceTab.adminFolio:
      return controller.midStayPulses.where((p) => p.status == 'OPEN').length;
  }
}

/// Persistent 260px left sidebar for Desktop Command Center (>= 1024px).
class DesktopCommandSidebar extends StatelessWidget {
  const DesktopCommandSidebar({super.key, required this.controller});

  final AdminDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('desktop-sidebar'),
      width: AdminBreakpoints.leftRailDesktopWidth,
      decoration: const BoxDecoration(
        color: KachavaAdminColors.surfaceContainer,
        border: Border(
          right: BorderSide(color: KachavaAdminColors.borderLimestone),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBrandHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: AdminWorkspaceTab.values
                  .map((tab) => _buildNavTile(tab))
                  .toList(),
            ),
          ),
          _buildStaffFooter(),
        ],
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: KachavaAdminColors.borderLimestone),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KACHAVA LUX',
            style: TextStyle(
              fontFamily: 'Libre Baskerville',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: KachavaAdminColors.zapotePrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AdminI18n.tr(
              controller.isEs,
              'HOST ADMIN · COMMAND CENTER',
              'HOST ADMIN · PANEL DE CONTROL',
            ),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: KachavaAdminColors.mutedBronze,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile(AdminWorkspaceTab tab) {
    final isSelected = controller.activeTab == tab;
    final count = badgeCountForTab(controller, tab);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        key: Key('nav-tab-${tab.id}'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => controller.selectTab(tab),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected
                ? KachavaAdminColors.zapotePrimary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                iconForWorkspaceTab(tab),
                size: 18,
                color: isSelected
                    ? Colors.white
                    : KachavaAdminColors.zapotePrimary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AdminI18n.tabLabel(tab, controller.isEs),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color:
                        isSelected ? Colors.white : KachavaAdminColors.obsidian,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? KachavaAdminColors.copalGold
                      : KachavaAdminColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? KachavaAdminColors.obsidian
                        : KachavaAdminColors.zapotePrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaffFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: KachavaAdminColors.surfacePaper,
        border: Border(
          top: BorderSide(color: KachavaAdminColors.borderLimestone),
        ),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: KachavaAdminColors.zapotePrimary,
            child: Icon(Icons.verified_user, size: 16, color: Colors.white),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HOST ADMIN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: KachavaAdminColors.obsidian,
                  ),
                ),
                Text(
                  'SANCTUARY COMMAND · ONLINE',
                  style: TextStyle(
                    fontSize: 10,
                    color: KachavaAdminColors.neutralMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
