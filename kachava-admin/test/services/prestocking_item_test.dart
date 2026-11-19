import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/domain/admin_service.dart';
import 'package:kachava_admin_dashboard/domain/catalog_values.dart';
import 'package:kachava_admin_dashboard/domain/item_pricing_rules.dart';
import 'package:kachava_admin_dashboard/domain/service_request.dart';

void main() {
  group('ServiceItem pre-stocking fields', () {
    test('old payloads map to ITEM, [] and nulls', () {
      final item = ServiceItem.fromJson({
        'id': 'i1',
        'name': {'en': 'Water'},
      });
      expect(item.pricingUnit, PricingUnit.item);
      expect(item.portionOzOptions, isEmpty);
      expect(item.sku, isNull);
      expect(item.netCostMXN, isNull);
      expect(item.sourceUrl, isNull);
    });

    test('reads and writes the contract fields', () {
      final item = ServiceItem.fromJson({
        'id': 'i2',
        'name': {'en': 'New York steak'},
        'sku': 'PRE-104',
        'netCostMXN': 30.9577,
        'sourceUrl': 'https://shop.test/steak',
        'priceUSD': 3.3114,
        'pricingUnit': 'OZ',
        'portionOzOptions': [8, 12],
      });
      expect(item.pricingUnit, PricingUnit.oz);
      expect(item.portionOzOptions, [8, 12]);
      final body = item.toWriteJson();
      expect(body['sku'], 'PRE-104');
      expect(body['netCostMXN'], 30.9577);
      expect(body['sourceUrl'], 'https://shop.test/steak');
      expect(body['priceUSD'], 3.3114);
      expect(body['pricingUnit'], 'OZ');
      expect(body['portionOzOptions'], [8, 12]);
    });

    test('OZ without options writes the defaults; ITEM writes []', () {
      const oz = ServiceItem(
          name: LocalizedText(en: 'Rib eye'), pricingUnit: PricingUnit.oz);
      expect(oz.toWriteJson()['portionOzOptions'], [6, 8, 10, 12, 14]);
      const item =
          ServiceItem(name: LocalizedText(en: 'Water'), portionOzOptions: [6]);
      expect(item.toWriteJson()['portionOzOptions'], <int>[]);
      expect(item.toWriteJson()['pricingUnit'], 'ITEM');
    });
  });

  group('ItemPricingRules', () {
    test('sku up to 40 chars', () {
      expect(ItemPricingRules.skuOk(null), isTrue);
      expect(ItemPricingRules.skuOk('A' * 40), isTrue);
      expect(ItemPricingRules.skuOk('A' * 41), isFalse);
    });

    test('source url must be http(s) and <= 500 chars', () {
      expect(ItemPricingRules.urlOk(null), isTrue);
      expect(ItemPricingRules.urlOk('https://a.test/x'), isTrue);
      expect(ItemPricingRules.urlOk('http://a.test'), isTrue);
      expect(ItemPricingRules.urlOk('ftp://a.test'), isFalse);
      expect(ItemPricingRules.urlOk('shop'), isFalse);
      expect(ItemPricingRules.urlOk('https://a.test/${'x' * 500}'), isFalse);
    });

    test('amounts: 2 decimals for ITEM, 4 for OZ, max 1e6', () {
      expect(ItemPricingRules.amountOk('3.31', decimals: 2), isTrue);
      expect(ItemPricingRules.amountOk('3.3114', decimals: 2), isFalse);
      expect(ItemPricingRules.amountOk('3.3114', decimals: 4), isTrue);
      expect(ItemPricingRules.amountOk('3.31145', decimals: 4), isFalse);
      expect(ItemPricingRules.amountOk('1000001', decimals: 2), isFalse);
      expect(ItemPricingRules.amountOk('-1', decimals: 2), isFalse);
    });

    test('portion options: ints 1..64, 1..10 entries, sorted unique', () {
      expect(ItemPricingRules.parseOz('12, 6, 8, 6'), [6, 8, 12]);
      expect(ItemPricingRules.parseOz(''), isNull);
      expect(ItemPricingRules.parseOz('0, 8'), isNull);
      expect(ItemPricingRules.parseOz('65'), isNull);
      expect(ItemPricingRules.parseOz('8.5'), isNull);
      expect(ItemPricingRules.parseOz('1,2,3,4,5,6,7,8,9,10,11'), isNull);
    });
  });

  group('ServiceRequestLine pricing', () {
    test('reads pricingUnit, ozPerPortion and line totals', () {
      final r = ServiceRequest.fromJson({
        'id': 'r1',
        'kind': 'ORDER',
        'lines': [
          {
            'name': {'en': 'New York steak'},
            'quantity': 5,
            'pricingUnit': 'OZ',
            'ozPerPortion': 12,
            'unitPriceUSD': 3.3114,
            'lineTotalUSD': 198.68,
          },
          {
            'name': {'en': 'Water'},
            'quantity': 2,
          },
        ],
      });
      final steak = r.lines.first;
      expect(steak.pricingUnit, PricingUnit.oz);
      expect(steak.ozPerPortion, 12);
      expect(steak.unitPriceUSD, 3.3114);
      expect(steak.lineTotalUSD, 198.68);
      final water = r.lines.last;
      expect(water.pricingUnit, PricingUnit.item);
      expect(water.ozPerPortion, isNull);
      expect(water.lineTotalUSD, isNull);
    });
  });
}
