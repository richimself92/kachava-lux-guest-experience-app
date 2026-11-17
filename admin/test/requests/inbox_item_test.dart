import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/domain/inbox_item.dart';
import 'package:kachava_admin_dashboard/domain/service_request.dart';

import '../support/fake_service_requests.dart';
import '../transport/fake_transport_repositories.dart';

void main() {
  RequestInboxItem request(String usageType, String status) =>
      RequestInboxItem(testRequest(1,
          usageType: usageType, status: status, isOrder: usageType == 'ORDER'));

  test('test_type_and_stage_comeFromTheRequestAndTrip', () {
    expect(
        request('ORDER', RequestStatusValues.received).type, InboxType.order);
    expect(request('PREFERENCE', RequestStatusValues.received).stage,
        InboxStage.fresh);
    expect(request('BOOKING', RequestStatusValues.preparing).stage,
        InboxStage.active);
    expect(
        request('BOOKING', RequestStatusValues.done).stage, InboxStage.closed);
    final trip =
        TripInboxItem(testTrip(id: 't1', guest: 'Ana', pickupAt: testNow));
    expect(trip.type, InboxType.trip);
    expect(trip.stage, InboxStage.fresh);
    expect(trip.rowId, 'trip-t1');
  });

  test('test_nextStep_order_confirm_startPreparing_markDelivered', () {
    InboxStepLabel? label(String s) => request('ORDER', s).nextStep?.label;
    expect(label(RequestStatusValues.received), InboxStepLabel.confirm);
    expect(label(RequestStatusValues.confirmed), InboxStepLabel.startPreparing);
    expect(label(RequestStatusValues.preparing), InboxStepLabel.markDelivered);
    expect(label(RequestStatusValues.done), isNull);
    final step = request('ORDER', RequestStatusValues.confirmed).nextStep;
    expect((step as RequestStep).action, RequestAction.start);
  });

  test('test_nextStep_bookingAndPreference_confirm_thenMarkDone', () {
    for (final type in ['BOOKING', 'PREFERENCE']) {
      expect(request(type, RequestStatusValues.received).nextStep?.label,
          InboxStepLabel.confirm);
      final done = request(type, RequestStatusValues.confirmed).nextStep;
      expect(done?.label, InboxStepLabel.markDone);
      expect((done as RequestStep).action, RequestAction.complete);
    }
  });

  test('test_nextStep_trip_followsTheProviderFlow', () {
    InboxNextStep? step(String status) => TripInboxItem(
            testTrip(id: 't', guest: 'A', pickupAt: testNow, status: status))
        .nextStep;
    expect(step('REQUESTED')?.label, InboxStepLabel.sendToProvider);
    expect(step('SENT_TO_PROVIDER')?.label, InboxStepLabel.confirmDriver);
    expect(step('CONFIRMED')?.label, InboxStepLabel.onTheWay);
    expect((step('EN_ROUTE') as TripStep).to, 'COMPLETED');
    expect(step('COMPLETED'), isNull);
  });

  test('test_waiting_overThirtyMinutes_isOverdue_onlyWhileNew', () {
    final asked = DateTime.utc(2026, 11, 3, 14);
    final item = RequestInboxItem(testRequest(1, createdAt: asked));
    expect(item.isOverdue(asked.add(const Duration(minutes: 29))), isFalse);
    expect(item.isOverdue(asked.add(const Duration(minutes: 31))), isTrue);
    final confirmed = RequestInboxItem(testRequest(1,
        createdAt: asked, status: RequestStatusValues.confirmed));
    expect(confirmed.isOverdue(asked.add(const Duration(hours: 2))), isFalse);
  });

  test('test_queueOrder_newFirst_oldestAskedFirst_thenInProgress', () {
    final a = RequestInboxItem(testRequest(1,
        status: RequestStatusValues.confirmed,
        createdAt: DateTime.utc(2026, 11, 3, 9)));
    final b = RequestInboxItem(
        testRequest(2, createdAt: DateTime.utc(2026, 11, 3, 12)));
    final c = RequestInboxItem(
        testRequest(3, createdAt: DateTime.utc(2026, 11, 3, 10)));
    final sorted = [a, b, c]..sort(InboxItem.queueOrder);
    expect(sorted.map((i) => i.id), ['req_3', 'req_2', 'req_1']);
  });

  test('test_taskId_matchesTheBackendSourceTaskConvention', () {
    expect(request('PREFERENCE', 'RECEIVED').taskId, 'task_preference_req_1');
    expect(
        RequestInboxItem(testRequest(1, isOrder: true, usageType: 'ORDER')
                .withStatus('RECEIVED'))
            .taskId,
        'task_order_req_1');
  });
}
