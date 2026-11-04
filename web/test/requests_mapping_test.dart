import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_guest_portal/domain/json_read.dart';
import 'package:kachava_guest_portal/domain/requests.dart';
import 'package:kachava_guest_portal/domain/stay.dart';
import 'package:kachava_guest_portal/domain/trip.dart';

import 'support/fixtures.dart';

void main() {
  group('status mapping (never raw enums)', () {
    test('bookings and preferences', () {
      expect(bookingStatusOf('REQUESTED'), RequestStatus.received);
      expect(bookingStatusOf('MODIFICATION_REQUESTED'), RequestStatus.received);
      expect(bookingStatusOf('CONFIRMED'), RequestStatus.confirmed);
      expect(bookingStatusOf('IN_PREPARATION'), RequestStatus.preparing);
      expect(bookingStatusOf('COMPLETED'), RequestStatus.done);
      expect(bookingStatusOf('CANCELLED'), RequestStatus.cancelled);
    });

    test('trips: provider hand-off is Arranging; en route is On the way', () {
      expect(tripStatusOf('REQUESTED'), RequestStatus.received);
      expect(tripStatusOf('SENT_TO_PROVIDER'), RequestStatus.arranging);
      expect(tripStatusOf('CONFIRMED'), RequestStatus.confirmed);
      expect(tripStatusOf('EN_ROUTE'), RequestStatus.onTheWay);
      expect(tripStatusOf('COMPLETED'), RequestStatus.done);
      expect(tripStatusOf('CANCELLED'), RequestStatus.cancelled);
    });

    test('villa stocking free-text statuses', () {
      expect(larderStatusOf('Pending'), RequestStatus.received);
      expect(larderStatusOf('Confirmed'), RequestStatus.confirmed);
      expect(larderStatusOf('In Progress'), RequestStatus.preparing);
      expect(larderStatusOf('Delivered'), RequestStatus.done);
      expect(larderStatusOf('Cancelled'), RequestStatus.cancelled);
    });

    test('host requests', () {
      expect(hostStatusOf('Requested', false), RequestStatus.received);
      expect(hostStatusOf('Assigned', false), RequestStatus.confirmed);
      expect(hostStatusOf('In Progress', false), RequestStatus.preparing);
      expect(hostStatusOf('Requested', true), RequestStatus.done);
    });

    test('4-dot track positions', () {
      expect(RequestStatus.received.trackIndex, 0);
      expect(RequestStatus.arranging.trackIndex, 0);
      expect(RequestStatus.confirmed.trackIndex, 1);
      expect(RequestStatus.preparing.trackIndex, 2);
      expect(RequestStatus.onTheWay.trackIndex, 2);
      expect(RequestStatus.done.trackIndex, 3);
      expect(RequestStatus.cancelled.trackIndex, -1);
      expect(RequestStatus.done.isActive, isFalse);
    });
  });

  group('composeRequests', () {
    test('merges orders, bookings, trips and host requests newest first', () {
      final s = GuestStay.fromJson(
          guestUuid,
          stayJson(
            larder: const [
              {
                'orderItemId': 'l1',
                'serviceId': 'stock',
                'catalogItemId': 'i1',
                'itemName': {'en': 'Water', 'es': 'Agua'},
                'quantity': 2,
                'lineTotalUSD': 6,
                'provisioningStatus': 'Pending'
              },
              {
                'orderItemId': 'l2',
                'serviceId': 'stock',
                'catalogItemId': 'i2',
                'itemName': {'en': 'Coffee', 'es': 'Café'},
                'quantity': 1,
                'lineTotalUSD': 12,
                'provisioningStatus': 'Delivered'
              },
            ],
            bookings: [
              bookingJson('b1', 'spa', capturedAt: '2026-11-02T10:00:00Z'),
              bookingJson('p1', 'pillow',
                  usageType: 'PREFERENCE', capturedAt: '2026-10-30T10:00:00Z'),
            ],
            threads: const [
              {
                'requestId': 'r1',
                'type': 'request',
                'title': 'Extra towels',
                'status': 'Assigned',
                'createdAt': '2026-11-02T12:00:00Z',
                'messages': []
              },
              {
                'requestId': 'c1',
                'type': 'ask',
                'title': 'Message',
                'status': 'Requested',
                'createdAt': '2026-11-03T12:00:00Z',
                'messages': []
              },
            ],
          ));
      final trips = [
        GuestTrip.fromJson(tripJson('t1', createdAt: '2026-11-01T12:00:00Z'))
      ];
      final list = composeRequests(stay: s, trips: trips, catalog: [
        service(
            id: 'stock',
            section: 'IN_VILLA',
            usageType: 'ORDER',
            nameEn: 'Villa stocking'),
      ]);
      expect(list.map((r) => r.id), [
        'host:r1',
        'booking:b1',
        'trip:t1',
        'booking:p1',
        'order:stock',
      ]);
      final order = list.last;
      expect(order.name.en, 'Villa stocking');
      expect(order.status, RequestStatus.received,
          reason: 'least advanced line');
      expect(order.lines, hasLength(2));
      expect(order.totalUSD, 18);
      expect(list.firstWhere((r) => r.id == 'booking:p1').kind,
          RequestKind.preference);
      expect(list.any((r) => r.id == 'host:c1'), isFalse,
          reason: 'chat lives in Host');
    });

    test('trip time is shown in resort time', () {
      final list = composeRequests(
          stay: GuestStay.fromJson(guestUuid, stayJson()),
          trips: [
            GuestTrip.fromJson(
                tripJson('t1', pickupAt: '2026-11-03T19:30:00.000Z'))
          ],
          catalog: const []);
      expect(list.single.time, '14:30');
      expect(list.single.day, DateTime.utc(2026, 11, 3));
      expect(list.single.people, 3);
    });
  });

  group('server timestamps and guest actions', () {
    Json line(String id, String serviceId, String createdAt) => {
          'orderItemId': id,
          'serviceId': serviceId,
          'catalogItemId': 'i-$id',
          'itemName': {'en': 'Water', 'es': 'Agua'},
          'quantity': 1,
          'lineTotalUSD': 4,
          'provisioningStatus': 'Pending',
          'createdAt': createdAt,
          'updatedAt': createdAt,
        };

    test('bookings and orders sort by createdAt, newest first', () {
      final s = GuestStay.fromJson(
          guestUuid,
          stayJson(
            larder: [line('l1', 'stock', '2026-11-02T09:00:00Z')],
            bookings: [
              bookingJson('b1', 'spa',
                  capturedAt: '2026-11-05T10:00:00Z',
                  createdAt: '2026-11-01T09:00:00Z'),
              bookingJson('b2', 'spa', createdAt: '2026-11-03T09:00:00Z'),
            ],
          ));
      final list = composeRequests(stay: s, trips: const [], catalog: const []);
      expect(
          list.map((r) => r.id), ['booking:b2', 'order:stock', 'booking:b1']);
      expect(s.bookings.first.createdAt, DateTime.utc(2026, 11, 1, 9));
      expect(s.larderOrders.single.createdAt, DateTime.utc(2026, 11, 2, 9));
    });

    test('Cancel / Change only while the server status is the initial one', () {
      final s = GuestStay.fromJson(
          guestUuid,
          stayJson(
            larder: [line('l1', 'stock', '2026-11-02T09:00:00Z')],
            bookings: [
              bookingJson('b1', 'spa'),
              bookingJson('b2', 'spa', status: 'CONFIRMED'),
              bookingJson('p1', 'pillow', usageType: 'PREFERENCE'),
            ],
          ));
      final trips = [
        GuestTrip.fromJson(tripJson('t1')),
        GuestTrip.fromJson(tripJson('t2', status: 'SENT_TO_PROVIDER')),
      ];
      final byId = {
        for (final r
            in composeRequests(stay: s, trips: trips, catalog: const []))
          r.id: r
      };
      String actions(String id) =>
          '${byId[id]!.canCancel}/${byId[id]!.canChange}';
      expect(actions('booking:b1'), 'true/true');
      expect(actions('booking:b2'), 'false/false');
      expect(actions('booking:p1'), 'true/false');
      expect(actions('trip:t1'), 'true/false');
      expect(actions('trip:t2'), 'false/false',
          reason: 'already with the provider');
      expect(actions('order:stock'), 'false/false');
      expect(byId['booking:b1']!.booking!.id, 'b1');
    });
  });
}
