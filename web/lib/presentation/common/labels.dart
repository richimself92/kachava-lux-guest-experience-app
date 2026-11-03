import '../../core/i18n/l10n.dart';
import '../../domain/journey.dart';
import '../../domain/requests.dart';
import '../../domain/trip.dart';

/// Task name: core tasks are fixed; a section with one service is named
/// after it, otherwise after the section.
String taskName(L10n l10n, JourneyTask task) {
  switch (task.core) {
    case CoreTask.flight:
      return l10n.taskFlight;
    case CoreTask.preferences:
      return l10n.taskPreferences;
    case CoreTask.departure:
      return l10n.taskDeparture;
    case CoreTask.rating:
      return l10n.taskRating;
    case null:
      if (task.services.length == 1) {
        final name = l10n.text(task.services.single.name);
        if (name.isNotEmpty) return name;
      }
      return l10n.section(task.section ?? '');
  }
}

/// "1.3 Villa stocking": the same numbered title everywhere.
String taskTitle(L10n l10n, JourneyTask task) =>
    '${task.number} ${taskName(l10n, task)}';

/// One-line summary for a done task, e.g. "AA 1482 · Nov 3".
String taskSummary(L10n l10n, JourneyTask task) {
  if (task.ownArrangement) return l10n.ownTransport;
  final r = task.doneBy;
  if (r == null) return '';
  final trip = r.trip;
  if (trip != null && trip.flightNumber.isNotEmpty) {
    return [trip.flightNumber, if (r.day != null) l10n.date(r.day!)]
        .join(' · ');
  }
  return [requestName(l10n, r), if (r.day != null) l10n.date(r.day!)]
      .join(' · ');
}

String requestName(L10n l10n, GuestRequest r) {
  final name = l10n.text(r.name);
  if (name.isNotEmpty) return name;
  if (r.plainName.isNotEmpty) return r.plainName;
  final trip = r.trip;
  if (trip != null) {
    return switch (trip.type) {
      TripType.arrival => l10n.arrivalTrip,
      TripType.departure => l10n.departureTrip,
      TripType.local => l10n.localTrip,
    };
  }
  return l10n.requestFallback;
}

/// "Nov 4 · 19:00 · 2 guests".
String requestWhen(L10n l10n, GuestRequest r) => [
      if (r.day != null) l10n.date(r.day!),
      if (r.time.isNotEmpty) r.time,
      if (r.people > 0) l10n.guests(r.people),
    ].join(' · ');
