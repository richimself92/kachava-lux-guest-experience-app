import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/domain/admin_enums.dart';
import 'package:kachava_admin_dashboard/presentation/admin_command_shell.dart';

/// Opens [tab] through the controller. The legacy Services/Larder and
/// Experiences workspaces are hidden from the menu until Phase 4 but still
/// reachable from alerts, so their tests open them this way.
Future<void> openWorkspace(WidgetTester tester, AdminWorkspaceTab tab) async {
  tester
      .widget<AdminCommandShell>(find.byType(AdminCommandShell))
      .controller
      .selectTab(tab);
  await tester.pumpAndSettle();
}
