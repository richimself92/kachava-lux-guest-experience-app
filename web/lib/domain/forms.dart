import 'catalog.dart';
import 'json_read.dart';
import 'resort_clock.dart';
import 'stay.dart';
import 'trip.dart';

/// Inline validation problems; the UI turns each into <= 5 words.
enum FormIssue {
  required,
  invalidTime,
  pastTime,
  tooSoon,
  dayUnavailable,
  notServed,
  overCapacity,
  tooManyBags,
  tooFewGuests,
  tooManyGuests,
  ageRequired,
  emptyCart,
}

final RegExp _hhmm = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

bool isValidTime(String value) => _hhmm.hasMatch(value.trim());

DateTime _at(DateTime day, String hhmm) {
  final parts = hhmm.split(':');
  return DateTime.utc(
      day.year, day.month, day.day, int.parse(parts[0]), int.parse(parts[1]));
}

// ---------------------------------------------------------------- TRIP

/// The 4 pages of the TRIP wizard: When, Flight (or Route), Group, Review.
const int tripPageCount = 4;

class TripDraft {
  TripDraft(this.type);

  final TripType type;
  DateTime? day;
  String time = '';
  String? airport;
  String airline = '';
  String flightNumber = '';
  String terminal = '';
  String origin = '';
  String destination = '';
  int passengers = 1;
  int luggage = 0;
  String? vehicleId;

  Json toJson() => {
        'day': day == null ? null : ResortClock.isoDay(day!),
        'time': time,
        'airport': airport,
        'airline': airline,
        'flightNumber': flightNumber,
        'terminal': terminal,
        'origin': origin,
        'destination': destination,
        'passengers': passengers,
        'luggage': luggage,
        'vehicleId': vehicleId,
      };

  static TripDraft fromJson(TripType type, Json json) {
    final day = DateTime.tryParse(asString(json['day']));
    return TripDraft(type)
      ..day = day == null ? null : DateTime.utc(day.year, day.month, day.day)
      ..time = asString(json['time'])
      ..airport = asStringOrNull(json['airport'])
      ..airline = asString(json['airline'])
      ..flightNumber = asString(json['flightNumber'])
      ..terminal = asString(json['terminal'])
      ..origin = asString(json['origin'])
      ..destination = asString(json['destination'])
      ..passengers = asInt(json['passengers']) ?? 1
      ..luggage = asInt(json['luggage']) ?? 0
      ..vehicleId = asStringOrNull(json['vehicleId']);
  }
}

/// Field → problem for one wizard page. Empty = the page is valid.
Map<String, FormIssue> validateTripPage(
  TripDraft d,
  int page,
  CatalogService service,
  DateTime nowWall,
) {
  final issues = <String, FormIssue>{};
  switch (page) {
    case 0:
      if (d.day == null) issues['day'] = FormIssue.required;
      if (d.time.trim().isEmpty) {
        issues['time'] = FormIssue.required;
      } else if (!isValidTime(d.time)) {
        issues['time'] = FormIssue.invalidTime;
      }
      if (issues.isEmpty) {
        final at = _at(d.day!, d.time.trim());
        final lead = Duration(hours: service.availability.minLeadHours ?? 0);
        if (!at.isAfter(nowWall)) {
          issues['time'] = FormIssue.pastTime;
        } else if (at.isBefore(nowWall.add(lead))) {
          issues['time'] = FormIssue.tooSoon;
        }
      }
    case 1:
      if (d.type.isAirport) {
        if (d.airport == null) {
          issues['airport'] = FormIssue.required;
        } else if (!service.airportCodes.contains(d.airport)) {
          issues['airport'] = FormIssue.notServed;
        }
        if (d.airline.trim().isEmpty) issues['airline'] = FormIssue.required;
        if (d.flightNumber.trim().isEmpty) {
          issues['flightNumber'] = FormIssue.required;
        }
      } else {
        if (d.origin.trim().isEmpty) issues['origin'] = FormIssue.required;
        if (d.destination.trim().isEmpty) {
          issues['destination'] = FormIssue.required;
        }
      }
    case 2:
      if (d.passengers < 1) issues['passengers'] = FormIssue.required;
      if (d.luggage < 0) issues['luggage'] = FormIssue.required;
      final vehicles = service.items;
      if (vehicles.isNotEmpty) {
        final vehicle = vehicles.where((v) => v.id == d.vehicleId).firstOrNull;
        if (vehicle == null) {
          issues['vehicle'] = FormIssue.required;
        } else if (vehicle.capacity != null) {
          if (d.passengers > vehicle.capacity!.passengers) {
            issues['passengers'] = FormIssue.overCapacity;
          }
          if (d.luggage > vehicle.capacity!.luggage) {
            issues['luggage'] = FormIssue.tooManyBags;
          }
        }
      }
  }
  return issues;
}

/// First invalid page (0..2), or null when the draft can be sent.
int? firstInvalidTripPage(TripDraft d, CatalogService s, DateTime nowWall) {
  for (var p = 0; p < 3; p++) {
    if (validateTripPage(d, p, s, nowWall).isNotEmpty) return p;
  }
  return null;
}

/// `POST /stays/:uuid/trips` body (ADR-010). Airport pickups are computed
/// by the resort, so only the flight time is sent for them.
Json tripPayload(TripDraft d, CatalogService service) {
  final wall = ResortClock.wallDateTime(d.day!, d.time.trim());
  final notes =
      d.terminal.trim().isEmpty ? '' : 'Terminal ${d.terminal.trim()}';
  return {
    'serviceId': service.id,
    if (d.vehicleId != null) 'itemId': d.vehicleId,
    'type': d.type.wire,
    if (d.type.isAirport) ...{
      'airportCode': d.airport,
      'flight': {
        'airline': d.airline.trim(),
        'number': d.flightNumber.trim(),
        'scheduledAt': wall,
      },
    } else ...{
      'pickupAt': wall,
      'origin': d.origin.trim(),
      'destination': d.destination.trim(),
    },
    'passengers': d.passengers,
    'luggage': d.luggage,
    if (notes.isNotEmpty) 'guestNotes': notes,
  };
}

// ---------------------------------------------------------------- BOOKING

enum BookingField { date, time, guests, notes, dietary, health }

/// A configured field; [question] is set for each wellness health question.
class BookingFieldSpec {
  const BookingFieldSpec(this.field, {this.question});
  final BookingField field;
  final LocalizedText? question;
}

/// Fields of this service's guest form (from its kind). The date is always
/// asked because the backend books a day.
List<BookingFieldSpec> bookingFields(CatalogService s) {
  final f = s.effectiveGuestForm;
  return [
    const BookingFieldSpec(BookingField.date),
    if (f.time || s.availability.timeSlots.isNotEmpty)
      const BookingFieldSpec(BookingField.time),
    if (f.guests) const BookingFieldSpec(BookingField.guests),
    if (f.dietary) const BookingFieldSpec(BookingField.dietary),
    if (f.health)
      if (s.healthQuestions.isEmpty)
        const BookingFieldSpec(BookingField.health)
      else
        for (final q in s.healthQuestions)
          BookingFieldSpec(BookingField.health, question: q),
    if (f.notes) const BookingFieldSpec(BookingField.notes),
  ];
}

/// Up to 4 fields fit one page; more become a wizard of <= 3 per page.
List<List<T>> paginateFields<T>(List<T> fields) {
  if (fields.length <= 4) return [fields];
  return [
    for (var i = 0; i < fields.length; i += 3)
      fields.sublist(i, i + 3 > fields.length ? fields.length : i + 3),
  ];
}

class BookingDraft {
  DateTime? day;
  String time = '';
  int guests = 0;
  String notes = '';
  String dietary = '';
  final Map<int, String> health = {};
}

const List<String> _weekdays = [
  'MON',
  'TUE',
  'WED',
  'THU',
  'FRI',
  'SAT',
  'SUN'
];

/// Validates the [fields] of one page.
Map<BookingField, FormIssue> validateBooking(
  BookingDraft d,
  List<BookingFieldSpec> fields,
  CatalogService s,
  DateTime nowWall,
) {
  final issues = <BookingField, FormIssue>{};
  final a = s.availability;
  final asked = fields.map((f) => f.field).toSet();
  final earliest = nowWall.add(Duration(hours: a.minLeadHours ?? 0));
  if (asked.contains(BookingField.date)) {
    final day = d.day;
    if (day == null) {
      issues[BookingField.date] = FormIssue.required;
    } else if (a.blockedDates.contains(ResortClock.isoDay(day)) ||
        (a.weekdays.isNotEmpty &&
            !a.weekdays.contains(_weekdays[day.weekday - 1]))) {
      issues[BookingField.date] = FormIssue.dayUnavailable;
    } else if (day.isBefore(ResortClock.dayOf(earliest))) {
      issues[BookingField.date] = FormIssue.tooSoon;
    }
  }
  if (asked.contains(BookingField.time)) {
    if (d.time.isEmpty) {
      issues[BookingField.time] = FormIssue.required;
    } else if (!isValidTime(d.time)) {
      issues[BookingField.time] = FormIssue.invalidTime;
    } else if (d.day != null && _at(d.day!, d.time).isBefore(earliest)) {
      issues[BookingField.time] = FormIssue.tooSoon;
    }
  }
  if (asked.contains(BookingField.guests)) {
    if (d.guests < 1) {
      issues[BookingField.guests] = FormIssue.required;
    } else if (a.minGuests != null && d.guests < a.minGuests!) {
      issues[BookingField.guests] = FormIssue.tooFewGuests;
    } else if (a.maxGuests != null && d.guests > a.maxGuests!) {
      issues[BookingField.guests] = FormIssue.tooManyGuests;
    }
  }
  return issues;
}

/// `POST /stays/:uuid/bookings` body.
/// What a guest may change on a REQUESTED booking: date, time and people.
List<BookingFieldSpec> changeableBookingFields(CatalogService s) => [
      for (final f in bookingFields(s))
        if (f.field == BookingField.date ||
            f.field == BookingField.time ||
            f.field == BookingField.guests)
          f,
    ];

/// Prefills the change form with the booking as the server holds it.
void prefillBookingDraft(BookingDraft d, GuestBooking b) {
  final day = DateTime.tryParse(b.scheduledDate);
  d.day = day == null ? null : DateTime.utc(day.year, day.month, day.day);
  d.time = b.scheduledTimeSlot;
  d.guests = b.partySize;
}

/// `PATCH /stays/:uuid/bookings/:id` body for the asked [fields].
Json bookingChangePayload(BookingDraft d, List<BookingFieldSpec> fields) {
  final asked = fields.map((f) => f.field).toSet();
  return {
    'scheduledDate': ResortClock.isoDay(d.day!),
    if (asked.contains(BookingField.time) && d.time.isNotEmpty)
      'scheduledTimeSlot': d.time,
    if (asked.contains(BookingField.guests) && d.guests > 0)
      'partySize': d.guests,
  };
}

Json bookingPayload(BookingDraft d, CatalogService s, {String? itemId}) {
  final fields = bookingFields(s);
  final health = <String, String>{};
  for (var i = 0; i < fields.length; i++) {
    if (fields[i].field != BookingField.health) continue;
    final answer = d.health[i]?.trim() ?? '';
    if (answer.isEmpty) continue;
    health[fields[i].question?.en ?? 'health'] = answer;
  }
  final metadata = {
    if (d.notes.trim().isNotEmpty) 'notes': d.notes.trim(),
    if (d.dietary.trim().isNotEmpty) 'dietary': d.dietary.trim(),
    if (health.isNotEmpty) 'health': health,
  };
  return {
    'serviceId': s.id,
    if (itemId != null) 'itemId': itemId,
    'scheduledDate': ResortClock.isoDay(d.day!),
    if (d.time.isNotEmpty) 'scheduledTimeSlot': d.time,
    if (d.guests > 0) 'partySize': d.guests,
    if (metadata.isNotEmpty) 'metadata': metadata,
  };
}

// ---------------------------------------------------------------- ORDER

/// Max quantity per line accepted by `PUT /larder`.
const int orderLineMax = 20;

class OrderCart {
  OrderCart(this.service, [Map<String, int>? initial])
      : quantities = {...?initial};

  final CatalogService service;
  final Map<String, int> quantities;

  int quantityOf(String itemId) => quantities[itemId] ?? 0;

  void set(String itemId, int quantity) {
    final q = quantity.clamp(0, orderLineMax);
    if (q == 0) {
      quantities.remove(itemId);
    } else {
      quantities[itemId] = q;
    }
  }

  double? unitPrice(CatalogItem item) =>
      item.priceUSD ?? service.pricing.amount;

  int get count => quantities.values.fold(0, (a, b) => a + b);

  double get total => service.items.fold(0.0, (sum, item) {
        final price = unitPrice(item) ?? 0;
        return sum + price * quantityOf(item.id);
      });

  bool get isEmpty => count == 0;

  /// Items grouped by item category, in catalog order.
  Map<String, List<CatalogItem>> get groups {
    final out = <String, List<CatalogItem>>{};
    for (final item in service.items) {
      out.putIfAbsent(item.category ?? '', () => []).add(item);
    }
    return out;
  }

  Json toPayload() => {
        'serviceId': service.id,
        'items': [
          for (final item in service.items)
            if (quantityOf(item.id) > 0)
              {'itemId': item.id, 'quantity': quantityOf(item.id)},
        ],
      };
}
