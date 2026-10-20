import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kachava_admin_dashboard/application/admin_dashboard_controller.dart';
import 'package:kachava_admin_dashboard/core/admin_i18n.dart';
import 'package:kachava_admin_dashboard/data/admin_api_client.dart';
import 'package:kachava_admin_dashboard/data/admin_wire_mapper.dart';
import 'package:kachava_admin_dashboard/data/api_admin_operations_repository.dart';
import 'package:kachava_admin_dashboard/domain/admin_enums.dart';
import 'package:kachava_admin_dashboard/main.dart';

void main() {
  group('Milestone 11 Track 3 — Admin Console Verification Suite', () {
    test(
        'test_extract_map_list_unwraps_alerts_and_nested_collections_and_triggers_chime',
        () async {
      final rawAlertsEnvelope = {
        'success': true,
        'alerts': [
          {
            'alertId': 'alt_nested_1',
            'stayId': 'stay_villa_102',
            'villaId': 'villa-102',
            'villaName': 'Villa 102',
            'guestName': 'Alex & Sarah Miller',
            'category': 'TRANSFER',
            'severity': 'HIGH',
            'title': 'Aviation Transfer Updated',
            'summary': 'Flight AA 1492 landing at 2:15 PM',
            'isAcknowledged': false,
          },
        ],
        'unreadCount': 1,
        'data': {
          'alerts': [
            {
              'alertId': 'alt_nested_1',
              'stayId': 'stay_villa_102',
              'villaId': 'villa-102',
              'villaName': 'Villa 102',
              'guestName': 'Alex & Sarah Miller',
              'category': 'TRANSFER',
              'severity': 'HIGH',
              'title': 'Aviation Transfer Updated',
              'summary': 'Flight AA 1492 landing at 2:15 PM',
              'isAcknowledged': false,
            },
          ],
          'unreadCount': 1,
        },
      };

      final parsed = AdminWireMapper.parseAlerts(rawAlertsEnvelope);
      expect(parsed.length, 1);
      expect(parsed.first.alertId, 'alt_nested_1');
      expect(
          AdminWireMapper.extractMapList({
            'items': [
              {'id': '1'}
            ]
          }).length,
          1);
      expect(
          AdminWireMapper.extractMapList({
            'stays': [
              {'id': '1'}
            ]
          }).length,
          1);
      expect(
          AdminWireMapper.extractMapList({
            'bookings': [
              {'id': '1'}
            ]
          }).length,
          1);
      expect(
          AdminWireMapper.extractMapList({
            'orders': [
              {'id': '1'}
            ]
          }).length,
          1);
      expect(
          AdminWireMapper.extractMapList({
            'requests': [
              {'id': '1'}
            ]
          }).length,
          1);
      expect(
          AdminWireMapper.extractMapList({
            'feedback': [
              {'id': '1'}
            ]
          }).length,
          1);

      var returnAlert = false;
      final mockHttp = MockClient((req) async {
        if (req.url.path.endsWith('/alerts')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'alerts': returnAlert
                    ? rawAlertsEnvelope['alerts']
                    : <Map<String, dynamic>>[],
                'unreadCount': returnAlert ? 1 : 0,
              },
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      final repo = ApiAdminOperationsRepository(
        apiClient: AdminApiClient(httpClient: mockHttp),
      );
      final ctrl = AdminDashboardController(repository: repo);
      await ctrl.initialize();
      expect(ctrl.unreadAlertsCount, 0);

      returnAlert = true;
      await ctrl.refreshFromBackend(silent: true);
      expect(ctrl.unreadAlertsCount, 1);
      expect(ctrl.isChimeRinging, isTrue);
      ctrl.dispose();
    });

    test(
        'test_wire_mapper_computes_exact_nights_and_maps_complete_flight_and_pulse_rating',
        () {
      final stay = AdminWireMapper.mapStay({
        'stayId': 'stay_oct_102',
        'guestTokenUuid': 'uuid-oct-102',
        'villaId': 'villa-102',
        'villaName': 'Villa 102',
        'guestName': 'Sofia & Mateo',
        'checkInDate': 'Oct 19',
        'checkOutDate': 'Oct 22',
        'status': 'ACTIVE_STAY',
        'personalization': {
          'housekeepingCadence': '11:00 AM Daily',
        },
        'flightTransfer': {
          'arrivalDate': 'Oct 19, 2026',
          'airline': 'American Airlines',
          'flightNumber': 'AA 1492',
          'arrivalAirport': 'CUN',
          'terminal': 'Terminal 3',
          'estimatedLanding': '14:25',
          'assignedDriver': 'Carlos · Escalade ESV',
          'meetingPoint': 'Puerta 4 FBO',
          'status': 'Confirmed',
        },
      });

      expect(stay.nights, 3);
      expect(stay.personalization.housekeepingCadence, '11:00 AM Daily');
      expect(stay.transfer.arrivalDate, 'Oct 19, 2026');
      expect(stay.transfer.airline, 'American Airlines');
      expect(stay.transfer.inboundFlight, 'AA 1492');
      expect(stay.transfer.inboundRoute, 'CUN');
      expect(stay.transfer.terminal, 'Terminal 3');
      expect(stay.transfer.inboundEta, '14:25');

      final pulses = AdminWireMapper.parseMidStayPulses({
        'feedback': [
          {
            'checkInId': 'pulse_rating_4',
            'stayId': 'stay_oct_102',
            'rating': 4,
            'sentiment': 'Serene & Seamless',
            'guestNote': 'Excelente servicio en la villa.',
          },
        ],
      }, [
        stay
      ]);
      expect(pulses.first.rating, 4);

      expect(
        AdminI18n.translatePref('Evening Service (07:00 PM)', true),
        'Servicio Nocturno (07:00 PM)',
      );
      expect(
        AdminI18n.translatePref('Servicio Nocturno (07:00 PM)', false),
        'Evening Service (07:00 PM)',
      );
      expect(AdminI18n.translatePref('On Request', true), 'A Solicitud');
      expect(AdminI18n.translatePref('A Solicitud', false), 'On Request');
      expect(AdminI18n.translatePref('Sin seleccionar', false), 'Not selected');
      expect(
        AdminI18n.translateText('Cleaning: Evening Service (07:00 PM)', true),
        'Limpieza: Servicio Nocturno (07:00 PM)',
      );
    });

    testWidgets(
      'test_stays_workspace_displays_nights_housekeeping_flight_box_and_checkout_confirm_dialog',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 960);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const KachavaAdminApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('nav-tab-admin-stays')));
        await tester.pumpAndSettle();

        expect(find.textContaining('(3 nights) · HOST ADMIN'), findsWidgets);
        expect(
            find.textContaining(
                '🧹 Housekeeping Schedule: 10:30 AM & 7:30 PM Turndown'),
            findsOneWidget);
        expect(find.textContaining('📅 Date:'), findsWidgets);
        expect(find.textContaining('🛬 Airport:'), findsWidgets);
        expect(find.textContaining('🚘 Chauffeur / Vehicle:'), findsWidgets);

        final releaseBtn =
            find.byKey(const Key('release-villa-stay_villa_102'));
        await tester.ensureVisible(releaseBtn);
        await tester.pumpAndSettle();
        await tester.tap(releaseBtn);
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Confirm Check-Out & Release'),
          findsWidgets,
        );
        expect(find.text('Stay Summary'), findsOneWidget);
        expect(find.text('Guest & Stay'), findsOneWidget);
        expect(find.text('Minibar & Pantry Ordered'), findsOneWidget);
        expect(
            find.text('Experiences, Yacht & Private Dining'), findsOneWidget);
        expect(find.text('Stay Rating & Feedback Survey'), findsOneWidget);
        expect(find.textContaining('Endemic Tropical Fruit Harvest'),
            findsWidgets);
        expect(find.textContaining('Galeon 470 Sky'), findsWidgets);

        await tester
            .tap(find.byKey(const Key('confirm-release-villa-stay_villa_102')));
        await tester.pumpAndSettle();
        expect(find.text('FREE VILLA / CHECKED OUT'), findsWidgets);

        // Toggle to Spanish and verify Stays Spanish labels
        await tester.tap(find.byKey(const Key('admin-locale-toggle-btn')));
        await tester.pumpAndSettle();
        expect(find.text('VILLA LIBRE / SALIDA'), findsWidgets);
        expect(find.textContaining('🧹 Horario de Limpieza:'), findsWidgets);
        expect(find.textContaining('📅 Fecha:'), findsWidgets);
        expect(find.textContaining('🛬 Aeropuerto:'), findsWidgets);
        expect(find.textContaining('🚘 Chofer / Vehículo:'), findsWidgets);
      },
    );

    testWidgets(
      'test_larder_quantities_experiences_cancel_with_reason_and_folio_summary_without_billing',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 960);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const KachavaAdminApp());
        await tester.pumpAndSettle();

        // Tab 3: Larder quantities (English default)
        await tester.tap(find.byKey(const Key('nav-tab-admin-larder')));
        await tester.pumpAndSettle();
        expect(find.textContaining('Qty: 1'), findsWidgets);
        expect(find.textContaining('Qty: 2'), findsWidgets);

        // Tab 4: Experiences approve & cancel with reason (English default)
        await tester.tap(find.byKey(const Key('nav-tab-admin-experiences')));
        await tester.pumpAndSettle();
        expect(find.text('Approve / Confirm'), findsWidgets);
        expect(find.text('Cancel with Reason'), findsWidgets);

        final approveBtn =
            find.byKey(const Key('assign-booking-bkg_102_yacht'));
        await tester.ensureVisible(approveBtn);
        await tester.tap(approveBtn);
        await tester.pumpAndSettle();

        final cancelBtn =
            find.byKey(const Key('cancel-booking-bkg_102_dining'));
        await tester.ensureVisible(cancelBtn);
        await tester.tap(cancelBtn);
        await tester.pumpAndSettle();
        expect(find.text('Cancel Booking with Reason'), findsOneWidget);
        expect(find.text('Confirm Cancellation'), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('cancel-booking-reason-input')),
          'Condiciones climáticas en altamar',
        );
        await tester.tap(find.byKey(const Key('confirm-cancel-booking-btn')));
        await tester.pumpAndSettle();

        expect(
          find.textContaining(
              '❌ Cancellation reason: Condiciones climáticas en altamar'),
          findsOneWidget,
        );

        // Tab 6: Stay Summary & Feedback (Zero billing/cards)
        expect(
            AdminWorkspaceTab.adminFolio.label, '6. Stay Summary & Feedback');
        expect(AdminWorkspaceTab.adminFolio.shortLabel, '6. Summary');
        expect(
          AdminI18n.tabLabel(AdminWorkspaceTab.adminFolio, true),
          '6. Resumen de Estancia y Calificación',
        );
        expect(
          AdminI18n.tabShortLabel(AdminWorkspaceTab.adminFolio, true),
          '6. Resumen',
        );

        await tester.tap(find.byKey(const Key('nav-tab-admin-folio')));
        await tester.pumpAndSettle();

        expect(find.textContaining('Card on File'), findsNothing);
        expect(
            find.textContaining('Guest Itemized Folio Ledger'), findsNothing);
        expect(find.textContaining('BILLABLE INCIDENTALS'), findsNothing);
        expect(find.byKey(const Key('approve-express-checkout-btn')),
            findsNothing);

        expect(
          find.text('Guest Stay Rating & Feedback ("How Is Your Stay Going?")'),
          findsOneWidget,
        );
        expect(find.text('Acknowledge & Mark Attended'), findsOneWidget);
        expect(
          find.text('Acquired Services & Stay Activity Summary'),
          findsOneWidget,
        );
        expect(find.text('Minibar & Pantry'), findsWidgets);
        expect(find.text('Experiences, Yacht & Private Dining'), findsWidgets);
        expect(find.text('Concierge Requests'), findsWidgets);
        expect(
            find.byKey(const Key('attend-pulse-pulse_102_01')), findsOneWidget);

        // Toggle to Spanish on Tab 6
        await tester.tap(find.byKey(const Key('admin-locale-toggle-btn')));
        await tester.pumpAndSettle();
        expect(
          find.text('Calificación y Comentarios: "¿Cómo va tu estancia?"'),
          findsOneWidget,
        );
        expect(find.text('Confirmar Atención del Host'), findsOneWidget);
        expect(
          find.text('Resumen de lo Adquirido y Solicitado por Estancia'),
          findsOneWidget,
        );
      },
    );
  });
}
