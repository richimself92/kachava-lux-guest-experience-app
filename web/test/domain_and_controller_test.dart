import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kachava_guest_portal/application/sanctuary_controller.dart';
import 'package:kachava_guest_portal/core/audio/soundscape_port.dart';
import 'package:kachava_guest_portal/core/auth/magic_link_parser.dart';
import 'package:kachava_guest_portal/core/constants/screen_id.dart';
import 'package:kachava_guest_portal/data/repositories/api_sanctuary_repository.dart';
import 'package:kachava_guest_portal/domain/entities/concierge_folio_entities.dart';
import 'package:kachava_guest_portal/domain/entities/stay_entities.dart';

void main() {
  group('MagicLinkParser Unit Tests', () {
    test('test_parse_withoutQueryParam_returnsDefaultDemoUuid', () {
      final result =
          MagicLinkParser.parseUri(Uri.parse('https://kachavalux.com/'));
      expect(result.isValid, isTrue);
      expect(result.guestUuid, equals(MagicLinkParser.defaultDemoUuid));
    });

    test('test_parse_withValidUuidQueryParam_returnsValidGuestUuid', () {
      final uri = Uri.parse(
        'https://kachavalux.com/?guestId=550e8400-e29b-41d4-a716-446655440000',
      );
      final result = MagicLinkParser.parseUri(uri);
      expect(result.isValid, isTrue);
      expect(result.guestUuid, equals('550e8400-e29b-41d4-a716-446655440000'));
    });

    test('test_parse_withMalformedGuestId_returnsInvalidResult', () {
      final uri = Uri.parse('https://kachavalux.com/?guestId=invalid-uuid');
      final result = MagicLinkParser.parseUri(uri);
      expect(result.isValid, isFalse);
    });
  });

  group('SanctuaryController & Domain Logic Unit Tests', () {
    late SanctuaryController controller;

    setUp(() async {
      controller = SanctuaryController(
        repository: ApiSanctuaryRepository(enableNetwork: false),
        soundscape: SanctuarySoundscapeSynthesizer(),
        initialUri: Uri.parse(
          'https://kachavalux.com/?guestId=550e8400-e29b-41d4-a716-446655440000',
        ),
      );
      await controller.initialize();
    });

    test('test_soundscapeToggle_switches432HzSynthesizerState', () {
      expect(controller.isSoundscapeActive, isFalse);
      expect(controller.soundscapeFrequencyHz, equals(432));

      controller.toggleSoundscape();
      expect(controller.isSoundscapeActive, isTrue);

      controller.toggleSoundscape();
      expect(controller.isSoundscapeActive, isFalse);
    });

    test('test_larderCart_updatesQuantitiesAndBlocksEmptyConfirmation',
        () async {
      expect(controller.larderTotalAmount, equals(0));
      expect(controller.larderTotalCount, equals(0));

      final emptyConfirmed = await controller.confirmVillaStocking();
      expect(emptyConfirmed, isFalse);

      controller.updateLarderQuantity('larder-3', 1);
      expect(controller.larderTotalAmount, equals(285));
      expect(controller.larderTotalCount, equals(1));

      final validConfirmed = await controller.confirmVillaStocking();
      expect(validConfirmed, isTrue);
      expect(controller.larderTotalCount, equals(0));
      expect(controller.larderTotalAmount, equals(0));
      expect(controller.submittedLarderItems.length, equals(1));
      expect(controller.submittedLarderItems.single.id, equals('larder-3'));
      expect(controller.submittedLarderItems.single.quantity, equals(1));
      expect(controller.submittedLarderTotalAmount, equals(285));
    });

    test(
        'test_requireExplicitGuestId_blocksDefaultDemoUrlAndMissingBackendStay',
        () async {
      final noParamCtrl = SanctuaryController(
        repository: ApiSanctuaryRepository(enableNetwork: false),
        soundscape: SanctuarySoundscapeSynthesizer(),
        requireExplicitGuestId: true,
        initialUri: Uri.parse('https://kavacha-app-guest-portal.web.app/'),
      );
      expect(noParamCtrl.isUuidValid, isFalse);
      noParamCtrl.dispose();

      final missingBackendCtrl = SanctuaryController(
        repository: ApiSanctuaryRepository(enableNetwork: false),
        soundscape: SanctuarySoundscapeSynthesizer(),
        requireExplicitGuestId: true,
        initialUri: Uri.parse(
          'https://kavacha-app-guest-portal.web.app/?guestId=f47ac10b-58cc-4372-a567-0e02b2c3d479',
        ),
      );
      expect(missingBackendCtrl.isUuidValid, isTrue);
      await missingBackendCtrl.initialize();
      expect(missingBackendCtrl.isUuidValid, isFalse);
      missingBackendCtrl.dispose();
    });

    test('test_yachtCharter_enforcesMaxCapacity12AndCalculatesPrice', () async {
      expect(controller.yachtCharter.guestCount, equals(2));

      controller.updateYachtGuestCount(15);
      expect(controller.yachtCharter.guestCount, equals(12));

      controller.updateYachtGuestCount(0);
      expect(controller.yachtCharter.guestCount, equals(1));

      controller.selectYachtPackage('full-day');
      expect(controller.yachtNetUpgradeUsd, equals(2000));
    });

    test('test_conciergeRequest_creates4StageTicketPhotoAndChatMessage',
        () async {
      final initialCount = controller.conciergeRequests.length;
      final created = await controller.createConciergeRequest(
        title: 'Plunge Pool Temperature Tuning',
        category: 'Maintenance',
        details: 'Please warm the terrace plunge pool by 2 degrees.',
        photoUrl:
            'https://storage.googleapis.com/kachava-lux/villa102/pool.jpg',
      );
      expect(created, isTrue);
      expect(controller.conciergeRequests.length, equals(initialCount + 1));

      final newest = controller.conciergeRequests.first;
      expect(newest.stage, equals(ConciergeStage.requested));
      expect(newest.currentStep, equals(1));
      expect(newest.photoUrl, contains('pool.jpg'));

      controller.advanceConciergeRequestStage(newest.id);
      expect(
        controller.conciergeRequests.first.stage,
        equals(ConciergeStage.assigned),
      );

      controller.sendChatMessage('Thank you HOST ADMIN!');
      expect(
          controller.chatMessages.last.text, equals('Thank you HOST ADMIN!'));
    });

    test('test_midStayCheckIn_submitsRatingAndPriorityHostCallback', () async {
      final submitted = await controller.submitMidStayCheckIn(
        rating: 4,
        sentimentId: 'tuned',
        housekeepingWindow: '10:30 AM Morning Refresh',
        focusAreas: const ['Pool Terrace Plunge Heat'],
        notes: 'Warm plunge pool before sunset.',
        requestPriorityCallback: true,
      );
      expect(submitted, isTrue);
      expect(controller.latestMidStayCheckIn?.rating, equals(4));
      expect(controller.latestMidStayCheckIn?.requestPriorityCallback, isTrue);
    });

    test('test_expressCheckout_requiresStepUpAndLocksMutationsWhenCheckedOut',
        () async {
      expect(controller.stay.lifecycleStatus,
          isNot(StayLifecycleStatus.checkedOut));
      expect(controller.isStepUpVerified, isFalse);

      final unverifiedCheckout = await controller.completeExpressCheckout();
      expect(unverifiedCheckout, isFalse);

      expect(controller.verifyStepUp('999'), isFalse);
      expect(controller.verifyStepUp('Miller'), isTrue);
      expect(controller.isStepUpVerified, isTrue);

      final verifiedCheckout = await controller.completeExpressCheckout();
      expect(verifiedCheckout, isTrue);
      expect(controller.stay.lifecycleStatus,
          equals(StayLifecycleStatus.checkedOut));
      expect(controller.isReadOnly, isTrue);

      final blockedMutation = await controller.createConciergeRequest(
        title: 'Blocked after checkout',
        category: 'Housekeeping',
        details: 'Should not mutate in read-only state',
      );
      expect(blockedMutation, isFalse);
    });

    test('test_navigateToAll13Screens_updatesCurrentScreen', () {
      for (final screen in ScreenId.values) {
        controller.navigateTo(screen);
        expect(controller.currentScreen, equals(screen));
      }
      expect(ScreenId.values.length, equals(13));
    });

    test('test_controllerDispose_isIdempotentAndClosesRepository', () {
      controller.dispose();
      expect(() => controller.dispose(), returnsNormally);
    });
  });

  group('ApiSanctuaryRepository REST Envelope & /stays/:guestUuid Alignment',
      () {
    test('test_loadSanctuaryAndMutations_useStaysRoutesAndUnwrapDataEnvelope',
        () async {
      final recordedRequests = <http.Request>[];
      final mockClient = MockClient((request) async {
        recordedRequests.add(request);
        if (request.method == 'GET' &&
            request.url.path.endsWith('/stays/uuid-102')) {
          return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'status': 'PRE_ARRIVAL',
                  'flightTransfer': {'flightNumber': 'AA 999'}
                }
              }),
              200);
        }
        return http.Response(
            jsonEncode({
              'success': true,
              'data': {'stepUpToken': 'hmac-token-102'}
            }),
            200);
      });

      final repo = ApiSanctuaryRepository(
          baseUrl: 'http://localhost:3001/api/v1', httpClient: mockClient);
      final snapshot = await repo.loadSanctuary('uuid-102');
      expect(snapshot.stay.lifecycleStatus,
          equals(StayLifecycleStatus.preArrival));
      expect(snapshot.transport.flightNumber, equals('AA 999'));
      expect(await repo.verifyStepUpChallenge('uuid-102', lastName: 'Miller'),
          equals('hmac-token-102'));

      await repo.saveLarderOrder('uuid-102', snapshot.larderItems);
      await repo.saveYachtCharter('uuid-102', snapshot.yachtCharter);
      await repo.completeCheckout('uuid-102', stepUpToken: 'hmac-token-102');

      final paths =
          recordedRequests.map((r) => '${r.method} ${r.url.path}').toList();
      expect(
          paths,
          containsAll([
            'GET /api/v1/stays/uuid-102',
            'POST /api/v1/stays/uuid-102/verify-step-up',
            'PUT /api/v1/stays/uuid-102/larder',
            'POST /api/v1/stays/uuid-102/bookings',
            'POST /api/v1/stays/uuid-102/folio/checkout'
          ]));
      repo.dispose();
    });

    test('test_mergeSnapshot_mapsDynamicGuestVillaAndDatesFromWirePayload',
        () async {
      final mockClient = MockClient((request) async => http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'status': 'ACTIVE_STAY',
                'villaName': 'Villa 106 — Copal Pavilion',
                'suiteName': 'Copal Pavilion · 4,100 sq ft',
                'stayDatesLabel': 'Nov 20, 2026 – Nov 25, 2026',
                'guestProfile': {
                  'name': 'Juan & Sofia',
                  'lastNameNormalized': 'sofia',
                  'celebration': 'Honeymoon Sanctuary'
                },
              }
            }),
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          ));
      final repo = ApiSanctuaryRepository(
          baseUrl: 'http://localhost:3001/api/v1', httpClient: mockClient);
      final snapshot = await repo.loadSanctuary('uuid-106');
      expect(snapshot.stay.guestNames, equals('Juan & Sofia'));
      expect(snapshot.stay.primaryGuestName, equals('Juan'));
      expect(snapshot.stay.lastName, equals('sofia'));
      expect(snapshot.stay.villaNumber, equals('106'));
      expect(snapshot.stay.villaTitle, equals('Villa 106 — Copal Pavilion'));
      expect(snapshot.stay.suiteName, equals('Copal Pavilion · 4,100 sq ft'));
      expect(snapshot.stay.stayDates, equals('Nov 20, 2026 – Nov 25, 2026'));
      expect(snapshot.stay.celebrationTitle, equals('Honeymoon Sanctuary'));
      expect(
          snapshot.stay.copyWith(privateHostName: 'HOST ADMIN').privateHostName,
          equals('HOST ADMIN'));
      repo.dispose();
    });

    test(
        'test_newStayHydration_mapsWifiDispatchesExcursionAndPreservesStateOnPoll',
        () async {
      final recordedPosts = <Map<String, dynamic>>[];
      const utf8Json = {'content-type': 'application/json; charset=utf-8'};
      final mockClient = MockClient((req) async {
        if (req.method == 'POST' && req.url.path.endsWith('/bookings')) {
          recordedPosts.add(jsonDecode(req.body) as Map<String, dynamic>);
          return http.Response(jsonEncode({'success': true, 'data': {}}), 201,
              headers: utf8Json);
        }
        if (req.url.path.endsWith('/catalog/experiences')) {
          return http.Response(
              jsonEncode({
                'success': true,
                'data': [
                  {
                    'id': 'exp-cenote',
                    'title': 'Private Cenote Sound Healing',
                    'basePriceUSD': 450
                  }
                ]
              }),
              200,
              headers: utf8Json);
        }
        if (req.url.path.endsWith('/catalog/larder')) {
          return http.Response(
              jsonEncode({
                'success': true,
                'data': [
                  {
                    'id': 'larder-mezcal',
                    'name': 'Artisanal Tobalá Mezcal',
                    'price': 190
                  }
                ]
              }),
              200,
              headers: utf8Json);
        }
        return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'status': 'PRE_ARRIVAL',
                'villaName': 'Villa 110 — Akumal Sanctuary',
                'guestProfile': {'name': 'Elena Rostova'},
                'villaAccess': {
                  'wifiSsid': 'Kachava_Villa_110',
                  'wifiPasscode': 'Akumal2026'
                },
                'flightTransfer': {
                  'arrivalDate': '',
                  'arrivalAirport': '',
                  'airline': '',
                  'flightNumber': '',
                  'estimatedLanding': '',
                  'terminal': '',
                  'status': 'Not Requested',
                  'assignedDriver': '',
                  'vehicleModel': '',
                  'meetingPoint': ''
                },
                'personalization': {
                  'pillowType': '',
                  'scentProfile': '',
                  'dietary': '',
                  'allergies': '',
                  'occasionDetails': ''
                },
                'larderOrders': <Map<String, dynamic>>[],
              }
            }),
            200,
            headers: utf8Json);
      });
      final ctrl = SanctuaryController(
          repository: ApiSanctuaryRepository(httpClient: mockClient),
          soundscape: SanctuarySoundscapeSynthesizer());
      await ctrl.initialize();
      expect(ctrl.stay.wifiSsid, equals('Kachava_Villa_110'));
      expect(ctrl.stay.wifiPassphrase, equals('Akumal2026'));
      expect(ctrl.larderTotalCount, equals(0));
      ctrl.updateLarderQuantity('larder-mezcal', 3);
      ctrl.selectYachtPackage('full-day');
      ctrl.updateYachtGuestCount(6);
      ctrl.updateYachtDate('2026-11-22');
      ctrl.scheduleExperience('exp-cenote', '2026-11-21 · 09:00 AM');
      await ctrl.refreshFromBackend();
      expect(ctrl.larderTotalCount, equals(3));
      expect(ctrl.yachtCharter.selectedPackageId, equals('full-day'));
      expect(ctrl.yachtCharter.guestCount, equals(6));
      expect(ctrl.yachtCharter.selectedDate, equals('2026-11-22'));
      expect(ctrl.experiences.first.isScheduled, isTrue);
      expect(ctrl.experiences.first.bookingStatus, equals('REQUESTED'));
      expect(recordedPosts.single['bookingType'], equals('EXCURSION'));
      expect(recordedPosts.single['catalogRefId'], equals('exp-cenote'));
      ctrl.dispose();
    });

    test(
        'test_milestone11_exactNightsAndStayBounds_parsesOct19ToOct22As3Nights',
        () async {
      final mockClient = MockClient((request) async => http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'status': 'ACTIVE_STAY',
                'villaName': 'Villa 102',
                'stayDatesLabel': 'Oct 19 – Oct 22',
                'nights': 4, // Backend stale nights should be overridden by 3!
                'personalization': {
                  'pillowType': 'Memory Foam',
                  'housekeepingCadence': '09:00 AM – 11:00 AM',
                },
                'larderOrders': [
                  {
                    'itemId': 'larder-1',
                    'quantity': 2,
                    'provisioningStatus': 'Stocked in Villa',
                  },
                ],
                'experienceBookings': [
                  {
                    'bookingType': 'EXCURSION',
                    'catalogRefId': 'exp-1',
                    'title': 'Cenote Dos Ojos Private Dive & Ritual',
                    'scheduledDate': 'Oct 20, 2026',
                    'scheduledTimeSlot': '11:00 AM',
                    'status': 'CANCELLED',
                    'cancellationReason': 'Weather advisory at cenote',
                  },
                  {
                    'bookingType': 'YACHT_CHARTER',
                    'category': 'Marine & Yacht',
                    'scheduledDate': 'Oct 21, 2026',
                    'scheduledTimeSlot': 'Morning Sail · 09:30 AM – 1:30 PM',
                    'status': 'CONFIRMED',
                  },
                  {
                    'bookingType': 'PRIVATE_DINING',
                    'category': 'Private Dining',
                    'scheduledDate': 'Oct 19, 2026',
                    'scheduledTimeSlot': '8:00 PM',
                    'status': 'CANCELLED',
                    'cancellationReason': 'Chef schedule conflict',
                  },
                ],
                'midstayFeedback': [
                  {
                    'rating': 5,
                    'selectedSentiment': 'transcendent',
                    'note': 'Everything is magical!',
                    'submittedAt': 'Oct 20, 2026',
                  },
                ],
              },
            }),
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          ));

      final ctrl = SanctuaryController(
        repository: ApiSanctuaryRepository(httpClient: mockClient),
        soundscape: SanctuarySoundscapeSynthesizer(),
      );
      await ctrl.initialize();

      expect(ctrl.stay.nights, equals(3));
      expect(ctrl.stay.checkInDateTime, equals(DateTime(2026, 10, 19)));
      expect(ctrl.stay.checkOutDateTime, equals(DateTime(2026, 10, 22)));
      expect(ctrl.stay.defaultStayDateLabel, equals('Oct 19, 2026'));
      expect(ctrl.stay.isDateWithinStay(DateTime(2026, 10, 19)), isTrue);
      expect(ctrl.stay.isDateWithinStay(DateTime(2026, 10, 22)), isTrue);
      expect(ctrl.stay.isDateWithinStay(DateTime(2026, 10, 23)), isFalse);

      expect(
        ctrl.preferences.housekeepingCadence,
        equals('09:00 AM – 11:00 AM'),
      );
      expect(ctrl.larderOrderStatus, equals('Stocked in Villa'));
      expect(ctrl.isLarderOrderConfirmed, isFalse);
      expect(
        ctrl.larderItems.firstWhere((i) => i.id == 'larder-1').quantity,
        equals(0),
      );

      final exp1 = ctrl.experiences.firstWhere((e) => e.id == 'exp-1');
      expect(exp1.isReserved, isTrue);
      expect(exp1.bookingStatus, equals('CANCELLED'));
      expect(exp1.cancellationReason, equals('Weather advisory at cenote'));

      expect(ctrl.yachtCharter.bookingStatus, equals('CONFIRMED'));
      expect(ctrl.yachtCharter.isConfirmed, isTrue);
      expect(ctrl.yachtCharter.selectedDate, equals('Oct 21, 2026'));

      expect(ctrl.diningReservation.bookingStatus, equals('CANCELLED'));
      expect(ctrl.diningReservation.isConfirmed, isFalse);
      expect(
        ctrl.diningReservation.cancellationReason,
        equals('Chef schedule conflict'),
      );

      expect(ctrl.latestMidStayCheckIn, isNotNull);
      expect(ctrl.latestMidStayCheckIn!.rating, equals(5));
      expect(
          ctrl.latestMidStayCheckIn!.notes, equals('Everything is magical!'));
      ctrl.dispose();
    });

    test(
        'test_milestone12_larderDeliveredClearsCartAndAllowsReordering_andSeedDiningNotesEmpty',
        () async {
      var orderDelivered = false;
      final mockClient = MockClient((request) async {
        if (request.method == 'PUT' && request.url.path.endsWith('/larder')) {
          return http.Response(
            jsonEncode({'success': true, 'data': {}}),
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'status': 'ACTIVE_STAY',
              'villaName': 'Villa 102',
              'larderOrders': orderDelivered
                  ? [
                      {
                        'itemId': 'larder-1',
                        'quantity': 2,
                        'provisioningStatus': 'Stocked in Villa',
                      },
                    ]
                  : [
                      {
                        'itemId': 'larder-1',
                        'quantity': 2,
                        'provisioningStatus': 'Pending',
                      },
                    ],
            },
          }),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final ctrl = SanctuaryController(
        repository: ApiSanctuaryRepository(httpClient: mockClient),
        soundscape: SanctuarySoundscapeSynthesizer(),
      );
      expect(ctrl.diningReservation.dietaryNotes, isEmpty);

      await ctrl.initialize();
      expect(ctrl.larderOrderStatus, equals('Pending'));
      expect(ctrl.isLarderOrderConfirmed, isTrue);
      expect(ctrl.larderTotalCount, equals(0));
      expect(ctrl.submittedLarderItems.single.quantity, equals(2));

      // Host marks order as Stocked in Villa -> next poll clears submitted items
      orderDelivered = true;
      await ctrl.refreshFromBackend();
      expect(ctrl.larderOrderStatus, equals('Stocked in Villa'));
      expect(ctrl.isLarderOrderConfirmed, isFalse);
      expect(ctrl.larderTotalCount, equals(0));
      expect(ctrl.submittedLarderItems, isEmpty);

      // Guest adds a new item to place a second order
      ctrl.updateLarderQuantity('larder-3', 1);
      expect(ctrl.larderOrderStatus, isEmpty);
      expect(ctrl.isLarderOrderConfirmed, isFalse);
      expect(ctrl.larderTotalCount, equals(1));

      final reordered = await ctrl.confirmVillaStocking();
      expect(reordered, isTrue);
      expect(ctrl.larderOrderStatus, equals('Pending'));
      expect(ctrl.isLarderOrderConfirmed, isTrue);
      expect(ctrl.larderTotalCount, equals(0));
      expect(ctrl.submittedLarderItems.single.id, equals('larder-3'));
      ctrl.dispose();
    });

    test('test_milestone11_bookingsLockOnceRequestedAndWaitForHostApproval',
        () async {
      final ctrl = SanctuaryController(
        repository: ApiSanctuaryRepository(enableNetwork: false),
        soundscape: SanctuarySoundscapeSynthesizer(),
      );
      await ctrl.initialize();

      // Seed data starts unconfirmed with empty dates
      expect(ctrl.yachtCharter.isConfirmed, isFalse);
      expect(ctrl.yachtCharter.bookingStatus, isEmpty);
      expect(ctrl.diningReservation.isConfirmed, isFalse);
      expect(ctrl.diningReservation.bookingStatus, isEmpty);

      // Submit Yacht -> REQUESTED (not auto-confirmed), then locked
      final yachtSent = await ctrl.submitYachtCharterRequest();
      expect(yachtSent, isTrue);
      expect(ctrl.yachtCharter.bookingStatus, equals('REQUESTED'));
      expect(ctrl.yachtCharter.isConfirmed, isFalse);
      expect(await ctrl.submitYachtCharterRequest(), isFalse);

      // Submit Dining -> REQUESTED (not auto-confirmed), then locked
      final diningSent = await ctrl.confirmDiningReservation();
      expect(diningSent, isTrue);
      expect(ctrl.diningReservation.bookingStatus, equals('REQUESTED'));
      expect(ctrl.diningReservation.isConfirmed, isFalse);
      expect(await ctrl.confirmDiningReservation(), isFalse);

      // Reserve Experience -> REQUESTED, then locked
      final expId = ctrl.experiences.first.id;
      ctrl.toggleExperienceReservation(
        expId,
        scheduledDate: 'Nov 13, 2026',
        scheduledTimeSlot: '11:00 AM',
      );
      final reservedExp = ctrl.experiences.firstWhere((e) => e.id == expId);
      expect(reservedExp.bookingStatus, equals('REQUESTED'));
      expect(reservedExp.scheduledDate, equals('Nov 13, 2026'));
      expect(reservedExp.scheduledTimeSlot, equals('11:00 AM'));

      // Trying to modify a locked experience is ignored
      ctrl.toggleExperienceReservation(
        expId,
        scheduledDate: 'Nov 15, 2026',
        scheduledTimeSlot: '04:30 PM',
      );
      expect(
        ctrl.experiences.firstWhere((e) => e.id == expId).scheduledDate,
        equals('Nov 13, 2026'),
      );
      ctrl.dispose();
    });
  });
}
