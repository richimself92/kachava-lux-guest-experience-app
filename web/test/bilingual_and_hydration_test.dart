import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kachava_guest_portal/application/sanctuary_controller.dart';
import 'package:kachava_guest_portal/core/audio/soundscape_port.dart';
import 'package:kachava_guest_portal/core/constants/screen_id.dart';
import 'package:kachava_guest_portal/core/i18n/guest_i18n.dart';
import 'package:kachava_guest_portal/data/repositories/api_sanctuary_repository.dart';
import 'package:kachava_guest_portal/domain/entities/concierge_folio_entities.dart';
import 'package:kachava_guest_portal/main.dart';

SanctuaryController _buildHydratedController() {
  final mockClient = MockClient((request) async {
    final payload = {
      'success': true,
      'data': {
        'status': 'ACTIVE_STAY',
        'villaName': 'Villa 106 — Copal Pavilion',
        'suiteName': 'Copal Pavilion · 4,100 sq ft',
        'stayDatesLabel': 'Nov 20, 2026 – Nov 25, 2026',
        'guestProfile': {
          'name': 'Juan & Maria',
          'lastNameNormalized': 'maria',
          'celebration': 'Honeymoon Escape',
        },
        'hostInfo': {'name': 'HOST ADMIN', 'role': '24/7 Host Operations'},
      },
    };
    return http.Response(
      jsonEncode(payload),
      200,
      headers: const {'content-type': 'application/json; charset=utf-8'},
    );
  });
  return SanctuaryController(
    repository: ApiSanctuaryRepository(
      baseUrl: 'http://localhost:3001/api/v1',
      httpClient: mockClient,
    ),
    soundscape: SanctuarySoundscapeSynthesizer(),
    initialUri: Uri.parse(
        'https://kachavalux.com/?guestId=550e8400-e29b-41d4-a716-446655440099'),
  );
}

void main() {
  group('Host Admin, Dynamic Hydration & Bilingual EN|ES Tests', () {
    test('test_defaultSeedAndController_assignsAllStaffToHostAdmin', () async {
      final controller = SanctuaryController(
        repository: ApiSanctuaryRepository(enableNetwork: false),
        soundscape: SanctuarySoundscapeSynthesizer(),
      );
      await controller.initialize();

      expect(controller.stay.privateHostName, equals('HOST ADMIN'));
      expect(controller.transport.assignedDriver, equals('HOST ADMIN'));
      expect(
        controller.conciergeRequests.every((r) => r.assignedTo == 'HOST ADMIN'),
        isTrue,
      );

      await controller.createConciergeRequest(
        title: 'Fresh towels',
        category: 'Housekeeping',
        details: 'Two pool towels',
      );
      expect(
          controller.conciergeRequests.first.assignedTo, equals('HOST ADMIN'));
      expect(controller.activeToastMessage, contains('HOST ADMIN'));
      controller.dispose();
    });

    test('test_wireMapperAndStayCopyWith_hydratesGuestVillaDatesAndHostInfo',
        () async {
      final controller = _buildHydratedController();
      await controller.initialize();

      expect(controller.stay.guestNames, equals('Juan & Maria'));
      expect(controller.stay.primaryGuestName, equals('Juan'));
      expect(controller.stay.lastName, equals('maria'));
      expect(controller.stay.villaNumber, equals('106'));
      expect(controller.stay.villaTitle, equals('Villa 106 — Copal Pavilion'));
      expect(controller.stay.suiteName, equals('Copal Pavilion · 4,100 sq ft'));
      expect(controller.stay.stayDates, equals('Nov 20, 2026 – Nov 25, 2026'));
      expect(controller.stay.celebrationTitle, equals('Honeymoon Escape'));
      expect(controller.stay.privateHostName, equals('HOST ADMIN'));
      expect(controller.stay.privateHostRole, equals('24/7 Host Operations'));

      final updated =
          controller.stay.copyWith(privateHostRole: 'Lead Concierge');
      expect(updated.privateHostRole, equals('Lead Concierge'));
      controller.dispose();
    });

    testWidgets(
      'test_guestPortal_rendersHydratedStayAndTogglesBilingualEnEs',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final controller = _buildHydratedController();
        await controller.initialize();
        await tester.pumpWidget(KachavaGuestPortalApp(controller: controller));
        await tester.pumpAndSettle();

        expect(controller.locale, equals(GuestLocale.en));
        expect(controller.isEs, isFalse);
        expect(find.textContaining('Juan & Maria'), findsWidgets);
        expect(find.textContaining('VILLA 106 — COPAL PAVILION'), findsWidgets);
        expect(
            find.textContaining('Nov 20, 2026 – Nov 25, 2026'), findsWidgets);
        expect(find.textContaining('HOST ADMIN'), findsWidgets);

        final localeBtn = find.byKey(const Key('guest-locale-toggle-btn'));
        expect(localeBtn, findsOneWidget);
        expect(find.text('✓ EN'), findsOneWidget);
        expect(find.text('ES'), findsOneWidget);
        await tester.tap(localeBtn);
        await tester.pumpAndSettle();

        expect(controller.locale, equals(GuestLocale.es));
        expect(controller.isEs, isTrue);
        expect(find.text('EN'), findsOneWidget);
        expect(find.text('✓ ES'), findsOneWidget);
        expect(find.textContaining('TU RESIDENCIA'), findsOneWidget);

        controller.navigateTo(ScreenId.personalize);
        await tester.pumpAndSettle();
        expect(
            find.textContaining('Confort de Habitación y Aroma de Bienvenida'),
            findsOneWidget);
        expect(find.textContaining('Dieta y Alergias'), findsOneWidget);
        expect(find.text('Pluma de Ganso'), findsOneWidget);

        await tester.tap(localeBtn);
        await tester.pumpAndSettle();
        expect(controller.isEs, isFalse);
        expect(find.textContaining('Room Comfort & Welcome Scent'),
            findsOneWidget);
        expect(find.textContaining('Dietary & Allergies'), findsOneWidget);

        controller.navigateTo(ScreenId.explore);
        await tester.pumpAndSettle();
        expect(find.text('CURATED SANCTUARY EXCURSIONS'), findsOneWidget);
        expect(find.textContaining('Galeon 470 Sky'), findsNothing);
        await tester.tap(localeBtn);
        await tester.pumpAndSettle();
        expect(find.text('EXCURSIONES Y EXPERIENCIAS'), findsOneWidget);
        await tester.tap(localeBtn);
        await tester.pumpAndSettle();

        controller.navigateTo(ScreenId.philosophy);
        await tester.pumpAndSettle();
        expect(
            find.byKey(const Key('philosophy-432hz-play-btn')), findsNothing);
        expect(
            find.textContaining('cools each villa naturally'), findsOneWidget);
        expect(find.textContaining('Every ingredient in each villa'),
            findsOneWidget);
      },
    );

    testWidgets(
      'test_spanishHospitalityTerminology_translatesAllScreensAndCategoriesNaturally',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        const esI18n = GuestI18n(GuestLocale.es);
        expect(esI18n.optionLabel('Goose Down'), equals('Pluma de Ganso'));
        expect(esI18n.optionLabel('Requested'), equals('Solicitado'));
        expect(esI18n.optionLabel('In Progress'), equals('En Proceso'));
        expect(esI18n.translateContent('Half-Day Guest Experience'),
            contains('Medio Día'));

        final controller = _buildHydratedController();
        await controller.initialize();
        controller.toggleLocale(); // Switch to ES
        await tester.pumpWidget(KachavaGuestPortalApp(controller: controller));
        await tester.pumpAndSettle();

        expect(find.text('PASO 1 · ANTES DE TU LLEGADA'), findsOneWidget);
        expect(find.text('1. Registrar Vuelo y Transporte'), findsOneWidget);
        expect(
            find.text('2. Confort, Aroma, Dieta y Alergias'), findsOneWidget);
        expect(find.text('3. Pedir Bebidas y Minibar'), findsOneWidget);
        expect(find.text('PASO 2 · DURANTE TU ESTANCIA'), findsOneWidget);
        expect(find.text('4. Excursiones y Tours'), findsOneWidget);
        expect(find.text('5. Reserva de Yate Privado'), findsOneWidget);
        expect(find.text('6. Cena con Chef Privado en Villa'), findsOneWidget);
        expect(find.text('7. Chat 24/7 y Solicitudes a Concierge'),
            findsOneWidget);
        expect(find.text('8. ¿Cómo va tu estancia?'), findsOneWidget);
        expect(find.text('PASO 3 · RESUMEN, PERFIL Y RESORT'), findsOneWidget);
        expect(find.text('9. Resumen de Estancia y Salida'), findsOneWidget);
        expect(find.text('10. Mi Perfil, Wi-Fi y Alergias'), findsOneWidget);
        expect(find.text('11. Arquitectura y Naturaleza del Resort'),
            findsOneWidget);
        expect(find.byKey(const Key('home-nav-included')), findsNothing);

        controller.navigateTo(ScreenId.stockVilla);
        await tester.pumpAndSettle();
        expect(find.text('PEDIDO DE MINIBAR Y BEBIDAS · HOST ADMIN'),
            findsOneWidget);
        expect(find.text('Confirmar Pedido'), findsOneWidget);
        expect(find.text('En Refrigerador'), findsNothing);

        controller.navigateTo(ScreenId.explore);
        await tester.pumpAndSettle();
        expect(find.text('Explora Experiencias y Actividades'), findsOneWidget);
        expect(find.text('Todas'), findsNothing);
        expect(find.text('Reservar'), findsWidgets);
      },
    );

    test('test_liveSyncAndCleanNewStay_mapsTicketsChatFolioAndRefreshes',
        () async {
      var pollCount = 0;
      final client = MockClient((req) async {
        pollCount++;
        final data = {
          'status': pollCount > 1 ? 'ACTIVE_STAY' : 'PRE_ARRIVAL',
          'villaName': 'Villa 108 — Jaguar Suite',
          'guestProfile': {'name': 'Carlos Rivera'},
          'flightTransfer': {
            'flightNumber': 'AM 402',
            'status': 'Chauffeur En Route',
            'chauffeurName': 'HOST ADMIN'
          },
          'conciergeRequests': pollCount == 1
              ? <Map<String, dynamic>>[]
              : [
                  {
                    'requestId': 'req_live_99',
                    'title': 'Need extra pillows',
                    'category': 'Concierge',
                    'status': 'In Progress',
                    'messages': [
                      {'sender': 'GUEST', 'text': 'Need extra pillows'},
                      {'sender': 'HOST', 'text': 'On our way, Carlos!'}
                    ],
                  },
                ],
          'folioItems': pollCount == 1
              ? <Map<String, dynamic>>[]
              : [
                  {
                    'itemId': 'fol_99',
                    'title': 'Cenote Tour',
                    'category': 'Excursions',
                    'dateLabel': 'Today',
                    'amountUSD': 380,
                    'isComped': false
                  },
                ],
        };
        return http.Response(jsonEncode({'success': true, 'data': data}), 200,
            headers: const {'content-type': 'application/json; charset=utf-8'});
      });
      final ctrl = SanctuaryController(
          repository: ApiSanctuaryRepository(httpClient: client),
          soundscape: SanctuarySoundscapeSynthesizer());
      await ctrl.initialize();
      expect(ctrl.conciergeRequests, isEmpty);
      expect(ctrl.folioItems, isEmpty);
      expect(ctrl.transport.status, equals('Chauffeur En Route'));
      ctrl.sendChatMessage('Need extra pillows');
      await ctrl.refreshFromBackend();
      expect(ctrl.conciergeRequests.first.id, equals('req_live_99'));
      expect(ctrl.conciergeRequests.first.stage, ConciergeStage.inProgress);
      expect(ctrl.chatMessages.last.text, equals('On our way, Carlos!'));
      expect(ctrl.chatMessages.last.isFromHost, isTrue);
      expect(ctrl.folioItems.single.amountUsd, equals(380));
      ctrl.dispose();
    });
  });
}
