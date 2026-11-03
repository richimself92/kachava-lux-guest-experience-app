import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_guest_portal/application/sanctuary_controller.dart';
import 'package:kachava_guest_portal/core/audio/soundscape_port.dart';
import 'package:kachava_guest_portal/core/constants/screen_id.dart';
import 'package:kachava_guest_portal/core/i18n/guest_feedback_i18n.dart';
import 'package:kachava_guest_portal/core/i18n/guest_i18n.dart';
import 'package:kachava_guest_portal/data/repositories/sanctuary_wire_mapper.dart';
import 'package:kachava_guest_portal/domain/repositories/sanctuary_repository.dart';
import 'package:kachava_guest_portal/main.dart';

import 'support/fake_sanctuary_repository.dart';
import 'support/villa_102_seed_data.dart';

const _uuid = '3f2b8c1e-4d5a-4b6c-8d7e-9f0a1b2c3d4e';
const _en = GuestI18n(GuestLocale.en);
const _es = GuestI18n(GuestLocale.es);

SanctuaryController _controllerFor(FakeSanctuaryRepository repository) =>
    SanctuaryController(
      repository: repository,
      soundscape: SanctuarySoundscapeSynthesizer(),
      requireExplicitGuestId: true,
      initialUri: Uri.parse('https://kachavalux.com/?guestId=$_uuid'),
    );

Map<String, dynamic> _payload() => {
      'status': 'ACTIVE_STAY',
      'villaName': 'Villa 102',
      'hostInfo': {'name': 'Eduardo Rivera', 'role': 'Private Host'},
      'conciergeRequests': [
        {
          'requestId': 'req-a',
          'title': 'Towels',
          'assignedTo': 'Eduardo',
          'messages': [
            {'sender': 'CONCIERGE', 'senderName': 'Eduardo', 'text': 'Hi'},
            {'sender': 'HOST', 'text': 'On our way'},
          ],
        },
        {
          'requestId': 'req-b',
          'title': 'Ice',
          'assignedStaffName': 'Carlos M.'
        },
        {'requestId': 'req-c', 'title': 'Water'},
      ],
    };

void main() {
  group('Resort Host terminology (EN/ES)', () {
    test('test_i18n_resortHostFallbackIsBilingual', () {
      expect(_en.resortHost, 'Resort Host');
      expect(_es.resortHost, 'Anfitrión del resort');
      expect(_en.hostLabel(''), 'Resort Host');
      expect(_en.hostLabel('Eduardo'), 'Eduardo');
      expect(_es.hostLabel('  '), 'Anfitrión del resort');
    });

    test('test_i18n_noUnbackedResponseTimePromise', () {
      for (final i18n in [_en, _es]) {
        expect(i18n.midStayShared, isNot(contains('7')));
        expect(i18n.midStayShared, isNot(contains('HOST ADMIN')));
        expect(i18n.submittedJustNow, isNot(contains('SLA')));
      }
    });

    test('test_newConciergeRequest_hasNoFabricatedAssigneeAndLocalizedTime',
        () async {
      final repo = FakeSanctuaryRepository.villa102();
      final c = _controllerFor(repo);
      await c.initialize();
      c.toggleLocale();

      await c.createConciergeRequest(
          title: 'Fresh towels', category: 'Housekeeping', details: 'Two');

      final sent = repo.conciergeRequests.single;
      expect(sent.assignedTo, isEmpty);
      expect(sent.timestampLabel, _es.requestedJustNow);
      c.dispose();
    });

    test('test_midStayCheckIn_labelIsLocalizedWithoutSla', () async {
      final c = _controllerFor(FakeSanctuaryRepository.villa102());
      await c.initialize();

      await c.submitMidStayCheckIn(
        rating: 5,
        sentimentId: 'serene',
        housekeepingWindow: 'Morning',
        focusAreas: const [],
        notes: '',
        requestPriorityCallback: false,
      );

      expect(c.latestMidStayCheckIn?.submittedAtLabel, _en.submittedJustNow);
      c.dispose();
    });

    test('test_chatMessage_optimisticLabelIsLocalized', () async {
      final repo = FakeSanctuaryRepository.villa102();
      final c = _controllerFor(repo);
      await c.initialize();
      c.toggleLocale();

      await c.sendChatMessage('Gracias');

      expect(c.chatMessages.last.timestampLabel, _es.sentJustNow);
      c.dispose();
    });
  });

  group('Wire mapping uses server people, never name rules', () {
    test('test_hostName_isKeptAsSentByServer', () {
      final s = SanctuaryWireMapper.mapSnapshot(_uuid, _payload());
      expect(s.stay.privateHostName, 'Eduardo Rivera');
    });

    test('test_conciergeAssignee_comesFromServerOrStaysEmpty', () {
      final s = SanctuaryWireMapper.mapSnapshot(_uuid, _payload());
      expect(s.conciergeRequests.map((r) => r.assignedTo).toList(),
          ['Eduardo', 'Carlos M.', '']);
    });

    test('test_hostChatAuthor_comesFromServerOrStaysEmpty', () {
      final s = SanctuaryWireMapper.mapSnapshot(_uuid, _payload());
      final hosts = s.chatMessages.where((m) => m.isFromHost).toList();
      expect(hosts.map((m) => m.senderName).toList(), ['Eduardo', '']);
    });
  });

  group('Folio total uses server lines only', () {
    test('test_folioTotal_sumsEveryPaidServerLineWithoutIdRules', () async {
      final snapshot = Villa102SeedData.buildDefaultSnapshot(_uuid);
      final c = _controllerFor(FakeSanctuaryRepository(
          onFetch: (_) async => SanctuaryFetched(snapshot)));
      await c.initialize();

      final paid = snapshot.folioItems
          .where((i) => !i.isIncludedPrivilege)
          .fold<int>(0, (s, i) => s + i.amountUsd);
      expect(snapshot.folioItems.map((i) => i.id), contains('fol-paid-2'));
      expect(c.folioTotalIncidentalsUsd, paid);
      c.dispose();
    });
  });

  group('Concierge screen falls back to Resort Host', () {
    testWidgets('test_unassignedRequestAndUnnamedHost_showResortHost',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      final snapshot = SanctuaryWireMapper.mapSnapshot(_uuid, _payload());
      final c = _controllerFor(FakeSanctuaryRepository(
          onFetch: (_) async => SanctuaryFetched(snapshot)));
      await c.initialize();
      c.navigateTo(ScreenId.concierge);

      await tester.pumpWidget(KachavaGuestPortalApp(controller: c));
      await tester.pumpAndSettle();

      expect(find.textContaining('Assigned to: Resort Host'), findsWidgets);
      expect(find.text('Resort Host'), findsWidgets);
      expect(find.textContaining('HOST ADMIN ·'), findsNothing);
      c.dispose();
    });
  });
}
