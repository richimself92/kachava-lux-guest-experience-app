/// Wire enums of the service catalog (backend `domain/catalog/catalog.models.ts`,
/// ADR-009). Unknown wire values are a [FormatException]: they are never
/// guessed.
library;

T _parse<T extends Enum>(
    List<T> values, String Function(T) wire, Object? raw, String name) {
  final text = '${raw ?? ''}'.trim();
  for (final value in values) {
    if (wire(value) == text) return value;
  }
  throw FormatException('Unknown $name "$text".');
}

T? _parseOrNull<T extends Enum>(
    List<T> values, String Function(T) wire, Object? raw) {
  final text = '${raw ?? ''}'.trim();
  for (final value in values) {
    if (wire(value) == text) return value;
  }
  return null;
}

/// Where the guest finds the service. Sections are filtered views.
enum ServiceSection {
  inVilla('IN_VILLA'),
  dining('DINING'),
  experiences('EXPERIENCES'),
  wellness('WELLNESS'),
  transportation('TRANSPORTATION');

  const ServiceSection(this.wire);
  final String wire;

  static ServiceSection parse(Object? raw) =>
      _parse(values, (v) => v.wire, raw, 'section');
}

/// How the guest uses the service.
enum UsageType {
  order('ORDER'),
  booking('BOOKING'),
  preference('PREFERENCE'),
  trip('TRIP');

  const UsageType(this.wire);
  final String wire;

  static UsageType parse(Object? raw) =>
      _parse(values, (v) => v.wire, raw, 'usageType');
}

/// Optional item inputs; which ones apply depends on the [ServiceKind].
enum ItemField {
  category,
  tags,
  dietaryTags,
  allergens,
  origin,
  unit,
  storage,
  capacity,
}

/// The template of a service: decides its type-specific block
/// ([detailField]) and which item fields matter. Immutable once created.
enum ServiceKind {
  bar('BAR', 'bar', ServiceSection.dining, UsageType.order,
      {ItemField.category, ItemField.tags}),
  breakfast('BREAKFAST', 'dining', ServiceSection.dining, UsageType.order,
      {ItemField.category, ItemField.dietaryTags, ItemField.allergens}),
  specialMenu(
      'SPECIAL_MENU', 'dining', ServiceSection.dining, UsageType.booking, {
    ItemField.category,
    ItemField.dietaryTags,
    ItemField.allergens,
  }),
  villaStocking(
      'VILLA_STOCKING', 'stocking', ServiceSection.inVilla, UsageType.order, {
    ItemField.category,
    ItemField.tags,
    ItemField.origin,
    ItemField.unit,
    ItemField.storage,
  }),
  experience('EXPERIENCE', 'experience', ServiceSection.experiences,
      UsageType.booking, {ItemField.category}),
  wellness('WELLNESS', 'wellness', ServiceSection.wellness, UsageType.booking,
      {ItemField.category}),
  preference('PREFERENCE', 'preference', ServiceSection.inVilla,
      UsageType.preference, {ItemField.category}),
  transport('TRANSPORT', 'transport', ServiceSection.transportation,
      UsageType.trip, {ItemField.capacity});

  const ServiceKind(this.wire, this.detailField, this.defaultSection,
      this.defaultUsage, this.itemFields);

  final String wire;

  /// Name of the one type-specific block this kind carries.
  final String detailField;

  /// UI defaults when creating; staff can change section and usage.
  final ServiceSection defaultSection;
  final UsageType defaultUsage;
  final Set<ItemField> itemFields;

  static ServiceKind parse(Object? raw) =>
      _parse(values, (v) => v.wire, raw, 'kind');

  /// Kinds offered when creating from a section view.
  static List<ServiceKind> forSection(ServiceSection section) => [
        for (final k in values)
          if (k.defaultSection == section) k
      ];
}

/// How the price reads.
enum PricingMode {
  included('INCLUDED'),
  fixed('FIXED'),
  perPerson('PER_PERSON'),
  perUnit('PER_UNIT'),
  perHour('PER_HOUR'),
  onRequest('ON_REQUEST');

  const PricingMode(this.wire);
  final String wire;

  /// Included and on-request services never carry an amount.
  bool get hasAmount => this != included && this != onRequest;

  static PricingMode parse(Object? raw) =>
      _parse(values, (v) => v.wire, raw, 'pricing.mode');
}

enum Weekday {
  mon('MON'),
  tue('TUE'),
  wed('WED'),
  thu('THU'),
  fri('FRI'),
  sat('SAT'),
  sun('SUN');

  const Weekday(this.wire);
  final String wire;

  static Weekday? tryParse(Object? raw) =>
      _parseOrNull(values, (v) => v.wire, raw);
}

/// When in the stay the service is offered.
enum OfferedWhen {
  beforeArrival('BEFORE_ARRIVAL'),
  duringStay('DURING_STAY'),
  both('BOTH');

  const OfferedWhen(this.wire);
  final String wire;

  static OfferedWhen? tryParse(Object? raw) =>
      _parseOrNull(values, (v) => v.wire, raw);
}

/// ACTIVE needs a cover and EN+ES name and short description (422 otherwise).
enum CatalogStatus {
  active('ACTIVE'),
  disabled('DISABLED');

  const CatalogStatus(this.wire);
  final String wire;

  CatalogStatus get toggled => this == active ? disabled : active;

  static CatalogStatus parse(Object? raw) =>
      _parseOrNull(values, (v) => v.wire, raw) ?? disabled;
}
