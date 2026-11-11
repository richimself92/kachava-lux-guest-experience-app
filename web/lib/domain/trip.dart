import 'json_read.dart';
import 'stay.dart';

enum TripType {
  arrival,
  departure,
  local;

  String get wire => switch (this) {
        arrival => 'ARRIVAL',
        departure => 'DEPARTURE',
        local => 'LOCAL',
      };

  bool get isAirport => this != local;

  static TripType parse(String raw) => switch (raw) {
        'ARRIVAL' => arrival,
        'DEPARTURE' => departure,
        _ => local,
      };
}

/// Guest-safe trip (`GET /stays/:uuid/trips`, ADR-010).
class GuestTrip {
  const GuestTrip({
    required this.id,
    required this.type,
    required this.status,
    this.serviceId,
    this.snapshot,
    this.airportCode,
    this.airline = '',
    this.flightNumber = '',
    this.flightAt,
    this.pickupAt,
    this.origin = '',
    this.destination = '',
    this.passengers = 0,
    this.luggage = 0,
    this.driverName = '',
    this.driverPhone = '',
    this.vehicle = '',
    this.plate = '',
    this.cancellationReason = '',
    this.createdAt,
  });

  factory GuestTrip.fromJson(Json json) {
    final flight = asJson(json['flight']);
    final driver = asJson(json['driver']);
    final vehicle = asJson(json['vehicle']);
    final snapshot = json['snapshot'];
    return GuestTrip(
      id: asString(json['tripId']).isNotEmpty
          ? asString(json['tripId'])
          : asString(json['id']),
      type: TripType.parse(asString(json['type'])),
      status: asString(json['status']),
      serviceId: asStringOrNull(json['serviceId']),
      snapshot: snapshot is Map ? ServiceSnapshot.fromJson(snapshot) : null,
      airportCode: asStringOrNull(json['airportCode']),
      airline: asString(flight['airline']),
      flightNumber: asString(flight['number']),
      flightAt: asDateTime(flight['scheduledAt']),
      pickupAt: asDateTime(json['pickupAt']),
      origin: asString(json['origin']),
      destination: asString(json['destination']),
      passengers: asInt(json['passengers']) ?? 0,
      luggage: asInt(json['luggage']) ?? 0,
      driverName: asString(driver['name']),
      driverPhone: asString(driver['phone']),
      vehicle: asString(vehicle['description']),
      plate: asString(vehicle['plate']),
      cancellationReason: asString(json['cancellationReason']),
      createdAt: asDateTime(json['createdAt']),
    );
  }

  final String id;
  final TripType type;
  final String status;
  final String? serviceId;
  final ServiceSnapshot? snapshot;
  final String? airportCode;
  final String airline;
  final String flightNumber;

  /// UTC instants.
  final DateTime? flightAt;
  final DateTime? pickupAt;
  final String origin;
  final String destination;
  final int passengers;
  final int luggage;

  /// Set by the resort when it confirms the trip (guest-safe, ADR-007).
  final String driverName;
  final String driverPhone;
  final String vehicle;
  final String plate;
  final String cancellationReason;
  final DateTime? createdAt;

  /// The guest may cancel only before the resort sends it to the provider.
  bool get isInitial => status == 'REQUESTED';
}
