import 'package:flutter/widgets.dart';

import '../../core/request_strings.dart';
import '../../core/resort_time.dart';
import '../../domain/service_request.dart';
import '../operations/ops_fields.dart';

/// "Substitutions: Allowed / Not allowed" and "Terms accepted · <time>" of
/// an order, only for the values the server sent. Without [resortTime] the
/// acceptance time is shown in UTC.
List<Widget> orderConsentFacts(ServiceRequest r,
    {required bool isEs, ResortTime? resortTime}) {
  final s = RequestStrings(isEs);
  final time = resortTime ??
      const ResortTime(timeZone: null, resolver: _NoZone.instance);
  return [
    if (r.substitutionsAllowed case final allowed?)
      FactRow(label: s.substitutions, value: s.substitutionsChoice(allowed)),
    if (r.termsAcceptedAt case final at?)
      FactRow(label: s.termsAccepted, value: time.label(at, isEs: isEs)),
  ];
}

/// No zone: [ResortTime.label] falls back to UTC.
class _NoZone implements ZoneOffsetResolver {
  const _NoZone();

  static const _NoZone instance = _NoZone();

  @override
  Duration? offsetAt(DateTime utc, String timeZone) => null;
}
