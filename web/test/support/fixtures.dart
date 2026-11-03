import 'package:kachava_guest_portal/domain/catalog.dart';
import 'package:kachava_guest_portal/domain/json_read.dart';
import 'package:kachava_guest_portal/domain/stay.dart';

/// Test-only builders that mirror the backend wire shapes.
const guestUuid = '3f2b8c1e-4d5a-4b6c-8d7e-9f0a1b2c3d4e';

Json serviceJson({
  required String id,
  required String section,
  String usageType = 'BOOKING',
  String kind = 'EXPERIENCE',
  String? nameEn,
  String? nameEs,
  String offeredWhen = 'DURING_STAY',
  int order = 0,
  List<Json> items = const [],
  Json pricing = const {'mode': 'FIXED', 'amount': 45, 'currency': 'USD'},
  Json guestForm = const {},
  Json availability = const {},
  List<String> airportCodes = const [],
  Json? preference,
  Json? bar,
  List<String> tags = const [],
}) =>
    {
      'id': id,
      'serviceId': id,
      'kind': kind,
      'section': section,
      'usageType': usageType,
      'name': {'en': nameEn ?? 'Svc $id', 'es': nameEs ?? 'Serv $id'},
      'shortDescription': {'en': 'Short $id', 'es': 'Corto $id'},
      'description': {'en': 'Long $id', 'es': 'Largo $id'},
      'tags': tags,
      'order': order,
      'cover': {
        'storagePath': 'catalog/services/$id.jpg',
        'url': 'https://img.test/$id.jpg',
        'alt': {'en': 'Photo $id', 'es': 'Foto $id'},
      },
      'gallery': const [],
      'pricing': pricing,
      'availability': {'offeredWhen': offeredWhen, ...availability},
      'guestInfo': const {},
      'guestForm': guestForm,
      'transport': usageType == 'TRIP' ? {'airportCodes': airportCodes} : null,
      'preference': preference,
      'bar': bar,
      'items': items,
    };

Json itemJson(String id,
        {String? nameEn, double? price, String? category, Json? capacity}) =>
    {
      'id': id,
      'itemId': id,
      'name': {'en': nameEn ?? 'Item $id', 'es': 'Artículo $id'},
      'description': const {'en': '', 'es': ''},
      'category': category,
      'image': null,
      'priceUSD': price,
      'capacity': capacity,
      'order': 0,
    };

CatalogService service({
  required String id,
  required String section,
  String usageType = 'BOOKING',
  String offeredWhen = 'DURING_STAY',
  int order = 0,
  String? nameEn,
  List<String> airportCodes = const [],
  List<Json> items = const [],
  Json guestForm = const {},
  Json availability = const {},
  Json? preference,
}) =>
    CatalogService.fromJson(serviceJson(
      id: id,
      section: section,
      usageType: usageType,
      offeredWhen: offeredWhen,
      order: order,
      nameEn: nameEn,
      airportCodes: airportCodes,
      items: items,
      guestForm: guestForm,
      availability: availability,
      preference: preference,
    ));

Json stayJson({
  String status = 'PRE_ARRIVAL',
  String? checkIn,
  String? checkOut,
  String dietary = '',
  List<Json> larder = const [],
  List<Json> bookings = const [],
  List<Json> threads = const [],
  List<Json> feedback = const [],
  String wifiSsid = 'Casa-Ceiba',
  String wifiPass = 'sea-breeze-77',
}) =>
    {
      'status': status,
      'villaName': 'Casa Ceiba',
      'stayDatesLabel': 'Nov 3 - Nov 8',
      'nights': 5,
      'guestsCount': 2,
      if (checkIn != null) 'checkInDate': checkIn,
      if (checkOut != null) 'checkOutDate': checkOut,
      'guestProfile': {'name': 'Ana Ruiz'},
      'hostInfo': {'name': 'Lucia Perez', 'shortName': 'Lucia'},
      'villaAccess': {'wifiSsid': wifiSsid, 'wifiPasscode': wifiPass},
      'personalization': {'dietary': dietary, 'dietaryAllergies': <String>[]},
      'larderOrders': larder,
      'experienceBookings': bookings,
      'conciergeRequests': threads,
      'midstayFeedback': feedback,
    };

GuestStay stay({
  String status = 'PRE_ARRIVAL',
  String? checkIn,
  String? checkOut,
  String dietary = '',
  List<Json> larder = const [],
  List<Json> bookings = const [],
  List<Json> feedback = const [],
}) =>
    GuestStay.fromJson(
        guestUuid,
        stayJson(
          status: status,
          checkIn: checkIn,
          checkOut: checkOut,
          dietary: dietary,
          larder: larder,
          bookings: bookings,
          feedback: feedback,
        ));

Json bookingJson(String id, String serviceId,
        {String status = 'REQUESTED',
        String usageType = 'BOOKING',
        String section = 'EXPERIENCES',
        String date = '2026-11-05',
        String slot = '19:00',
        int party = 2,
        String capturedAt = '2026-11-01T10:00:00.000Z'}) =>
    {
      'bookingId': id,
      'serviceId': serviceId,
      'itemId': null,
      'section': section,
      'usageType': usageType,
      'snapshot': {
        'serviceName': {'en': 'Svc $serviceId', 'es': 'Serv $serviceId'},
        'section': section,
        'lines': const [],
        'totalUSD': 90,
        'capturedAt': capturedAt,
      },
      'title': 'Svc $serviceId',
      'scheduledDate': date,
      'scheduledTimeSlot': slot,
      'partySize': party,
      'status': status,
    };

Json tripJson(String id,
        {String type = 'ARRIVAL',
        String status = 'REQUESTED',
        String serviceId = 'trip1',
        String pickupAt = '2026-11-03T19:30:00.000Z',
        String createdAt = '2026-11-01T12:00:00.000Z'}) =>
    {
      'id': id,
      'tripId': id,
      'type': type,
      'status': status,
      'serviceId': serviceId,
      'snapshot': {
        'serviceName': {'en': 'Airport transfer', 'es': 'Traslado'},
        'section': 'TRANSPORTATION',
        'lines': const [],
        'totalUSD': 85,
      },
      'airportCode': 'CUN',
      'flight': {
        'airline': 'AA',
        'number': 'AA 1482',
        'scheduledAt': '2026-11-03T19:30:00.000Z'
      },
      'pickupAt': pickupAt,
      'passengers': 3,
      'luggage': 4,
      'createdAt': createdAt,
    };

/// A small catalog exercising every usage type (test data only).
List<Json> fullCatalog() => [
      serviceJson(
        id: 'trip1',
        section: 'TRANSPORTATION',
        usageType: 'TRIP',
        kind: 'TRANSPORT',
        offeredWhen: 'BOTH',
        nameEn: 'Airport transfer',
        airportCodes: const ['CUN'],
        availability: const {'minLeadHours': 24},
        items: [
          itemJson('suv',
              nameEn: 'SUV',
              price: 85,
              capacity: const {'passengers': 6, 'luggage': 6}),
        ],
      ),
      serviceJson(
        id: 'stock',
        section: 'IN_VILLA',
        usageType: 'ORDER',
        kind: 'VILLA_STOCKING',
        offeredWhen: 'BEFORE_ARRIVAL',
        nameEn: 'Villa stocking',
        pricing: const {'mode': 'PER_UNIT', 'amount': null},
        items: [
          itemJson('water', nameEn: 'Water', price: 4, category: 'Drinks'),
          itemJson('coffee', nameEn: 'Coffee', price: 12, category: 'Pantry'),
        ],
      ),
      serviceJson(
        id: 'bar',
        section: 'DINING',
        usageType: 'ORDER',
        kind: 'BAR',
        offeredWhen: 'DURING_STAY',
        nameEn: 'Pool bar',
        bar: const {'ageConfirmationRequired': true},
        pricing: const {'mode': 'FIXED', 'amount': null},
        items: [
          itemJson('mojito', nameEn: 'Mojito', price: 14, category: 'Cocktails')
        ],
      ),
      serviceJson(
        id: 'spa',
        section: 'WELLNESS',
        usageType: 'BOOKING',
        kind: 'WELLNESS',
        offeredWhen: 'BOTH',
        nameEn: 'Massage',
        pricing: const {'mode': 'PER_PERSON', 'amount': 120},
        guestForm: const {'time': true, 'guests': true, 'notes': true},
        availability: const {
          'minGuests': 1,
          'maxGuests': 2,
          'timeSlots': [
            {'start': '10:00', 'end': '11:00'},
            {'start': '16:00', 'end': '17:00'}
          ],
        },
      ),
      serviceJson(
        id: 'pillow',
        section: 'IN_VILLA',
        usageType: 'PREFERENCE',
        kind: 'PREFERENCE',
        offeredWhen: 'BEFORE_ARRIVAL',
        nameEn: 'Pillow menu',
        pricing: const {'mode': 'INCLUDED'},
        preference: const {'selection': 'SINGLE', 'changeDeadlineHours': 24},
        items: [
          itemJson('soft', nameEn: 'Soft'),
          itemJson('firm', nameEn: 'Firm')
        ],
      ),
    ];
