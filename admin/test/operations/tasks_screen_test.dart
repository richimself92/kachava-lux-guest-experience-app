import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/application/list_query_store.dart';
import 'package:kachava_admin_dashboard/core/admin_theme.dart';
import 'package:kachava_admin_dashboard/core/resort_time.dart';
import 'package:kachava_admin_dashboard/domain/admin_task.dart';
import 'package:kachava_admin_dashboard/presentation/components/components.dart';
import 'package:kachava_admin_dashboard/presentation/operations/tasks/tasks_screen.dart';

import '../support/fake_operations.dart';
import 'recorded_operations_contract.dart';

void main() {
  late FakeTaskRepository tasks;
  late FakeReservationRepository stays;

  setUp(() {
    tasks = FakeTaskRepository()
      ..tasks.addAll([
        AdminTask.fromJson(recordedTask),
        AdminTask.fromJson({
          ...recordedTask,
          'id': 'task_2',
          'title': 'Stock fruit',
          'overdue': false,
          'status': 'IN_PROGRESS',
          'ownerStaffId': 'stf_1',
          'ownerName': 'Lucia Host',
        }),
      ]);
    stays = FakeReservationRepository();
  });

  Future<void> pump(WidgetTester tester, {String? openId}) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: KachavaAdminTheme.build(),
      home: Scaffold(
        body: TasksScreen(
          tasks: tasks,
          stays: stays,
          queries: ListQueryStore(),
          staff: const [testStaff],
          resortTime: const ResortTime(
              timeZone: 'America/Cancun',
              resolver: FixedOffsetResolver(Duration(hours: -5))),
          isEs: false,
          openId: openId,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester, String id) async {
    await tester.tap(find.byKey(Key('row-tasks-$id')));
    await tester.pumpAndSettle();
  }

  testWidgets('table: columns, due sort, overdue chip, filters',
      (tester) async {
    await pump(tester);
    for (final h in ['Title', 'Villa / Guest', 'Owner', 'Priority', 'Due']) {
      expect(find.text(h), findsWidgets, reason: h);
    }
    expect(tasks.queries.first.sort?.wireValue, 'dueAt:asc');
    final overdue =
        tester.widget<StatusChip>(find.byKey(const Key('task-overdue-task_1')));
    expect((overdue.label, overdue.tone), ('Overdue', StatusTone.error));
    expect(find.byKey(const Key('task-overdue-task_2')), findsNothing);
    expect(find.text('Nov 3 · 18:00'), findsWidgets);
    // <= 3 inline filters; "Overdue" lives in the Filters menu.
    for (final f in ['status', 'priority', 'owner']) {
      expect(find.byKey(Key('filter-tasks-$f')), findsOneWidget, reason: f);
    }
  });

  testWidgets('Assign needs an owner', (tester) async {
    await pump(tester);
    await open(tester, 'task_1');
    expect(find.text('Assign'), findsOneWidget);
    await tester.tap(find.byKey(const Key('task-next-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task-assign-confirm')));
    await tester.pumpAndSettle();
    expect(tasks.moves, isEmpty, reason: 'no owner picked');

    await tester.tap(find.byKey(const Key('task-next-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task-assign-owner')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lucia Host').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task-assign-confirm')));
    await tester.pumpAndSettle();
    expect(tasks.moves.single.$2,
        {'to': 'ASSIGNED', 'ownerStaffId': 'stf_1', 'ownerName': 'Lucia Host'});
    expect(find.text('Start'), findsOneWidget);
  });

  testWidgets('Complete needs a note', (tester) async {
    await pump(tester);
    await open(tester, 'task_2');
    expect(find.text('Complete'), findsWidgets);
    await tester.tap(find.byKey(const Key('task-next-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('input-dialog-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsOneWidget);
    await tester.enterText(
        find.byKey(const Key('task-complete-note')), 'Fruit bowl placed');
    await tester.tap(find.byKey(const Key('input-dialog-confirm')));
    await tester.pumpAndSettle();
    expect(tasks.moves.single.$2,
        {'to': 'COMPLETED', 'note': 'Fruit bowl placed'});
    expect(find.byKey(const Key('task-next-action')), findsNothing);
  });

  testWidgets('+ New task: title and category required, then POST',
      (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('primary-tasks')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('form-save')));
    await tester.pumpAndSettle();
    expect(tasks.creates, isEmpty);
    await tester.enterText(find.byKey(const Key('task-title')), 'Towels');
    await tester.enterText(
        find.byKey(const Key('task-category')), 'Housekeeping');
    await tester.enterText(
        find.byKey(const Key('task-due')), '2026-11-03 18:00');
    await tester.tap(find.byKey(const Key('form-save')));
    await tester.pumpAndSettle();
    expect(tasks.creates.single, {
      'title': 'Towels',
      'category': 'Housekeeping',
      'priority': 'NORMAL',
      'dueAt': '2026-11-03T18:00',
    });
  });

  testWidgets('openId opens the task detail', (tester) async {
    await pump(tester, openId: 'task_2');
    expect(find.byKey(const Key('task-detail')), findsOneWidget);
  });
}
