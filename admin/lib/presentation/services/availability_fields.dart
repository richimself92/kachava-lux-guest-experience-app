import 'package:flutter/widgets.dart';

import '../../core/service_catalog_labels.dart';
import '../../core/service_catalog_strings.dart';
import '../../domain/admin_service.dart';
import '../../domain/json_draft.dart';
import 'draft_choice_fields.dart';
import 'draft_list_fields.dart';
import 'draft_text_fields.dart';

/// Availability inputs (`availability.*`).
enum _Avail {
  days,
  slots,
  blocked,
  lead,
  cancel,
  minG,
  maxG,
  duration,
  offered
}

/// Shown by default for each guest use; the rest relevant to it go under
/// "More"; anything else is hidden.
const Map<UsageType, List<_Avail>> _basic = {
  UsageType.order: [_Avail.days, _Avail.slots, _Avail.lead, _Avail.offered],
  UsageType.booking: [
    _Avail.days,
    _Avail.slots,
    _Avail.lead,
    _Avail.minG,
    _Avail.maxG,
    _Avail.duration,
    _Avail.offered,
  ],
  UsageType.preference: [_Avail.offered, _Avail.lead],
  UsageType.trip: [_Avail.lead, _Avail.maxG, _Avail.offered],
};

const Map<UsageType, List<_Avail>> _advanced = {
  UsageType.order: [_Avail.blocked, _Avail.cancel],
  UsageType.booking: [_Avail.blocked, _Avail.cancel],
  UsageType.preference: [_Avail.days, _Avail.slots, _Avail.blocked],
  UsageType.trip: [_Avail.slots, _Avail.blocked, _Avail.cancel],
};

/// Availability fields relevant to [usage]: the basic ones, or the
/// [advanced] ones that live under "More".
List<Widget> availabilityFields(JsonDraft draft, UsageType usage, bool isEs,
        {bool advanced = false}) =>
    [
      for (final a in (advanced ? _advanced : _basic)[usage]!)
        _field(draft, a, isEs),
    ];

Widget _field(JsonDraft draft, _Avail a, bool isEs) {
  const p = 'availability';
  final s = ServiceCatalogStrings(isEs);
  DraftIntField count(String key, String label, int min, int max) =>
      DraftIntField(
          draft: draft,
          path: '$p.$key',
          label: label,
          isEs: isEs,
          min: min,
          max: max);
  return switch (a) {
    _Avail.days => DraftWeekdays(
        draft: draft, path: '$p.weekdays', label: s.days, isEs: isEs),
    _Avail.slots => DraftTimeSlotsField(
        draft: draft, path: '$p.timeSlots', label: s.timeSlots, isEs: isEs),
    _Avail.blocked => DraftCsvField(
        draft: draft,
        path: '$p.blockedDates',
        label: s.blockedDates,
        tip: s.blockedTip,
        isEs: isEs,
        maxEntries: 366,
        pattern: RegExp(r'^\d{4}-\d{2}-\d{2}$'),
        invalidText: s.dateFormat),
    _Avail.lead => count('minLeadHours', s.leadTime, 0, 720),
    _Avail.cancel => count('cancellationHours', s.cancelBy, 0, 720),
    _Avail.minG => count('minGuests', s.minGuests, 1, 500),
    _Avail.maxG => count('maxGuests', s.maxGuests, 1, 500),
    _Avail.duration => count('durationMinutes', s.duration, 1, 1440),
    _Avail.offered => DraftDropdown(
          draft: draft,
          path: '$p.offeredWhen',
          label: s.offered,
          noneLabel: s.none,
          options: [
            for (final o in OfferedWhen.values)
              (o.wire, ServiceCatalogLabels(isEs).offeredWhen(o))
          ]),
  };
}
