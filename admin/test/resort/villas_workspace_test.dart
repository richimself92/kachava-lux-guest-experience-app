import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/application/list_query_store.dart';
import 'package:kachava_admin_dashboard/core/admin_theme.dart';
import 'package:kachava_admin_dashboard/domain/admin_villa.dart';
import 'package:kachava_admin_dashboard/presentation/components/components.dart';
import 'package:kachava_admin_dashboard/presentation/workspaces/villas_workspace.dart';

import '../support/fake_resort_repositories.dart';

Future<void> _pump(WidgetTester tester, FakeVillaRepository repo,
    {Size size = const Size(1440, 900),
    bool isEs = false,
    ListQueryStore? store}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: KachavaAdminTheme.build(),
    home: Scaffold(
      body: VillasWorkspace(
          repository: repo, queries: store ?? ListQueryStore(), isEs: isEs),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String key, String text) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.enterText(find.byKey(Key(key)), text);
  await tester.pump();
}

Future<void> _choose(WidgetTester tester, String key, String label) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _menu(WidgetTester tester, String item) async {
  await tester.tap(find.byKey(const Key('villa-actions')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key(item)));
  await tester.pumpAndSettle();
}

Future<void> _filter(WidgetTester tester, String key, String option) async {
  await tester.tap(find.byKey(Key('filter-villas-$key')));
  await tester.pumpAndSettle();
  await tester
      .tap(find.widgetWithText(CheckedPopupMenuItem<String>, option).last);
  await tester.pumpAndSettle();
}

Finder _row(String id) => find.byKey(Key('row-villas-$id'));

AdminVilla _villa(String id, String name,
        {bool isActive = true, String? guest}) =>
    AdminVilla.fromJson({
      'id': id,
      'name': name,
      'category': 'Ocean',
      'capacity': 4,
      'wifi': {'ssid': 'Ceiba-Guest', 'password': 'secret-1'},
      'operationalStatus': 'AVAILABLE',
      'housekeepingStatus': 'DIRTY',
      'maintenanceStatus': 'OK',
      'maintenanceNote': '',
      'isActive': isActive,
      'currentGuestName': guest,
    });

void main() {
  testWidgets('empty database: "No villas yet · New villa"', (tester) async {
    await _pump(tester, FakeVillaRepository());
    expect(find.text('No villas yet'), findsOneWidget);
    final empty = find.byKey(const Key('list-villas-empty'));
    expect(find.descendant(of: empty, matching: find.text('New villa')),
        findsOneWidget);
    expect(find.byKey(const Key('primary-villas')), findsOneWidget);
    expect(find.byKey(const Key('pager-villas')), findsNothing);
  });

  testWidgets('table: 6 columns, sorted by name, chips not raw enums',
      (tester) async {
    final repo = FakeVillaRepository(
        [_villa('b', 'Casa B', guest: 'Ana Ruiz'), _villa('a', 'Casa A')]);
    await _pump(tester, repo);
    final listQuery =
        repo.queries.firstWhere((q) => q != VillasWorkspace.categoriesQuery);
    expect(listQuery.sort?.wireValue, 'name:asc');
    expect(listQuery.pageSize, 25);
    final table = tester.widget<AdminDataTable<AdminVilla>>(
        find.byType(AdminDataTable<AdminVilla>));
    expect(table.columns.map((c) => c.label).toList(), [
      'Name',
      'Category',
      'Capacity',
      'Status',
      'Housekeeping',
      'Current guest',
    ]);
    expect(find.text('Available'), findsNWidgets(2));
    expect(find.text('Needs cleaning'), findsNWidgets(2));
    expect(find.text('AVAILABLE'), findsNothing);
    expect(find.text('Ana Ruiz'), findsOneWidget);
    final a = tester.getTopLeft(_row('a')).dy;
    final b = tester.getTopLeft(_row('b')).dy;
    expect(a, lessThan(b));
  });

  testWidgets('New villa: required fields, inline errors, save + toast',
      (tester) async {
    final repo = FakeVillaRepository();
    await _pump(tester, repo);
    await tester.tap(find.byKey(const Key('primary-villas')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('detail-panel-title')), findsOneWidget);
    expect(find.text('New villa'), findsWidgets);
    // Optional fields are collapsed under "More".
    expect(find.byKey(const Key('villa-wifi-ssid')), findsNothing);

    await _type(tester, 'villa-capacity', '99');
    await tester.tap(find.byKey(const Key('form-save')));
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsNWidgets(2));
    expect(find.text('1 to 50 guests'), findsOneWidget);
    expect(repo.villas, isEmpty);

    await _type(tester, 'villa-name', 'Casa Ceiba');
    await _type(tester, 'villa-category', 'Ocean view');
    await _type(tester, 'villa-capacity', '6');
    await _choose(tester, 'villa-status', 'Cleaning');
    await tester.tap(find.byKey(const Key('form-save')));
    await tester.pumpAndSettle();

    final saved = repo.villas.single;
    expect(saved.name, 'Casa Ceiba');
    expect(saved.capacity, 6);
    expect(saved.operationalStatus, 'CLEANING');
    expect(saved.housekeepingStatus, 'CLEAN');
    expect(saved.maintenanceStatus, 'OK');
    expect(find.text('Villa saved'), findsOneWidget);
    expect(find.byKey(const Key('detail-panel')), findsNothing);
    expect(_row(saved.id), findsOneWidget);
  });

  testWidgets('edit keeps unopened "More" values; Wi-Fi password is masked',
      (tester) async {
    final repo = FakeVillaRepository([_villa('v1', 'Casa Ceiba')]);
    await _pump(tester, repo);
    await tester.tap(_row('v1'));
    await tester.pumpAndSettle();
    await _type(tester, 'villa-capacity', '8');
    await tester.tap(find.byKey(const Key('form-save')));
    await tester.pumpAndSettle();
    expect(repo.villas.single.capacity, 8);
    expect(repo.villas.single.wifiSsid, 'Ceiba-Guest');
    expect(repo.villas.single.wifiPassword, 'secret-1');

    await tester.tap(_row('v1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    final password = find.descendant(
        of: find.byKey(const Key('villa-wifi-password')),
        matching: find.byType(EditableText));
    expect(tester.widget<EditableText>(password).obscureText, isTrue);
    await tester.tap(find.byKey(const Key('villa-wifi-password-toggle')));
    await tester.pump();
    expect(tester.widget<EditableText>(password).obscureText, isFalse);
    await _type(tester, 'villa-wifi-password', 'new-pass');
    await _choose(tester, 'villa-maintenance', 'Issue reported');
    await _type(tester, 'villa-maintenance-note', 'Leaking tap');
    await tester.tap(find.byKey(const Key('form-save')));
    await tester.pumpAndSettle();
    expect(repo.villas.single.wifiPassword, 'new-pass');
    expect(repo.villas.single.maintenanceStatus, 'ISSUE_REPORTED');
    expect(repo.villas.single.maintenanceNote, 'Leaking tap');
  });

  testWidgets('Deactivate asks one line, then shows "Inactive"; Activate',
      (tester) async {
    final repo = FakeVillaRepository([_villa('v1', 'Casa Ceiba')]);
    await _pump(tester, repo);
    await tester.tap(_row('v1'));
    await tester.pumpAndSettle();
    await _menu(tester, 'villa-action-deactivate');
    expect(find.text('Deactivate Casa Ceiba?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
    await tester.pumpAndSettle();
    expect(repo.villas.single.isActive, isFalse);
    expect(find.text('Villa deactivated'), findsOneWidget);
    expect(find.descendant(of: _row('v1'), matching: find.text('Inactive')),
        findsOneWidget);

    await tester.tap(_row('v1'));
    await tester.pumpAndSettle();
    await _menu(tester, 'villa-action-activate');
    await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
    await tester.pumpAndSettle();
    expect(repo.villas.single.isActive, isTrue);
  });

  testWidgets('Delete: 409 "Has stays · Deactivate instead" offers Deactivate',
      (tester) async {
    final repo = FakeVillaRepository([_villa('v1', 'Casa Ceiba')])
      ..withStays.add('v1');
    await _pump(tester, repo);
    await tester.tap(_row('v1'));
    await tester.pumpAndSettle();
    await _menu(tester, 'villa-action-delete');
    expect(find.text('Delete Casa Ceiba?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Has stays · Deactivate instead'), findsOneWidget);
    expect(repo.villas, hasLength(1));
    await tester.tap(find.widgetWithText(SnackBarAction, 'Deactivate'));
    await tester.pumpAndSettle();
    expect(repo.villas.single.isActive, isFalse);
  });

  testWidgets('Delete is allowed when the villa has no stays', (tester) async {
    final repo = FakeVillaRepository([_villa('v1', 'Casa Ceiba')]);
    await _pump(tester, repo);
    await tester.tap(_row('v1'));
    await tester.pumpAndSettle();
    await _menu(tester, 'villa-action-delete');
    await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
    await tester.pumpAndSettle();
    expect(repo.villas, isEmpty);
    expect(find.text('Villa deleted'), findsOneWidget);
    expect(find.text('No villas yet'), findsOneWidget);
  });

  testWidgets('30 villas: pages of 25, search, filters, sort by name',
      (tester) async {
    final repo = FakeVillaRepository(generatedVillas(30));
    final store = ListQueryStore();
    await _pump(tester, repo, store: store);
    expect(find.text('1–25 of 30'), findsOneWidget);
    await tester.tap(find.byKey(const Key('pager-villas-next')));
    await tester.pumpAndSettle();
    expect(find.text('26–30 of 30'), findsOneWidget);
    expect(_row('v30'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('search-villas')), 'Villa 1');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(repo.queries.last.q, 'Villa 1');
    expect(repo.queries.last.page, 1);
    expect(find.text('1–10 of 10'), findsOneWidget);
    await tester.tap(find.byKey(const Key('clear-filters-villas')));
    await tester.pumpAndSettle();

    await _filter(tester, 'operationalStatus', 'Blocked');
    expect(repo.queries.last.filters, {'operationalStatus': 'BLOCKED'});
    expect(find.text('1–6 of 6'), findsOneWidget);

    await _filter(tester, 'category', 'Garden');
    expect(repo.queries.last.filters['category'], 'Garden');

    await _filter(tester, 'isActive', 'No');
    expect(repo.queries.last.filters['isActive'], 'false');
    // The list query survives navigation (kept in the store).
    expect(store.read(VillasWorkspace.storeKey).filters, hasLength(3));

    await tester.tap(find.byKey(const Key('clear-filters-villas')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name').first);
    await tester.pumpAndSettle();
    expect(repo.queries.last.sort?.wireValue, 'name:desc');
    expect(_row('v30'), findsOneWidget);
  });

  testWidgets('375px: compact rows, full-screen sheet, Spanish chips',
      (tester) async {
    final repo = FakeVillaRepository(
        [_villa('v1', 'Casa Ceiba', guest: 'Ana'), _villa('v2', 'Casa Luna')]);
    await _pump(tester, repo, size: const Size(375, 812), isEs: true);
    expect(find.byKey(const Key('compact-villas')), findsOneWidget);
    expect(find.text('Disponible'), findsNWidgets(2));
    expect(find.text('Ocean · Ana'), findsOneWidget);
    expect(find.byKey(const Key('primary-villas')), findsOneWidget);
    await tester.tap(_row('v1'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('detail-panel')), findsOneWidget);
    expect(find.text('Capacidad *', findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed load is one line with Retry', (tester) async {
    final repo = FakeVillaRepository()..failWith = Exception('503');
    await _pump(tester, repo);
    expect(find.byKey(const Key('list-villas-error')), findsOneWidget);
    repo.failWith = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No villas yet'), findsOneWidget);
  });
}
