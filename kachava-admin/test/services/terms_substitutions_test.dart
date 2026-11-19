import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/core/admin_theme.dart';
import 'package:kachava_admin_dashboard/core/resort_time.dart';
import 'package:kachava_admin_dashboard/domain/admin_service.dart';
import 'package:kachava_admin_dashboard/domain/service_form_layout.dart';
import 'package:kachava_admin_dashboard/domain/service_kind_fields.dart';
import 'package:kachava_admin_dashboard/domain/service_request.dart';
import 'package:kachava_admin_dashboard/presentation/requests/order_consent_facts.dart';
import 'package:kachava_admin_dashboard/presentation/services/request_detail_panel.dart';
import 'package:kachava_admin_dashboard/presentation/services/service_editor.dart';

import '../support/fake_service_catalog.dart';
import '../support/fake_service_requests.dart';

Map<String, dynamic> _requestJson(Map<String, dynamic> extra) => {
      'id': 'r1',
      'kind': 'ORDER',
      'at': '2026-11-20T10:00',
      ...extra,
    };

void main() {
  group('model', () {
    test('guestInfo.terms is read and written', () {
      final info = ServiceGuestInfo.fromJson({
        'terms': {'en': 'No returns', 'es': 'Sin devoluciones'}
      });
      expect(info.terms.en, 'No returns');
      expect(info.toJson()['terms'],
          {'en': 'No returns', 'es': 'Sin devoluciones'});
      expect(ServiceGuestInfo.fromJson(const {}).terms.en, '');
    });

    test('stocking asks about substitutions, next to the order limits', () {
      final keys = kindFields(ServiceKind.villaStocking).map((f) => f.key);
      expect(keys, [
        'maxPerItem',
        'orderDeadlineHoursBeforeCheckIn',
        'askSubstitutions'
      ]);
      expect(
          kindFields(ServiceKind.villaStocking).last.type, KindFieldType.flag);
      final more = serviceFormLayout(ServiceKind.villaStocking).more;
      expect(
          more,
          containsAllInOrder([
            'stocking.orderDeadlineHoursBeforeCheckIn',
            'stocking.askSubstitutions',
            'guestInfo.cancellationPolicy',
            'guestInfo.terms',
          ]));
      expect(serviceFormLayout(ServiceKind.experience).more,
          contains('guestInfo.terms'));
    });

    test('request reads substitutionsAllowed and termsAcceptedAt', () {
      final r = ServiceRequest.fromJson(_requestJson({
        'substitutionsAllowed': false,
        'termsAcceptedAt': '2026-11-19T15:30:00.000Z',
      }));
      expect(r.substitutionsAllowed, isFalse);
      expect(r.termsAcceptedAt, DateTime.utc(2026, 11, 19, 15, 30));
      final old = ServiceRequest.fromJson(_requestJson(const {}));
      expect(old.substitutionsAllowed, isNull);
      expect(old.termsAcceptedAt, isNull);
    });
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: KachavaAdminTheme.build(),
      home: Scaffold(body: Row(children: [SizedBox(width: 560, child: child)])),
    ));
    await tester.pumpAndSettle();
  }

  group('service editor', () {
    testWidgets('writes guestInfo.terms and stocking.askSubstitutions',
        (tester) async {
      final repo = FakeServiceCatalogRepository();
      final service = testService(1, kind: ServiceKind.villaStocking);
      repo.seed([service]);
      await pump(
          tester,
          ServiceEditor(
            deps: fakeCatalogDeps(repo),
            service: service,
            onClose: () {},
            onSaved: () {},
          ));
      await tester.ensureVisible(find.byKey(const Key('svc-more')).first);
      await tester.tap(find.byKey(const Key('svc-more')).first);
      await tester.pumpAndSettle();
      expect(
          find.byTooltip('Shown to guests before they order; they must '
              'accept it.'),
          findsOneWidget);
      final terms = find.byKey(const Key('svc-guestInfo.terms.en'));
      await tester.ensureVisible(terms);
      await tester.enterText(terms, 'Prices may vary.');
      final ask = find.byKey(const Key('svc-stocking.askSubstitutions'));
      // The panel header overlaps a hit-test tap here; drive the switch.
      tester.widget<Switch>(ask).onChanged!(true);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('form-save')).first);
      await tester.pumpAndSettle();
      final body = repo.patches.single;
      expect((body['guestInfo'] as Map)['terms'],
          {'en': 'Prices may vary.', 'es': ''});
      expect((body['stocking'] as Map)['askSubstitutions'], isTrue);
    });
  });

  group('order consent facts', () {
    const time = ResortTime(
        timeZone: 'America/Cancun',
        resolver: FixedOffsetResolver(Duration(hours: -5)));

    testWidgets('substitutions and terms acceptance (resort time)',
        (tester) async {
      final r = ServiceRequest.fromJson(_requestJson({
        'substitutionsAllowed': true,
        'termsAcceptedAt': '2026-11-19T15:30:00.000Z',
      }));
      await pump(
          tester,
          Column(
              children: orderConsentFacts(r, isEs: false, resortTime: time)));
      expect(find.text('Substitutions'), findsOneWidget);
      expect(find.text('Allowed'), findsOneWidget);
      expect(find.text('Terms accepted'), findsOneWidget);
      expect(find.text('Nov 19 · 10:30'), findsOneWidget);
    });

    testWidgets('Spanish "not allowed"; nothing when the fields are null',
        (tester) async {
      final r = ServiceRequest.fromJson(
          _requestJson({'substitutionsAllowed': false}));
      await pump(tester,
          Column(children: orderConsentFacts(r, isEs: true, resortTime: time)));
      expect(find.text('Sustituciones'), findsOneWidget);
      expect(find.text('No permitidas'), findsOneWidget);
      expect(find.text('Términos aceptados'), findsNothing);
      final none = ServiceRequest.fromJson(_requestJson(const {}));
      expect(orderConsentFacts(none, isEs: false), isEmpty);
    });

    testWidgets('the request detail panel shows them for orders',
        (tester) async {
      final r = ServiceRequest.fromJson(_requestJson({
        'substitutionsAllowed': false,
        'termsAcceptedAt': '2026-11-19T15:30:00.000Z',
      }));
      await pump(
          tester,
          RequestDetailPanel(
            request: r,
            repository: FakeServiceRequestRepository(),
            onClose: () {},
            onChanged: () {},
            isEs: false,
          ));
      expect(find.text('Not allowed'), findsOneWidget);
      expect(find.text('Nov 19 · 15:30 UTC'), findsOneWidget);
    });
  });
}
