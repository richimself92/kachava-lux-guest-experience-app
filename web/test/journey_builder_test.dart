import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_guest_portal/domain/catalog.dart';
import 'package:kachava_guest_portal/domain/journey.dart';
import 'package:kachava_guest_portal/domain/requests.dart';
import 'package:kachava_guest_portal/domain/stay.dart';
import 'package:kachava_guest_portal/domain/trip.dart';

import 'support/fixtures.dart';

final _transfer = service(
    id: 'trip1',
    section: 'TRANSPORTATION',
    usageType: 'TRIP',
    offeredWhen: 'BOTH',
    airportCodes: const ['CUN'],
    availability: const {'minLeadHours': 48});
final _stocking = service(
    id: 'stock',
    section: 'IN_VILLA',
    usageType: 'ORDER',
    offeredWhen: 'BEFORE_ARRIVAL');
final _bar = service(
    id: 'bar', section: 'DINING', usageType: 'ORDER', offeredWhen: 'BOTH');
final _breakfast =
    service(id: 'bf', section: 'DINING', offeredWhen: 'DURING_STAY');
final _spa = service(id: 'spa', section: 'WELLNESS', offeredWhen: 'BOTH');
final _pillow = service(
    id: 'pillow',
    section: 'IN_VILLA',
    usageType: 'PREFERENCE',
    offeredWhen: 'BEFORE_ARRIVAL');

Journey _build({
  GuestStay? guestStay,
  List<CatalogService>? catalog,
  List<GuestRequest> requests = const [],
  Set<String> skips = const {},
  DateTime? today,
  Set<String> drafts = const {},
  Set<String> own = const {},
}) =>
    buildJourney(
      stay: guestStay ?? stay(checkIn: '2026-11-03', checkOut: '2026-11-08'),
      catalog:
          catalog ?? [_transfer, _stocking, _bar, _breakfast, _spa, _pillow],
      requests: requests,
      skips: skips,
      resortToday: today ?? DateTime.utc(2026, 11, 1),
      drafts: drafts,
      ownArrangements: own,
    );

List<String> _numbers(Journey j, int step) =>
    j.step(step).tasks.map((t) => '${t.number} ${t.id}').toList();

void main() {
  group('numbering', () {
    test('core slots first, then sections in admin order', () {
      final j = _build();
      expect(_numbers(j, 1), [
        '1.1 core:flight',
        '1.2 core:preferences',
        '1.3 section:IN_VILLA',
        '1.4 section:DINING',
        '1.5 section:WELLNESS',
      ]);
      expect(_numbers(j, 2), [
        '2.1 section:DINING',
        '2.2 section:WELLNESS',
        '2.3 section:TRANSPORTATION'
      ]);
      expect(_numbers(j, 3), ['3.1 core:departure', '3.2 core:rating']);
    });

    test('a new section appends at its admin position; core numbers never move',
        () {
      final exp = service(
          id: 'tour', section: 'EXPERIENCES', offeredWhen: 'BEFORE_ARRIVAL');
      final j =
          _build(catalog: [_transfer, _stocking, _bar, _spa, _pillow, exp]);
      expect(_numbers(j, 1), [
        '1.1 core:flight',
        '1.2 core:preferences',
        '1.3 section:IN_VILLA',
        '1.4 section:DINING',
        '1.5 section:EXPERIENCES',
        '1.6 section:WELLNESS',
      ]);
    });

    test('a disabled section vanishes and only later rows shift', () {
      final j = _build(catalog: [_transfer, _bar, _spa, _pillow]);
      expect(_numbers(j, 1), [
        '1.1 core:flight',
        '1.2 core:preferences',
        '1.3 section:DINING',
        '1.4 section:WELLNESS',
      ]);
    });

    test('core task without config is hidden, other core numbers stay', () {
      final j = _build(catalog: [_stocking]);
      expect(_numbers(j, 1), ['1.2 core:preferences', '1.3 section:IN_VILLA']);
      expect(_numbers(j, 3), ['3.2 core:rating']);
    });

    test('preference services live inside 1.2, not as section rows', () {
      final j = _build();
      final prefs = j.taskById(1, 'core:preferences')!;
      expect(prefs.services.map((s) => s.id), ['pillow']);
      expect(
          j
              .step(1)
              .tasks
              .where((t) => t.section == 'IN_VILLA')
              .single
              .services
              .map((s) => s.id),
          ['stock']);
    });

    test('trip services are not catalog tasks before arrival', () {
      final j = _build();
      expect(
          j.step(1).tasks.any((t) => t.section == 'TRANSPORTATION'), isFalse);
    });
  });

  group('open step by resort date', () {
    test('before check-in opens step 1 and locks later steps', () {
      final j = _build(today: DateTime.utc(2026, 11, 2));
      expect(j.openStep, 1);
      expect(j.step(2).locked, isTrue);
      expect(j.step(2).opensOn, DateTime.utc(2026, 11, 3));
      // Departure opens 2 days before check-out (48 h transfer lead time).
      expect(j.step(3).opensOn, DateTime.utc(2026, 11, 6));
    });

    test('from check-in opens step 2', () {
      final j = _build(today: DateTime.utc(2026, 11, 3));
      expect(j.dateStep, 2);
      expect(j.step(1).locked, isFalse);
      expect(j.step(3).locked, isTrue);
    });

    test('step 3 opens at check-out minus max(lead, 1 day)', () {
      expect(_build(today: DateTime.utc(2026, 11, 6)).dateStep, 3);
      final noLead =
          _build(catalog: [_stocking], today: DateTime.utc(2026, 11, 7));
      expect(noLead.dateStep, 3);
      expect(
          _build(catalog: [_stocking], today: DateTime.utc(2026, 11, 6))
              .dateStep,
          2);
    });

    test('without published dates the lifecycle status decides', () {
      expect(_build(guestStay: stay(status: 'PRE_ARRIVAL')).dateStep, 1);
      expect(_build(guestStay: stay(status: 'ACTIVE_STAY')).dateStep, 2);
      expect(_build(guestStay: stay(status: 'CHECKED_OUT')).dateStep, 3);
    });

    test('open step without pending tasks opens the next with pending', () {
      final s =
          stay(checkIn: '2026-11-03', checkOut: '2026-11-08', dietary: 'None');
      final j = _build(guestStay: s, catalog: [_breakfast]);
      expect(j.step(1).hasPending, isFalse);
      expect(j.openStep, 2);
      expect(j.next, isNull, reason: 'step 2 is a locked preview');
      expect(j.allSet, isFalse);
    });

    test('nothing pending anywhere is All set', () {
      final unrated = _build(
          guestStay: stay(status: 'ACTIVE_STAY', dietary: 'None'),
          catalog: const []);
      expect(unrated.allSet, isFalse, reason: 'rating still pending in step 3');
      expect(unrated.openStep, 3);
      final done = _build(
          guestStay:
              stay(status: 'ACTIVE_STAY', dietary: 'None', feedback: const [
            {'feedbackId': 'f1'}
          ]),
          catalog: const []);
      expect(done.allSet, isTrue);
      expect(done.next, isNull);
    });
  });

  group('progress, next and skip', () {
    test('progress counts required tasks; optional rating excluded', () {
      final j = _build();
      expect(j.step(1).total, 5);
      expect(j.step(1).done, 0);
      expect(j.step(3).total, 1);
    });

    test('done task shows the request that completed it', () {
      final trips = [GuestTrip.fromJson(tripJson('t1'))];
      final requests =
          composeRequests(stay: stay(), trips: trips, catalog: [_transfer]);
      final j = _build(requests: requests);
      final flight = j.taskById(1, 'core:flight')!;
      expect(flight.state, TaskState.done);
      expect(flight.doneBy!.trip!.flightNumber, 'AA 1482');
      expect(j.step(1).done, 1);
      expect(j.next!.id, 'core:preferences');
    });

    test('cancelled requests do not complete a task', () {
      final trips = [GuestTrip.fromJson(tripJson('t1', status: 'CANCELLED'))];
      final requests =
          composeRequests(stay: stay(), trips: trips, catalog: [_transfer]);
      expect(_build(requests: requests).taskById(1, 'core:flight')!.state,
          TaskState.pending);
    });

    test('Not now skips: leaves the count, Next moves on', () {
      final j = _build(skips: {'1:core:flight'});
      expect(j.taskById(1, 'core:flight')!.state, TaskState.skipped);
      expect(j.step(1).total, 4);
      expect(j.next!.id, 'core:preferences');
    });

    test('done state of a BOTH service is shared by steps 1 and 2', () {
      final s = stay(bookings: [bookingJson('b1', 'spa', section: 'WELLNESS')]);
      final requests =
          composeRequests(stay: s, trips: const [], catalog: [_spa]);
      final j = _build(guestStay: s, requests: requests);
      expect(j.taskById(1, 'section:WELLNESS')!.state, TaskState.done);
      expect(j.taskById(2, 'section:WELLNESS')!.state, TaskState.done);
    });

    test('a draft shows in progress; partial preferences are in progress', () {
      final j = _build(drafts: {'section:DINING'});
      expect(j.taskById(1, 'section:DINING')!.state, TaskState.draft);
      final diet =
          _build(guestStay: stay(dietary: 'Vegan', checkIn: '2026-11-03'));
      expect(diet.taskById(1, 'core:preferences')!.state, TaskState.draft);
    });

    test('own arrangement completes the transfer task', () {
      final j = _build(own: {'core:flight'});
      final t = j.taskById(1, 'core:flight')!;
      expect(t.state, TaskState.done);
      expect(t.ownArrangement, isTrue);
    });

    test('Next targets the open step first', () {
      final j = _build(today: DateTime.utc(2026, 11, 4));
      expect(j.openStep, 2);
      expect(j.next!.number, '2.1');
    });
  });
}
