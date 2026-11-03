import 'catalog_values.dart';
import 'json_read.dart';

/// Price block of a service.
class ServicePricing {
  const ServicePricing({
    this.mode = '',
    this.amount,
    this.currency = 'USD',
    this.chargeToFolio = false,
    this.note = const LocalizedText(),
  });

  factory ServicePricing.fromJson(Map<String, dynamic> json) => ServicePricing(
        mode: JsonRead.text(json, 'mode'),
        amount: JsonRead.doubleOrNull(json, 'amount'),
        currency: JsonRead.textOrNull(json, 'currency') ?? 'USD',
        chargeToFolio: JsonRead.flag(json, 'chargeToFolio'),
        note: LocalizedText.fromJson(json['note']),
      );

  /// `INCLUDED | FIXED | PER_PERSON | PER_UNIT | PER_HOUR | ON_REQUEST`.
  final String mode;

  /// USD; `null` for INCLUDED / ON_REQUEST or when items carry the price.
  final double? amount;

  /// The contract only accepts `USD`.
  final String currency;
  final bool chargeToFolio;
  final LocalizedText note;

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'amount': amount,
        'currency': currency,
        'chargeToFolio': chargeToFolio,
        'note': note.toJson(),
      };
}

/// A `HH:mm`-`HH:mm` window in resort time.
class TimeSlot {
  const TimeSlot({required this.start, required this.end});

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
      start: JsonRead.text(json, 'start'), end: JsonRead.text(json, 'end'));

  final String start;
  final String end;

  Map<String, dynamic> toJson() => {'start': start, 'end': end};
}

/// When a service can be requested.
class ServiceAvailability {
  const ServiceAvailability({
    this.weekdays = const [],
    this.timeSlots = const [],
    this.blockedDates = const [],
    this.minLeadHours,
    this.cancellationHours,
    this.minGuests,
    this.maxGuests,
    this.durationMinutes,
    this.offeredWhen,
  });

  factory ServiceAvailability.fromJson(Map<String, dynamic> json) =>
      ServiceAvailability(
        weekdays: JsonRead.strings(json, 'weekdays'),
        timeSlots: [
          for (final slot in JsonRead.objects(json, 'timeSlots'))
            TimeSlot.fromJson(slot)
        ],
        blockedDates: JsonRead.strings(json, 'blockedDates'),
        minLeadHours: JsonRead.intOrNull(json, 'minLeadHours'),
        cancellationHours: JsonRead.intOrNull(json, 'cancellationHours'),
        minGuests: JsonRead.intOrNull(json, 'minGuests'),
        maxGuests: JsonRead.intOrNull(json, 'maxGuests'),
        durationMinutes: JsonRead.intOrNull(json, 'durationMinutes'),
        offeredWhen: JsonRead.textOrNull(json, 'offeredWhen'),
      );

  /// `MON` .. `SUN`.
  final List<String> weekdays;
  final List<TimeSlot> timeSlots;

  /// `YYYY-MM-DD`.
  final List<String> blockedDates;
  final int? minLeadHours;
  final int? cancellationHours;
  final int? minGuests;
  final int? maxGuests;
  final int? durationMinutes;

  /// `BEFORE_ARRIVAL | DURING_STAY | BOTH`.
  final String? offeredWhen;

  Map<String, dynamic> toJson() => {
        'weekdays': weekdays,
        'timeSlots': [for (final s in timeSlots) s.toJson()],
        'blockedDates': blockedDates,
        'minLeadHours': minLeadHours,
        'cancellationHours': cancellationHours,
        'minGuests': minGuests,
        'maxGuests': maxGuests,
        'durationMinutes': durationMinutes,
        'offeredWhen': offeredWhen,
      };
}

/// Guest-facing information blocks.
class ServiceGuestInfo {
  const ServiceGuestInfo({
    this.includes = const LocalizedText(),
    this.excludes = const LocalizedText(),
    this.whatToBring = const LocalizedText(),
    this.location = const LocalizedText(),
    this.restrictions = const LocalizedText(),
    this.cancellationPolicy = const LocalizedText(),
  });

  factory ServiceGuestInfo.fromJson(Map<String, dynamic> json) =>
      ServiceGuestInfo(
        includes: LocalizedText.fromJson(json['includes']),
        excludes: LocalizedText.fromJson(json['excludes']),
        whatToBring: LocalizedText.fromJson(json['whatToBring']),
        location: LocalizedText.fromJson(json['location']),
        restrictions: LocalizedText.fromJson(json['restrictions']),
        cancellationPolicy: LocalizedText.fromJson(json['cancellationPolicy']),
      );

  final LocalizedText includes;
  final LocalizedText excludes;
  final LocalizedText whatToBring;
  final LocalizedText location;
  final LocalizedText restrictions;
  final LocalizedText cancellationPolicy;

  Map<String, dynamic> toJson() => {
        'includes': includes.toJson(),
        'excludes': excludes.toJson(),
        'whatToBring': whatToBring.toJson(),
        'location': location.toJson(),
        'restrictions': restrictions.toJson(),
        'cancellationPolicy': cancellationPolicy.toJson(),
      };
}

/// Which inputs the guest form asks for.
class ServiceGuestForm {
  const ServiceGuestForm({
    this.date = false,
    this.time = false,
    this.guests = false,
    this.notes = false,
    this.dietary = false,
    this.health = false,
  });

  factory ServiceGuestForm.fromJson(Map<String, dynamic> json) =>
      ServiceGuestForm(
        date: JsonRead.flag(json, 'date'),
        time: JsonRead.flag(json, 'time'),
        guests: JsonRead.flag(json, 'guests'),
        notes: JsonRead.flag(json, 'notes'),
        dietary: JsonRead.flag(json, 'dietary'),
        health: JsonRead.flag(json, 'health'),
      );

  final bool date;
  final bool time;
  final bool guests;
  final bool notes;
  final bool dietary;
  final bool health;

  Map<String, dynamic> toJson() => {
        'date': date,
        'time': time,
        'guests': guests,
        'notes': notes,
        'dietary': dietary,
        'health': health,
      };
}

/// Staff-only operation block (never sent to guests).
class ServiceOperation {
  const ServiceOperation({
    this.providerId,
    this.responsibleDepartment,
    this.responsibleStaffId,
    this.requiresConfirmation = false,
    this.internalInstructions = '',
  });

  factory ServiceOperation.fromJson(Map<String, dynamic> json) =>
      ServiceOperation(
        providerId: JsonRead.textOrNull(json, 'providerId'),
        responsibleDepartment:
            JsonRead.textOrNull(json, 'responsibleDepartment'),
        responsibleStaffId: JsonRead.textOrNull(json, 'responsibleStaffId'),
        requiresConfirmation: JsonRead.flag(json, 'requiresConfirmation'),
        internalInstructions: JsonRead.text(json, 'internalInstructions'),
      );

  /// External transport provider, if any.
  final String? providerId;

  /// `CONCIERGE | CULINARY | MARINE | TRANSPORT | HOUSEKEEPING | ENGINEERING
  /// | WELLNESS`.
  final String? responsibleDepartment;
  final String? responsibleStaffId;
  final bool requiresConfirmation;
  final String internalInstructions;

  Map<String, dynamic> toJson() => {
        'providerId': providerId,
        'responsibleDepartment': responsibleDepartment,
        'responsibleStaffId': responsibleStaffId,
        'requiresConfirmation': requiresConfirmation,
        'internalInstructions': internalInstructions,
      };
}

/// Passengers and luggage of a transport vehicle item.
class VehicleCapacity {
  const VehicleCapacity({required this.passengers, required this.luggage});

  static VehicleCapacity? fromJson(Object? json) {
    if (json is! Map) return null;
    final map = Map<String, dynamic>.from(json);
    final passengers = JsonRead.intOrNull(map, 'passengers');
    if (passengers == null) return null;
    return VehicleCapacity(
        passengers: passengers,
        luggage: JsonRead.intOrNull(map, 'luggage') ?? 0);
  }

  final int passengers;
  final int luggage;

  Map<String, dynamic> toJson() =>
      {'passengers': passengers, 'luggage': luggage};
}
