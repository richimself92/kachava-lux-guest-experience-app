import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/domain/admin_service.dart';
import 'package:kachava_admin_dashboard/domain/service_form_layout.dart';

void main() {
  group('serviceFormLayout', () {
    test('order kinds show items, time slots and lead time', () {
      for (final kind in [ServiceKind.bar, ServiceKind.villaStocking]) {
        expect(serviceFormLayout(kind).main, [
          ServiceFormField.items,
          'availability.timeSlots',
          'availability.minLeadHours',
        ]);
      }
      expect(serviceFormLayout(ServiceKind.bar).more,
          containsAllInOrder(['bar.ageConfirmationRequired', 'pricing']));
      expect(
          serviceFormLayout(ServiceKind.villaStocking).more,
          containsAll([
            'stocking.maxPerItem',
            'stocking.orderDeadlineHoursBeforeCheckIn',
            'availability.weekdays',
            'availability.blockedDates',
          ]));
    });

    test('dining shows pricing, max guests, slots and menus', () {
      for (final kind in [ServiceKind.breakfast, ServiceKind.specialMenu]) {
        expect(serviceFormLayout(kind).main, [
          ServiceFormField.pricing,
          'availability.maxGuests',
          'availability.timeSlots',
          ServiceFormField.items,
        ]);
        expect(serviceFormLayout(kind).more,
            containsAll(['availability.minLeadHours', 'guestInfo.includes']));
      }
      expect(serviceFormLayout(ServiceKind.specialMenu).more,
          contains('dining.pairingAvailable'));
    });

    test('experience keeps the essentials up front', () {
      final layout = serviceFormLayout(ServiceKind.experience);
      expect(layout.main, [
        ServiceFormField.pricing,
        'availability.durationMinutes',
        'availability.timeSlots',
        'availability.minGuests',
        'availability.maxGuests',
        'availability.minLeadHours',
        'guestInfo.includes',
        'experience.meetingPoint',
      ]);
      expect(
          layout.more,
          containsAll([
            'experience.itinerary',
            'experience.languages',
            'experience.minAge',
            'guestInfo.whatToBring',
            'guestInfo.restrictions',
            'availability.cancellationHours',
            'guestInfo.cancellationPolicy',
            'availability.blockedDates',
            'availability.weekdays',
            ServiceFormField.provider,
          ]));
    });

    test('wellness, preference and transport', () {
      expect(serviceFormLayout(ServiceKind.wellness).main, [
        ServiceFormField.items,
        'availability.timeSlots',
        'wellness.location',
        'availability.maxGuests',
        'wellness.healthQuestions',
      ]);
      expect(serviceFormLayout(ServiceKind.wellness).more,
          contains('wellness.contraindications'));
      expect(serviceFormLayout(ServiceKind.preference).main,
          [ServiceFormField.items, 'preference.selection']);
      expect(serviceFormLayout(ServiceKind.preference).more,
          contains('preference.changeDeadlineHours'));
      // Transfers are free: vehicles are optional, under More.
      expect(serviceFormLayout(ServiceKind.transport).main, [
        'transport.airportCodes',
        ServiceFormField.provider,
        'availability.minLeadHours',
      ]);
      expect(
          serviceFormLayout(ServiceKind.transport).more,
          containsAll([
            'transport.priceBasis',
            'transport.flightDetailsRequired',
            ServiceFormField.pricing,
            ServiceFormField.items,
          ]));
    });

    test('every kind keeps the generic fields under More, never twice', () {
      for (final kind in ServiceKind.values) {
        final layout = serviceFormLayout(kind);
        final all = [...layout.main, ...layout.more];
        expect(all.toSet().length, all.length, reason: kind.wire);
        expect(
            layout.more,
            containsAll([
              ServiceFormField.responsible,
              'operation.internalInstructions',
              'description',
              'order',
              'featured',
              'tags',
              'category',
              ServiceFormField.gallery,
              'section',
              'pricing.note',
            ]),
            reason: kind.wire);
        expect(all, contains(ServiceFormField.pricing), reason: kind.wire);
        expect(all, isNot(contains('usageType')));
      }
    });
  });

  group('guestFormFor', () {
    test('bookings ask date, time, guests and notes', () {
      for (final kind in [
        ServiceKind.specialMenu,
        ServiceKind.breakfast,
        ServiceKind.experience,
        ServiceKind.wellness,
      ]) {
        final f = guestFormFor(kind);
        expect([f.date, f.time, f.guests, f.notes], [true, true, true, true],
            reason: kind.wire);
      }
    });

    test('dietary for food and experiences, health for wellness only', () {
      for (final kind in ServiceKind.values) {
        final f = guestFormFor(kind);
        expect(f.health, kind == ServiceKind.wellness, reason: kind.wire);
        expect(
            f.dietary,
            {
              ServiceKind.bar,
              ServiceKind.villaStocking,
              ServiceKind.breakfast,
              ServiceKind.specialMenu,
              ServiceKind.experience,
            }.contains(kind),
            reason: kind.wire);
      }
    });

    test('orders, preferences and trips only take notes', () {
      for (final kind in [
        ServiceKind.bar,
        ServiceKind.villaStocking,
        ServiceKind.preference,
        ServiceKind.transport,
      ]) {
        final f = guestFormFor(kind);
        expect([f.date, f.time, f.guests, f.notes], [false, false, false, true],
            reason: kind.wire);
      }
    });
  });

  test('withKindDefaults derives usage and guest form on a draft', () {
    final draft = AdminService.emptyDraft(ServiceKind.wellness)
      ..['usageType'] = 'ORDER'
      ..['guestForm'] = {'date': false};
    final out = AdminService.parse(withKindDefaults(draft));
    expect(out.usageType, UsageType.booking);
    expect(out.guestForm.health, isTrue);
    expect(out.guestForm.date, isTrue);
  });

  test('breakfast is booked with a time slot, not ordered', () {
    final out = AdminService.parse(
        withKindDefaults(AdminService.emptyDraft(ServiceKind.breakfast)));
    expect(out.usageType, UsageType.booking);
    expect(out.guestForm.time, isTrue);
    expect(out.guestForm.dietary, isTrue);
  });

  test('a new experience starts priced per person', () {
    final s =
        AdminService.parse(AdminService.emptyDraft(ServiceKind.experience));
    expect(s.pricing.mode, PricingMode.perPerson);
    final bar = AdminService.parse(AdminService.emptyDraft(ServiceKind.bar));
    expect(bar.pricing.mode, PricingMode.onRequest);
  });
}
