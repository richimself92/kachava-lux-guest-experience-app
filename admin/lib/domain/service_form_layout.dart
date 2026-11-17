import 'service_catalog_enums.dart';
import 'service_kind_fields.dart';
import 'service_parts.dart';

/// Ids of the service form that are not a single draft path. Every other
/// id is the dotted draft path it edits (`availability.timeSlots`,
/// `experience.meetingPoint`...).
abstract final class ServiceFormField {
  /// Mode + amount + charge to folio.
  static const String pricing = 'pricing';

  /// Products, menus, options or vehicles of the service.
  static const String items = 'items';
  static const String provider = 'provider';

  /// Department + responsible staff.
  static const String responsible = 'responsible';
  static const String gallery = 'gallery';
}

/// One scrolling form: [main] fields are always visible, [more] live in
/// the collapsed "More options" section.
class ServiceFormLayout {
  const ServiceFormLayout(this.main, this.more);

  final List<String> main;
  final List<String> more;
}

const _a = 'availability';
const _slots = '$_a.timeSlots';
const _lead = '$_a.minLeadHours';
const _maxG = '$_a.maxGuests';
const _minG = '$_a.minGuests';
const _duration = '$_a.durationMinutes';
const _days = '$_a.weekdays';
const _blocked = '$_a.blockedDates';
const _cancel = '$_a.cancellationHours';
const _offered = '$_a.offeredWhen';
const _f = ServiceFormField.items;
const _p = ServiceFormField.pricing;

const _orderMain = [_f, _slots, _lead];
const _diningMain = [_p, _maxG, _slots, _f];
const _experienceMain = [
  _p, _duration, _slots, _minG, _maxG, _lead, //
  'guestInfo.includes', 'experience.meetingPoint',
];
const _wellnessMain = [
  _f, _slots, 'wellness.location', _maxG, 'wellness.healthQuestions', //
];

/// Transfers are free for guests: vehicles are optional (under More).
const _transportMain = [
  'transport.airportCodes', ServiceFormField.provider, _lead, //
];

/// Fields that kind needs up front (the rest of its fields go to "More").
List<String> _mainFields(ServiceKind kind) => switch (kind) {
      ServiceKind.bar || ServiceKind.villaStocking => _orderMain,
      ServiceKind.breakfast || ServiceKind.specialMenu => _diningMain,
      ServiceKind.experience => _experienceMain,
      ServiceKind.wellness => _wellnessMain,
      ServiceKind.preference => const [_f, 'preference.selection'],
      ServiceKind.transport => _transportMain,
    };

/// Availability inputs that mean something for [kind].
List<String> _availability(ServiceKind kind) => switch (kind) {
      ServiceKind.bar || ServiceKind.villaStocking => [
          _slots,
          _lead,
          _days,
          _blocked,
          _offered,
        ],
      ServiceKind.preference => [_lead, _days, _slots, _blocked, _offered],
      ServiceKind.transport => [_lead, _maxG, _slots, _blocked, _offered],
      _ => [_duration, _slots, _minG, _maxG, _lead, _days, _blocked, _offered],
    };

const _guestInfo = [
  'guestInfo.includes',
  'guestInfo.excludes',
  'guestInfo.location',
  'guestInfo.whatToBring',
  'guestInfo.restrictions',
];

const _generic = [
  _p,
  'pricing.note',
  ServiceFormField.provider,
  ServiceFormField.responsible,
  'operation.requiresConfirmation',
  'operation.internalInstructions',
  'description',
  'category',
  'tags',
  'order',
  'featured',
  ServiceFormField.gallery,
  'section',
];

/// The single form of [kind]: what it needs first, everything else of the
/// service (nothing is dropped from the data model) under "More".
ServiceFormLayout serviceFormLayout(ServiceKind kind) {
  final main = _mainFields(kind);
  final all = [
    if (kind == ServiceKind.transport) _f,
    for (final spec in kindFields(kind)) '${kind.detailField}.${spec.key}',
    ..._availability(kind),
    ..._guestInfo,
    _cancel,
    'guestInfo.cancellationPolicy',
    ..._generic,
  ];
  return ServiceFormLayout(main, [
    for (final id in all)
      if (!main.contains(id)) id
  ]);
}

const _dietKinds = {
  ServiceKind.bar,
  ServiceKind.villaStocking,
  ServiceKind.breakfast,
  ServiceKind.specialMenu,
  ServiceKind.experience,
};

/// What the guest form asks for each kind (no longer a staff setting).
ServiceGuestForm guestFormFor(ServiceKind kind) {
  final booking = switch (kind) {
    ServiceKind.breakfast ||
    ServiceKind.specialMenu ||
    ServiceKind.experience ||
    ServiceKind.wellness =>
      true,
    _ => false,
  };
  return ServiceGuestForm(
    date: booking,
    time: booking,
    guests: booking,
    notes: true,
    dietary: _dietKinds.contains(kind),
    health: kind == ServiceKind.wellness,
  );
}

/// [draft] with the values derived from its kind: usage and guest form.
Map<String, dynamic> withKindDefaults(Map<String, dynamic> draft) {
  final kind = ServiceKind.parse(draft['kind']);
  return {
    ...draft,
    'usageType': kind.defaultUsage.wire,
    'guestForm': guestFormFor(kind).toJson(),
  };
}
