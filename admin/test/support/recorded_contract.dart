/// JSON shapes of the real backend contract (`backend/`, commit 94d8838),
/// recorded from `http://localhost:3011/api/v1/admin` against the emulators.
/// Adapter tests answer with these bodies so a contract drift fails here.
library;

const _meta = {'timestamp': '2026-11-03T04:09:05.094Z', 'requestId': 'req_1'};

/// `GET /admin/settings` on an empty database: nothing is configured.
const Map<String, dynamic> recordedEmptySettings = {
  'success': true,
  'data': {
    'checkInTime': null,
    'checkOutTime': null,
    'timeZone': null,
    'airports': [],
    'transportAlertLeadHours': null,
    'updatedAt': null,
    'updatedBy': null,
  },
  'meta': _meta,
};

/// `PATCH /admin/settings` answer after configuring every value.
const Map<String, dynamic> recordedConfiguredSettings = {
  'success': true,
  'data': {
    'checkInTime': '15:00',
    'checkOutTime': '11:00',
    'timeZone': 'America/Cancun',
    'airports': [
      {
        'code': 'CUN',
        'name': 'Cancun International',
        'departureBufferHours': 3,
        'isActive': true,
      },
      {
        'code': 'TQO',
        'name': 'Tulum',
        'departureBufferHours': 2.5,
        'isActive': false,
      },
    ],
    'transportAlertLeadHours': 24,
    'updatedAt': '2026-11-03T05:00:00.000Z',
    'updatedBy': 'admin@kachava.local',
  },
  'meta': _meta,
};

/// One villa as returned by `GET/POST/PATCH /admin/villas[/:id]`.
const Map<String, dynamic> recordedVilla = {
  'id': '3f1c2a9e-0000-4000-8000-000000000001',
  'villaId': '3f1c2a9e-0000-4000-8000-000000000001',
  'name': 'Casa Ceiba',
  'category': 'Ocean view',
  'capacity': 4,
  'wifi': {'ssid': 'Ceiba-Guest', 'password': 's3cret-pass'},
  'operationalStatus': 'AVAILABLE',
  'housekeepingStatus': 'CLEAN',
  'maintenanceStatus': 'OK',
  'maintenanceNote': '',
  'isActive': true,
  'createdAt': '2026-11-03T05:00:00.000Z',
  'createdBy': 'admin@kachava.local',
  'updatedAt': '2026-11-03T05:00:00.000Z',
  'updatedBy': 'admin@kachava.local',
  'currentGuestName': null,
};

Map<String, dynamic> recordedRecord(Map<String, dynamic> data) =>
    {'success': true, 'data': data, 'meta': _meta};

Map<String, dynamic> recordedPage(List<Map<String, dynamic>> data,
        {int page = 1, int pageSize = 25, int? total}) =>
    {
      'success': true,
      'data': data,
      'meta': {
        'page': page,
        'pageSize': pageSize,
        'total': total ?? data.length,
        ..._meta,
      },
    };

/// `DELETE /admin/villas/:id` for a villa referenced by stays.
const Map<String, dynamic> recordedVillaHasStays = {
  'success': false,
  'statusCode': 409,
  'error': 'Conflict',
  'message': 'Villa has stays; deactivate it instead of deleting it.',
  'path': '/api/v1/admin/villas/v1',
  'meta': _meta,
};

/// `DELETE /admin/villas/:id` when deleting is allowed.
const Map<String, dynamic> recordedVillaDeleted = {
  'success': true,
  'data': {'deleted': true, 'id': 'v1'},
  'meta': _meta,
};

/// `POST /admin/uploads/sign` on the local Storage emulator (POST upload).
const Map<String, dynamic> recordedUploadSign = {
  'success': true,
  'data': {
    'uploadUrl': 'http://127.0.0.1:9199/upload/storage/v1/b/demo-kachava'
        '.appspot.com/o?uploadType=media&name=catalog%2Fservices%2Fa.png',
    'method': 'POST',
    'headers': {'Content-Type': 'image/png'},
    'expiresAt': '2026-11-03T04:24:47.488Z',
    'storagePath': 'catalog/services/a.png',
    'publicUrl': 'http://127.0.0.1:9199/v0/b/demo-kachava.appspot.com/o/'
        'catalog%2Fservices%2Fa.png?alt=media',
    'maxBytes': 5242880,
  },
  'meta': _meta,
};

/// One catalog service (`AdminServiceView`) of kind BAR.
const Map<String, dynamic> recordedService = {
  'id': 'svc-1',
  'serviceId': 'svc-1',
  'kind': 'BAR',
  'section': 'DINING',
  'category': 'Drinks',
  'usageType': 'ORDER',
  'name': {'en': 'Lux bar', 'es': 'Lux bar'},
  'shortDescription': {'en': 'Cocktails', 'es': 'Cocteles'},
  'description': {'en': '', 'es': ''},
  'tags': ['bar'],
  'order': 2,
  'featured': false,
  'cover': {
    'storagePath': 'catalog/services/cover.jpg',
    'alt': {'en': 'Bar', 'es': 'Bar'},
    'usageRightsConfirmed': true,
    'url': 'http://127.0.0.1:9199/v0/b/x/o/catalog%2Fservices%2Fcover.jpg',
  },
  'gallery': [],
  'pricing': {
    'mode': 'PER_UNIT',
    'amount': null,
    'currency': 'USD',
    'chargeToFolio': true,
    'note': {'en': '', 'es': ''},
  },
  'availability': {
    'weekdays': ['MON', 'FRI'],
    'timeSlots': [
      {'start': '17:00', 'end': '22:00'}
    ],
    'blockedDates': ['2026-12-24'],
    'minLeadHours': 2,
    'cancellationHours': null,
    'minGuests': null,
    'maxGuests': null,
    'durationMinutes': null,
    'offeredWhen': 'DURING_STAY',
  },
  'guestInfo': {
    'includes': {'en': '', 'es': ''},
    'excludes': {'en': '', 'es': ''},
    'whatToBring': {'en': '', 'es': ''},
    'location': {'en': 'Pool deck', 'es': 'Terraza'},
    'restrictions': {'en': '', 'es': ''},
    'cancellationPolicy': {'en': '', 'es': ''},
  },
  'guestForm': {
    'date': true,
    'time': true,
    'guests': false,
    'notes': true,
    'dietary': false,
    'health': false,
  },
  'operation': {
    'providerId': null,
    'responsibleDepartment': 'CULINARY',
    'responsibleStaffId': null,
    'requiresConfirmation': true,
    'internalInstructions': 'Check ID',
  },
  'bar': {'ageConfirmationRequired': true},
  'dining': null,
  'stocking': null,
  'experience': null,
  'wellness': null,
  'preference': null,
  'transport': null,
  'status': 'ACTIVE',
  'createdAt': '2026-11-03T05:00:00.000Z',
  'createdBy': 'admin@kachava.local',
  'updatedAt': '2026-11-03T05:00:00.000Z',
  'updatedBy': 'admin@kachava.local',
};

/// One service item (`AdminItemView`) with flat item fields.
const Map<String, dynamic> recordedItem = {
  'id': 'item-1',
  'itemId': 'item-1',
  'serviceId': 'svc-1',
  'name': {'en': 'Mezcal', 'es': 'Mezcal'},
  'description': {'en': '', 'es': ''},
  'category': 'Spirits',
  'image': null,
  'priceUSD': 12.5,
  'tags': [],
  'dietaryTags': ['vegan'],
  'allergens': [],
  'origin': 'Oaxaca',
  'unit': 'glass',
  'storage': null,
  'capacity': null,
  'order': 0,
  'status': 'ACTIVE',
  'createdAt': '2026-11-03T05:00:00.000Z',
  'createdBy': 'admin@kachava.local',
  'updatedAt': '2026-11-03T05:00:00.000Z',
  'updatedBy': 'admin@kachava.local',
};
