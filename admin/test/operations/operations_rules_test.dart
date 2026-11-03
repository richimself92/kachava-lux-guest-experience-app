import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/application/admin_shell_controller.dart';
import 'package:kachava_admin_dashboard/core/stay_strings.dart';
import 'package:kachava_admin_dashboard/domain/admin_enums.dart';
import 'package:kachava_admin_dashboard/domain/admin_notification.dart';
import 'package:kachava_admin_dashboard/domain/admin_task.dart';
import 'package:kachava_admin_dashboard/domain/dashboard_view.dart';
import 'package:kachava_admin_dashboard/domain/reservation.dart';

import '../support/fake_operations.dart';

void main() {
  test('stay moves: check-in/cancel before arrival, check-out in house', () {
    expect(StayValues.actionsFor('PRE_ARRIVAL'), ['CHECK_IN', 'CANCEL']);
    expect(StayValues.actionsFor('ACTIVE_STAY'), ['CHECK_OUT']);
    expect(StayValues.actionsFor('CHECKED_OUT'), isEmpty);
    expect(StayValues.actionsFor('CANCELLED'), isEmpty);
  });

  test('task flow: one forward step at a time, none once final', () {
    expect(TaskValues.next('PENDING'), 'ASSIGNED');
    expect(TaskValues.next('ASSIGNED'), 'IN_PROGRESS');
    expect(TaskValues.next('IN_PROGRESS'), 'COMPLETED');
    expect(TaskValues.next('COMPLETED'), isNull);
    expect(TaskValues.next('CANCELLED'), isNull);
  });

  test('missing KPI or unread count is a format error, never a zero', () {
    expect(() => DashboardKpis.fromJson(const {'occupiedVillas': 1}),
        throwsFormatException);
    expect(() => UnreadCounts.fromJson(const {}), throwsFormatException);
  });

  test('ReservationPatch sends nothing it was not given', () {
    expect(const ReservationPatch().toJson(), isEmpty);
    expect(const ReservationPatch(wifiPassword: 'x').toJson(), {
      'wifi': {'password': 'x'}
    });
  });

  test('money: thousands separators and currency, EN/ES', () {
    expect(const StayStrings(false).money(1234.5), r'$1,234.50 USD');
    expect(const StayStrings(true).money(1234.5), r'$1.234,50 USD');
    expect(const StayStrings(false).money(null), '—');
  });

  test('shell open requests are delivered once to their tab', () {
    final shell = AdminShellController(staff: FakeStaffDirectory());
    addTearDown(shell.dispose);
    shell.openRecord(AdminWorkspaceTab.adminTasks, 'task_1');
    expect(shell.activeTab, AdminWorkspaceTab.adminTasks);
    expect(shell.takeOpenRequest(AdminWorkspaceTab.adminStays), isNull);
    expect(shell.peekOpenRequest(AdminWorkspaceTab.adminTasks)?.id, 'task_1');
    expect(shell.takeOpenRequest(AdminWorkspaceTab.adminTasks)?.id, 'task_1');
    expect(shell.takeOpenRequest(AdminWorkspaceTab.adminTasks), isNull);
    shell.openRecord(AdminWorkspaceTab.adminStays, 's1');
    shell.selectTab(AdminWorkspaceTab.adminVillas);
    expect(shell.peekOpenRequest(AdminWorkspaceTab.adminStays), isNull);
  });

  test('staff roster loads best effort', () async {
    final shell =
        AdminShellController(staff: FakeStaffDirectory(const [testStaff]));
    addTearDown(shell.dispose);
    await shell.loadStaff();
    expect(shell.staffDirectory.single.staffId, 'stf_1');
  });
}
