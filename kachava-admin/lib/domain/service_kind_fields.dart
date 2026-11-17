import 'service_catalog_enums.dart';

/// Input kinds of a type-specific block.
enum KindFieldType {
  /// On/off switch.
  flag,

  /// Whole number within [KindFieldSpec.min]..[KindFieldSpec.max].
  count,

  /// One of [KindFieldSpec.options] (wire values).
  choice,

  /// `{en, es}` text.
  localized,

  /// Comma-separated codes matching [KindFieldSpec.pattern].
  codes,

  /// List of `{en, es}` texts (e.g. health questions).
  localizedList,

  /// Steps `{title{en,es}, description{en,es}, durationMinutes}`.
  itinerary,
}

/// One field of the block named [ServiceKind.detailField] (limits mirror
/// the backend `service-blocks.dto.ts`).
class KindFieldSpec {
  const KindFieldSpec(
    this.key,
    this.type, {
    this.min = 0,
    this.max = 0,
    this.options = const [],
    this.nullable = true,
    this.pattern = '',
    this.maxEntries = 20,
  });

  final String key;
  final KindFieldType type;
  final int min;
  final int max;
  final List<String> options;
  final bool nullable;
  final String pattern;
  final int maxEntries;
}

const _hours = 720;

/// The block fields staff edit for [kind]; empty when the block has nothing
/// relevant to the kind (breakfast shares `dining` with special menus).
List<KindFieldSpec> kindFields(ServiceKind kind) => switch (kind) {
      ServiceKind.bar => const [
          KindFieldSpec('ageConfirmationRequired', KindFieldType.flag),
        ],
      ServiceKind.breakfast => const [],
      ServiceKind.specialMenu => const [
          KindFieldSpec('pairingAvailable', KindFieldType.flag),
        ],
      ServiceKind.villaStocking => const [
          KindFieldSpec('maxPerItem', KindFieldType.count, min: 1, max: 100),
          KindFieldSpec('orderDeadlineHoursBeforeCheckIn', KindFieldType.count,
              max: _hours),
        ],
      ServiceKind.experience => const [
          KindFieldSpec('itinerary', KindFieldType.itinerary),
          KindFieldSpec('meetingPoint', KindFieldType.localized),
          KindFieldSpec('languages', KindFieldType.codes,
              pattern: r'^[a-z]{2}$', maxEntries: 10),
          KindFieldSpec('minAge', KindFieldType.count, max: 99),
        ],
      ServiceKind.wellness => const [
          KindFieldSpec('location', KindFieldType.choice,
              options: ['VILLA', 'SPA', 'BOTH']),
          KindFieldSpec('healthQuestions', KindFieldType.localizedList),
          KindFieldSpec('contraindications', KindFieldType.localized),
        ],
      ServiceKind.preference => const [
          KindFieldSpec('selection', KindFieldType.choice,
              options: ['SINGLE', 'MULTIPLE'], nullable: false),
          KindFieldSpec('changeDeadlineHours', KindFieldType.count,
              max: _hours),
        ],
      ServiceKind.transport => const [
          KindFieldSpec('airportCodes', KindFieldType.codes,
              pattern: r'^[A-Z]{3}$'),
          KindFieldSpec('priceBasis', KindFieldType.choice,
              options: ['PER_TRIP', 'PER_VEHICLE']),
          KindFieldSpec('flightDetailsRequired', KindFieldType.flag),
        ],
    };
