import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_guest_portal/domain/catalog.dart';
import 'package:kachava_guest_portal/domain/forms.dart';
import 'package:kachava_guest_portal/domain/json_read.dart';
import 'package:kachava_guest_portal/domain/trip.dart';

import 'support/fixtures.dart';

final _now = DateTime.utc(2026, 11, 1, 10); // resort wall time
final _transfer = service(
  id: 'trip1',
  section: 'TRANSPORTATION',
  usageType: 'TRIP',
  airportCodes: const ['CUN'],
  availability: const {'minLeadHours': 24},
  items: [
    itemJson('suv',
        nameEn: 'SUV',
        price: 85,
        capacity: const {'passengers': 6, 'luggage': 6}),
  ],
);

List<BookingField> _fieldsOf(String kind, {Json guestForm = const {}}) =>
    bookingFields(CatalogService.fromJson(serviceJson(
            id: kind,
            section: kind == 'SPECIAL_MENU' ? 'DINING' : 'X',
            kind: kind,
            guestForm: guestForm)))
        .map((f) => f.field)
        .toList();

void main() {
  group('guest form flags fall back to the kind rule', () {
    test('no flags: experience asks diet, wellness asks health', () {
      expect(_fieldsOf('EXPERIENCE'), [
        BookingField.date,
        BookingField.time,
        BookingField.guests,
        BookingField.dietary,
        BookingField.notes,
      ]);
      expect(_fieldsOf('WELLNESS'), [
        BookingField.date,
        BookingField.time,
        BookingField.guests,
        BookingField.health,
        BookingField.notes,
      ]);
      expect(_fieldsOf('SPECIAL_MENU'), contains(BookingField.dietary));
    });

    test('configured flags win over the kind rule', () {
      expect(_fieldsOf('EXPERIENCE', guestForm: const {'notes': true}),
          [BookingField.date, BookingField.notes]);
    });

    test('kind rule matches the admin derivation', () {
      ServiceGuestForm of(String kind, String section, String usage) =>
          CatalogService.fromJson(serviceJson(
                  id: kind, section: section, kind: kind, usageType: usage))
              .kindGuestForm;
      final bar = of('BAR', 'DINING', 'ORDER');
      expect([bar.date, bar.time, bar.guests, bar.notes, bar.dietary],
          [false, false, false, true, true]);
      expect(of('VILLA_STOCKING', 'IN_VILLA', 'ORDER').dietary, isTrue);
      final trip = of('TRANSPORT', 'TRANSPORTATION', 'TRIP');
      expect([trip.date, trip.notes, trip.dietary, trip.health],
          [false, true, false, false]);
      final pref = of('PREFERENCE', 'IN_VILLA', 'PREFERENCE');
      expect([pref.date, pref.notes, pref.dietary], [false, true, false]);
    });
  });

  group('TRIP wizard validation', () {
    test('page 1 When needs a future date and time', () {
      final d = TripDraft(TripType.arrival);
      expect(validateTripPage(d, 0, _transfer, _now).keys,
          containsAll(['day', 'time']));
      d
        ..day = DateTime.utc(2026, 11, 1)
        ..time = '09:00';
      expect(
          validateTripPage(d, 0, _transfer, _now)['time'], FormIssue.pastTime);
      d.time = '25:00';
      expect(validateTripPage(d, 0, _transfer, _now)['time'],
          FormIssue.invalidTime);
      d
        ..day = DateTime.utc(2026, 11, 3)
        ..time = '14:30';
      expect(validateTripPage(d, 0, _transfer, _now), isEmpty);
    });

    test('airport trips respect the lead time on the first page too', () {
      // Arriving today with a 24 h rule: say so up front, not after the
      // guest filled the flight and the server refused it.
      final d = TripDraft(TripType.arrival)
        ..day = DateTime.utc(2026, 11, 1)
        ..time = '20:00';
      expect(
          validateTripPage(d, 0, _transfer, _now)['time'], FormIssue.tooSoon);
    });

    test('local trips respect the lead time', () {
      final d = TripDraft(TripType.local)
        ..day = DateTime.utc(2026, 11, 1)
        ..time = '20:00';
      expect(
          validateTripPage(d, 0, _transfer, _now)['time'], FormIssue.tooSoon);
    });

    test('page 2 Flight: airport from Settings, airline and number', () {
      final d = TripDraft(TripType.arrival)..airport = 'MEX';
      final issues = validateTripPage(d, 1, _transfer, _now);
      expect(issues['airport'], FormIssue.notServed);
      expect(issues['airline'], FormIssue.required);
      expect(issues['flightNumber'], FormIssue.required);
      d
        ..airport = 'CUN'
        ..airline = 'AA'
        ..flightNumber = 'AA 1482';
      expect(validateTripPage(d, 1, _transfer, _now), isEmpty);
    });

    test('page 2 Route for local trips', () {
      final d = TripDraft(TripType.local);
      expect(validateTripPage(d, 1, _transfer, _now).keys,
          ['origin', 'destination']);
    });

    test('page 3 Group: vehicle required and capacity respected', () {
      final d = TripDraft(TripType.arrival)..passengers = 7;
      expect(validateTripPage(d, 2, _transfer, _now)['vehicle'],
          FormIssue.required);
      d
        ..vehicleId = 'suv'
        ..luggage = 9;
      final issues = validateTripPage(d, 2, _transfer, _now);
      expect(issues['passengers'], FormIssue.overCapacity);
      expect(issues['luggage'], FormIssue.tooManyBags);
    });

    test('payload: airport trips send the flight, never a pickup', () {
      final d = TripDraft(TripType.departure)
        ..day = DateTime.utc(2026, 11, 8)
        ..time = '16:05'
        ..airport = 'CUN'
        ..airline = 'AA'
        ..flightNumber = 'AA 1483'
        ..terminal = '3'
        ..passengers = 2
        ..luggage = 2
        ..vehicleId = 'suv';
      expect(firstInvalidTripPage(d, _transfer, _now), isNull);
      final body = tripPayload(d, _transfer);
      expect(body['type'], 'DEPARTURE');
      expect(body['airportCode'], 'CUN');
      expect(body['flight'], {
        'airline': 'AA',
        'number': 'AA 1483',
        'scheduledAt': '2026-11-08T16:05'
      });
      expect(body.containsKey('pickupAt'), isFalse);
      expect(body['itemId'], 'suv');
      expect(body['guestNotes'], 'Terminal 3');
    });

    test('draft survives Save & exit (json round trip)', () {
      final d = TripDraft(TripType.arrival)
        ..day = DateTime.utc(2026, 11, 3)
        ..time = '14:30'
        ..airline = 'AA';
      final back = TripDraft.fromJson(TripType.arrival, d.toJson());
      expect(back.day, d.day);
      expect(back.time, '14:30');
      expect(back.airline, 'AA');
    });
  });

  group('BOOKING form', () {
    final spa = service(
      id: 'spa',
      section: 'WELLNESS',
      guestForm: const {'time': true, 'guests': true, 'notes': true},
      availability: const {
        'minGuests': 1,
        'maxGuests': 2,
        'minLeadHours': 24,
        'weekdays': ['MON', 'TUE', 'WED', 'THU', 'FRI'],
        'blockedDates': ['2026-11-05'],
        'timeSlots': [
          {'start': '10:00', 'end': '11:00'}
        ],
      },
    );

    test('fields follow the admin guest form; <= 4 fields is one page', () {
      final fields = bookingFields(spa).map((f) => f.field).toList();
      expect(fields, [
        BookingField.date,
        BookingField.time,
        BookingField.guests,
        BookingField.notes
      ]);
      expect(paginateFields(fields), hasLength(1));
    });

    test('more than 4 fields becomes a wizard of <= 3 per page', () {
      expect(paginateFields([1, 2, 3, 4, 5]).map((p) => p.length), [3, 2]);
      expect(paginateFields([1, 2, 3, 4, 5, 6, 7]).map((p) => p.length),
          [3, 3, 1]);
    });

    test('date: blocked, weekday and lead time', () {
      final fields = bookingFields(spa);
      final d = BookingDraft()
        ..day = DateTime.utc(2026, 11, 5)
        ..time = '10:00'
        ..guests = 2;
      expect(validateBooking(d, fields, spa, _now)[BookingField.date],
          FormIssue.dayUnavailable);
      d.day = DateTime.utc(2026, 11, 7); // Saturday
      expect(validateBooking(d, fields, spa, _now)[BookingField.date],
          FormIssue.dayUnavailable);
      d
        ..day = DateTime.utc(2026, 11, 2)
        ..time = '09:00';
      expect(validateBooking(d, fields, spa, _now)[BookingField.time],
          FormIssue.tooSoon);
      d.time = '10:00';
      d.day = DateTime.utc(2026, 11, 3);
      expect(validateBooking(d, fields, spa, _now), isEmpty);
    });

    test('people within min/max', () {
      final d = BookingDraft()
        ..day = DateTime.utc(2026, 11, 3)
        ..time = '10:00'
        ..guests = 3;
      expect(
          validateBooking(
              d, bookingFields(spa), spa, _now)[BookingField.guests],
          FormIssue.tooManyGuests);
    });

    test('payload carries date, slot, party and answers', () {
      final d = BookingDraft()
        ..day = DateTime.utc(2026, 11, 3)
        ..time = '10:00'
        ..guests = 2
        ..notes = 'Anniversary';
      expect(bookingPayload(d, spa), {
        'serviceId': 'spa',
        'scheduledDate': '2026-11-03',
        'scheduledTimeSlot': '10:00',
        'partySize': 2,
        'metadata': {'notes': 'Anniversary'},
      });
    });
  });

  group('ORDER cart', () {
    final bar =
        service(id: 'bar', section: 'DINING', usageType: 'ORDER', items: [
      itemJson('mojito', price: 14, category: 'Cocktails'),
      itemJson('beer', price: 6, category: 'Beer'),
      itemJson('water', category: 'Beer'),
    ]);

    test('totals, grouping and payload', () {
      final cart = OrderCart(bar)
        ..set('mojito', 2)
        ..set('beer', 1);
      expect(cart.count, 3);
      expect(cart.total, 34);
      expect(cart.groups.keys, ['Cocktails', 'Beer']);
      expect(cart.toPayload(), {
        'serviceId': 'bar',
        'items': [
          {'itemId': 'mojito', 'quantity': 2},
          {'itemId': 'beer', 'quantity': 1},
        ],
      });
    });

    test('quantity clamps to 0..20 and 0 removes the line', () {
      final cart = OrderCart(bar)..set('beer', 99);
      expect(cart.quantityOf('beer'), orderLineMax);
      cart.set('beer', 0);
      expect(cart.isEmpty, isTrue);
    });
  });
}
