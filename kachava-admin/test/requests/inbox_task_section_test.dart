import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/core/admin_theme.dart';
import 'package:kachava_admin_dashboard/domain/admin_task.dart';
import 'package:kachava_admin_dashboard/domain/inbox_item.dart';
import 'package:kachava_admin_dashboard/presentation/requests/inbox_task_section.dart';

import '../support/fake_operations.dart';
import '../support/fake_service_requests.dart';

void main() {
  late FakeTaskRepository tasks;
  late FakeServiceRequestRepository requests;
  late List<String> opened;
  final item = RequestInboxItem(testRequest(1, usageType: 'PREFERENCE'));

  setUp(() {
    tasks = FakeTaskRepository();
    requests = FakeServiceRequestRepository();
    opened = [];
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: KachavaAdminTheme.build(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: InboxTaskSection(
            item: item,
            tasks: tasks,
            staff: const [testStaff],
            isEs: false,
            onOpenTask: opened.add,
            onCreateTask: (i) => requests.ensureTask(i.id),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('test_linkedTask_showsStatusOwner_openTask_andAssign',
      (tester) async {
    tasks.tasks.add(AdminTask(
        id: item.taskId,
        title: 'Prepare: Pillow menu',
        category: 'IN_VILLA',
        priority: 'NORMAL',
        status: TaskValues.pending,
        overdue: false));
    await pump(tester);

    expect(find.byKey(const Key('inbox-task-status')), findsOneWidget);
    await tester.tap(find.byKey(const Key('inbox-open-task')));
    expect(opened, [item.taskId]);

    await tester.tap(find.byKey(const Key('inbox-assign')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('inbox-assign-owner')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(testStaff.fullName).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('inbox-assign-confirm')));
    await tester.pumpAndSettle();

    expect(tasks.moves.single.$2['to'], TaskValues.assigned);
    expect(find.text(testStaff.fullName), findsOneWidget);
    expect(find.byKey(const Key('inbox-assign')), findsNothing);
  });

  testWidgets('test_noTask_createTask_callsTheServer', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('inbox-create-task')));
    await tester.pumpAndSettle();

    expect(requests.ensuredTasks, ['req_1']);
    expect(find.byKey(const Key('inbox-task-status')), findsOneWidget);
  });
}
