import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kachava_guest_portal/application/sanctuary_controller.dart';
import 'package:kachava_guest_portal/application/sanctuary_poller.dart';
import 'package:kachava_guest_portal/core/audio/soundscape_port.dart';
import 'package:kachava_guest_portal/core/constants/screen_id.dart';
import 'package:kachava_guest_portal/core/i18n/guest_feedback_i18n.dart';
import 'package:kachava_guest_portal/data/repositories/api_sanctuary_repository.dart';
import 'package:kachava_guest_portal/domain/repositories/sanctuary_repository.dart';
import 'package:kachava_guest_portal/main.dart';

import 'support/fake_sanctuary_repository.dart';
import 'support/villa_102_seed_data.dart';

const _uuid = '3f2b8c1e-4d5a-4b6c-8d7e-9f0a1b2c3d4e';
const _json = {'content-type': 'application/json; charset=utf-8'};

SanctuaryController _controllerFor(SanctuaryRepository repository) =>
    SanctuaryController(
      repository: repository,
      soundscape: SanctuarySoundscapeSynthesizer(),
      requireExplicitGuestId: true,
      initialUri: Uri.parse('https://kachavalux.com/?guestId=$_uuid'),
    );

/// Serves a real stay until [status] is switched to an error code.
class _SwitchableServer {
  int status = 200;

  late final MockClient client = MockClient((_) async {
    if (status != 200) return http.Response('{}', status, headers: _json);
    return http.Response(
      jsonEncode({
        'success': true,
        'data': {
          'status': 'ACTIVE_STAY',
          'villaName': 'Villa 106 — Copal Pavilion',
          'guestProfile': {'name': 'Juan & Maria'},
        },
      }),
      200,
      headers: _json,
    );
  });

  SanctuaryController controller() => _controllerFor(ApiSanctuaryRepository(
      baseUrl: 'http://localhost:3001/api/v1', httpClient: client));
}

void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
}

void main() {
  group('SanctuaryController connection state', () {
    test('test_newController_beforeServerResponse_holdsNoGuestData', () {
      final controller = _controllerFor(FakeSanctuaryRepository.villa102());

      expect(controller.hasServerData, isFalse);
      expect(controller.stay.guestNames, isEmpty);
      expect(controller.stay.villaTitle, isEmpty);
      expect(controller.conciergeRequests, isEmpty);
      expect(controller.checklist, isEmpty);
      controller.dispose();
    });

    test('test_refresh_after503_keepsLastDataAndFlagsReconnecting', () async {
      final server = _SwitchableServer();
      final controller = server.controller();
      await controller.initialize();

      server.status = 503;
      await controller.refreshFromBackend();

      expect(controller.isUuidValid, isTrue);
      expect(controller.hasServerData, isTrue);
      expect(controller.isReconnecting, isTrue);
      expect(controller.stay.guestNames, equals('Juan & Maria'));

      server.status = 200;
      await controller.refreshFromBackend();
      expect(controller.isReconnecting, isFalse);
      controller.dispose();
    });

    test('test_refresh_after404_marksLinkInvalid', () async {
      final server = _SwitchableServer();
      final controller = server.controller();
      await controller.initialize();

      server.status = 404;
      await controller.refreshFromBackend();

      expect(controller.isUuidValid, isFalse);
      controller.dispose();
    });

    test('test_everyMutation_whenServerFails_returnsFalseWithoutSuccessToast',
        () async {
      final repo = FakeSanctuaryRepository.villa102(
          mutationResult: const MutationFailed());
      final c = _controllerFor(repo);
      await c.initialize();
      final failureMessage = c.i18n.mutationFailed;
      final attempts = <String, Future<bool> Function()>{
        'flight': () => c.updateFlightDetails(c.transport),
        'personalization': () => c.savePersonalization(c.preferences),
        'yacht': c.submitYachtCharterRequest,
        'dining': c.confirmDiningReservation,
        'concierge': () => c.createConciergeRequest(
            title: 'Ice bucket', category: 'Concierge', details: ''),
        'midstay': () => c.submitMidStayCheckIn(
            rating: 4,
            sentimentId: 'tuned',
            housekeepingWindow: '10:30 AM',
            focusAreas: const [],
            notes: '',
            requestPriorityCallback: false),
        'larder': () {
          c.updateLarderQuantity('larder-1', 1);
          return c.confirmVillaStocking();
        },
        'checkout': () async {
          await c.verifyStepUp('Miller');
          return c.completeExpressCheckout();
        },
      };

      for (final entry in attempts.entries) {
        c.clearToast();
        expect(await entry.value(), isFalse, reason: entry.key);
        expect(c.activeToastMessage, equals(failureMessage), reason: entry.key);
        expect(c.isToastError, isTrue, reason: entry.key);
      }
      expect(c.yachtCharter.bookingStatus, isEmpty);
      expect(c.diningReservation.bookingStatus, isEmpty);
      expect(c.conciergeRequests.any((r) => r.title == 'Ice bucket'), isFalse);
      expect(c.latestMidStayCheckIn, isNull);
      expect(c.submittedLarderItems, isEmpty);
      expect(c.isReadOnly, isFalse);
      c.dispose();
    });

    test('test_experienceRequest_whenServerFails_showsErrorNotSuccess',
        () async {
      final repo = FakeSanctuaryRepository.villa102(
          mutationResult: const MutationFailed());
      final c = _controllerFor(repo);
      await c.initialize();

      c.scheduleExperience('exp-2', 'Nov 13, 2026 · 11:00 AM');
      await pumpEventQueue();

      expect(c.activeToastMessage, equals(c.i18n.mutationFailed));
      expect(c.isToastError, isTrue);
      expect(c.experiences.firstWhere((e) => e.id == 'exp-2').bookingStatus,
          isEmpty);
      c.dispose();
    });
  });

  group('Guest portal shell connection states', () {
    testWidgets('test_startup_showsLoadingScreen_notFictitiousGuest',
        (tester) async {
      final firstResponse = Completer<SanctuaryFetchResult>();
      final repo =
          FakeSanctuaryRepository(onFetch: (_) => firstResponse.future);
      final controller = _controllerFor(repo);
      unawaited(controller.initialize());

      await tester.pumpWidget(KachavaGuestPortalApp(controller: controller));
      await tester.pump();

      expect(find.byKey(const Key('sanctuary-loading-screen')), findsOneWidget);
      expect(find.byKey(const Key('sanctuary-mobile-shell')), findsNothing);
      expect(find.textContaining('Miller'), findsNothing);
      expect(find.textContaining('VILLA 102'), findsNothing);
      expect(find.textContaining('Access Restricted'), findsNothing);

      firstResponse.complete(
          SanctuaryFetched(Villa102SeedData.buildDefaultSnapshot(_uuid)));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('sanctuary-loading-screen')), findsNothing);
      expect(find.byKey(const Key('sanctuary-mobile-shell')), findsOneWidget);
      controller.dispose();
    });

    testWidgets('test_http503_keepsPriorDataAndShowsReconnecting',
        (tester) async {
      _useTallViewport(tester);
      final server = _SwitchableServer();
      final controller = server.controller();
      await tester.runAsync(controller.initialize);
      await tester.pumpWidget(KachavaGuestPortalApp(controller: controller));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reconnecting-indicator')), findsNothing);

      server.status = 503;
      await tester.runAsync(controller.refreshFromBackend);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reconnecting-indicator')), findsOneWidget);
      expect(find.text('Reconnecting…'), findsOneWidget);
      expect(find.textContaining('Juan & Maria'), findsWidgets);
      expect(find.textContaining('Access Restricted'), findsNothing);

      controller.toggleLocale();
      await tester.pumpAndSettle();
      expect(find.text('Reconectando…'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('test_http404_showsAccessRestricted', (tester) async {
      final server = _SwitchableServer()..status = 404;
      final controller = server.controller();
      await tester.runAsync(controller.initialize);

      await tester.pumpWidget(KachavaGuestPortalApp(controller: controller));
      await tester.pumpAndSettle();

      expect(find.textContaining('Access Restricted'), findsWidgets);
      expect(find.byKey(const Key('sanctuary-loading-screen')), findsNothing);
      controller.dispose();
    });

    testWidgets('test_failedYachtSubmit_showsErrorLineAndNoSuccessMessage',
        (tester) async {
      _useTallViewport(tester);
      final repo = FakeSanctuaryRepository.villa102(
          mutationResult: const MutationFailed());
      final controller = _controllerFor(repo);
      await controller.initialize();
      controller.navigateTo(ScreenId.yacht);
      await tester.pumpWidget(KachavaGuestPortalApp(controller: controller));
      await tester.pumpAndSettle();

      final requestBtn = find.byKey(const Key('yacht-reserve-btn'));
      await tester.ensureVisible(requestBtn);
      await tester.tap(requestBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Solicitud de Yate enviada'), findsNothing);
      expect(find.text(controller.i18n.mutationFailed), findsOneWidget);
      expect(find.byKey(const Key('sanctuary-error-banner')), findsOneWidget);
      expect(controller.yachtCharter.bookingStatus, isEmpty);
      controller.dispose();
    });
  });

  group('Live polling cadence', () {
    testWidgets('test_poller_neverStartsWhilePreviousPollInFlight',
        (tester) async {
      var started = 0;
      final inFlight = <Completer<void>>[];
      final poller = SanctuaryPoller(
        onPoll: () {
          started++;
          final c = Completer<void>();
          inFlight.add(c);
          return c.future;
        },
        onError: (error, _) => fail('unexpected poll error: $error'),
      );
      expect(SanctuaryPoller.defaultInterval, const Duration(seconds: 10));

      poller.start();
      await tester.pump(const Duration(seconds: 9));
      expect(started, 0);
      await tester.pump(const Duration(seconds: 1));
      expect(started, 1);

      await tester.pump(const Duration(seconds: 30));
      expect(started, 1, reason: 'previous poll still in flight');

      inFlight.single.complete();
      await tester.pump(const Duration(seconds: 10));
      expect(started, 2);
      poller.stop();
    });

    testWidgets('test_app_pollsEvery10SecondsWithoutOverlap', (tester) async {
      final hanging = Completer<SanctuaryFetchResult>();
      final snapshot = Villa102SeedData.buildDefaultSnapshot(_uuid);
      final repo = FakeSanctuaryRepository(onFetch: (_) async {
        return SanctuaryFetched(snapshot);
      });
      final controller = _controllerFor(repo);
      await controller.initialize();
      expect(repo.fetchCount, 1);

      await tester.pumpWidget(KachavaGuestPortalApp(
          controller: controller, enableLivePolling: true));
      await tester.pump(const Duration(seconds: 2));
      expect(repo.fetchCount, 1, reason: 'no 2-second polling any more');

      repo.onFetch = (_) => hanging.future;
      await tester.pump(const Duration(seconds: 8));
      expect(repo.fetchCount, 2);
      await tester.pump(const Duration(seconds: 20));
      expect(repo.fetchCount, 2, reason: 'poll in flight blocks the next one');

      hanging.complete(SanctuaryFetched(snapshot));
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });
  });
}
