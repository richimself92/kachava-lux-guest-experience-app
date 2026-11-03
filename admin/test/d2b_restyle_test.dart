import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/seeded_admin_repository.dart';
import 'package:kachava_admin_dashboard/domain/admin_enums.dart';
import 'package:kachava_admin_dashboard/main.dart';
import 'package:kachava_admin_dashboard/presentation/admin_command_shell.dart';
import 'package:kachava_admin_dashboard/presentation/components/components.dart';
import 'support/fake_resort_repositories.dart';

/// Track D2b: clean-UI restyle of Services, Experiences, Tasks and Stay summary.
void main() {
  Future<AdminCommandShell> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(KachavaAdminApp(
        resort: fakeResortRepositories(),
        timeZones: testTimeZones,
        repository: SeededAdminRepository()));
    await tester.pumpAndSettle();
    return tester.widget<AdminCommandShell>(find.byType(AdminCommandShell));
  }

  Finder inWorkspace(String id, Finder matching) =>
      find.descendant(of: find.byKey(Key('workspace-$id')), matching: matching);

  Future<void> openTab(WidgetTester tester, AdminCommandShell shell,
      AdminWorkspaceTab tab) async {
    shell.controller.selectTab(tab);
    await tester.pumpAndSettle();
  }

  void expectNoEyebrows(String id) {
    for (final eyebrow in [
      'FR-1',
      'LIVE ',
      'CATALOG',
      '·  FR',
      'PROVISIONING'
    ]) {
      expect(inWorkspace(id, find.textContaining(eyebrow)), findsNothing,
          reason: 'eyebrow "$eyebrow" should be gone from $id');
    }
  }

  testWidgets('test_services_pageHeaderAndNoEyebrows', (tester) async {
    final shell = await pumpApp(tester);
    await openTab(tester, shell, AdminWorkspaceTab.adminLarder);

    expect(
        inWorkspace('admin-larder', find.byType(PageHeader)), findsOneWidget);
    expect(inWorkspace('admin-larder', find.text('Services')), findsOneWidget);
    expect(inWorkspace('admin-larder', find.byType(StatusChip)), findsWidgets);
    expectNoEyebrows('admin-larder');
    // The legacy catalog (removed `/admin/catalog/*`) has no add button.
    expect(find.byKey(const Key('add-catalog-larder-btn')), findsNothing);
  });

  testWidgets('test_experiences_pageHeaderAndNoEyebrows', (tester) async {
    final shell = await pumpApp(tester);
    await openTab(tester, shell, AdminWorkspaceTab.adminExperiences);

    expect(inWorkspace('admin-experiences', find.text('Experiences')),
        findsOneWidget);
    expect(inWorkspace('admin-experiences', find.byType(StatusChip)),
        findsWidgets);
    expectNoEyebrows('admin-experiences');
    expect(find.byKey(const Key('add-catalog-experience-btn')), findsNothing);
  });

  testWidgets('test_tasks_titleAndResortHostInsteadOfConcierge',
      (tester) async {
    final shell = await pumpApp(tester);
    await openTab(tester, shell, AdminWorkspaceTab.adminConcierge);

    expect(inWorkspace('admin-concierge', find.text('Tasks')), findsOneWidget);
    expect(inWorkspace('admin-concierge', find.textContaining('Concierge')),
        findsNothing);
    expect(inWorkspace('admin-concierge', find.textContaining('HOST ADMIN...')),
        findsNothing);
    expect(
        inWorkspace(
            'admin-concierge', find.bySemanticsLabel(RegExp('Resort Host'))),
        findsWidgets);
    expectNoEyebrows('admin-concierge');
  });

  testWidgets('test_tasks_spanishTitle', (tester) async {
    final shell = await pumpApp(tester);
    await tester.tap(find.byKey(const Key('admin-locale-toggle-btn')));
    await tester.pumpAndSettle();
    await openTab(tester, shell, AdminWorkspaceTab.adminConcierge);

    expect(inWorkspace('admin-concierge', find.text('Tareas')), findsOneWidget);
  });

  testWidgets('test_staySummary_backButtonReturnsToReservations',
      (tester) async {
    final shell = await pumpApp(tester);
    await openTab(tester, shell, AdminWorkspaceTab.adminFolio);

    expect(
        inWorkspace('admin-folio', find.text('Stay summary')), findsOneWidget);
    expectNoEyebrows('admin-folio');
    final back = find.byKey(const Key('stay-summary-back-btn'));
    expect(back, findsOneWidget);
    expect(find.descendant(of: back, matching: find.text('Reservations')),
        findsOneWidget);

    await tester.tap(back);
    await tester.pumpAndSettle();

    expect(shell.controller.activeTab, AdminWorkspaceTab.adminStays);
    expect(find.byKey(const Key('workspace-admin-stays')), findsOneWidget);
  });
}
