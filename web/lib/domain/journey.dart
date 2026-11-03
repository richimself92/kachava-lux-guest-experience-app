import 'catalog.dart';
import 'requests.dart';
import 'stay.dart';
import 'trip.dart';

/// Fixed journey tasks; their numbers never move.
enum CoreTask {
  flight(1, 1),
  preferences(1, 2),
  departure(3, 1),
  rating(3, 2);

  const CoreTask(this.step, this.slot);
  final int step;
  final int slot;

  String get id => 'core:$name';
}

enum TaskState { pending, draft, done, skipped }

/// Rows shown per open step before "See all N".
const int journeyMaxRows = 5;

/// First catalog slot per step (after the core slots).
const Map<int, int> _firstCatalogSlot = {1: 3, 2: 1, 3: 3};

class JourneyTask {
  const JourneyTask({
    required this.id,
    required this.step,
    required this.slot,
    required this.state,
    this.core,
    this.section,
    this.services = const [],
    this.optional = false,
    this.doneBy,
    this.ownArrangement = false,
  });

  /// `core:flight` or `section:DINING`; stable across steps (done is shared).
  final String id;
  final int step;
  final int slot;
  final TaskState state;
  final CoreTask? core;
  final String? section;

  /// Catalog services behind the task (section services, the trip service,
  /// or the PREFERENCE services for 1.2).
  final List<CatalogService> services;
  final bool optional;

  /// The request that completed the task (one-line summary).
  final GuestRequest? doneBy;

  /// Done because the guest said they arrange it themselves.
  final bool ownArrangement;

  String get number => '$step.$slot';
  String get skipKey => '$step:$id';
  bool get isPending => state == TaskState.pending || state == TaskState.draft;
}

class JourneyStep {
  const JourneyStep({
    required this.number,
    required this.tasks,
    required this.locked,
    this.opensOn,
  });

  final int number;
  final List<JourneyTask> tasks;

  /// A future step: read-only preview until [opensOn].
  final bool locked;
  final DateTime? opensOn;

  Iterable<JourneyTask> get _counted =>
      tasks.where((t) => !t.optional && t.state != TaskState.skipped);
  int get total => _counted.length;
  int get done => _counted.where((t) => t.state == TaskState.done).length;
  bool get hasPending => tasks.any((t) => t.isPending);
}

class Journey {
  const Journey({
    required this.steps,
    required this.openStep,
    required this.dateStep,
    required this.next,
    required this.allSet,
  });

  final List<JourneyStep> steps;

  /// Step expanded on Home.
  final int openStep;

  /// Step the resort date points to.
  final int dateStep;

  /// Target of the sticky "Next" button; null hides it.
  final JourneyTask? next;
  final bool allSet;

  JourneyStep step(int number) => steps.firstWhere((s) => s.number == number);

  JourneyTask? taskById(int step, String id) {
    for (final t in this.step(step).tasks) {
      if (t.id == id) return t;
    }
    return null;
  }
}

/// Pure journey builder: Home, screen titles and Requests read its output.
Journey buildJourney({
  required GuestStay stay,
  required List<CatalogService> catalog,
  required List<GuestRequest> requests,
  required Set<String> skips,
  required DateTime resortToday,
  Set<String> drafts = const {},
  Set<String> ownArrangements = const {},
}) {
  final today =
      DateTime.utc(resortToday.year, resortToday.month, resortToday.day);
  final live =
      requests.where((r) => r.status != RequestStatus.cancelled).toList();
  final tripService = _airportTripService(catalog);
  final departureOpens = _departureOpens(stay, tripService);
  final dateStep = _dateStep(stay, today, departureOpens);

  JourneyTask make({
    required String id,
    required int step,
    required int slot,
    required bool done,
    CoreTask? core,
    String? section,
    List<CatalogService> services = const [],
    bool optional = false,
    GuestRequest? doneBy,
    bool partial = false,
    bool own = false,
  }) {
    final skipKey = '$step:$id';
    final state = done
        ? TaskState.done
        : (partial || drafts.contains(id))
            ? TaskState.draft
            : skips.contains(skipKey)
                ? TaskState.skipped
                : TaskState.pending;
    return JourneyTask(
      id: id,
      step: step,
      slot: slot,
      state: state,
      core: core,
      section: section,
      services: services,
      optional: optional,
      doneBy: done ? doneBy : null,
      ownArrangement: done && own,
    );
  }

  JourneyTask? tripTask(CoreTask core, TripType type) {
    if (tripService == null) return null;
    final trip = _latest(live.where((r) => r.trip?.type == type));
    final own = ownArrangements.contains(core.id);
    return make(
      id: core.id,
      step: core.step,
      slot: core.slot,
      core: core,
      services: [tripService],
      done: trip != null || own,
      doneBy: trip,
      own: trip == null && own,
    );
  }

  final preferenceServices = catalog
      .where((s) => s.usageType == UsageType.preference)
      .toList()
    ..sort(_byOrder);
  final answered = preferenceServices
      .where((s) => live.any((r) => r.serviceId == s.id))
      .length;
  final dietSaved = stay.dietary.trim().isNotEmpty;

  final flight = tripTask(CoreTask.flight, TripType.arrival);
  final departure = tripTask(CoreTask.departure, TripType.departure);
  final step1 = <JourneyTask>[
    if (flight != null) flight,
    make(
      id: CoreTask.preferences.id,
      step: 1,
      slot: CoreTask.preferences.slot,
      core: CoreTask.preferences,
      services: preferenceServices,
      done: dietSaved && answered == preferenceServices.length,
      partial: dietSaved || answered > 0,
    ),
    ..._catalogTasks(1, catalog, live, make),
  ];
  final step2 = _catalogTasks(2, catalog, live, make);
  final step3 = <JourneyTask>[
    if (departure != null) departure,
    make(
      id: CoreTask.rating.id,
      step: 3,
      slot: CoreTask.rating.slot,
      core: CoreTask.rating,
      optional: true,
      done: stay.ratingsSent > 0,
    ),
  ];

  final opens = {2: stay.checkIn, 3: departureOpens};
  final steps = [
    for (final (n, tasks) in [(1, step1), (2, step2), (3, step3)])
      JourneyStep(
        number: n,
        tasks: tasks,
        locked: n > dateStep,
        opensOn: n > dateStep ? opens[n] : null,
      ),
  ];

  var openStep = dateStep;
  var allSet = false;
  if (!steps[dateStep - 1].hasPending) {
    final later = steps.where((s) => s.number > dateStep && s.hasPending);
    if (later.isNotEmpty) {
      openStep = later.first.number;
    } else {
      allSet = true;
    }
  }

  JourneyTask? next;
  for (final s in steps.where((s) => s.number >= openStep && !s.locked)) {
    final pending = s.tasks.where((t) => t.isPending);
    if (pending.isNotEmpty) {
      next = pending.first;
      break;
    }
  }

  return Journey(
    steps: steps,
    openStep: openStep,
    dateStep: dateStep,
    next: next,
    allSet: allSet,
  );
}

typedef _TaskFactory = JourneyTask Function({
  required String id,
  required int step,
  required int slot,
  required bool done,
  CoreTask? core,
  String? section,
  List<CatalogService> services,
  bool optional,
  GuestRequest? doneBy,
  bool partial,
  bool own,
});

/// One task per catalog section offered in [step], in admin section order.
List<JourneyTask> _catalogTasks(
  int step,
  List<CatalogService> catalog,
  List<GuestRequest> live,
  _TaskFactory make,
) {
  final offered = catalog.where((s) {
    if (s.usageType == UsageType.preference) return false;
    if (step == 1) {
      return s.availability.offeredWhen.before && s.usageType != UsageType.trip;
    }
    return step == 2 && s.availability.offeredWhen.during;
  });
  final bySection = <String, List<CatalogService>>{};
  for (final s in offered) {
    bySection.putIfAbsent(s.section, () => []).add(s);
  }
  final sections = bySection.keys.toList()
    ..sort((a, b) {
      final rank = sectionRank(a).compareTo(sectionRank(b));
      return rank != 0 ? rank : a.compareTo(b);
    });
  var slot = _firstCatalogSlot[step]!;
  return [
    for (final section in sections)
      () {
        final services = bySection[section]!..sort(_byOrder);
        final ids = services.map((s) => s.id).toSet();
        final doneBy = _latest(live.where((r) => ids.contains(r.serviceId)));
        return make(
          id: 'section:$section',
          step: step,
          slot: slot++,
          section: section,
          services: services,
          done: doneBy != null,
          doneBy: doneBy,
        );
      }(),
  ];
}

int _byOrder(CatalogService a, CatalogService b) {
  final o = a.order.compareTo(b.order);
  return o != 0
      ? o
      : a.name.en.toLowerCase().compareTo(b.name.en.toLowerCase());
}

GuestRequest? _latest(Iterable<GuestRequest> requests) =>
    requests.isEmpty ? null : requests.first;

/// The airport transfer service behind 1.1 and 3.1 (needs Settings airports).
CatalogService? _airportTripService(List<CatalogService> catalog) {
  final candidates = catalog
      .where((s) => s.usageType == UsageType.trip && s.airportCodes.isNotEmpty)
      .toList()
    ..sort(_byOrder);
  return candidates.isEmpty ? null : candidates.first;
}

/// Step 3 opens at check-out minus max(departure lead time, 1 day).
DateTime? _departureOpens(GuestStay stay, CatalogService? tripService) {
  final checkOut = stay.checkOut;
  if (checkOut == null) return null;
  final leadHours = tripService?.availability.minLeadHours ?? 0;
  final leadDays = (leadHours / 24).ceil();
  return checkOut.subtract(Duration(days: leadDays < 1 ? 1 : leadDays));
}

int _dateStep(GuestStay stay, DateTime today, DateTime? departureOpens) {
  final checkIn = stay.checkIn;
  if (checkIn == null) {
    return switch (stay.phase) {
      StayPhase.preArrival => 1,
      StayPhase.inStay => 2,
      StayPhase.departed => 3,
    };
  }
  if (today.isBefore(checkIn)) return 1;
  if (departureOpens != null && !today.isBefore(departureOpens)) return 3;
  return 2;
}
