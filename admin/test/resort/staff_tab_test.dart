import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/application/resort_settings_controller.dart';
import 'package:kachava_admin_dashboard/core/admin_theme.dart';
import 'package:kachava_admin_dashboard/domain/staff_member.dart';
import 'package:kachava_admin_dashboard/presentation/workspaces/settings_workspace.dart';

import '../support/fake_resort_repositories.dart';
import '../support/fake_staff_roster.dart';

void main() {
  late FakeStaffRoster roster;
  late int changes;

  setUp(() {
    roster = FakeStaffRoster();
    changes = 0;
  });

  Future<void> pumpStaff(WidgetTester tester,
      {Size size = const Size(1440, 900),
      bool isEs = false,
      bool wired = true}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings = ResortSettingsController(FakeSettingsRepository());
    addTearDown(settings.dispose);
    await settings.load();
    await tester.pumpWidget(MaterialApp(
      theme: KachavaAdminTheme.build(),
      home: Scaffold(
        body: SettingsWorkspace(
          settings: settings,
          timeZones: testTimeZones,
          isEs: isEs,
          staff: wired ? roster : null,
          onStaffChanged: () => changes++,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-form')), findsOneWidget);
    await tester.tap(find.byKey(const Key('settings-tab-staff')));
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester, String key, String text) async {
    await tester.enterText(find.byKey(Key(key)), text);
    await tester.pump();
  }

  Future<void> choose(WidgetTester tester, String key, String option) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  testWidgets('roster table: 6 columns, name order, empty line',
      (tester) async {
    await pumpStaff(tester);
    expect(find.text('No staff yet'), findsOneWidget);

    roster.staff.addAll([testMember(2), testMember(1, isActive: false)]);
    await tester.tap(find.byKey(const Key('settings-tab-general')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-tab-staff')));
    await tester.pumpAndSettle();

    for (final h in [
      'Name',
      'Role',
      'Department',
      'Email',
      'Phone',
      'Active'
    ]) {
      expect(find.text(h), findsWidgets, reason: h);
    }
    expect(roster.queries.last.sort?.wireValue, 'fullName:asc');
    expect(find.text('Member 1'), findsOneWidget);
    expect(find.text('member2@test.local'), findsOneWidget);
    expect(find.text('Resort Host'), findsWidgets);
    expect(find.text('Inactive'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('create: required fields, then saved and pickers reloaded',
      (tester) async {
    await pumpStaff(tester);
    await tester.tap(find.byKey(const Key('primary-staff')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(roster.created, isEmpty);
    expect(find.text('Required'), findsWidgets);

    await fill(tester, 'staff-name', 'Lucia Perez');
    await choose(tester, 'staff-role', 'Coordinator');
    await choose(tester, 'staff-department', 'Culinary');
    await fill(tester, 'staff-email', 'lucia@resort');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email'), findsOneWidget);

    await fill(tester, 'staff-email', 'lucia@resort.test');
    await fill(tester, 'staff-phone', '+52 998');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final m = roster.created.single;
    expect(m.fullName, 'Lucia Perez');
    expect(m.rbacRole, StaffRole.departmentCoordinator);
    expect(m.department, StaffDepartment.culinary);
    expect(m.email, 'lucia@resort.test');
    expect(m.phone, '+52 998');
    expect(changes, 1);
    expect(find.text('Staff saved'), findsOneWidget);
    expect(find.text('Lucia Perez'), findsOneWidget);
  });

  testWidgets('a used email keeps the form open with one line', (tester) async {
    roster.staff.add(testMember(1));
    await pumpStaff(tester);
    await tester.tap(find.byKey(const Key('primary-staff')));
    await tester.pumpAndSettle();
    await fill(tester, 'staff-name', 'Other');
    await choose(tester, 'staff-role', 'Host admin');
    await choose(tester, 'staff-department', 'Wellness');
    await fill(tester, 'staff-email', 'member1@test.local');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Email already used'), findsOneWidget);
    expect(changes, 0);
  });

  testWidgets('edit and deactivate from the detail', (tester) async {
    roster.staff.add(testMember(1));
    await pumpStaff(tester);
    await tester.tap(find.byKey(const Key('row-staff-staff_1')));
    await tester.pumpAndSettle();

    await fill(tester, 'staff-name', 'Member One');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(roster.updated.single.fullName, 'Member One');
    expect(roster.updated.single.staffId, 'staff_1');

    await tester.tap(find.byKey(const Key('row-staff-staff_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('staff-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('staff-action-deactivate')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deactivate').last);
    await tester.pumpAndSettle();

    expect(roster.activations.single, ('staff_1', false));
    expect(changes, 2);
    expect(find.text('Staff deactivated'), findsOneWidget);
    expect(find.text('Inactive'), findsOneWidget);
  });

  testWidgets('mobile 375 and Spanish: compact rows, no overflow',
      (tester) async {
    roster.staff.add(testMember(1, department: StaffDepartment.housekeeping));
    await pumpStaff(tester, size: const Size(375, 812), isEs: true);

    expect(find.text('Member 1'), findsOneWidget);
    expect(find.text('Resort Host · Limpieza'), findsOneWidget);
    expect(find.text('Personal'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('without a roster the tab shows one error line', (tester) async {
    await pumpStaff(tester, wired: false);
    expect(find.byKey(const Key('staff-not-connected')), findsOneWidget);
  });
}
