/// JSON shapes of the real trips contract (`backend/`, commit 1ed5498:
/// `toAdminTripView` = Trip + `id` + `unconfirmedDue`). Adapter tests answer
/// with these bodies so a contract drift fails here.
library;

const _meta = {'timestamp': '2026-11-03T04:09:05.094Z', 'requestId': 'req_1'};

/// A staff-created DEPARTURE trip after "Send to provider" (CUN, van).
const Map<String, dynamic> recordedTrip = {
  'id': 'trip_5b1e',
  'tripId': 'trip_5b1e',
  'stayId': 'stay_1',
  'villaId': 'villa_3',
  'villaName': 'Casa Ceiba',
  'guestName': 'Ana Ruiz',
  'serviceId': 'svc_transfer',
  'itemId': 'item_van',
  'snapshot': {
    'serviceId': 'svc_transfer',
    'serviceName': {'en': 'Airport transfer', 'es': 'Traslado aeropuerto'},
    'section': 'TRANSPORTATION',
    'usageType': 'TRIP',
    'pricingMode': 'FIXED',
    'chargeToFolio': true,
    'currency': 'USD',
    'lines': [
      {
        'itemId': 'item_van',
        'name': {'en': 'Van', 'es': 'Camioneta'},
        'unitPriceUSD': 90,
        'quantity': 1,
        'lineTotalUSD': 90,
      }
    ],
    'totalUSD': 90,
    'capturedAt': '2026-11-03T05:00:00.000Z',
    'vehicleCapacity': {'passengers': 6, 'luggage': 4},
  },
  'type': 'DEPARTURE',
  'airportCode': 'CUN',
  'flight': {
    'airline': 'Aeromexico',
    'number': 'AM 512',
    'scheduledAt': '2026-11-04T17:00:00.000Z',
  },
  'pickupAt': '2026-11-04T14:00:00.000Z',
  'origin': null,
  'destination': null,
  'roundTrip': false,
  'waitMinutes': null,
  'passengers': 2,
  'luggage': 3,
  'guestNotes': 'Baby seat',
  'notes': 'Gate 3',
  'providerId': 'prov_1',
  'driver': null,
  'vehicle': null,
  'status': 'SENT_TO_PROVIDER',
  'cancellationReason': null,
  'createdBy': 'STAFF',
  'statusHistory': [
    {
      'from': null,
      'to': 'REQUESTED',
      'at': '2026-11-03T05:00:00.000Z',
      'by': 'admin@kachava.local',
      'reason': null,
    },
    {
      'from': 'REQUESTED',
      'to': 'SENT_TO_PROVIDER',
      'at': '2026-11-03T05:10:00.000Z',
      'by': 'admin@kachava.local',
      'reason': null,
    },
  ],
  'createdAt': '2026-11-03T05:00:00.000Z',
  'createdByActor': 'admin@kachava.local',
  'updatedAt': '2026-11-03T05:10:00.000Z',
  'updatedBy': 'admin@kachava.local',
  'unconfirmedDue': true,
};

/// A guest LOCAL trip without a service snapshot (legacy shape), cancelled.
const Map<String, dynamic> recordedLocalTrip = {
  'id': 'trip_local',
  'tripId': 'trip_local',
  'stayId': 'stay_2',
  'villaId': 'villa_1',
  'villaName': 'Casa Luna',
  'guestName': 'Bea Soto',
  'serviceId': null,
  'itemId': null,
  'snapshot': null,
  'type': 'LOCAL',
  'airportCode': null,
  'flight': null,
  'pickupAt': '2026-11-03T15:30:00.000Z',
  'origin': 'Villa',
  'destination': 'Tulum ruins',
  'roundTrip': true,
  'waitMinutes': 90,
  'passengers': 3,
  'luggage': 0,
  'guestNotes': '',
  'notes': '',
  'providerId': null,
  'driver': {'name': 'Luis', 'phone': '+52 984 000'},
  'vehicle': {'description': 'White Suburban', 'plate': 'ABC-123'},
  'status': 'CANCELLED',
  'cancellationReason': 'Guest changed plans',
  'createdBy': 'GUEST',
  'statusHistory': [],
  'createdAt': '2026-11-03T05:00:00.000Z',
  'createdByActor': 'guest:stay_2',
  'updatedAt': '2026-11-03T05:00:00.000Z',
  'updatedBy': 'guest:stay_2',
  'unconfirmedDue': null,
};

/// 422 body of incomplete Settings (global exception filter).
const Map<String, dynamic> recordedSettingsRequired = {
  'success': false,
  'statusCode': 422,
  'error': 'UnprocessableEntity',
  'message': 'Resort settings are incomplete',
  'code': 'SETTINGS_REQUIRED',
  'details': ['timeZone'],
  'timestamp': '2026-11-03T05:00:00.000Z',
  'path': '/api/v1/admin/trips?from=2026-11-03',
  'meta': _meta,
};

/// A plain business-rule 422 (no code).
const Map<String, dynamic> recordedRuleError = {
  'success': false,
  'statusCode': 422,
  'error': 'UnprocessableEntity',
  'message': 'Cannot move the trip to CONFIRMED',
  'timestamp': '2026-11-03T05:00:00.000Z',
  'path': '/api/v1/admin/trips/trip_5b1e/transition',
  'meta': _meta,
};
