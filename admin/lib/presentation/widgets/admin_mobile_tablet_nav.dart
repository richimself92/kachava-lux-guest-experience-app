import 'package:flutter/material.dart';
import '../../application/admin_shell_controller.dart';
import '../../core/responsive_breakpoints.dart';
import '../../core/theme/kachava_tokens.dart';
import '../navigation/admin_nav_list.dart';
import '../navigation/admin_nav_model.dart';

/// Compact 72px icon rail for tablet viewports (600px–1023px).
class TabletCompactRail extends StatelessWidget {
  const TabletCompactRail({super.key, required this.controller});

  final AdminShellController controller;

  @override
  Widget build(BuildContext context) {
    final groups = [
      [AdminNavModel.dashboard],
      for (final section in AdminNavModel.visibleSections()) section.items,
    ];
    return Container(
      key: const Key('tablet-compact-rail'),
      width: AdminBreakpoints.leftRailTabletWidth,
      decoration: const BoxDecoration(
        color: KachavaTokens.background,
        border: Border(right: BorderSide(color: KachavaTokens.border)),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          for (var g = 0; g < groups.length; g++) ...[
            if (g > 0) const Divider(height: 17, indent: 16, endIndent: 16),
            for (final item in groups[g]) _railButton(item),
          ],
        ],
      ),
    );
  }

  Widget _railButton(AdminNavItem item) {
    final selected =
        AdminNavModel.itemForWorkspace(controller.activeTab)?.id == item.id;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Center(
        child: IconButton(
          key: Key('nav-tab-${item.workspace!.id}'),
          tooltip: item.label(controller.isEs),
          isSelected: selected,
          style: IconButton.styleFrom(
            fixedSize: const Size(48, 48),
            backgroundColor: selected ? KachavaTokens.primarySelected : null,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KachavaTokens.radiusLg)),
          ),
          onPressed: () => controller.selectTab(item.workspace!),
          icon: Icon(item.icon,
              color: selected
                  ? KachavaTokens.primary
                  : KachavaTokens.textSecondary),
        ),
      ),
    );
  }
}

/// Mobile (< 600px) navigation drawer with the same content as the sidebar.
class AdminMobileNavDrawer extends StatelessWidget {
  const AdminMobileNavDrawer({super.key, required this.controller});

  final AdminShellController controller;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      key: const Key('mobile-nav-drawer'),
      backgroundColor: KachavaTokens.background,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: AdminNavList(
          activeTab: controller.activeTab,
          isEs: controller.isEs,
          onSelect: (tab) {
            controller.selectTab(tab);
            Scaffold.of(context).closeDrawer();
          },
        ),
      ),
    );
  }
}
