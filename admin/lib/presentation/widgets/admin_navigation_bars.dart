import 'package:flutter/material.dart';
import '../../application/admin_shell_controller.dart';
import '../../core/responsive_breakpoints.dart';
import '../../core/theme/kachava_tokens.dart';
import '../navigation/admin_nav_list.dart';
export 'admin_mobile_tablet_nav.dart';

/// Persistent left sidebar for desktop (>= 1024px), per the client mockup.
class DesktopCommandSidebar extends StatelessWidget {
  const DesktopCommandSidebar({super.key, required this.controller});

  static const double width = AdminBreakpoints.leftRailDesktopWidth;

  final AdminShellController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('desktop-sidebar'),
      width: width,
      decoration: const BoxDecoration(
        color: KachavaTokens.background,
        border: Border(right: BorderSide(color: KachavaTokens.border)),
      ),
      child: AdminNavList(
        activeTab: controller.activeTab,
        isEs: controller.isEs,
        onSelect: controller.selectTab,
      ),
    );
  }
}
