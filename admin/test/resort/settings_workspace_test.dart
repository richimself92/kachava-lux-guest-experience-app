import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/application/resort_settings_controller.dart';
import 'package:kachava_admin_dashboard/core/admin_theme.dart';
import 'package:kachava_admin_dashboard/domain/admin_settings.dart';
import 'package:kachava_admin_dashboard/presentation/workspaces/settings_workspace.dart';

import '../support/fake_resort_repositories.dart';

Future<ResortSettingsController> _pump(WidgetTester tester,
    {FakeSettingsRepository? repo,
    bool isEs = false,
    Size size = const Size(1440, 900)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final controller = ResortSettingsController(repo ?? FakeSettingsRepository());
  addTearDown(controller.dispose);
  await controller.load();
  await tester.pumpWidget(MaterialApp(
    theme: KachavaAdminTheme.build(),
    home: Scaffold(
      body: SettingsWorkspace(
          settings: controller, timeZones: testTimeZones, isEs: isEs),
    ),
  ));
  await tester.pumpAndSettle();
  return controller;
}

Finder _input(String key) => find.descendant(
    of: find.byKey(Key(key)), matching: find.byType(EditableText));

Future<void> _type(WidgetTester tester, String key, String text) async {
  await tester.enterText(find.byKey(Key(key)), text);
  await tester.pump();
}

Future<void> _pickZone(WidgetTester tester, String query, String zone) async {
  await tester.tap(find.byKey(const Key('settings-time-zone')));
  await tester.pumpAndSettle();
  await tester.enterText(_input('settings-time-zone'), query);
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(MenuItemButton, zone).last);
  await tester.pumpAndSettle();
}

Future<void> _addAirport(
    WidgetTester tester, String code, String name, String hours) async {
  final add = find.byKey(const Key('settings-airport-add'));
  await tester.tap(add.evaluate().isEmpty
      ? find.descendant(
          of: find.byKey(const Key('settings-airports-empty')),
          matching: find.byType(OutlinedButton))
      : add);
  await tester.pumpAndSettle();
  await _type(tester, 'airport-code', code);
  await _type(tester, 'airport-name', name);
  await _type(tester, 'airport-buffer', hours);
  await tester.tap(find.byKey(const Key('airport-dialog-save')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an empty database shows "Not set" and one airports line',
      (tester) async {
    await _pump(tester);
    expect(find.text('Settings'), findsOneWidget);
    // check-in, check-out, alert lead (text fields) + time zone (menu).
    expect(find.text('Not set'), findsNWidgets(4));
    expect(find.text('No airports'), findsOneWidget);
    expect(find.text('Add airport'), findsOneWidget);
    expect(find.byKey(const Key('settings-save')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('inputs side by side share one top edge (with or without ⓘ)',
      (tester) async {
    await _pump(tester);
    final tops = [
      for (final key in [
        'settings-check-in',
        'settings-check-out',
        'settings-alert-lead',
      ])
        tester.getTopLeft(find.byKey(Key(key))).dy,
    ];
    expect(tops.toSet(), hasLength(1), reason: '$tops');
  });

  testWidgets('inline validation blocks Save (<= 5 words)', (tester) async {
    final repo = FakeSettingsRepository();
    await _pump(tester, repo: repo);
    await _type(tester, 'settings-check-in', '25:00');
    await _type(tester, 'settings-alert-lead', '500');
    await tester.tap(find.byKey(const Key('settings-save')));
    await tester.pumpAndSettle();
    expect(find.text('Use HH:mm'), findsOneWidget);
    expect(find.text('1 to 168 hours'), findsOneWidget);
    expect(repo.updates, isEmpty);
  });

  testWidgets('a typed zone that is not listed is refused', (tester) async {
    final repo = FakeSettingsRepository();
    await _pump(tester, repo: repo);
    await tester.tap(find.byKey(const Key('settings-time-zone')));
    await tester.pumpAndSettle();
    await tester.enterText(_input('settings-time-zone'), 'Mars/Olympus');
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(1400, 880));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-save')));
    await tester.pumpAndSettle();
    expect(find.text('Pick a listed zone'), findsOneWidget);
    expect(repo.updates, isEmpty);
  });

  testWidgets('configures every value, saves once and confirms in one line',
      (tester) async {
    final repo = FakeSettingsRepository();
    final controller = await _pump(tester, repo: repo);
    await _type(tester, 'settings-check-in', '15:00');
    await _type(tester, 'settings-check-out', '11:00');
    await _pickZone(tester, 'cancun', 'America/Cancun');
    await _type(tester, 'settings-alert-lead', '24');
    await _addAirport(tester, 'cun', 'Cancun International', '3');
    await _addAirport(tester, 'TQO', 'Tulum', '2.5');
    expect(find.byKey(const Key('settings-airport-CUN')), findsOneWidget);
    expect(find.text('2.5 h'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-save')));
    await tester.pumpAndSettle();
    final saved = repo.updates.single;
    expect(saved.checkInTime, '15:00');
    expect(saved.checkOutTime, '11:00');
    expect(saved.timeZone, 'America/Cancun');
    expect(saved.transportAlertLeadHours, 24);
    expect(saved.airports.map((a) => a.code), ['CUN', 'TQO']);
    expect(saved.airports.first.departureBufferHours, 3);
    expect(find.text('Settings saved'), findsOneWidget);
    expect(controller.isMissing(ResortSetting.timeZone), isFalse);
  });

  testWidgets('airports: duplicate code, edit, deactivate and remove',
      (tester) async {
    final repo = FakeSettingsRepository(const AdminSettings(airports: [
      AirportSetting(code: 'CUN', name: 'Cancun', departureBufferHours: 3),
    ]));
    await _pump(tester, repo: repo);
    expect(find.text('3 h'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-airport-add')));
    await tester.pumpAndSettle();
    await _type(tester, 'airport-code', 'CUN');
    await _type(tester, 'airport-name', 'Again');
    await _type(tester, 'airport-buffer', '30');
    await tester.tap(find.byKey(const Key('airport-dialog-save')));
    await tester.pumpAndSettle();
    expect(find.text('Code already added'), findsOneWidget);
    expect(find.text('0 to 24 hours'), findsOneWidget);
    await tester.tap(find.byKey(const Key('airport-dialog-cancel')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-airport-CUN-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await _type(tester, 'airport-buffer', '4');
    await tester.tap(find.byKey(const Key('airport-dialog-save')));
    await tester.pumpAndSettle();
    expect(find.text('4 h'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-airport-CUN-active')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-save')));
    await tester.pumpAndSettle();
    expect(repo.updates.last.airports.single.isActive, isFalse);
    expect(repo.updates.last.airports.single.departureBufferHours, 4);

    await tester.tap(find.byKey(const Key('settings-airport-CUN-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Remove CUN?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('No airports'), findsOneWidget);
  });

  testWidgets('a clear field is sent as null (not configured)', (tester) async {
    final repo = FakeSettingsRepository(
        const AdminSettings(checkInTime: '15:00', timeZone: 'UTC'));
    await _pump(tester, repo: repo);
    await _type(tester, 'settings-check-in', '');
    await tester.tap(find.byKey(const Key('settings-save')));
    await tester.pumpAndSettle();
    expect(repo.updates.single.checkInTime, isNull);
    expect(repo.updates.single.timeZone, 'UTC');
  });

  testWidgets('a failed save keeps the values and offers Retry',
      (tester) async {
    final repo = FakeSettingsRepository()..failUpdate = Exception('500');
    await _pump(tester, repo: repo);
    await _type(tester, 'settings-check-in', '14:00');
    await tester.tap(find.byKey(const Key('settings-save')));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't save"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('14:00'), findsOneWidget);
  });

  testWidgets('a failed load is one line with Retry', (tester) async {
    final repo = FakeSettingsRepository()..failFetch = Exception('503');
    await _pump(tester, repo: repo);
    expect(find.byKey(const Key('settings-error')), findsOneWidget);
    repo.failFetch = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-form')), findsOneWidget);
  });

  testWidgets('Spanish labels and 375px without overflow', (tester) async {
    await _pump(tester, isEs: true, size: const Size(375, 812));
    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Zona horaria'), findsOneWidget);
    expect(find.text('Sin aeropuertos'), findsOneWidget);
    expect(find.text('Sin configurar'), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });
}
