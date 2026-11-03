import 'package:kachava_admin_dashboard/domain/admin_enums.dart';
import 'support/open_workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/application/admin_dashboard_controller.dart';
import 'package:kachava_admin_dashboard/application/inspector_selection.dart';
import 'package:kachava_admin_dashboard/core/admin_i18n.dart';
import 'package:kachava_admin_dashboard/core/alert_chime_port.dart';
import 'package:kachava_admin_dashboard/data/admin_staff_mapper.dart';
import 'package:kachava_admin_dashboard/data/admin_sync_mapper.dart';
import 'package:kachava_admin_dashboard/data/admin_wire_mapper.dart';
import 'support/seeded_admin_repository.dart';
import 'package:kachava_admin_dashboard/domain/admin_stay_entities.dart';
import 'package:kachava_admin_dashboard/main.dart';
import 'package:kachava_admin_dashboard/presentation/widgets/slide_over_inspector_drawer.dart';
import 'support/fake_resort_repositories.dart';

import 'support/admin_sync_envelope.dart';

class _SilentChime implements AlertChimePort {
  @override
  bool get isRinging => false;
  @override
  void triggerTenSecondChime({void Function()? onAutoStop}) {}
  @override
  void stopChime() {}
  @override
  void dispose() {}
}

final _staffWire = [
  for (final (id, name) in [('srv_ana', 'Ana Ruiz'), ('srv_ben', 'Ben Ortiz')])
    {'staffId': id, 'fullName': name, 'shortName': name},
];

const _fabricated = [
  'villa-102',
  'Villa 102',
  'Visa •••• 8412',
  'stay_1',
  'staff_carlos',
  'staff_eduardo',
  'staff_sofia',
  'Guest',
  'HOST ADMIN',
  'Just now',
  'PRE_AUTHORIZED',
];

void _expectNoFabricated(List<String> values) {
  for (final v in values) {
    expect(_fabricated, isNot(contains(v)), reason: 'fabricated "$v"');
  }
}

Future<AdminDashboardController> _controllerWith(
    Map<String, dynamic> envelope) async {
  final repo =
      SeededAdminRepository(initialData: AdminSyncMapper.parse(envelope))
        ..syncStaff(AdminStaffMapper.parseDirectory(_staffWire));
  final controller =
      AdminDashboardController(repository: repo, alertChime: _SilentChime());
  await controller.initialize();
  return controller;
}

Future<void> _pumpDrawer(WidgetTester tester, AdminDashboardController c,
    AdminDrawerSelection selection) async {
  await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body:
              SlideOverInspectorDrawer(controller: c, selection: selection))));
  await tester.pumpAndSettle();
}

String? _drawerStaffValue(WidgetTester tester) => tester
    .widget<DropdownButton<String>>(find.descendant(
        of: find.byKey(const Key('drawer-staff-dropdown')),
        matching: find.byType(DropdownButton<String>)))
    .value;

void main() {
  group('Wire mapper never invents values', () {
    test('test_mapStay_missingFields_leavesEmptyInsteadOfFabricated', () {
      // Arrange
      final raw = {'stayId': 'stay_live_9'};
      // Act
      final stay = AdminWireMapper.mapStay(raw);
      // Assert
      _expectNoFabricated([
        stay.villaId,
        stay.villaName,
        stay.guestNames,
        stay.cardReference,
        stay.paymentStatus,
        stay.assignedMajordomoName,
        stay.transfer.assignedChauffeurId,
      ]);
      expect(stay.villaId, isEmpty);
      expect(stay.villaName, isEmpty);
      expect(stay.guestNames, isEmpty);
      expect(stay.cardReference, isEmpty);
      expect(stay.paymentStatus, isEmpty);
      expect(stay.transfer.assignedChauffeurId, isEmpty);
      expect(stay.nights, 0);
    });

    test('test_parseStays_stayWithoutId_isSkippedWithoutCrash', () {
      // Arrange
      final raw = [
        {
          'guestProfile': {'name': 'No Id'}
        },
        {'stayId': 'stay_live_9'},
      ];
      // Act
      final stays = AdminWireMapper.parseStays(raw);
      // Assert
      expect(stays.map((s) => s.stayId), ['stay_live_9']);
    });

    test('test_parseAlerts_missingFields_emptyAndIdlessAlertSkipped', () {
      // Arrange
      final raw = [
        {'alertId': 'alt_live', 'category': 'CONCIERGE'},
        {'title': 'No id'},
      ];
      // Act
      final alerts = AdminWireMapper.parseAlerts(raw);
      // Assert
      expect(alerts.map((a) => a.alertId), ['alt_live']);
      final a = alerts.single;
      _expectNoFabricated([a.villaId, a.villaName, a.guestNames]);
      expect(a.createdAtLabel, isEmpty);
    });

    test('test_parseBookings_missingStaff_unassignedAndIdlessSkipped', () {
      // Arrange
      final raw = [
        {'bookingId': 'bkg_live', 'title': 'Cenote'},
        {'title': 'No id'},
      ];
      // Act
      final bookings = AdminWireMapper.parseBookings(raw, const []);
      // Assert
      expect(bookings.map((b) => b.bookingId), ['bkg_live']);
      final b = bookings.single;
      _expectNoFabricated(
          [b.villaName, b.guestNames, b.assignedStaffId, b.assignedStaffName]);
      expect(b.assignedStaffId, isEmpty);
      expect(b.assignedStaffName, isEmpty);
    });

    test('test_parseLarderOrders_missingStayAndStaff_notFabricated', () {
      // Arrange
      final raw = [
        {'orderItemId': 'li_1', 'name': 'Mezcal', 'priceUsd': 90},
      ];
      // Act
      final order = AdminWireMapper.parseLarderOrders(raw, const []).single;
      // Assert
      _expectNoFabricated([
        order.stayId,
        order.villaName,
        order.guestNames,
        order.assignedStaffId,
        order.assignedStaffName,
      ]);
      expect(order.assignedStaffId, isEmpty);
    });

    test('test_parseConciergeAndPulses_missingFields_notFabricated', () {
      // Arrange
      final tickets = [
        {
          'requestId': 'req_live',
          'photoStoragePath': '/uploads/x.jpg',
          'messages': [
            {'messageId': 'm1', 'text': 'Hola'}
          ],
        },
        {'title': 'No id'},
      ];
      final pulses = [
        {'checkInId': 'pulse_live'},
        {'notes': 'No id'},
      ];
      // Act
      final t = AdminWireMapper.parseConciergeTickets(tickets, const []);
      final p = AdminWireMapper.parseMidStayPulses(pulses, const []);
      // Assert
      expect(t.map((e) => e.requestId), ['req_live']);
      expect(p.map((e) => e.checkInId), ['pulse_live']);
      _expectNoFabricated([
        t.single.villaName,
        t.single.guestNames,
        t.single.assignedStaffId,
        t.single.assignedStaffName,
        t.single.messages.single.senderName,
        t.single.messages.single.timestampLabel,
        p.single.villaName,
        p.single.guestNames,
        p.single.handledByStaffName,
      ]);
      expect(t.single.signedPhotoGetUrl, isNull);
    });
  });

  group('Domain entities carry no invented defaults', () {
    test('test_stayRecord_omittedOptionals_areEmptyNotFabricated', () {
      // Arrange + Act
      final stay = AdminWireMapper.mapStay({'stayId': 's'});
      final bare = AdminStayRecord(
          stayId: 's',
          guestTokenUuid: '',
          villaId: '',
          villaName: '',
          guestNames: '',
          checkInDate: '',
          checkOutDate: '',
          lifecycleStatus: stay.lifecycleStatus,
          assignedMajordomoName: '',
          personalization: stay.personalization,
          transfer: stay.transfer,
          cardReference: '');
      // Assert
      expect(bare.nights, 0);
      expect(bare.wifiSsid, isEmpty);
      expect(bare.wifiPasscode, isEmpty);
      expect(bare.paymentStatus, isEmpty);
    });
  });

  group('Cache never assigns an arbitrary staff member', () {
    test('test_assignBooking_unknownStaffId_leavesUnassignedNotFirstStaff',
        () async {
      // Arrange
      final repo = SeededAdminRepository(
          initialData: AdminSyncMapper.parse(adminSyncEnvelope(bookings: [
        {'bookingId': 'bkg_live', 'assignedStaffId': 'srv_ben'}
      ])))
        ..syncStaff(AdminStaffMapper.parseDirectory(_staffWire));
      // Act
      final b = await repo.assignAndUpdateBooking(
          bookingId: 'bkg_live', staffId: 'ghost', status: 'Confirmed');
      // Assert
      expect(b.assignedStaffId, isEmpty);
      expect(b.assignedStaffName, isEmpty);
    });

    test('test_staffLabel_emptyName_showsUnassignedInBothLocales', () {
      expect(AdminI18n.staffLabel('', false), 'Unassigned');
      expect(AdminI18n.staffLabel('', true), 'Sin asignar');
      expect(AdminI18n.staffLabel('Ana Ruiz', true), 'Ana Ruiz');
      expect(AdminI18n.orDash('  '), '—');
      expect(AdminI18n.orDash('Villa 3'), 'Villa 3');
    });
  });

  group('Inspector drawer staff selection', () {
    testWidgets('test_drawer_stayWithoutChauffeur_preselectsNoStaff',
        (tester) async {
      // Arrange
      final c = await _controllerWith(
          adminSyncEnvelope(stays: [liveStayWire(stayId: 'stay_a')]));
      // Act
      await _pumpDrawer(
          tester,
          c,
          const AdminDrawerSelection(
              type: InspectorRecordType.stay,
              recordId: 'stay_a',
              title: 't',
              subtitle: 's'));
      // Assert
      expect(_drawerStaffValue(tester), isNull);
      expect(find.text('Unassigned'), findsOneWidget);
      await tester.tap(find.byKey(const Key('drawer-staff-dropdown')));
      await tester.pumpAndSettle();
      expect(find.text('Ana Ruiz'), findsWidgets);
      expect(find.text('Ben Ortiz'), findsWidgets);
    });

    testWidgets('test_drawer_booking_preselectsServerAssignedStaff',
        (tester) async {
      // Arrange
      final c = await _controllerWith(adminSyncEnvelope(bookings: [
        {'bookingId': 'bkg_live', 'assignedStaffId': 'srv_ben'}
      ]));
      // Act
      await _pumpDrawer(
          tester,
          c,
          const AdminDrawerSelection(
              type: InspectorRecordType.booking,
              recordId: 'bkg_live',
              title: 't',
              subtitle: 's'));
      // Assert
      expect(_drawerStaffValue(tester), 'srv_ben');
    });
  });

  group('New stay dialog requires dates', () {
    ElevatedButton submit(WidgetTester tester) => tester.widget<ElevatedButton>(
        find.byKey(const Key('confirm-create-stay-btn')));

    testWidgets('test_newStayDialog_emptyDates_submitDisabledUntilFilled',
        (tester) async {
      // Arrange
      tester.view.physicalSize = const Size(1440, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(KachavaAdminApp(
          resort: fakeResortRepositories(),
          timeZones: testTimeZones,
          repository: SeededAdminRepository()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-tab-admin-stays')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('create-new-stay-btn')));
      await tester.pumpAndSettle();
      // Act + Assert
      await tester.enterText(
          find.byKey(const Key('new-stay-guest-input')), 'Nadia Boulanger');
      await tester.pump();
      expect(submit(tester).onPressed, isNull);
      await tester.enterText(
          find.byKey(const Key('new-stay-checkin-input')), 'Dec 1, 2026');
      await tester.pump();
      expect(submit(tester).onPressed, isNull);
      await tester.enterText(
          find.byKey(const Key('new-stay-checkout-input')), 'Dec 4, 2026');
      await tester.pump();
      expect(submit(tester).onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('confirm-create-stay-btn')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Nov 20, 2026'), findsNothing);
      expect(find.textContaining('Dec 1, 2026'), findsWidgets);
    });
  });

  group('Workspaces render missing values honestly', () {
    Future<void> pumpLive(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final repo = SeededAdminRepository(
          initialData: AdminSyncMapper.parse(adminSyncEnvelope(stays: [
        {'stayId': 'stay_bare'}
      ], bookings: [
        {'bookingId': 'bkg_bare', 'title': 'Cenote', 'stayId': 'stay_bare'}
      ], larderOrders: [
        {'orderItemId': 'li_bare', 'stayId': 'stay_bare', 'name': 'Mezcal'}
      ])))
        ..syncStaff(AdminStaffMapper.parseDirectory(_staffWire));
      await tester.pumpWidget(KachavaAdminApp(
          resort: fakeResortRepositories(),
          timeZones: testTimeZones,
          repository: repo));
      await tester.pumpAndSettle();
    }

    testWidgets('test_experiences_bookingWithoutStaff_showsUnassigned',
        (tester) async {
      // Arrange
      await pumpLive(tester);
      // Act
      await openWorkspace(tester, AdminWorkspaceTab.adminExperiences);
      await tester.pumpAndSettle();
      // Assert
      expect(find.text('Assigned: Unassigned'), findsOneWidget);
      expect(find.textContaining('— · —'), findsWidgets);
      expect(find.textContaining('Assigned: HOST ADMIN'), findsNothing);
    });

    testWidgets('test_larderAssign_assignsSignedInStaffNotHardcodedId',
        (tester) async {
      // Arrange
      await pumpLive(tester);
      await openWorkspace(tester, AdminWorkspaceTab.adminLarder);
      await tester.pumpAndSettle();
      expect(find.textContaining('Unassigned'), findsOneWidget);
      expect(find.textContaining('Complimentary Staples'), findsNothing);
      // Act
      await tester.tap(find.byKey(const Key('assign-larder-li_bare')));
      await tester.pumpAndSettle();
      // Assert
      expect(find.textContaining('Ana Ruiz'), findsWidgets);
    });
  });
}
