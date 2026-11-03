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
  final double? amount;

  /// ISO currency of [amount]; the plan fixes USD.
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

/// When a service can be requested.
class ServiceAvailability {
  const ServiceAvailability({
    this.daysOfWeek = const [],
    this.timeSlots = const [],
    this.blockedDates = const [],
    this.leadTimeHours,
    this.cancellationHours,
    this.minGuests,
    this.maxGuests,
    this.durationMinutes,
    this.offeredWhen = '',
  });

  factory ServiceAvailability.fromJson(Map<String, dynamic> json) =>
      ServiceAvailability(
        daysOfWeek: JsonRead.ints(json, 'daysOfWeek'),
        timeSlots: JsonRead.strings(json, 'timeSlots'),
        blockedDates: JsonRead.strings(json, 'blockedDates'),
        leadTimeHours: JsonRead.intOrNull(json, 'leadTimeHours'),
        cancellationHours: JsonRead.intOrNull(json, 'cancellationHours'),
        minGuests: JsonRead.intOrNull(json, 'minGuests'),
        maxGuests: JsonRead.intOrNull(json, 'maxGuests'),
        durationMinutes: JsonRead.intOrNull(json, 'durationMinutes'),
        offeredWhen: JsonRead.text(json, 'offeredWhen'),
      );

  /// ISO weekdays 1 (Mon) .. 7 (Sun).
  final List<int> daysOfWeek;

  /// `HH:mm-HH:mm` windows in resort time.
  final List<String> timeSlots;

  /// `YYYY-MM-DD`.
  final List<String> blockedDates;
  final int? leadTimeHours;
  final int? cancellationHours;
  final int? minGuests;
  final int? maxGuests;
  final int? durationMinutes;

  /// `BEFORE_STAY | DURING_STAY | BOTH`.
  final String offeredWhen;

  Map<String, dynamic> toJson() => {
        'daysOfWeek': daysOfWeek,
        'timeSlots': timeSlots,
        'blockedDates': blockedDates,
        'leadTimeHours': leadTimeHours,
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

/// Which questions the guest form asks.
class ServiceGuestForm {
  const ServiceGuestForm({
    this.askDate = false,
    this.askTime = false,
    this.askGuests = false,
    this.askNotes = false,
    this.askDiet = false,
    this.askHealth = false,
  });

  factory ServiceGuestForm.fromJson(Map<String, dynamic> json) =>
      ServiceGuestForm(
        askDate: JsonRead.flag(json, 'askDate'),
        askTime: JsonRead.flag(json, 'askTime'),
        askGuests: JsonRead.flag(json, 'askGuests'),
        askNotes: JsonRead.flag(json, 'askNotes'),
        askDiet: JsonRead.flag(json, 'askDiet'),
        askHealth: JsonRead.flag(json, 'askHealth'),
      );

  final bool askDate;
  final bool askTime;
  final bool askGuests;
  final bool askNotes;
  final bool askDiet;
  final bool askHealth;

  Map<String, dynamic> toJson() => {
        'askDate': askDate,
        'askTime': askTime,
        'askGuests': askGuests,
        'askNotes': askNotes,
        'askDiet': askDiet,
        'askHealth': askHealth,
      };
}

/// Staff-only operation block.
class ServiceOperation {
  const ServiceOperation({
    this.providerId,
    this.internalOwner = '',
    this.requiresConfirmation = false,
    this.internalNotes = '',
  });

  factory ServiceOperation.fromJson(Map<String, dynamic> json) =>
      ServiceOperation(
        providerId: JsonRead.textOrNull(json, 'providerId'),
        internalOwner: JsonRead.text(json, 'internalOwner'),
        requiresConfirmation: JsonRead.flag(json, 'requiresConfirmation'),
        internalNotes: JsonRead.text(json, 'internalNotes'),
      );

  final String? providerId;
  final String internalOwner;
  final bool requiresConfirmation;
  final String internalNotes;

  Map<String, dynamic> toJson() => {
        'providerId': providerId,
        'internalOwner': internalOwner,
        'requiresConfirmation': requiresConfirmation,
        'internalNotes': internalNotes,
      };
}
