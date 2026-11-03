import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_guest_portal/data/guest_api.dart';

import 'support/fake_guest_api.dart';
import 'support/fixtures.dart';

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(
      of: find.byKey(const Key('portal-tabs')), matching: find.text(label)));
  await tester.pumpAndSettle();
}

const Map<String, Object> _openThread = {
  'requestId': 'c9',
  'type': 'ask',
  'category': 'Resort Host chat',
  'status': 'Requested',
  'createdAt': '2026-11-01T10:00:00Z',
  'messages': [
    {
      'sender': 'GUEST',
      'senderName': 'Ana',
      'text': 'Hello',
      'sentAt': '2026-11-01T10:00:00Z'
    }
  ],
};

void main() {
  group('My requests', () {
    testWidgets('empty: one line + Browse services', (tester) async {
      await pumpPortal(tester, api: FakeGuestApi(catalog: fullCatalog()));
      await _tab(tester, 'Requests');
      expect(find.text('No requests'), findsOneWidget);
      await tester.tap(find.text('Browse services'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('screen-services')), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('plain statuses, numbers from the journey, chips and sheet',
        (tester) async {
      final api = FakeGuestApi(
        stay: stayJson(bookings: [
          bookingJson('b1', 'spa',
              status: 'CONFIRMED', section: 'WELLNESS', date: '2026-11-04'),
        ]),
        catalog: fullCatalog(),
        trips: [tripJson('t1', status: 'EN_ROUTE')],
      );
      await pumpPortal(tester, api: api);
      await _tab(tester, 'Requests');
      expect(find.text('My requests'), findsOneWidget);
      expect(find.text('1.4 Svc spa'), findsOneWidget);
      expect(find.text('Nov 4 · 19:00 · 2 guests'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('On the way'), findsOneWidget);
      expect(find.text('EN_ROUTE'), findsNothing);
      await tester.tap(find.byKey(const Key('requests-done')));
      await tester.pumpAndSettle();
      expect(find.text('Confirmed'), findsNothing);
      await tester.tap(find.byKey(const Key('requests-all')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('request-booking:b1')));
      await tester.pumpAndSettle();
      expect(find.text('Received'), findsOneWidget);
      expect(find.text('\$90 USD'), findsOneWidget);
      await tester.tap(find.byKey(const Key('request-ask-host')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('screen-host')), findsOneWidget);
      expect(find.text('1.4 Svc spa'), findsOneWidget,
          reason: 'request attached to the chat');
      await unmount(tester);
    });
  });

  group('Cancel and Change while Received', () {
    FakeGuestApi api() => FakeGuestApi(
          stay: stayJson(bookings: [
            bookingJson('b1', 'spa', section: 'WELLNESS', date: '2026-11-04'),
          ]),
          catalog: fullCatalog(),
          trips: [tripJson('t1')],
        );

    testWidgets('cancel a booking after a one-line confirm', (tester) async {
      final fake = await pumpPortal(tester, api: api());
      await _tab(tester, 'Requests');
      await tester.tap(find.byKey(const Key('request-booking:b1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('request-ask-host')), findsNothing);
      expect(find.byKey(const Key('request-change')), findsOneWidget);
      await tester.tap(find.byKey(const Key('request-cancel')));
      await tester.pumpAndSettle();
      expect(find.text('Cancel 1.4 Svc spa?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('request-cancel-confirm')));
      await tester.pumpAndSettle();
      expect(fake.writes.single, ('cancelBooking', 'b1'));
      expect(find.text('Request cancelled'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a trip can be cancelled but not changed', (tester) async {
      final fake = await pumpPortal(tester, api: api());
      await _tab(tester, 'Requests');
      await tester.tap(find.byKey(const Key('request-trip:t1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('request-change')), findsNothing);
      await tester.tap(find.byKey(const Key('request-cancel')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('request-cancel-confirm')));
      await tester.pumpAndSettle();
      expect(fake.writes.single, ('cancelTrip', 't1'));
      await unmount(tester);
    });

    testWidgets('Change opens the booking form prefilled and re-sends it',
        (tester) async {
      final fake = await pumpPortal(tester, api: api());
      await _tab(tester, 'Requests');
      await tester.tap(find.byKey(const Key('request-booking:b1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('request-change')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('booking-guests')), findsOneWidget);
      await tester.tap(find.byKey(const Key('form-primary')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('form-primary')));
      await tester.pumpAndSettle();
      expect(fake.writes.single.$1, 'changeBooking');
      expect(fake.writes.single.$2, {
        'bookingId': 'b1',
        'scheduledDate': '2026-11-04',
        'scheduledTimeSlot': '19:00',
        'partySize': 2,
      });
      expect(find.text('Request changed'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('after confirmation only Ask Host remains', (tester) async {
      await pumpPortal(tester,
          api: FakeGuestApi(
            stay: stayJson(
                bookings: [bookingJson('b1', 'spa', status: 'CONFIRMED')]),
            catalog: fullCatalog(),
          ));
      await _tab(tester, 'Requests');
      await tester.tap(find.byKey(const Key('request-booking:b1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('request-ask-host')), findsOneWidget);
      expect(find.byKey(const Key('request-cancel')), findsNothing);
      await unmount(tester);
    });
  });

  group('Resort Host chat', () {
    testWidgets('text message opens a thread; success only after the server',
        (tester) async {
      final api = await pumpPortal(tester);
      await _tab(tester, 'Host');
      expect(find.text('No messages yet'), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key('host-input')), 'Extra towels please');
      await tester.tap(find.byKey(const Key('host-send')));
      await tester.pumpAndSettle();
      expect(api.writes.single.$1, 'thread');
      expect(
          api.writes.single.$2, {'text': 'Extra towels please', 'photo': null});
      expect(find.text('Message sent'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('real photo: upload first, then the thread carries its path',
        (tester) async {
      final api =
          await pumpPortal(tester, picker: FakePhotoPicker(samplePhoto));
      await _tab(tester, 'Host');
      await tester.tap(find.byKey(const Key('host-attach')));
      await tester.pumpAndSettle();
      expect(find.text('leak.jpg'), findsOneWidget);
      await tester.tap(find.byKey(const Key('host-send')));
      await tester.pumpAndSettle();
      expect(api.writes.map((w) => w.$1), ['upload', 'thread']);
      expect((api.writes.last.$2! as Map)['photo'],
          '/private/stays/s1/concierge/x/leak.jpg');
      expect(find.byKey(const Key('host-photo-chip')), findsNothing);
      await unmount(tester);
    });

    testWidgets('a photo goes inside the open thread', (tester) async {
      final api = FakeGuestApi(stay: stayJson(threads: [_openThread]));
      await pumpPortal(tester, api: api, picker: FakePhotoPicker(samplePhoto));
      await _tab(tester, 'Host');
      await tester.tap(find.byKey(const Key('host-attach')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('host-send')));
      await tester.pumpAndSettle();
      expect(api.writes.map((w) => w.$1), ['upload', 'message']);
      expect(api.writes.last.$2, {
        'thread': 'c9',
        'text': '',
        'photo': '/private/stays/s1/concierge/c9/leak.jpg',
      });
      await unmount(tester);
    });

    testWidgets('chat photos from the server are shown in the bubble',
        (tester) async {
      await pumpPortal(tester,
          api: FakeGuestApi(
              stay: stayJson(threads: [
            {
              ..._openThread,
              'messages': [
                {
                  'sender': 'GUEST',
                  'text': '',
                  'sentAt': '2026-11-01T10:00:00Z',
                  'photoUrl': 'https://signed.test/read/p.jpg'
                }
              ],
            }
          ])));
      await _tab(tester, 'Host');
      expect(find.byKey(const Key('chat-photo')), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('follow-up goes to the open thread; failure keeps the text',
        (tester) async {
      final api = FakeGuestApi(
        stay: stayJson(threads: const [
          {
            'requestId': 'c9',
            'type': 'ask',
            'category': 'Resort Host chat',
            'status': 'Requested',
            'createdAt': '2026-11-01T10:00:00Z',
            'messages': [
              {
                'sender': 'GUEST',
                'senderName': 'Ana',
                'text': 'Hello',
                'sentAt': '2026-11-01T10:00:00Z'
              }
            ],
          }
        ]),
      )..writeFailure = FailureKind.unreachable;
      await pumpPortal(tester, api: api);
      await _tab(tester, 'Host');
      await tester.enterText(
          find.byKey(const Key('host-input')), 'Are you there?');
      await tester.tap(find.byKey(const Key('host-send')));
      await tester.pumpAndSettle();
      expect(api.writes.single.$1, 'message');
      expect(find.text("Couldn't send"), findsOneWidget);
      expect(find.text('Are you there?'), findsOneWidget);
      expect(find.text('Message sent'), findsNothing);
      await unmount(tester);
    });
  });
}
