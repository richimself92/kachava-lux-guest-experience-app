import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kachava_guest_portal/application/sanctuary_controller.dart';
import 'package:kachava_guest_portal/core/audio/soundscape_port.dart';
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

SanctuaryFetched _villa102() =>
    SanctuaryFetched(Villa102SeedData.buildDefaultSnapshot(_uuid));

/// Fake repository whose fetches stay pending until the test completes them.
FakeSanctuaryRepository _gatedRepository(
        List<Completer<SanctuaryFetchResult>> gates) =>
    FakeSanctuaryRepository(onFetch: (_) {
      final gate = Completer<SanctuaryFetchResult>();
      gates.add(gate);
      return gate.future;
    });

SanctuaryController _apiController(MockClient client) =>
    _controllerFor(ApiSanctuaryRepository(
        baseUrl: 'http://localhost:3001/api/v1', httpClient: client));

void main() {
  group('Disposal and in-flight requests', () {
    test('test_dispose_duringInFlightPoll_completesWithoutTouchingState',
        () async {
      final gates = <Completer<SanctuaryFetchResult>>[];
      final c = _controllerFor(_gatedRepository(gates));
      final poll = c.refreshFromBackend();

      c.dispose();
      gates.single.complete(_villa102());

      await expectLater(poll, completes);
      expect(c.hasServerData, isFalse);
    });

    test('test_dispose_duringRefreshAfterConciergeRequest_returnsFalseSafely',
        () async {
      final gates = <Completer<SanctuaryFetchResult>>[];
      final c = _controllerFor(_gatedRepository(gates));
      final first = c.initialize();
      gates.single.complete(_villa102());
      await first;

      final request = c.createConciergeRequest(
          title: 'Ice', category: 'Concierge', details: '');
      await pumpEventQueue();
      c.dispose();
      gates.last.complete(_villa102());

      expect(await request, isFalse);
    });
  });

  group('Manual refresh shares the poller in-flight guard', () {
    test('test_manualRefresh_whileFirstLoadInFlight_doesNotFetchAgain',
        () async {
      final gates = <Completer<SanctuaryFetchResult>>[];
      final repo = _gatedRepository(gates);
      final c = _controllerFor(repo);

      final first = c.initialize();
      final manual = c.refreshFromBackend();
      expect(repo.fetchCount, 1);

      gates.single.complete(_villa102());
      await Future.wait([first, manual]);
      expect(c.hasServerData, isTrue);
      c.dispose();
    });

    testWidgets('test_manualRefresh_neverOverlapsTimedPoll', (tester) async {
      final gates = <Completer<SanctuaryFetchResult>>[];
      final repo = _gatedRepository(gates);
      final c = _controllerFor(repo)..startLivePolling();

      await tester.pump(const Duration(seconds: 10));
      expect(repo.fetchCount, 1);
      unawaited(c.refreshFromBackend());
      await tester.pump(const Duration(seconds: 10));
      expect(repo.fetchCount, 1, reason: 'timed poll still in flight');

      gates.single.complete(_villa102());
      await tester.pump();
      unawaited(c.refreshFromBackend());
      await tester.pump();
      expect(repo.fetchCount, 2);

      gates.last.complete(_villa102());
      c.dispose();
      await tester.pump(const Duration(seconds: 30));
      expect(repo.fetchCount, 2, reason: 'dispose stops the poller');
    });
  });

  group('No success without server confirmation', () {
    test('test_stepUp_serverRejects_staysUnverifiedAndCheckoutIsBlocked',
        () async {
      final repo = FakeSanctuaryRepository.villa102()
        ..onStepUp = (_) async => null;
      final c = _controllerFor(repo);
      await c.initialize();

      expect(await c.verifyStepUp('Miller'), isFalse);
      expect(c.isStepUpVerified, isFalse);
      expect(c.activeToastMessage, isNot(contains('verified')));
      expect(await c.completeExpressCheckout(), isFalse);
      expect(repo.mutationCalls, isNot(contains('checkout')));
      c.dispose();
    });

    test('test_stepUp_isUnverifiedUntilServerAnswers', () async {
      final answer = Completer<String?>();
      final repo = FakeSanctuaryRepository.villa102()
        ..onStepUp = (_) => answer.future;
      final c = _controllerFor(repo);
      await c.initialize();

      final verifying = c.verifyStepUp('102');
      await pumpEventQueue();
      expect(c.isStepUpVerified, isFalse);

      answer.complete('server-token');
      expect(await verifying, isTrue);
      expect(repo.stepUpAnswers, equals(['102']));
      expect(await c.completeExpressCheckout(), isTrue);
      expect(repo.lastCheckoutToken, equals('server-token'));
      c.dispose();
    });

    test('test_switchSignaturePrivilege_showsNoCoordinationClaim', () async {
      final c = _controllerFor(FakeSanctuaryRepository.villa102());
      await c.initialize();
      final checklistBefore = c.completedChecklistCount;

      c.switchSignaturePrivilege('golf');

      expect(c.activeToastMessage, isNull);
      expect(c.completedChecklistCount, equals(checklistBefore));
      c.dispose();
    });

    test('test_chatMessage_whenSendFails_isRemovedAndErrorShown', () async {
      final repo = FakeSanctuaryRepository.villa102(
          mutationResult: const MutationFailed());
      final c = _controllerFor(repo);
      await c.initialize();

      expect(await c.sendChatMessage('Hello host'), isFalse);

      expect(c.chatMessages.any((m) => m.text == 'Hello host'), isFalse);
      expect(c.activeToastMessage, equals(c.i18n.mutationFailed));
      c.dispose();
    });

    test('test_failedMutation_notifiesListenersWithErrorFlagAlreadySet',
        () async {
      final c = _controllerFor(FakeSanctuaryRepository.villa102(
          mutationResult: const MutationFailed()));
      await c.initialize();
      final seen = <bool>[];
      c.addListener(() => seen.add(c.isToastError));

      await c.submitYachtCharterRequest();

      expect(seen, isNotEmpty);
      expect(seen.last, isTrue);
      c.dispose();
    });
  });

  group('Polling notifications and link states', () {
    test('test_pollWithIdenticalPayload_doesNotNotifyListeners', () async {
      var body = jsonEncode({
        'data': {'villaName': 'Villa 106', 'status': 'ACTIVE_STAY'},
      });
      final c = _apiController(
          MockClient((_) async => http.Response(body, 200, headers: _json)));
      await c.initialize();
      var notifications = 0;
      c.addListener(() => notifications++);

      await c.refreshFromBackend();
      expect(notifications, 0);

      body = jsonEncode({
        'data': {'villaName': 'Villa 107', 'status': 'ACTIVE_STAY'},
      });
      await c.refreshFromBackend();
      expect(notifications, 1);
      c.dispose();
    });

    testWidgets('test_http403_showsAccessRestricted', (tester) async {
      final c = _apiController(
          MockClient((_) async => http.Response('{}', 403, headers: _json)));
      await tester.runAsync(c.initialize);

      await tester.pumpWidget(KachavaGuestPortalApp(controller: c));
      await tester.pumpAndSettle();

      expect(c.isUuidValid, isFalse);
      expect(find.textContaining('Access Restricted'), findsWidgets);
      expect(find.byKey(const Key('reconnecting-indicator')), findsNothing);
      c.dispose();
    });

    testWidgets('test_malformedFirstPayload_showsReconnectingNotStuckLoading',
        (tester) async {
      final c = _apiController(MockClient((_) async => http.Response(
          jsonEncode({
            'data': {'status': 42},
          }),
          200,
          headers: _json)));
      await tester.runAsync(c.initialize);

      await tester.pumpWidget(KachavaGuestPortalApp(controller: c));
      await tester.pump();

      expect(c.isReconnecting, isTrue);
      expect(find.byKey(const Key('reconnecting-indicator')), findsOneWidget);
      expect(find.text(c.i18n.reconnecting), findsOneWidget);
      c.dispose();
    });
  });
}
