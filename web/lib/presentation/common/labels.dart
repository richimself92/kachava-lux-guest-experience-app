import '../../core/i18n/l10n.dart';
import '../../domain/journey.dart';
import '../../domain/requests.dart';
import '../../domain/resort_clock.dart';
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

/// One-line summary for a done task, e.g. "Thu Nov 6 · 14:10 · AA 1482".
String taskSummary(L10n l10n, JourneyTask task) {
  if (task.ownArrangement) return l10n.ownTransport;
  final r = task.doneBy;
  if (r == null) return '';
  final trip = r.trip;
  if (trip != null) {
    return [
      if (r.day != null) l10n.dayDate(r.day!),
      if (r.time.isNotEmpty) r.time,
      if (trip.flightNumber.isNotEmpty) trip.flightNumber,
    ].join(' · ');
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

/// "Thu Nov 4 · 19:00 · 2 guests"; an order without a schedule reads
/// "Ordered Mon Nov 2 · 09:30" (resort time).
String requestWhen(L10n l10n, GuestRequest r) {
  final ordered = r.sortAt;
  if (r.kind == RequestKind.order && r.day == null && ordered != null) {
    final wall = ResortClock.toWall(ordered);
    return l10n.ordered(
        '${l10n.dayDate(ResortClock.dayOf(wall))} · ${l10n.clock(wall)}');
  }
  return [
    if (r.day != null) l10n.dayDate(r.day!),
    if (r.time.isNotEmpty) r.time,
    if (r.people > 0) l10n.guests(r.people),
  ].join(' · ');
}

/// What was asked, one line: order lines ("2 × Water, 1 × Bread") or the
/// trip's flight / route. Bookings and preferences say it in the title.
String requestWhat(L10n l10n, GuestRequest r) {
  final trip = r.trip;
  if (trip != null) return tripWhat(l10n, trip);
  if (r.kind != RequestKind.order) return '';
  return r.lines.map((l) => '${l.quantity} × ${l10n.text(l.name)}').join(', ');
}

/// "Flight AA 1482 · CUN" for airport trips, "Origin → Destination" otherwise.
String tripWhat(L10n l10n, GuestTrip trip) {
  if (trip.type.isAirport && trip.flightNumber.isNotEmpty) {
    return [l10n.flight(trip.flightNumber), trip.airportCode ?? '']
        .where((s) => s.isNotEmpty)
        .join(' · ');
  }
  return [trip.origin, trip.destination].where((s) => s.isNotEmpty).join(' → ');
}

/// Driver block is shown once the resort confirmed the trip.
bool showsDriver(GuestRequest r) =>
    (r.trip?.driverName.isNotEmpty ?? false) &&
    r.status.trackIndex >= RequestStatus.confirmed.trackIndex;

/// "Driver Ana · White van".
String driverSummary(L10n l10n, GuestTrip trip) => [
      l10n.driverLine(trip.driverName),
      if (trip.vehicle.isNotEmpty) trip.vehicle,
    ].join(' · ');

/// Plain cancellation reason; the guest's own cancel reads "Cancelled by you".
String requestReason(L10n l10n, GuestRequest r) {
  if (r.status != RequestStatus.cancelled) return '';
  if (r.reason == guestCancellationReason) return l10n.cancelledByYou;
  return r.reason;
}
