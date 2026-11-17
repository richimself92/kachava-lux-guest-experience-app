import 'catalog_values.dart';
import 'json_read.dart';
import 'service_item.dart';

/// Wire values of transport trips (ADR-010).
abstract final class TripValues {
  static const List<String> types = ['ARRIVAL', 'DEPARTURE', 'LOCAL'];

  /// The forward flow, one step at a time.
  static const List<String> flow = [
    'REQUESTED',
    'SENT_TO_PROVIDER',
    'CONFIRMED',
    'EN_ROUTE',
    'COMPLETED',
  ];
  static const String cancelled = 'CANCELLED';
  static const List<String> statuses = [...flow, cancelled];

  /// The only forward move from [status]; `null` for final statuses.
  static String? next(String status) {
    final index = flow.indexOf(status);
    return index < 0 || index == flow.length - 1 ? null : flow[index + 1];
  }

  static bool isFinal(String status) =>
      status == 'COMPLETED' || status == cancelled;

  static bool isAirport(String type) =>
      type == 'ARRIVAL' || type == 'DEPARTURE';
}

/// Flight of an airport trip; [scheduledAt] is the UTC instant.
class TripFlight {
  const TripFlight({
    required this.airline,
    required this.number,
    this.scheduledAt,
  });

  static TripFlight? fromJson(Object? json) {
    if (json is! Map) return null;
    final map = Map<String, dynamic>.from(json);
    return TripFlight(
      airline: JsonRead.text(map, 'airline'),
      number: JsonRead.text(map, 'number'),
      scheduledAt: _instant(map['scheduledAt']),
    );
  }

  final String airline;
  final String number;
  final DateTime? scheduledAt;
}

class TripDriver {
  const TripDriver({required this.name, required this.phone});

  static TripDriver? fromJson(Object? json) {
    if (json is! Map) return null;
    final map = Map<String, dynamic>.from(json);
    return TripDriver(
        name: JsonRead.text(map, 'name'), phone: JsonRead.text(map, 'phone'));
  }

  final String name;
  final String phone;

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone};
}

class TripVehicle {
  const TripVehicle({required this.description, required this.plate});

  static TripVehicle? fromJson(Object? json) {
    if (json is! Map) return null;
    final map = Map<String, dynamic>.from(json);
    return TripVehicle(
        description: JsonRead.text(map, 'description'),
        plate: JsonRead.text(map, 'plate'));
  }

  final String description;
  final String plate;

  Map<String, dynamic> toJson() => {'description': description, 'plate': plate};
}

/// One `statusHistory[]` entry.
class TripStatusChange {
  const TripStatusChange({
    required this.from,
    required this.to,
    required this.at,
    required this.by,
    required this.reason,
  });

  factory TripStatusChange.fromJson(Map<String, dynamic> json) =>
      TripStatusChange(
        from: JsonRead.textOrNull(json, 'from'),
        to: JsonRead.text(json, 'to'),
        at: _instant(json['at']),
        by: JsonRead.text(json, 'by'),
        reason: JsonRead.textOrNull(json, 'reason'),
      );

  final String? from;
  final String to;
  final DateTime? at;
  final String by;
  final String? reason;
}

/// A transport trip as staff see it (`GET /admin/trips[/:id]`).
class AdminTrip {
  const AdminTrip({
    required this.id,
    required this.stayId,
    required this.villaId,
    required this.villaName,
    required this.guestName,
    required this.type,
    required this.status,
    this.serviceId,
    this.itemId,
    this.serviceName = const LocalizedText(),
    this.vehicleName = const LocalizedText(),
    this.vehicleCapacity,
    this.airportCode,
    this.flight,
    this.pickupAt,
    this.origin,
    this.destination,
    this.roundTrip = false,
    this.waitMinutes,
    this.passengers = 0,
    this.luggage = 0,
    this.guestNotes = '',
    this.notes = '',
    this.providerId,
    this.driver,
    this.vehicle,
    this.cancellationReason,
    this.createdBy = '',
    this.history = const [],
    this.unconfirmedDue,
  });

  factory AdminTrip.fromJson(Map<String, dynamic> json) {
    final snapshot = JsonRead.object(json, 'snapshot');
    final lines = JsonRead.objects(snapshot, 'lines');
    return AdminTrip(
      id: JsonRead.requireId(json),
      stayId: JsonRead.text(json, 'stayId'),
      villaId: JsonRead.text(json, 'villaId'),
      villaName: JsonRead.text(json, 'villaName'),
      guestName: JsonRead.text(json, 'guestName'),
      type: JsonRead.text(json, 'type'),
      status: JsonRead.text(json, 'status'),
      serviceId: JsonRead.textOrNull(json, 'serviceId'),
      itemId: JsonRead.textOrNull(json, 'itemId'),
      serviceName: LocalizedText.fromJson(snapshot['serviceName']),
      vehicleName: lines.isEmpty
          ? const LocalizedText()
          : LocalizedText.fromJson(lines.first['name']),
      vehicleCapacity: VehicleCapacity.fromJson(snapshot['vehicleCapacity']),
      airportCode: JsonRead.textOrNull(json, 'airportCode'),
      flight: TripFlight.fromJson(json['flight']),
      pickupAt: _instant(json['pickupAt']),
      origin: JsonRead.textOrNull(json, 'origin'),
      destination: JsonRead.textOrNull(json, 'destination'),
      roundTrip: JsonRead.flag(json, 'roundTrip'),
      waitMinutes: JsonRead.intOrNull(json, 'waitMinutes'),
      passengers: JsonRead.intOrNull(json, 'passengers') ?? 0,
      luggage: JsonRead.intOrNull(json, 'luggage') ?? 0,
      guestNotes: JsonRead.text(json, 'guestNotes'),
      notes: JsonRead.text(json, 'notes'),
      providerId: JsonRead.textOrNull(json, 'providerId'),
      driver: TripDriver.fromJson(json['driver']),
      vehicle: TripVehicle.fromJson(json['vehicle']),
      cancellationReason: JsonRead.textOrNull(json, 'cancellationReason'),
      createdBy: JsonRead.text(json, 'createdBy'),
      history: [
        for (final h in JsonRead.objects(json, 'statusHistory'))
          TripStatusChange.fromJson(h),
      ],
      unconfirmedDue: json['unconfirmedDue'] is bool
          ? json['unconfirmedDue'] as bool
          : null,
    );
  }

  final String id;
  final String stayId;
  final String villaId;
  final String villaName;
  final String guestName;

  /// ARRIVAL | DEPARTURE | LOCAL.
  final String type;
  final String status;
  final String? serviceId;
  final String? itemId;

  /// Snapshot captured at request time.
  final LocalizedText serviceName;
  final LocalizedText vehicleName;
  final VehicleCapacity? vehicleCapacity;
  final String? airportCode;
  final TripFlight? flight;

  /// UTC instant (display in resort time).
  final DateTime? pickupAt;
  final String? origin;
  final String? destination;
  final bool roundTrip;
  final int? waitMinutes;
  final int passengers;
  final int luggage;
  final String guestNotes;

  /// Staff-only.
  final String notes;
  final String? providerId;
  final TripDriver? driver;
  final TripVehicle? vehicle;
  final String? cancellationReason;

  /// GUEST | STAFF.
  final String createdBy;
  final List<TripStatusChange> history;

  /// Not confirmed and picking up soon; `null` when the alert lead time is
  /// not configured in Settings (unknown, never guessed).
  final bool? unconfirmedDue;

  String? get nextStatus => TripValues.next(status);
  bool get isFinal => TripValues.isFinal(status);
}

/// Flight as typed by staff: [scheduledAt] is a resort wall time
/// (`YYYY-MM-DDTHH:mm`) that the backend reads in the Settings time zone.
class TripFlightInput {
  const TripFlightInput({
    required this.airline,
    required this.number,
    required this.scheduledAt,
  });

  final String airline;
  final String number;
  final String scheduledAt;

  Map<String, dynamic> toJson() =>
      {'airline': airline, 'number': number, 'scheduledAt': scheduledAt};
}

/// `POST /admin/trips`: staff on behalf of a guest. Optional values that are
/// `null` (or blank text) are not sent. [pickupAt] is a resort wall time;
/// airport trips may omit it (the backend suggests one from the flight).
class NewTripRequest {
  const NewTripRequest({
    required this.stayId,
    required this.serviceId,
    required this.type,
    required this.passengers,
    this.itemId,
    this.airportCode,
    this.flight,
    this.pickupAt,
    this.origin,
    this.destination,
    this.roundTrip,
    this.waitMinutes,
    this.luggage,
    this.guestNotes,
    this.notes,
    this.providerId,
  });

  final String stayId;
  final String serviceId;
  final String type;
  final int passengers;
  final String? itemId;
  final String? airportCode;
  final TripFlightInput? flight;
  final String? pickupAt;
  final String? origin;
  final String? destination;
  final bool? roundTrip;
  final int? waitMinutes;
  final int? luggage;
  final String? guestNotes;
  final String? notes;
  final String? providerId;

  Map<String, dynamic> toJson() => {
        'stayId': stayId,
        'serviceId': serviceId,
        ..._text('itemId', itemId),
        'type': type,
        ..._text('airportCode', airportCode),
        if (flight != null) 'flight': flight!.toJson(),
        ..._text('pickupAt', pickupAt),
        ..._text('origin', origin),
        ..._text('destination', destination),
        if (roundTrip != null) 'roundTrip': roundTrip,
        if (waitMinutes != null) 'waitMinutes': waitMinutes,
        'passengers': passengers,
        if (luggage != null) 'luggage': luggage,
        ..._text('guestNotes', guestNotes),
        ..._text('notes', notes),
        ..._text('providerId', providerId),
      };
}

/// `POST /admin/trips/:id/transition`.
class TripTransition {
  const TripTransition({
    required this.to,
    this.reason,
    this.driver,
    this.vehicle,
    this.providerId,
  });

  final String to;
  final String? reason;
  final TripDriver? driver;
  final TripVehicle? vehicle;
  final String? providerId;

  Map<String, dynamic> toJson() => {
        'to': to,
        ..._text('reason', reason),
        if (driver != null) 'driver': driver!.toJson(),
        if (vehicle != null) 'vehicle': vehicle!.toJson(),
        ..._text('providerId', providerId),
      };
}

/// Inclusive resort-day window of the trips list (`from`/`to` on the wire).
/// In a [ListQuery] it lives under [filterKey] as `from..to`.
class TripDateRange {
  const TripDateRange(this.from, this.to);

  static const String filterKey = 'range';
  static final RegExp _day = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  final String from;
  final String to;

  String encode() => '$from..$to';

  static TripDateRange? parse(String? raw) {
    final parts = (raw ?? '').split('..');
    if (parts.length != 2) return null;
    if (!_day.hasMatch(parts.first) || !_day.hasMatch(parts.last)) return null;
    return TripDateRange(parts.first, parts.last);
  }

  /// The quick ranges around the resort [today] (`YYYY-MM-DD`).
  static TripRangePresets presets(String today) => TripRangePresets(today);

  /// [day] (`YYYY-MM-DD`) moved by [days] calendar days.
  static String shift(String day, int days) {
    final d = DateTime.parse('${day}T00:00:00Z').add(Duration(days: days));
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
  }

  @override
  bool operator ==(Object other) =>
      other is TripDateRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => encode();
}

/// Quick date ranges of the trips list, relative to the resort day.
class TripRangePresets {
  const TripRangePresets(this.day);

  /// The resort day (`YYYY-MM-DD`) the presets are relative to.
  final String day;

  TripDateRange get todayAndTomorrow =>
      TripDateRange(day, TripDateRange.shift(day, 1));
  TripDateRange get today => TripDateRange(day, day);
  TripDateRange get tomorrow {
    final next = TripDateRange.shift(day, 1);
    return TripDateRange(next, next);
  }

  TripDateRange get next7Days =>
      TripDateRange(day, TripDateRange.shift(day, 6));
  TripDateRange get last7Days =>
      TripDateRange(TripDateRange.shift(day, -7), TripDateRange.shift(day, -1));
}

Map<String, dynamic> _text(String key, String? value) =>
    value == null || value.trim().isEmpty ? const {} : {key: value.trim()};

DateTime? _instant(Object? raw) =>
    raw is String ? DateTime.tryParse(raw)?.toUtc() : null;
