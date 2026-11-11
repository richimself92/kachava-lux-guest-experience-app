import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/core/service_catalog_labels.dart';
import 'package:kachava_admin_dashboard/domain/admin_service.dart';
import 'package:kachava_admin_dashboard/domain/catalog_values.dart';
import 'package:kachava_admin_dashboard/domain/service_kind_fields.dart';

AdminService _priced(PricingMode mode, double? amount) => AdminService(
      kind: ServiceKind.bar,
      section: ServiceSection.dining,
      usageType: UsageType.order,
      name: const LocalizedText(en: 'Bar'),
      pricing: ServicePricing(mode: mode, amount: amount),
    );

void main() {
  group('ServiceCatalogLabels', () {
    const en = ServiceCatalogLabels(false);
    const es = ServiceCatalogLabels(true);

    test('enum labels are short EN/ES words, never raw wire values', () {
      expect(en.section(ServiceSection.inVilla), 'In-villa');
      expect(es.section(ServiceSection.dining), 'Gastronomía');
      expect(en.kind(ServiceKind.villaStocking), 'Villa stocking');
      expect(es.kind(ServiceKind.specialMenu), 'Menú especial');
      expect(en.usage(UsageType.trip), 'Trip');
      expect(es.usage(UsageType.booking), 'Reserva');
      expect(en.pricingMode(PricingMode.perPerson), 'Per person');
      expect(es.weekday(Weekday.sat), 'Sáb');
      expect(en.offeredWhen(OfferedWhen.beforeArrival), 'Before arrival');
      for (final value in [
        ...ServiceSection.values.map(en.section),
        ...ServiceKind.values.map(es.kind),
        ...UsageType.values.map(en.usage),
      ]) {
        expect(value, isNot(contains('_')));
      }
    });

    test('price column text', () {
      expect(en.price(_priced(PricingMode.included, null)), 'Included');
      expect(es.price(_priced(PricingMode.onRequest, null)), 'A consultar');
      expect(en.price(_priced(PricingMode.fixed, 1234.5)), r'$1,234.50 USD');
      expect(
          en.price(_priced(PricingMode.perPerson, 40)), r'$40.00 USD / person');
      expect(es.price(_priced(PricingMode.perHour, 15)), r'$15.00 USD / hora');
      expect(en.price(_priced(PricingMode.perUnit, null)), 'Per item');
      expect(en.money(null), '—');
      expect(en.money(0.5), r'$0.50 USD');
    });
  });

  group('kindFields', () {
    test('each kind lists only its own block fields', () {
      expect(kindFields(ServiceKind.bar).map((f) => f.key),
          ['ageConfirmationRequired']);
      expect(kindFields(ServiceKind.breakfast), isEmpty);
      expect(
          kindFields(ServiceKind.specialMenu).single.key, 'pairingAvailable');
      expect(kindFields(ServiceKind.villaStocking).map((f) => f.key),
          ['maxPerItem', 'orderDeadlineHoursBeforeCheckIn']);
      expect(kindFields(ServiceKind.experience).map((f) => f.type), [
        KindFieldType.itinerary,
        KindFieldType.localized,
        KindFieldType.codes,
        KindFieldType.count,
      ]);
      expect(kindFields(ServiceKind.transport).first.pattern, r'^[A-Z]{3}$');
    });

    test('count fields carry the backend limits', () {
      final maxPerItem = kindFields(ServiceKind.villaStocking).first;
      expect((maxPerItem.min, maxPerItem.max), (1, 100));
      final minAge = kindFields(ServiceKind.experience).last;
      expect((minAge.min, minAge.max), (0, 99));
    });

    test('choice fields list their wire options', () {
      final location = kindFields(ServiceKind.wellness).first;
      expect(location.options, ['VILLA', 'SPA', 'BOTH']);
      expect(location.nullable, isTrue);
      final selection = kindFields(ServiceKind.preference).first;
      expect(selection.nullable, isFalse);
    });
  });
}
