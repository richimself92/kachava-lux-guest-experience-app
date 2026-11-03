import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_guest_portal/application/sanctuary_controller.dart';
import 'package:kachava_guest_portal/core/audio/soundscape_port.dart';
import 'package:kachava_guest_portal/core/constants/screen_id.dart';
import 'package:kachava_guest_portal/core/i18n/guest_feedback_i18n.dart';
import 'package:kachava_guest_portal/core/i18n/guest_i18n.dart';
import 'package:kachava_guest_portal/data/repositories/sanctuary_request_dto.dart';
import 'package:kachava_guest_portal/data/repositories/sanctuary_wire_mapper.dart';
import 'package:kachava_guest_portal/domain/entities/experience_entities.dart';
import 'package:kachava_guest_portal/domain/entities/empty_sanctuary.dart';
import 'package:kachava_guest_portal/domain/repositories/sanctuary_repository.dart';
import 'package:kachava_guest_portal/main.dart';
import 'package:kachava_guest_portal/presentation/shell/access_restricted_screen.dart';
import 'package:kachava_guest_portal/presentation/shell/step_up_verification_dialog.dart';

import 'support/fake_sanctuary_repository.dart';
import 'support/villa_102_seed_data.dart';

const _uuid = '3f2b8c1e-4d5a-4b6c-8d7e-9f0a1b2c3d4e';

Future<SanctuaryController> _pumpPortal(
  WidgetTester tester,
  SanctuarySnapshot snapshot,
  ScreenId screen,
) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  final repo =
      FakeSanctuaryRepository(onFetch: (_) async => SanctuaryFetched(snapshot));
  final c = SanctuaryController(
    repository: repo,
    soundscape: SanctuarySoundscapeSynthesizer(),
    requireExplicitGuestId: true,
    initialUri: Uri.parse('https://kachavalux.com/?guestId=$_uuid'),
  );
  await c.initialize();
  c.navigateTo(screen);
  await tester.pumpWidget(KachavaGuestPortalApp(controller: c));
  await tester.pumpAndSettle();
  return c;
}

SanctuarySnapshot _withExperience(SanctuarySnapshot s, String id,
        ExperienceItem Function(ExperienceItem) edit) =>
    SanctuarySnapshot(
      stay: s.stay,
      transport: s.transport,
      preferences: s.preferences,
      checklist: s.checklist,
      larderItems: s.larderItems,
      experiences: [
        for (final e in s.experiences) e.id == id ? edit(e) : e,
      ],
      yachtPackages: s.yachtPackages,
      yachtCharter: s.yachtCharter,
      diningMenus: s.diningMenus,
      diningReservation: s.diningReservation,
      conciergeRequests: s.conciergeRequests,
      chatMessages: s.chatMessages,
      folioItems: s.folioItems,
    );

Future<SanctuaryController> _pumpStepUpDialog(
    WidgetTester tester, GuestLocale locale) async {
  final c = SanctuaryController(
    repository: FakeSanctuaryRepository.villa102(),
    soundscape: SanctuarySoundscapeSynthesizer(),
    requireExplicitGuestId: true,
    initialUri: Uri.parse('https://kachavalux.com/?guestId=$_uuid'),
  );
  await c.initialize();
  if (c.locale != locale) c.toggleLocale();
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: StepUpVerificationDialog(controller: c, onVerified: () async {}),
    ),
  ));
  return c;
}

SanctuarySnapshot _withoutCatalogs(SanctuarySnapshot s) => SanctuarySnapshot(
      stay: s.stay,
      transport: s.transport,
      preferences: s.preferences,
      checklist: s.checklist,
      larderItems: s.larderItems,
      experiences: s.experiences,
      yachtPackages: const [],
      yachtCharter: EmptySanctuary.yachtCharter,
      diningMenus: const [],
      diningReservation: EmptySanctuary.diningReservation,
      conciergeRequests: s.conciergeRequests,
      chatMessages: s.chatMessages,
      folioItems: s.folioItems,
    );

void main() {
  group('Wire mapping invents nothing', () {
    test('test_mapSnapshot_guestWithoutMessages_hasNoWelcomeChat', () {
      final snapshot = SanctuaryWireMapper.mapSnapshot(_uuid, {
        'villaName': 'Villa 110',
        'guestProfile': {'name': 'Elena Rostova'},
      });
      expect(snapshot.chatMessages, isEmpty);
    });

    test('test_mapSnapshot_feedbackWithoutRating_hasNoDefaultRating', () {
      final snapshot = SanctuaryWireMapper.mapSnapshot(_uuid, {
        'midstayFeedback': [
          {'note': 'Lovely'},
        ],
      });
      final checkIn = snapshot.latestMidStayCheckIn!;
      expect(checkIn.rating, equals(0));
      expect(checkIn.sentimentId, isEmpty);
    });

    test('test_stayWithoutDates_hasNoInventedDateBounds', () {
      final stay = EmptySanctuary.stay(_uuid);
      expect(stay.checkInDateTime, isNull);
      expect(stay.checkOutDateTime, isNull);
      expect(stay.defaultStayDateLabel, isEmpty);
    });

    test('test_stayWithDates_keepsParsedBounds', () {
      final stay =
          EmptySanctuary.stay(_uuid).copyWith(stayDates: 'Mar 3 – Mar 7, 2027');
      expect(stay.checkInDateTime, equals(DateTime(2027, 3, 3)));
      expect(stay.checkOutDateTime, equals(DateTime(2027, 3, 7)));
      expect(stay.defaultStayDateLabel, equals('Mar 3, 2027'));
    });

    test('test_screenSubtitles_doNotNameAFictitiousVillaOrFlight', () {
      for (final screen in ScreenId.values) {
        expect(screen.subtitle, isNot(contains('102')), reason: screen.name);
        expect(screen.subtitle, isNot(contains('AA 1492')),
            reason: screen.name);
      }
    });
  });

  group('Feedback copy is bilingual and honest', () {
    const en = GuestI18n(GuestLocale.en), es = GuestI18n(GuestLocale.es);

    test('test_yachtAndDiningRequested_areLocalized', () {
      expect(en.yachtRequested, isNot(equals(es.yachtRequested)));
      expect(en.diningRequested, isNot(equals(es.diningRequested)));
      expect(en.yachtRequested, isNot(contains('Solicitud')));
    });

    test('test_mutationFailed_doesNotClaimNothingWasSent', () {
      expect(en.mutationFailed, isNot(contains('Nothing was sent')));
      expect(en.mutationFailed, contains("Couldn't confirm"));
      expect(es.mutationFailed, contains('No se pudo confirmar'));
    });
  });

  group('Screens without server data', () {
    testWidgets('test_accessRestricted_isLocalizedWithoutInventedPhone',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
          home: AccessRestrictedScreen(i18n: GuestI18n(GuestLocale.es))));
      expect(find.textContaining('Acceso restringido'), findsOneWidget);
      expect(find.textContaining('Access Restricted'), findsNothing);
      expect(find.textContaining('415'), findsNothing);
    });

    testWidgets('test_profile_showsNoInventedPhone', (tester) async {
      final c = await _pumpPortal(tester,
          Villa102SeedData.buildDefaultSnapshot(_uuid), ScreenId.profile);
      expect(find.textContaining('415'), findsNothing);
      c.dispose();
    });

    testWidgets('test_concierge_offersNoFakePhotoAttachment', (tester) async {
      final c = await _pumpPortal(tester,
          Villa102SeedData.buildDefaultSnapshot(_uuid), ScreenId.concierge);
      expect(
          find.byKey(const Key('concierge-attach-photo-chip')), findsNothing);
      c.dispose();
    });

    testWidgets('test_yachtWithoutPackages_showsOneLineEmptyState',
        (tester) async {
      final snapshot =
          _withoutCatalogs(Villa102SeedData.buildDefaultSnapshot(_uuid));
      final c = await _pumpPortal(tester, snapshot, ScreenId.yacht);
      expect(find.byKey(const Key('yacht-empty-state')), findsOneWidget);
      expect(find.byKey(const Key('yacht-reserve-btn')), findsNothing);
      c.dispose();
    });

    testWidgets('test_diningWithoutMenus_showsOneLineEmptyState',
        (tester) async {
      final snapshot =
          _withoutCatalogs(Villa102SeedData.buildDefaultSnapshot(_uuid));
      final c = await _pumpPortal(tester, snapshot, ScreenId.dining);
      expect(find.byKey(const Key('dining-empty-state')), findsOneWidget);
      expect(find.byKey(const Key('dining-confirm-btn')), findsNothing);
      c.dispose();
    });
  });
  group('Step-up prompt does not reveal the answer', () {
    for (final locale in GuestLocale.values) {
      testWidgets('test_stepUpDialog_${locale.name}_hidesVillaAndLastName',
          (tester) async {
        final c = await _pumpStepUpDialog(tester, locale);
        expect(c.stay.villaNumber, equals('102'));
        expect(c.stay.lastName, equals('Miller'));
        expect(find.textContaining('102'), findsNothing);
        expect(find.textContaining('Miller'), findsNothing);
        final prompt =
            c.i18n.t('Villa number or last name', 'Número de villa o apellido');
        expect(find.textContaining(prompt), findsWidgets);
        c.dispose();
      });
    }
  });

  group('Experience bookings invent no time slot', () {
    SanctuaryController controller() => SanctuaryController(
          repository: FakeSanctuaryRepository.villa102(),
          soundscape: SanctuarySoundscapeSynthesizer(),
          requireExplicitGuestId: true,
          initialUri: Uri.parse('https://kachavalux.com/?guestId=$_uuid'),
        );

    test('test_reserveWithoutTime_isIgnored', () async {
      final c = controller();
      await c.initialize();
      final id = c.experiences.first.id;
      c.toggleExperienceReservation(id, scheduledDate: 'Nov 13, 2026');
      c.scheduleExperience(id, 'Nov 13, 2026');
      final exp = c.experiences.firstWhere((e) => e.id == id);
      expect(exp.bookingStatus, isEmpty);
      expect(exp.scheduledTimeSlot, isEmpty);
      c.dispose();
    });

    test('test_bookingDto_withoutTime_sendsNoDefaultTime', () {
      final exp =
          Villa102SeedData.buildDefaultSnapshot(_uuid).experiences.first;
      final dto =
          SanctuaryRequestDto.toExperienceBookingDto(exp, 'Nov 13, 2026', 2);
      expect(dto['scheduledTimeSlot'], isEmpty);
    });

    testWidgets('test_explore_bannerWithoutTime_showsNoDefaultTime',
        (tester) async {
      final snapshot = _withExperience(
          Villa102SeedData.buildDefaultSnapshot(_uuid),
          'exp-2',
          (e) => e.copyWith(
              bookingStatus: 'REQUESTED', scheduledDate: 'Nov 13, 2026'));
      final c = await _pumpPortal(tester, snapshot, ScreenId.explore);
      expect(find.textContaining('Nov 13, 2026'), findsWidgets);
      expect(find.textContaining('10:00 AM'), findsNothing);
      c.dispose();
    });
  });
}
