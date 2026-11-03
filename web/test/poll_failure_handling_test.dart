import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:kachava_guest_portal/application/sanctuary_controller.dart';
import 'package:kachava_guest_portal/application/sanctuary_poller.dart';
import 'package:kachava_guest_portal/core/audio/soundscape_port.dart';
import 'package:kachava_guest_portal/core/i18n/guest_feedback_i18n.dart';
import 'package:kachava_guest_portal/data/repositories/api_sanctuary_repository.dart';
import 'package:kachava_guest_portal/domain/repositories/sanctuary_repository.dart';
import 'package:kachava_guest_portal/presentation/shell/step_up_verification_dialog.dart';

import 'support/fake_sanctuary_repository.dart';
import 'support/villa_102_seed_data.dart';

const _uuid = '3f2b8c1e-4d5a-4b6c-8d7e-9f0a1b2c3d4e';

SanctuaryController _controllerFor(SanctuaryRepository repository) =>
    SanctuaryController(
      repository: repository,
      soundscape: SanctuarySoundscapeSynthesizer(),
      requireExplicitGuestId: true,
      initialUri: Uri.parse('https://kachavalux.com/?guestId=$_uuid'),
    );

SanctuaryFetched _villa102() =>
    SanctuaryFetched(Villa102SeedData.buildDefaultSnapshot(_uuid));

void main() {
  group('Rejected link stops polling', () {
    testWidgets('test_linkRejectedOnFirstLoad_neverPollsAgain', (tester) async {
      final repo = FakeSanctuaryRepository(
          onFetch: (_) async => const SanctuaryLinkRejected());
      final c = _controllerFor(repo);
      await c.initialize();
      c.startLivePolling();

      await tester.pump(const Duration(seconds: 35));
      await c.refreshFromBackend();

      expect(c.isLinkInvalid, isTrue);
      expect(repo.fetchCount, 1);
      c.dispose();
    });

    testWidgets('test_linkRejectedDuringLivePolling_stopsTimer',
        (tester) async {
      final repo = FakeSanctuaryRepository(onFetch: (_) async => _villa102());
      final c = _controllerFor(repo);
      await c.initialize();
      c.startLivePolling();

      repo.onFetch = (_) async => const SanctuaryLinkRejected();
      await tester.pump(const Duration(seconds: 10));
      expect(repo.fetchCount, 2);
      await tester.pump(const Duration(seconds: 40));

      expect(c.isLinkInvalid, isTrue);
      expect(repo.fetchCount, 2);
      c.dispose();
    });
  });

  group('Poller reports every error', () {
    testWidgets('test_poller_throwingPoll_isReportedAndTimerKeepsRunning',
        (tester) async {
      final errors = <Object>[];
      final poller = SanctuaryPoller(
        onPoll: () async => throw StateError('boom'),
        onError: (error, _) => errors.add(error),
      );

      await poller.pollNow();
      expect(errors, hasLength(1));

      poller.start();
      await tester.pump(const Duration(seconds: 10));
      await tester.pump(const Duration(seconds: 10));
      expect(errors, hasLength(3));
      expect(errors.every((e) => e is StateError), isTrue);
      poller.stop();
    });

    test('test_nonTransientFetchError_mapsToReconnecting', () async {
      final repo = FakeSanctuaryRepository(
          onFetch: (_) async => throw StateError('unexpected'));
      final c = _controllerFor(repo);

      await c.initialize();

      expect(c.isReconnecting, isTrue);
      expect(c.hasServerData, isFalse);
      c.dispose();
    });

    test('test_apiRepository_rethrownError_isCaughtByPoller', () async {
      final c = _controllerFor(ApiSanctuaryRepository(
        baseUrl: 'http://localhost:3001/api/v1',
        httpClient: MockClient((_) async => throw StateError('bug')),
      ));

      await c.initialize();

      expect(c.isReconnecting, isTrue);
      c.dispose();
    });

    testWidgets('test_pollErrorThenRecovery_timerKeepsPolling', (tester) async {
      final repo = FakeSanctuaryRepository(
          onFetch: (_) async => throw StateError('unexpected'));
      final c = _controllerFor(repo);
      await c.initialize();
      c.startLivePolling();

      repo.onFetch = (_) async => _villa102();
      await tester.pump(const Duration(seconds: 10));

      expect(repo.fetchCount, 2);
      expect(c.hasServerData, isTrue);
      expect(c.isReconnecting, isFalse);
      c.dispose();
    });
  });

  group('Step-up dialog recovers from errors', () {
    testWidgets('test_stepUpThrows_reEnablesButtonAndShowsFailure',
        (tester) async {
      final repo = FakeSanctuaryRepository.villa102()
        ..onStepUp = (_) async => throw StateError('boom');
      final c = _controllerFor(repo);
      await c.initialize();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body:
              StepUpVerificationDialog(controller: c, onVerified: () async {}),
        ),
      ));

      await tester.enterText(
          find.byKey(const Key('step-up-input-field')), 'Miller');
      await tester.tap(find.byKey(const Key('step-up-confirm-btn')));
      await tester.pump();

      final button = tester
          .widget<ElevatedButton>(find.byKey(const Key('step-up-confirm-btn')));
      expect(button.onPressed, isNotNull);
      expect(find.text(c.i18n.stepUpFailed), findsOneWidget);
      expect(c.isStepUpVerified, isFalse);
      c.dispose();
    });
  });
}
