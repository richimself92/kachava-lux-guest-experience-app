import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../application/admin_shell_controller.dart';
import '../../core/responsive_breakpoints.dart';
import '../../core/theme/kachava_tokens.dart';
import '../navigation/admin_nav_list.dart';
import '../navigation/admin_nav_model.dart';
import '../requests/request_inbox_scope.dart';

/// Compact 72px icon rail for tablet viewports (600px–1023px).
class TabletCompactRail extends StatelessWidget {
  const TabletCompactRail({super.key, required this.controller});

  final AdminShellController controller;

  @override
  Widget build(BuildContext context) {
    final watcher = RequestInboxScope.maybeOf(context)?.watcher;
    if (watcher == null) return _rail(context);
    return ListenableBuilder(
        listenable: watcher, builder: (context, _) => _rail(context));
  }

  Widget _rail(BuildContext context) {
    final groups = [
      AdminNavModel.topItems,
      for (final section in AdminNavModel.visibleSections()) section.items,
    ];
    return Container(
      key: const Key('tablet-compact-rail'),
      width: AdminBreakpoints.leftRailTabletWidth,
      decoration: const BoxDecoration(
        color: KachavaTokens.paper,
        border: Border(right: BorderSide(color: KachavaTokens.line)),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          for (var g = 0; g < groups.length; g++) ...[
            if (g > 0) const Divider(height: 17, indent: 16, endIndent: 16),
            for (final item in groups[g]) _railButton(context, item),
          ],
        ],
      ),
    );
  }

  static BorderSide _rule(bool selected) =>
      BorderSide(color: selected ? KachavaTokens.brand : Colors.transparent);

  /// Plain tabular count in pending (badge theme), no pill.
  Widget _railIcon(BuildContext context, AdminNavItem item, bool selected) {
    final count = navBadgeFor(context, item) ?? 0;
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      child: Icon(item.icon,
          color: selected ? KachavaTokens.ink : KachavaTokens.muted),
    );
  }

  Widget _railButton(BuildContext context, AdminNavItem item) {
    final selected =
        AdminNavModel.itemForWorkspace(controller.activeTab)?.id == item.id;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Center(
        // Selected = wash + 1px brand rule on the left edge, square corners.
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(left: _rule(selected)),
          ),
          child: IconButton(
            key: Key('nav-tab-${item.workspace!.id}'),
            tooltip: item.label(controller.isEs),
            isSelected: selected,
            style: IconButton.styleFrom(
              fixedSize: const Size(48, 48),
              backgroundColor: selected ? KachavaTokens.wash : null,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(KachavaTokens.radius)),
            ),
            onPressed: () => controller.selectTab(item.workspace!),
            icon: _railIcon(context, item, selected),
          ),
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
      backgroundColor: KachavaTokens.paper,
      shape: const RoundedRectangleBorder(),
      // As wide as its content: min(18rem, 85vw).
      width: math.min(288, MediaQuery.sizeOf(context).width * 0.85),
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
