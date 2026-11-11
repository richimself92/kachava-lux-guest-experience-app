import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/application/guest_activity_watcher.dart';
import 'package:kachava_admin_dashboard/application/request_inbox_source.dart';
import 'package:kachava_admin_dashboard/domain/conversation.dart';
import 'package:kachava_admin_dashboard/domain/inbox_item.dart';

import '../support/fake_operations.dart';
import '../support/fake_service_requests.dart';
import '../transport/fake_transport_repositories.dart';

ConversationRow guestMessage(String stayId, DateTime at,
        {bool fromGuest = true}) =>
    ConversationRow(
      stayId: stayId,
      guestName: 'Valeria Gómez',
      villaName: 'Villa Coral',
      lastText: 'Can you have a cake ready?',
      lastAt: at,
      lastFromGuest: fromGuest,
      lastHasPhoto: false,
      unreadCount: 1,
      awaitingReply: fromGuest,
    );

void main() {
  late FakeServiceRequestRepository requests;
  late FakeTripRepository trips;
  late FakeConversationRepository conversations;
  late GuestActivityWatcher watcher;
  late int rings;

  setUp(() {
    rings = 0;
    requests = FakeServiceRequestRepository()
      ..requests.add(testRequest(1, section: 'IN_VILLA'));
    trips = FakeTripRepository();
    conversations = FakeConversationRepository();
    watcher = GuestActivityWatcher(
      inbox: RequestInboxSource(requests: requests, trips: trips),
      conversations: conversations,
      onArrival: () => rings++,
    );
  });

  tearDown(() => watcher.dispose());

  test('test_firstCheck_isTheSilentBaseline_withTheBadgeCount', () async {
    await watcher.check();
    expect(rings, 0);
    expect(watcher.requestCount, 1);
    expect(watcher.arrival, isNull);
  });

  test('test_newGuestRequest_chimes_andIsTheToastArrival', () async {
    await watcher.check();
    requests.requests.add(testRequest(2, section: 'IN_VILLA'));

    await watcher.check();

    expect(rings, 1);
    expect(watcher.requestCount, 2);
    final arrival = watcher.arrival as RequestArrival;
    expect(arrival.item.id, 'req_2');
    expect(watcher.isUnread(arrival.item), isTrue);
  });

  test('test_refreshWithoutNewItems_andStaffTrips_doNotChime', () async {
    await watcher.check();
    await watcher.check();
    trips.trips.add(testTrip(id: 't1', guest: 'Ana', pickupAt: testNow));

    await watcher.check();

    expect(rings, 0);
    expect(watcher.requestCount, 2);
  });

  test('test_newGuestMessage_chimes_staffReplyDoesNot', () async {
    final t0 = DateTime.utc(2026, 11, 3, 15);
    conversations.rows.add(guestMessage('s1', t0));
    await watcher.check();
    expect(watcher.messageCount, 1);

    conversations.rows[0] =
        guestMessage('s1', t0.add(const Duration(minutes: 2)));
    await watcher.check();
    expect(rings, 1);
    expect((watcher.arrival as MessageArrival).conversation.stayId, 's1');

    conversations.rows[0] = guestMessage(
        's1', t0.add(const Duration(minutes: 3)),
        fromGuest: false);
    await watcher.check();
    expect(rings, 1);
  });

  test('test_markOpened_clearsUnread_andDismissHidesTheToast', () async {
    await watcher.check();
    requests.requests.add(testRequest(2));
    await watcher.check();
    final item = (watcher.arrival as RequestArrival).item;

    watcher.markOpened(item.rowId);
    watcher.dismiss();

    expect(watcher.isUnread(item), isFalse);
    expect(watcher.arrival, isNull);
    expect(watcher.itemFor('req_2')?.id, 'req_2');
  });

  test('test_failedCheck_keepsTheLastCounts', () async {
    await watcher.check();
    trips.failList = StateError('offline');
    await watcher.check();
    expect(watcher.requestCount, 1);
    expect(watcher.isUnread(RequestInboxItem(testRequest(9))), isTrue);
  });
}
