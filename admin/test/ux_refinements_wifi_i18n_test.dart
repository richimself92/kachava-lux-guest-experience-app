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
import 'package:kachava_admin_dashboard/main.dart';

void main() {
  group('Prominent Guest Comfort Box, Configurable Wi-Fi & Wire Mapping', () {
    test('test_wire_mapper_maps_wifi_ssid_and_passcode_from_villa_access', () {
      final stay = AdminWireMapper.mapStay({
        'stayId': 'stay_wifi_104',
        'guestTokenUuid': 'uuid-wifi-104',
        'villaId': 'villa-104',
        'villaName': 'Villa 104',
        'guestName': 'Carlos Santana',
        'status': 'ACTIVE_STAY',
        'villaAccess': {
          'wifiSsid': 'Kachava_Villa_104_VIP',
          'wifiPasscode': 'Santuario2026!',
        },
      });
      expect(stay.wifiSsid, 'Kachava_Villa_104_VIP');
      expect(stay.wifiPasscode, 'Santuario2026!');
      final copied = stay.copyWith(
        wifiSsid: 'Updated_SSID',
        wifiPasscode: 'Updated_Pass',
      );
      expect(copied.wifiSsid, 'Updated_SSID');
      expect(copied.wifiPasscode, 'Updated_Pass');
    });

    test('test_update_stay_wifi_sends_patch_and_updates_state', () async {
      Map<String, dynamic>? patchBody;
      String? patchPath;
      final mockHttp = MockClient((req) async {
        if (req.method == 'PATCH' && req.url.path.endsWith('/wifi')) {
          patchPath = req.url.path;
          patchBody = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
        }
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });
      final repo = ApiAdminOperationsRepository(
        apiClient: AdminApiClient(httpClient: mockHttp),
      );
      final ctrl = AdminDashboardController(repository: repo);
      await ctrl.initialize();
      await ctrl.createNewStay(
        villaName: 'Villa 101 — Palm Sanctuary',
        guestNames: 'Elena & Mateo',
        checkInDate: 'Dec 01, 2026',
        checkOutDate: 'Dec 05, 2026',
        occasion: 'Anniversary',
        wifiSsid: 'Kachava_Villa_101',
        wifiPasscode: 'Palma2026',
      );
      final created = ctrl.stays.first;
      expect(created.wifiSsid, 'Kachava_Villa_101');
      expect(created.wifiPasscode, 'Palma2026');
      await ctrl.updateStayWifi(
        stayId: created.stayId,
        wifiSsid: 'Kachava_Custom_Net',
        wifiPasscode: 'CustomPass99',
      );
      expect(patchPath, '/api/v1/admin/stays/${created.stayId}/wifi');
      expect(patchBody?['wifiSsid'], 'Kachava_Custom_Net');
      expect(patchBody?['wifiPasscode'], 'CustomPass99');
      expect(ctrl.stays.first.wifiSsid, 'Kachava_Custom_Net');
      expect(ctrl.stays.first.wifiPasscode, 'CustomPass99');
      ctrl.dispose();
    });

    testWidgets(
      'test_stays_workspace_renders_prominent_preferences_box_and_wifi_dialog',
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
        expect(
          find.textContaining('GUEST COMFORT, SCENT, DIET, ALLERGIES & NOTES'),
          findsWidgets,
        );
        expect(
          find.textContaining('ALLERGY ALERT: Shellfish Allergy (Severe)'),
          findsOneWidget,
        );
        expect(find.textContaining('Pillow:'), findsWidgets);
        expect(find.textContaining('Welcome Scent:'), findsWidgets);
        expect(
          find.textContaining(
              'Special Notes & Occasion: 4th Wedding Anniversary'),
          findsOneWidget,
        );
        expect(
            find.textContaining('Wi-Fi: Kachava_Sanctuary_102'), findsWidgets);
        final editWifiBtn =
            find.byKey(const Key('edit-wifi-btn-stay_villa_102'));
        await tester.ensureVisible(editWifiBtn);
        await tester.pumpAndSettle();
        await tester.tap(editWifiBtn);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('wifi-ssid-input')),
          'Kachava_Ceiba_102',
        );
        await tester.enterText(
          find.byKey(const Key('wifi-pass-input')),
          'CeibaSecret2026',
        );
        await tester.tap(find.byKey(const Key('confirm-wifi-btn')));
        await tester.pumpAndSettle();
        expect(find.textContaining('Wi-Fi: Kachava_Ceiba_102'), findsOneWidget);
        expect(find.textContaining('CeibaSecret2026'), findsOneWidget);
      },
    );
  });

  group('Larder Zone Removal, Chat Enter Submit & Seen Alert IDs Chime', () {
    testWidgets(
      'test_larder_omits_zones_and_category_field_and_chat_submits_on_enter',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 960);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        await tester.pumpWidget(const KachavaAdminApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('nav-tab-admin-larder')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('larder-zone-CHILLED IN LARDER')),
          findsNothing,
        );
        expect(find.text('CHILLED IN LARDER'), findsNothing);

        await tester.tap(find.byKey(const Key('add-catalog-larder-btn')));
        await tester.pumpAndSettle();
        expect(
            find.byKey(const Key('catalog-larder-name-input')), findsOneWidget);
        expect(find.byKey(const Key('catalog-larder-price-input')),
            findsOneWidget);
        expect(find.byKey(const Key('catalog-larder-category-input')),
            findsNothing);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('nav-tab-admin-concierge')));
        await tester.pumpAndSettle();

        final chatInput = find.byKey(const Key('chat-input-req_102_hvac'));
        await tester.enterText(chatInput, 'Sent via Enter key submission!');
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await tester.pumpAndSettle();

        expect(find.text('Sent via Enter key submission!'), findsOneWidget);
      },
    );

    test(
      'test_seen_alert_ids_triggers_chime_even_when_unread_count_stays_equal',
      () async {
        var alertsPayload = <Map<String, dynamic>>[
          {
            'alertId': 'alt_initial_1',
            'stayId': 'stay_1',
            'villaId': 'villa-102',
            'villaName': 'Villa 102',
            'guestName': 'Alex',
            'category': 'CONCIERGE',
            'severity': 'NORMAL',
            'title': 'Stay Preferences Updated',
            'summary': 'Pillow: Goose Down · Scent: Copal & Amber',
            'isAcknowledged': false,
          },
        ];
        final mockHttp = MockClient((req) async {
          if (req.url.path.endsWith('/alerts')) {
            return http.Response(
              jsonEncode({'success': true, 'data': alertsPayload}),
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
        expect(ctrl.isChimeRinging, isFalse);

        // Suppose alt_initial_1 was acknowledged and a brand-new alt_new_2 arrived in the same poll
        // so unreadAlertsCount is still 1 (not > prevUnread), but alt_new_2 is unseen!
        alertsPayload = [
          {
            'alertId': 'alt_new_2',
            'stayId': 'stay_1',
            'villaId': 'villa-102',
            'villaName': 'Villa 102',
            'guestName': 'Alex',
            'category': 'TRANSFER',
            'severity': 'HIGH',
            'title': 'Aviation Transfer Updated',
            'summary': 'Flight AA 1492 landing at 2:15 PM',
            'isAcknowledged': false,
          },
          {
            'alertId': 'alt_initial_1',
            'stayId': 'stay_1',
            'villaId': 'villa-102',
            'villaName': 'Villa 102',
            'guestName': 'Alex',
            'category': 'CONCIERGE',
            'severity': 'NORMAL',
            'title': 'Stay Preferences Updated',
            'summary': 'Pillow: Goose Down',
            'isAcknowledged': true,
          },
        ];
        ctrl.toggleLocale(); // Switch to ES to also verify Spanish toast translation
        await ctrl.refreshFromBackend(silent: true);
        expect(ctrl.isChimeRinging, isTrue);
        expect(
          ctrl.lastToastMessage,
          contains('Vuelo y Traslado Actualizado'),
        );
        ctrl.dispose();
      },
    );
  });

  group(
      'Exhaustive Spanish Translation (AdminI18n.translatePref & translateText)',
      () {
    test('test_translate_pref_and_dynamic_alert_translations_in_spanish', () {
      expect(AdminI18n.translatePref('', true), 'Sin seleccionar');
      expect(AdminI18n.translatePref('', false), 'Not selected');
      expect(AdminI18n.translatePref('Goose Down', true), 'Pluma de Ganso');
      expect(AdminI18n.translatePref('Hypoallergenic Firm', true),
          'Firme Hipoalergénica');
      expect(AdminI18n.translatePref('Copal & Amber', true), 'Copal y Ámbar');
      expect(AdminI18n.translatePref('Orange Blossom', true), 'Flor de Azahar');
      expect(AdminI18n.translatePref('White Cedar', true), 'Cedro Blanco');
      expect(AdminI18n.translatePref('Fragrance-Free', true), 'Sin Fragancia');
      expect(AdminI18n.translatePref('Standard', true), 'Estándar');
      expect(AdminI18n.translatePref('Pescatarian', true), 'Pescatariana');
      expect(AdminI18n.translatePref('Vegetarian', true), 'Vegetariana');
      expect(AdminI18n.translatePref('Vegan', true), 'Vegana');
      expect(AdminI18n.translatePref('Gluten-Free', true), 'Sin Gluten');

      expect(
        AdminI18n.translateText('Aviation Transfer Updated', true),
        'Vuelo y Traslado Actualizado',
      );
      expect(
        AdminI18n.translateText('Stay Preferences Updated', true),
        'Preferencias de Estancia Actualizadas',
      );
      expect(
        AdminI18n.translateText(
          'Pillow: Goose Down · Scent: Copal & Amber · Diet: Vegan · Notes: Honeymoon',
          true,
        ),
        contains('Almohada: Pluma de Ganso'),
      );
      expect(
        AdminI18n.translateText(
          'Flight AA 1492 landing at 2:15 PM · 3 artisanal larder items requested · Scheduled for Tomorrow',
          true,
        ),
        allOf(
          contains('Vuelo AA 1492'),
          contains('aterrizando a las 2:15 PM'),
          contains('productos de minibar solicitados'),
          contains('Programado para'),
        ),
      );
    });
  });
}
