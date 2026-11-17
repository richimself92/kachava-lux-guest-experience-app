import 'catalog_values.dart';
import 'json_read.dart';
import 'service_catalog_enums.dart';

/// Price block of a service (`pricing`). Currency is always USD.
class ServicePricing {
  const ServicePricing({
    this.mode = PricingMode.onRequest,
    this.amount,
    this.chargeToFolio = false,
    this.note = const LocalizedText(),
  });

  factory ServicePricing.fromJson(Map<String, dynamic> json) => ServicePricing(
        mode: json['mode'] == null
            ? PricingMode.onRequest
            : PricingMode.parse(json['mode']),
        amount: JsonRead.doubleOrNull(json, 'amount'),
        chargeToFolio: JsonRead.flag(json, 'chargeToFolio'),
        note: LocalizedText.fromJson(json['note']),
      );

  static const String currency = 'USD';

  final PricingMode mode;

  /// `null` when the price lives on the items (or for price-free modes).
  final double? amount;
  final bool chargeToFolio;
  final LocalizedText note;

  Map<String, dynamic> toJson() => {
        'mode': mode.wire,
        'amount': mode.hasAmount ? amount : null,
        'currency': currency,
        'chargeToFolio': chargeToFolio,
        'note': note.toJson(),
      };
}

/// `{start, end}` in `HH:mm`, resort time.
class TimeSlot {
  const TimeSlot(this.start, this.end);

  static TimeSlot? fromJson(Object? json) {
    if (json is! Map) return null;
    final map = Map<String, dynamic>.from(json);
    final start = JsonRead.text(map, 'start');
    final end = JsonRead.text(map, 'end');
    return start.isEmpty || end.isEmpty ? null : TimeSlot(start, end);
  }

  final String start;
  final String end;

  Map<String, dynamic> toJson() => {'start': start, 'end': end};
}

/// When a service can be requested (`availability`).
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
        weekdays: [
          for (final raw in JsonRead.strings(json, 'weekdays'))
            if (Weekday.tryParse(raw) case final day?) day
        ],
        timeSlots: [
          for (final raw in (json['timeSlots'] as List? ?? const []))
            if (TimeSlot.fromJson(raw) case final slot?) slot
        ],
        blockedDates: JsonRead.strings(json, 'blockedDates'),
        minLeadHours: JsonRead.intOrNull(json, 'minLeadHours'),
        cancellationHours: JsonRead.intOrNull(json, 'cancellationHours'),
        minGuests: JsonRead.intOrNull(json, 'minGuests'),
        maxGuests: JsonRead.intOrNull(json, 'maxGuests'),
        durationMinutes: JsonRead.intOrNull(json, 'durationMinutes'),
        offeredWhen: OfferedWhen.tryParse(json['offeredWhen']),
      );

  final List<Weekday> weekdays;
  final List<TimeSlot> timeSlots;

  /// `YYYY-MM-DD`.
  final List<String> blockedDates;
  final int? minLeadHours;
  final int? cancellationHours;
  final int? minGuests;
  final int? maxGuests;
  final int? durationMinutes;
  final OfferedWhen? offeredWhen;

  Map<String, dynamic> toJson() => {
        'weekdays': [for (final d in weekdays) d.wire],
        'timeSlots': [for (final s in timeSlots) s.toJson()],
        'blockedDates': blockedDates,
        'minLeadHours': minLeadHours,
        'cancellationHours': cancellationHours,
        'minGuests': minGuests,
        'maxGuests': maxGuests,
        'durationMinutes': durationMinutes,
        'offeredWhen': offeredWhen?.wire,
      };
}

/// Guest-facing information (`guestInfo`), EN/ES each.
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

  static const List<String> keys = [
    'includes',
    'excludes',
    'whatToBring',
    'location',
    'restrictions',
    'cancellationPolicy',
  ];

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

/// Which inputs the guest form asks for (`guestForm`).
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

/// Staff-only operation data (`operation`); never shown to guests.
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

  /// A transport provider id (`/admin/transport-providers`).
  final String? providerId;

  /// `CONCIERGE | CULINARY | MARINE | TRANSPORT | HOUSEKEEPING | ENGINEERING |
  /// WELLNESS`.
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
