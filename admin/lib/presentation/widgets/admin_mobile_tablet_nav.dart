import 'package:flutter/material.dart';
import '../../application/admin_dashboard_controller.dart';
import '../../core/admin_i18n.dart';
import '../../core/admin_theme.dart';
import '../../core/responsive_breakpoints.dart';
import '../../domain/admin_enums.dart';
import 'admin_navigation_bars.dart';

/// Compact 72px NavigationRail for Tablet Viewports (600px–1023px).
class TabletCompactRail extends StatelessWidget {
  const TabletCompactRail({super.key, required this.controller});

  final AdminDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('tablet-compact-rail'),
      width: AdminBreakpoints.leftRailTabletWidth,
      decoration: const BoxDecoration(
        color: KachavaAdminColors.surfaceContainer,
        border: Border(
          right: BorderSide(color: KachavaAdminColors.borderLimestone),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Icon(Icons.spa, color: KachavaAdminColors.zapotePrimary),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: AdminWorkspaceTab.values.map((tab) {
                final selected = controller.activeTab == tab;
                return IconButton(
                  key: Key('nav-tab-${tab.id}'),
                  tooltip: AdminI18n.tabLabel(tab, controller.isEs),
                  onPressed: () => controller.selectTab(tab),
                  icon: Icon(
                    iconForWorkspaceTab(tab),
                    color: selected
                        ? KachavaAdminColors.zapotePrimary
                        : KachavaAdminColors.neutralMuted,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Adaptive bottom navigation bar for Mobile Roaming Host viewports (< 600px).
class MobileCommandBottomNav extends StatelessWidget {
  const MobileCommandBottomNav({super.key, required this.controller});

  final AdminDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('mobile-bottom-nav'),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: const BoxDecoration(
        color: KachavaAdminColors.surfacePaper,
        border: Border(
          top: BorderSide(color: KachavaAdminColors.borderLimestone),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: AdminWorkspaceTab.values.map((tab) {
            final selected = controller.activeTab == tab;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                key: Key('nav-tab-${tab.id}'),
                label: Text(AdminI18n.tabShortLabel(tab, controller.isEs)),
                selected: selected,
                onSelected: (_) => controller.selectTab(tab),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
