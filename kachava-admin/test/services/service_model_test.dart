import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/domain/admin_service.dart';
import 'package:kachava_admin_dashboard/domain/catalog_values.dart';

/// Wire shape of `GET /admin/services/:id` (backend `AdminServiceView`).
Map<String, dynamic> serviceJson({
  String kind = 'BAR',
  String status = 'DISABLED',
  Map<String, dynamic>? extra,
}) =>
    {
      'id': 's1',
      'serviceId': 's1',
      'kind': kind,
      'section': 'DINING',
      'category': 'Drinks',
      'usageType': 'ORDER',
      'name': {'en': 'Lux bar', 'es': 'Lux bar'},
      'shortDescription': {'en': 'Cocktails', 'es': 'Cocteles'},
      'description': {'en': '', 'es': ''},
      'tags': ['bar'],
      'order': 3,
      'featured': true,
      'cover': {
        'storagePath': 'catalog/services/a.png',
        'url': 'https://cdn.test/a.png',
        'alt': {'en': 'Bar', 'es': 'Bar'},
        'usageRightsConfirmed': true,
      },
      'gallery': [],
      'pricing': {
        'mode': 'PER_UNIT',
        'amount': null,
        'currency': 'USD',
        'chargeToFolio': true,
        'note': {'en': '', 'es': ''},
      },
      'availability': {
        'weekdays': ['MON', 'FRI'],
        'timeSlots': [
          {'start': '17:00', 'end': '23:00'}
        ],
        'blockedDates': ['2026-12-24'],
        'minLeadHours': 2,
        'cancellationHours': null,
        'minGuests': null,
        'maxGuests': null,
        'durationMinutes': null,
        'offeredWhen': 'DURING_STAY',
      },
      'guestInfo': {
        'includes': {'en': 'Ice', 'es': 'Hielo'},
      },
      'guestForm': {'date': false, 'time': true, 'notes': true},
      'operation': {
        'providerId': null,
        'responsibleDepartment': 'CULINARY',
        'responsibleStaffId': null,
        'requiresConfirmation': true,
        'internalInstructions': 'Check ID',
      },
      'bar': {'ageConfirmationRequired': true},
      'dining': null,
      'status': status,
      'createdAt': '2026-11-02T10:00:00Z',
      'updatedBy': 'staff-1',
      ...?extra,
    };

void main() {
  group('AdminService.fromJson', () {
    test('reads the backend field names', () {
      final s = AdminService.fromJson(serviceJson());
      expect(s.id, 's1');
      expect(s.kind, ServiceKind.bar);
      expect(s.section, ServiceSection.dining);
      expect(s.usageType, UsageType.order);
      expect(s.category, 'Drinks');
      expect(s.order, 3);
      expect(s.featured, isTrue);
      expect(s.cover?.url, 'https://cdn.test/a.png');
      expect(s.pricing.mode, PricingMode.perUnit);
      expect(s.pricing.amount, isNull);
      expect(s.availability.weekdays, [Weekday.mon, Weekday.fri]);
      expect(s.availability.timeSlots.single.start, '17:00');
      expect(s.availability.minLeadHours, 2);
      expect(s.availability.offeredWhen, OfferedWhen.duringStay);
      expect(s.guestInfo.includes.es, 'Hielo');
      expect(s.guestForm.time, isTrue);
      expect(s.guestForm.date, isFalse);
      expect(s.operation.responsibleDepartment, 'CULINARY');
      expect(s.operation.internalInstructions, 'Check ID');
      expect(s.details, {'ageConfirmationRequired': true});
      expect(s.status, CatalogStatus.disabled);
      expect(s.audit.updatedBy, 'staff-1');
    });

    test('kind block is read from the field named after the kind', () {
      final s = AdminService.fromJson(serviceJson(kind: 'BREAKFAST', extra: {
        'bar': null,
        'dining': {'pairingAvailable': true},
      }));
      expect(s.kind.detailField, 'dining');
      expect(s.details, {'pairingAvailable': true});
    });

    test('an unknown kind is a FormatException (never guessed)', () {
      expect(() => AdminService.fromJson(serviceJson(kind: 'YACHT')),
          throwsFormatException);
    });
  });

  group('AdminService write JSON', () {
    test('create sends kind, section, usage and only its own kind block', () {
      final json = AdminService.fromJson(serviceJson()).toCreateJson();
      expect(json['kind'], 'BAR');
      expect(json['section'], 'DINING');
      expect(json['usageType'], 'ORDER');
      expect(json['bar'], {'ageConfirmationRequired': true});
      for (final other in ['dining', 'stocking', 'experience', 'transport']) {
        expect(json.containsKey(other), isFalse, reason: other);
      }
      expect(json['cover'], {
        'storagePath': 'catalog/services/a.png',
        'alt': {'en': 'Bar', 'es': 'Bar'},
        'usageRightsConfirmed': true,
      });
      expect(json['availability']['timeSlots'], [
        {'start': '17:00', 'end': '23:00'}
      ]);
      expect(json['availability']['weekdays'], ['MON', 'FRI']);
      expect(json.containsKey('id'), isFalse);
    });

    test('patch never sends the immutable kind', () {
      final json = AdminService.fromJson(serviceJson()).toPatchJson();
      expect(json.containsKey('kind'), isFalse);
      expect(json['status'], 'DISABLED');
      expect(json['order'], 3);
    });

    test('price-free modes never send an amount', () {
      final s = AdminService.fromJson(serviceJson(extra: {
        'pricing': {'mode': 'INCLUDED', 'amount': 40},
      }));
      expect(s.toPatchJson()['pricing']['amount'], isNull);
    });

    test('draft JSON round-trips without an id', () {
      final draft = AdminService.fromJson(serviceJson()).toDraftJson();
      final again = AdminService.parse(draft);
      expect(again.id, 's1');
      expect(again.cover?.url, 'https://cdn.test/a.png');
      expect(AdminService.parse({...draft}..remove('id')).id, '');
      expect(again.kind, ServiceKind.bar);
      expect(again.toCreateJson(),
          AdminService.fromJson(serviceJson()).toCreateJson());
    });
  });

  group('ServiceKind defaults', () {
    test('every kind has a section, a guest use and a detail field', () {
      expect(ServiceKind.villaStocking.wire, 'VILLA_STOCKING');
      expect(ServiceKind.villaStocking.defaultSection, ServiceSection.inVilla);
      expect(ServiceKind.transport.defaultUsage, UsageType.trip);
      expect(ServiceKind.specialMenu.detailField, 'dining');
      expect(ServiceKind.forSection(ServiceSection.dining),
          [ServiceKind.bar, ServiceKind.breakfast, ServiceKind.specialMenu]);
    });

    test('item fields follow the kind', () {
      expect(ServiceKind.breakfast.itemFields,
          containsAll([ItemField.dietaryTags, ItemField.allergens]));
      expect(ServiceKind.villaStocking.itemFields,
          containsAll([ItemField.origin, ItemField.unit, ItemField.storage]));
      expect(ServiceKind.transport.itemFields, contains(ItemField.capacity));
      expect(ServiceKind.bar.itemFields, isNot(contains(ItemField.capacity)));
    });

    test('empty template starts disabled with the kind block', () {
      final draft = AdminService.emptyDraft(ServiceKind.transport);
      final s = AdminService.parse(draft);
      expect(s.section, ServiceSection.transportation);
      expect(s.usageType, UsageType.trip);
      expect(s.status, CatalogStatus.disabled);
      expect(s.pricing.mode, PricingMode.onRequest);
      expect(s.toCreateJson().containsKey('transport'), isTrue);
    });
  });

  group('ServiceItem', () {
    test('reads and writes the backend item fields', () {
      final item = ServiceItem.fromJson({
        'id': 'i1',
        'name': {'en': 'Van', 'es': 'Camioneta'},
        'description': {'en': '', 'es': ''},
        'category': null,
        'image': null,
        'priceUSD': 85.5,
        'tags': [],
        'dietaryTags': ['vegan'],
        'allergens': ['nuts'],
        'origin': 'Yucatán',
        'unit': 'kg',
        'storage': 'Fridge',
        'capacity': {'passengers': 6, 'luggage': 4},
        'order': 1,
        'status': 'ACTIVE',
      });
      expect(item.priceUSD, 85.5);
      expect(item.capacity?.passengers, 6);
      expect(item.status, CatalogStatus.active);
      final json = item.toWriteJson();
      expect(json['priceUSD'], 85.5);
      expect(json['capacity'], {'passengers': 6, 'luggage': 4});
      expect(json['dietaryTags'], ['vegan']);
      expect(json['status'], 'ACTIVE');
      expect(json['image'], isNull);
      expect(json.containsKey('id'), isFalse);
    });

    test('blank optional texts are sent as null', () {
      final item = ServiceItem.parse({
        'name': {'en': 'Tea', 'es': 'Té'},
        'origin': '  ',
      });
      expect(item.toWriteJson()['origin'], isNull);
      expect(item.status, CatalogStatus.disabled);
    });
  });

  test('LocalizedText helpers', () {
    expect(const LocalizedText(en: 'a').isComplete, isFalse);
  });
}
