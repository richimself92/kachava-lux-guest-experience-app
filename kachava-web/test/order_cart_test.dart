import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_guest_portal/core/i18n/l10n.dart';
import 'package:kachava_guest_portal/domain/catalog.dart';
import 'package:kachava_guest_portal/domain/forms.dart';
import 'package:kachava_guest_portal/domain/stay.dart';

import 'support/fixtures.dart';

CatalogService _stock() =>
    service(id: 'stock', section: 'IN_VILLA', usageType: 'ORDER', items: [
      itemJson('water', nameEn: 'Water', price: 4, category: 'Drinks'),
      itemJson('steak',
          nameEn: 'New York steak',
          price: 3.3114,
          category: 'Proteins',
          pricingUnit: 'OZ',
          portionOzOptions: [6, 8, 10, 12, 14]),
      itemJson('jamon',
          nameEn: 'Ham',
          nameEs: 'Jamón serrano',
          price: 2,
          category: 'Proteins',
          pricingUnit: 'OZ',
          portionOzOptions: [4, 6, 10]),
    ]);

void main() {
  group('CatalogItem pricing unit', () {
    test('defaults to ITEM with no oz options', () {
      final item = CatalogItem.fromJson(itemJson('water', price: 4));
      expect(item.pricingUnit, PricingUnit.item);
      expect(item.byWeight, isFalse);
      expect(item.portionOzOptions, isEmpty);
    });

    test('parses OZ and its portion options', () {
      final item = _stock().items[1];
      expect(item.pricingUnit, PricingUnit.oz);
      expect(item.byWeight, isTrue);
      expect(item.portionOzOptions, [6, 8, 10, 12, 14]);
    });

    test('default oz is 8 when offered, else the middle option', () {
      expect(_stock().items[1].defaultOz, 8);
      expect(_stock().items[2].defaultOz, 6);
    });
  });

  group('OZ cart', () {
    test('5 × 12 oz × 3.3114 = 198.684 rounds to 198.68', () {
      final s = _stock();
      final cart = OrderCart(s)
        ..set('steak', 5)
        ..setOz('steak', 12);
      expect(cart.lineTotal(s.items[1]), 198.68);
      cart.set('water', 2);
      expect(cart.total, closeTo(206.68, 1e-9));
    });

    test('uses the default oz until the guest picks one', () {
      final s = _stock();
      final cart = OrderCart(s)..set('steak', 1);
      expect(cart.ozOf(s.items[1]), 8);
      expect(cart.lineTotal(s.items[1]), 26.49);
    });

    test('ignores an oz the item does not offer', () {
      final s = _stock();
      final cart = OrderCart(s)..setOz('steak', 13);
      expect(cart.ozOf(s.items[1]), 8);
    });

    test('payload sends ozPerPortion for OZ lines only', () {
      final cart = OrderCart(_stock())
        ..set('water', 2)
        ..set('steak', 5)
        ..setOz('steak', 12);
      expect(cart.toPayload()['items'], [
        {'itemId': 'water', 'quantity': 2},
        {'itemId': 'steak', 'quantity': 5, 'ozPerPortion': 12},
      ]);
    });

    test('draft saves {qty, oz} and reloads it', () {
      final cart = OrderCart(_stock())
        ..set('water', 2)
        ..set('steak', 3)
        ..setOz('steak', 14);
      final draft = cart.toDraft();
      expect(draft, {
        'water': {'qty': 2},
        'steak': {'qty': 3, 'oz': 14},
      });
      final again = OrderCart.restore(_stock(), draft: draft);
      expect(again.quantityOf('steak'), 3);
      expect(again.ozOf(_stock().items[1]), 14);
    });

    test('old {itemId: qty} drafts still load', () {
      final cart = OrderCart.restore(_stock(), draft: {'water': 3, 'steak': 2});
      expect(cart.quantityOf('water'), 3);
      expect(cart.quantityOf('steak'), 2);
      expect(cart.ozOf(_stock().items[1]), 8);
    });

    test('stored server lines seed qty and oz; the draft wins', () {
      const line = LarderOrderLine(
          orderItemId: 'l1',
          serviceId: 'stock',
          itemId: 'steak',
          name: LocalizedText(en: 'NY', es: 'NY'),
          quantity: 4,
          pricingUnit: PricingUnit.oz,
          ozPerPortion: 10);
      final s = _stock();
      final cart = OrderCart.restore(s, lines: const [line]);
      expect(cart.quantityOf('steak'), 4);
      expect(cart.ozOf(s.items[1]), 10);
      final drafted = OrderCart.restore(s, lines: const [
        line
      ], draft: {
        'steak': {'qty': 1, 'oz': 6}
      });
      expect(drafted.quantityOf('steak'), 1);
      expect(drafted.ozOf(s.items[1]), 6);
    });
  });

  group('order filter', () {
    test('search is case- and accent-insensitive on EN and ES names', () {
      final cart = OrderCart(_stock());
      List<String> ids(Map<String, List<CatalogItem>> g) =>
          [for (final l in g.values) ...l.map((i) => i.id)];
      expect(ids(cart.groupsFor(query: 'JAMON')), ['jamon']);
      expect(ids(cart.groupsFor(query: 'steák')), ['steak']);
      expect(ids(cart.groupsFor(category: 'Drinks')), ['water']);
      expect(cart.groupsFor(query: 'ham', category: 'Drinks'), isEmpty);
      expect(cart.groupsFor().keys, ['Drinks', 'Proteins']);
      expect(cart.categories, ['Drinks', 'Proteins']);
    });
  });

  group('line labels', () {
    test('OZ lines read "5 × 12 oz Name"', () {
      const l10n = L10n(Lang.en);
      expect(l10n.orderLine(2, 'Water'), '2 × Water');
      expect(l10n.orderLine(5, 'Steak', oz: 12), '5 × 12 oz Steak');
      expect(l10n.perOz(3.3114), '\$3.31 / oz');
      expect(l10n.estimate(5, 12, 198.684),
          'Estimated total · 5 × 12 oz = 60 oz · \$198.68');
      expect(const L10n(Lang.es).estimate(5, 12, 198.684),
          'Total estimado · 5 × 12 oz = 60 oz · \$198.68');
    });
  });

  test('stored OZ lines carry pricingUnit and ozPerPortion', () {
    final line = LarderOrderLine.fromJson(const {
      'orderItemId': 'l1',
      'serviceId': 'stock',
      'catalogItemId': 'steak',
      'name': 'NY',
      'quantity': 5,
      'pricingUnit': 'OZ',
      'ozPerPortion': 12,
      'unitPriceUSD': 3.3114,
      'lineTotalUSD': 198.68,
    });
    expect(line.pricingUnit, PricingUnit.oz);
    expect(line.ozPerPortion, 12);
    final item = LarderOrderLine.fromJson(const {
      'catalogItemId': 'w',
      'quantity': 1,
      'ozPerPortion': null,
    });
    expect(item.pricingUnit, PricingUnit.item);
    expect(item.ozPerPortion, isNull);
  });

  group('terms and substitutions', () {
    CatalogService svc({bool ask = true, String terms = 'Line 1\n\nLine 2'}) =>
        CatalogService.fromJson({
          ...serviceJson(
              id: 'stock',
              section: 'IN_VILLA',
              usageType: 'ORDER',
              guestInfo: {
                'terms': {'en': terms, 'es': terms}
              },
              items: [
                itemJson('water', price: 4)
              ]),
          'stocking': {'askSubstitutions': ask},
        });

    test('parses guestInfo.terms and stocking.askSubstitutions', () {
      final s = svc();
      expect(s.guestInfo.terms.en, 'Line 1\n\nLine 2');
      expect(s.askSubstitutions, isTrue);
      expect(service(id: 'x', section: 'S').askSubstitutions, isFalse);
    });

    test('issues until a choice is made and the terms are accepted', () {
      final cart = OrderCart(svc())..set('water', 1);
      expect(cart.issues,
          {FormIssue.substitutionRequired, FormIssue.termsRequired});
      cart
        ..substitutions = false
        ..termsAccepted = true;
      expect(cart.issues, isEmpty);
      expect(cart.toPayload(), {
        'serviceId': 'stock',
        'items': [
          {'itemId': 'water', 'quantity': 1}
        ],
        'substitutionsAllowed': false,
        'termsAccepted': true,
      });
    });

    test('nothing asked: no issues and no extra fields', () {
      final cart = OrderCart(svc(ask: false, terms: ''))..set('water', 1);
      expect(cart.issues, isEmpty);
      expect(cart.toPayload().keys, ['serviceId', 'items']);
    });

    test('stored lines carry substitutionsAllowed to the request', () {
      final line = LarderOrderLine.fromJson(const {
        'catalogItemId': 'w',
        'serviceId': 'stock',
        'quantity': 1,
        'substitutionsAllowed': true,
      });
      expect(line.substitutionsAllowed, isTrue);
      final cart = OrderCart.restore(svc(), lines: [line]);
      expect(cart.substitutions, isTrue, reason: 'seeded from the order');
      expect(
          OrderCart.restore(svc(), lines: [line], substitutions: false)
              .substitutions,
          isFalse,
          reason: 'draft wins');
    });
  });

  test('lines and drafts for items no longer in the catalog are dropped', () {
    const legacy = LarderOrderLine(
        orderItemId: 'l9',
        serviceId: 'stock',
        itemId: 'retired',
        name: LocalizedText(en: 'Old', es: 'Viejo'),
        quantity: 5);
    final cart = OrderCart.restore(_stock(),
        lines: const [legacy], draft: {'gone': 3, 'water': 2});
    expect(cart.count, 2);
    expect(cart.quantities.keys, ['water']);
    expect(cart.toDraft().keys, ['water']);
  });
}
