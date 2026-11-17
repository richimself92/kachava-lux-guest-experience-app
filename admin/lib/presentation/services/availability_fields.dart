import 'package:flutter/widgets.dart';

import '../../core/service_catalog_labels.dart';
import '../../core/service_catalog_strings.dart';
import '../../domain/admin_service.dart';
import '../../domain/json_draft.dart';
import 'draft_choice_fields.dart';
import 'draft_list_fields.dart';
import 'draft_text_fields.dart';

/// The input of `availability.<key>` (`timeSlots`, `minLeadHours`...).
Widget availabilityField(JsonDraft draft, String key, bool isEs) {
  const p = 'availability';
  final s = ServiceCatalogStrings(isEs);
  DraftIntField count(String label, int min, int max) => DraftIntField(
      draft: draft,
      path: '$p.$key',
      label: label,
      isEs: isEs,
      min: min,
      max: max);
  return switch (key) {
    'weekdays' => DraftWeekdays(
        draft: draft, path: '$p.weekdays', label: s.days, isEs: isEs),
    'timeSlots' => DraftTimeSlotsField(
        draft: draft, path: '$p.timeSlots', label: s.timeSlots, isEs: isEs),
    'blockedDates' => _blocked(draft, s, isEs),
    'minLeadHours' => count(s.leadTime, 0, 720),
    'cancellationHours' => count(s.cancelBy, 0, 720),
    'minGuests' => count(s.minGuests, 1, 500),
    'maxGuests' => count(s.maxGuests, 1, 500),
    'durationMinutes' => count(s.duration, 1, 1440),
    'offeredWhen' => _offered(draft, s, isEs),
    _ => throw ArgumentError.value(key, 'key', 'Unknown availability field'),
  };
}

Widget _offered(JsonDraft draft, ServiceCatalogStrings s, bool isEs) =>
    DraftDropdown(
        draft: draft,
        path: 'availability.offeredWhen',
        label: s.offered,
        noneLabel: s.none,
        options: [
          for (final o in OfferedWhen.values)
            (o.wire, ServiceCatalogLabels(isEs).offeredWhen(o))
        ]);

Widget _blocked(JsonDraft draft, ServiceCatalogStrings s, bool isEs) =>
    DraftCsvField(
        draft: draft,
        path: 'availability.blockedDates',
        label: s.blockedDates,
        tip: s.blockedTip,
        isEs: isEs,
        maxEntries: 366,
        pattern: RegExp(r'^\d{4}-\d{2}-\d{2}$'),
        invalidText: s.dateFormat);
