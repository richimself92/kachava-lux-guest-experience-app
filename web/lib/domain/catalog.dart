import 'json_read.dart';

/// Bilingual text from the admin; a missing translation stays empty.
class LocalizedText {
  const LocalizedText({this.en = '', this.es = ''});

  factory LocalizedText.fromJson(Object? json) {
    final map = asJson(json);
    return LocalizedText(
        en: asString(map['en']).trim(), es: asString(map['es']).trim());
  }

  static const empty = LocalizedText();

  final String en;
  final String es;

  bool get isEmpty => en.isEmpty && es.isEmpty;
}

/// Admin sections in admin order (backend `SERVICE_SECTIONS`).
const List<String> catalogSectionOrder = [
  'IN_VILLA',
  'DINING',
  'EXPERIENCES',
  'WELLNESS',
  'TRANSPORTATION',
];

int sectionRank(String section) {
  final i = catalogSectionOrder.indexOf(section);
  return i < 0 ? catalogSectionOrder.length : i;
}

enum UsageType {
  order,
  booking,
  preference,
  trip,
  unknown;

  static UsageType parse(String raw) => switch (raw) {
        'ORDER' => order,
        'BOOKING' => booking,
        'PREFERENCE' => preference,
        'TRIP' => trip,
        _ => unknown,
      };
}

enum OfferedWhen {
  beforeArrival,
  duringStay,
  both;

  /// Not configured yet: offered during the stay.
  static OfferedWhen parse(String raw) => switch (raw) {
        'BEFORE_ARRIVAL' => beforeArrival,
        'BOTH' => both,
        _ => duringStay,
      };

  bool get before => this != duringStay;
  bool get during => this != beforeArrival;
}

enum PricingMode { included, fixed, perPerson, perUnit, perHour, onRequest }

class CatalogImage {
  const CatalogImage({required this.url, this.alt = LocalizedText.empty});

  static CatalogImage? fromJson(Object? json) {
    final map = asJson(json);
    final url = asString(map['url']);
    if (url.isEmpty) return null;
    return CatalogImage(url: url, alt: LocalizedText.fromJson(map['alt']));
  }

  final String url;
  final LocalizedText alt;
}

class ServicePricing {
  const ServicePricing({
    this.mode = PricingMode.onRequest,
    this.amount,
    this.note = LocalizedText.empty,
  });

  factory ServicePricing.fromJson(Object? json) {
    final map = asJson(json);
    return ServicePricing(
      mode: switch (asString(map['mode'])) {
        'INCLUDED' => PricingMode.included,
        'FIXED' => PricingMode.fixed,
        'PER_PERSON' => PricingMode.perPerson,
        'PER_UNIT' => PricingMode.perUnit,
        'PER_HOUR' => PricingMode.perHour,
        _ => PricingMode.onRequest,
      },
      amount: asDouble(map['amount']),
      note: LocalizedText.fromJson(map['note']),
    );
  }

  final PricingMode mode;
  final double? amount;
  final LocalizedText note;
}

class TimeSlot {
  const TimeSlot(this.start, this.end);
  final String start;
  final String end;
}

class ServiceAvailability {
  const ServiceAvailability({
    this.weekdays = const [],
    this.timeSlots = const [],
    this.blockedDates = const [],
    this.minLeadHours,
    this.minGuests,
    this.maxGuests,
    this.durationMinutes,
    this.offeredWhen = OfferedWhen.duringStay,
  });

  factory ServiceAvailability.fromJson(Object? json) {
    final map = asJson(json);
    return ServiceAvailability(
      weekdays: asStringList(map['weekdays']),
      timeSlots: asJsonList(map['timeSlots'])
          .map((s) => TimeSlot(asString(s['start']), asString(s['end'])))
          .where((s) => s.start.isNotEmpty)
          .toList(),
      blockedDates: asStringList(map['blockedDates']),
      minLeadHours: asInt(map['minLeadHours']),
      minGuests: asInt(map['minGuests']),
      maxGuests: asInt(map['maxGuests']),
      durationMinutes: asInt(map['durationMinutes']),
      offeredWhen: OfferedWhen.parse(asString(map['offeredWhen'])),
    );
  }

  /// MON..SUN; empty = every day.
  final List<String> weekdays;
  final List<TimeSlot> timeSlots;
  final List<String> blockedDates;
  final int? minLeadHours;
  final int? minGuests;
  final int? maxGuests;
  final int? durationMinutes;
  final OfferedWhen offeredWhen;
}

class ServiceGuestInfo {
  const ServiceGuestInfo({
    this.includes = LocalizedText.empty,
    this.whatToBring = LocalizedText.empty,
    this.location = LocalizedText.empty,
    this.restrictions = LocalizedText.empty,
    this.cancellationPolicy = LocalizedText.empty,
  });

  factory ServiceGuestInfo.fromJson(Object? json) {
    final map = asJson(json);
    return ServiceGuestInfo(
      includes: LocalizedText.fromJson(map['includes']),
      whatToBring: LocalizedText.fromJson(map['whatToBring']),
      location: LocalizedText.fromJson(map['location']),
      restrictions: LocalizedText.fromJson(map['restrictions']),
      cancellationPolicy: LocalizedText.fromJson(map['cancellationPolicy']),
    );
  }

  final LocalizedText includes;
  final LocalizedText whatToBring;
  final LocalizedText location;
  final LocalizedText restrictions;
  final LocalizedText cancellationPolicy;
}

/// Which inputs the guest form asks for (admin "Guest form").
class ServiceGuestForm {
  const ServiceGuestForm({
    this.date = false,
    this.time = false,
    this.guests = false,
    this.notes = false,
    this.dietary = false,
    this.health = false,
  });

  factory ServiceGuestForm.fromJson(Object? json) {
    final map = asJson(json);
    return ServiceGuestForm(
      date: asBool(map['date']),
      time: asBool(map['time']),
      guests: asBool(map['guests']),
      notes: asBool(map['notes']),
      dietary: asBool(map['dietary']),
      health: asBool(map['health']),
    );
  }

  final bool date;
  final bool time;
  final bool guests;
  final bool notes;
  final bool dietary;
  final bool health;
}

class VehicleCapacity {
  const VehicleCapacity(this.passengers, this.luggage);
  final int passengers;
  final int luggage;
}

class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.name,
    this.description = LocalizedText.empty,
    this.category,
    this.image,
    this.priceUSD,
    this.capacity,
  });

  factory CatalogItem.fromJson(Json json) {
    final capacity = asJson(json['capacity']);
    return CatalogItem(
      id: asString(json['itemId']).isNotEmpty
          ? asString(json['itemId'])
          : asString(json['id']),
      name: LocalizedText.fromJson(json['name']),
      description: LocalizedText.fromJson(json['description']),
      category: asStringOrNull(json['category']),
      image: CatalogImage.fromJson(json['image']),
      priceUSD: asDouble(json['priceUSD']),
      capacity: capacity.isEmpty
          ? null
          : VehicleCapacity(asInt(capacity['passengers']) ?? 0,
              asInt(capacity['luggage']) ?? 0),
    );
  }

  final String id;
  final LocalizedText name;
  final LocalizedText description;
  final String? category;
  final CatalogImage? image;
  final double? priceUSD;
  final VehicleCapacity? capacity;
}

/// One ACTIVE service of the guest catalog (`GET /catalog/services`).
class CatalogService {
  const CatalogService({
    required this.id,
    required this.section,
    required this.usageType,
    required this.name,
    this.kind = '',
    this.shortDescription = LocalizedText.empty,
    this.description = LocalizedText.empty,
    this.tags = const [],
    this.order = 0,
    this.cover,
    this.gallery = const [],
    this.pricing = const ServicePricing(),
    this.availability = const ServiceAvailability(),
    this.guestInfo = const ServiceGuestInfo(),
    this.guestForm = const ServiceGuestForm(),
    this.items = const [],
    this.ageConfirmationRequired = false,
    this.multipleChoice = false,
    this.changeDeadlineHours,
    this.airportCodes = const [],
    this.meetingPoint = LocalizedText.empty,
    this.healthQuestions = const [],
  });

  factory CatalogService.fromJson(Json json) {
    final preference = asJson(json['preference']);
    final transport = asJson(json['transport']);
    final experience = asJson(json['experience']);
    final wellness = asJson(json['wellness']);
    return CatalogService(
      id: asString(json['serviceId']).isNotEmpty
          ? asString(json['serviceId'])
          : asString(json['id']),
      kind: asString(json['kind']),
      section: asString(json['section']),
      usageType: UsageType.parse(asString(json['usageType'])),
      name: LocalizedText.fromJson(json['name']),
      shortDescription: LocalizedText.fromJson(json['shortDescription']),
      description: LocalizedText.fromJson(json['description']),
      tags: asStringList(json['tags']),
      order: asInt(json['order']) ?? 0,
      cover: CatalogImage.fromJson(json['cover']),
      gallery: asJsonList(json['gallery'])
          .map(CatalogImage.fromJson)
          .whereType<CatalogImage>()
          .toList(),
      pricing: ServicePricing.fromJson(json['pricing']),
      availability: ServiceAvailability.fromJson(json['availability']),
      guestInfo: ServiceGuestInfo.fromJson(json['guestInfo']),
      guestForm: ServiceGuestForm.fromJson(json['guestForm']),
      items: asJsonList(json['items'])
          .map(CatalogItem.fromJson)
          .where((i) => i.id.isNotEmpty)
          .toList(),
      ageConfirmationRequired:
          asBool(asJson(json['bar'])['ageConfirmationRequired']),
      multipleChoice: asString(preference['selection']) == 'MULTIPLE',
      changeDeadlineHours: asInt(preference['changeDeadlineHours']),
      airportCodes: asStringList(transport['airportCodes']),
      meetingPoint: LocalizedText.fromJson(experience['meetingPoint']),
      healthQuestions: asJsonList(wellness['healthQuestions'])
          .map(LocalizedText.fromJson)
          .where((q) => !q.isEmpty)
          .toList(),
    );
  }

  final String id;
  final String kind;
  final String section;
  final UsageType usageType;
  final LocalizedText name;
  final LocalizedText shortDescription;
  final LocalizedText description;
  final List<String> tags;
  final int order;
  final CatalogImage? cover;
  final List<CatalogImage> gallery;
  final ServicePricing pricing;
  final ServiceAvailability availability;
  final ServiceGuestInfo guestInfo;
  final ServiceGuestForm guestForm;
  final List<CatalogItem> items;
  final bool ageConfirmationRequired;
  final bool multipleChoice;
  final int? changeDeadlineHours;

  /// TRIP services: airports configured in Settings that this service serves.
  final List<String> airportCodes;
  final LocalizedText meetingPoint;
  final List<LocalizedText> healthQuestions;

  /// Cover first, then the gallery (max 8).
  List<CatalogImage> get photos => [if (cover != null) cover!, ...gallery];

  /// Lowest and highest item price (null when items carry no price).
  (double, double)? get itemPriceRange {
    final prices = items.map((i) => i.priceUSD).whereType<double>().toList();
    if (prices.isEmpty) return null;
    prices.sort();
    return (prices.first, prices.last);
  }
}
