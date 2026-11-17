/// Response shapes recorded from the backend modules of ADR-011
/// (`backend/src/modules/{dashboard,reservations,tasks,notifications,
/// conversations}`), wrapped by `ResponseTransformInterceptor`.
library;

Map<String, dynamic> _meta() =>
    {'timestamp': '2026-11-03T15:00:00.000Z', 'requestId': 'req_abcd1234'};

Map<String, dynamic> wrapped(Object data) =>
    {'success': true, 'data': data, 'meta': _meta()};

Map<String, dynamic> paged(List<Map<String, dynamic>> data,
        {int total = 1, Map<String, int> extra = const {}}) =>
    {
      'success': true,
      'data': data,
      'meta': {'page': 1, 'pageSize': 25, 'total': total, ...extra, ..._meta()},
    };

const Map<String, dynamic> recordedDashboard = {
  'resortDate': '2026-11-03',
  'kpis': {
    'occupiedVillas': 5,
    'availableVillas': 3,
    'occupancyPct': 63,
    'arrivals': 2,
    'departures': 1,
    'openRequests': 4,
  },
  'activity': {
    'rows': [
      {
        'stayId': 'stay_a',
        'guestName': 'Ana Ruiz',
        'villaId': 'v1',
        'villaName': 'Casa Ceiba',
        'status': 'IN_HOUSE',
        'overdue': true,
      },
      {
        'stayId': 'stay_b',
        'guestName': 'Bruno Diaz',
        'villaId': 'v2',
        'villaName': 'Casa Jade',
        'status': 'ARRIVAL',
        'overdue': false,
      },
    ],
    'total': 9,
  },
};

const Map<String, dynamic> recordedReservationRow = {
  'id': 'stay_a',
  'guestName': 'Ana Ruiz',
  'villaId': 'v1',
  'villaName': 'Casa Ceiba',
  'checkIn': '2026-11-03',
  'checkOut': '2026-11-07',
  'status': 'PRE_ARRIVAL',
  'resortHostName': null,
  'magicLinkUrl': 'http://localhost:3000/?guestId=uuid-1',
};

const Map<String, dynamic> recordedStayDetail = {
  ...recordedReservationRow,
  'nights': 4,
  'guestsCount': 2,
  'partnerName': '',
  'email': 'ana@example.com',
  'phone': '',
  'language': 'es',
  'occasion': 'Anniversary',
  'resortHost': {'staffId': 'stf_1', 'name': 'Lucia Host'},
  'wifi': {'ssid': 'Ceiba', 'password': 'pw-1'},
  'internalNotes': 'VIP',
  'cancellationReason': null,
  'statusHistory': [
    {
      'from': 'PRE_ARRIVAL',
      'to': 'ACTIVE_STAY',
      'at': '2026-11-03T15:00:00.000Z',
      'by': 'admin@kachava.local',
      'reason': null,
    }
  ],
  'createdAt': '2026-11-01T10:00:00.000Z',
  'updatedAt': '2026-11-03T15:00:00.000Z',
};

const Map<String, dynamic> recordedFolio = {
  'stay': {'id': 'stay_a', 'guestName': 'Ana Ruiz', 'nights': 4},
  'services': [
    {
      'type': 'TRIP',
      'id': 'trip_1',
      'serviceId': 'svc_t',
      'name': {'en': 'Airport transfer', 'es': 'Traslado'},
      'status': 'CONFIRMED',
      'date': '2026-11-03T18:00:00.000Z',
      'totalUSD': 90,
      'chargeToFolio': true,
      'lines': [],
      'snapshot': null,
    },
    {
      'type': 'BOOKING',
      'id': 'bk_1',
      'serviceId': 'svc_e',
      'name': {'en': 'Cenote tour', 'es': 'Tour cenote'},
      'status': 'Requested',
      'date': '2026-11-04',
      'totalUSD': 120.5,
      'chargeToFolio': true,
      'lines': [],
      'snapshot': null,
    },
  ],
  'rating': {
    'rating': 5,
    'sentiment': 'PERFECT',
    'note': 'Lovely',
    'createdAt': '2026-11-04T10:00:00.000Z'
  },
  'charges': {
    'items': [
      {
        'folioItemId': 'fi_1',
        'displayOrder': 1,
        'title': 'Cenote tour',
        'subtitle': '',
        'category': 'EXCURSION',
        'badgeLabel': null,
        'isComplimentary': false,
        'originalValuationUSD': null,
        'chargedAmountUSD': 120.5,
        'status': 'PRE_AUTHORIZED',
        'sourceRefId': 'bk_1',
        'createdAt': '2026-11-03T15:00:00.000Z',
      }
    ],
    'summary': {'finalSettledTotalUSD': 1234.5},
    'totalUSD': 1234.5,
  },
  'pmsIntegrated': false,
};

const Map<String, dynamic> recordedGuestProfile = {
  'stayId': 'stay_a',
  'guestName': 'Ana Ruiz',
  'villaId': 'v1',
  'villaName': 'Casa Ceiba',
  'checkIn': '2026-11-03',
  'checkOut': '2026-11-07',
  'status': 'ACTIVE_STAY',
  'language': 'es',
  'hasAllergies': true,
  'openRequests': 2,
  'partnerName': '',
  'email': 'ana@example.com',
  'phone': '',
  'preferences': {
    'pillow': 'Goose down',
    'scent': '',
    'dietary': 'Vegetarian',
    'temperature': '',
    'lighting': '',
    'housekeeping': '',
    'interests': ['Snorkel'],
    'communication': '',
    'choices': [
      {
        'bookingId': 'b9',
        'serviceId': 's9',
        'title': 'Lavender',
        'status': 'Requested'
      }
    ],
  },
  'allergies': {
    'hasAllergies': true,
    'items': ['Shellfish'],
    'label': 'Shellfish'
  },
  'occasion': {'celebration': 'Anniversary', 'details': ''},
  'requestHistory': [
    {
      'type': 'TRIP',
      'id': 'trip_1',
      'title': 'ARRIVAL trip',
      'status': 'CONFIRMED',
      'open': true,
      'createdAt': '2026-11-02T10:00:00.000Z'
    }
  ],
  'internalNotes': 'VIP',
};

const Map<String, dynamic> recordedTask = {
  'id': 'task_1',
  'taskId': 'task_1',
  'title': 'Turn-down service',
  'source': {'type': 'MANUAL', 'refId': null, 'stayId': 'stay_a'},
  'villaId': 'v1',
  'villaName': 'Casa Ceiba',
  'guestName': 'Ana Ruiz',
  'category': 'Housekeeping',
  'ownerStaffId': null,
  'ownerName': null,
  'priority': 'HIGH',
  'dueAt': '2026-11-03T23:00:00.000Z',
  'status': 'PENDING',
  'completion': null,
  'cancellationReason': null,
  'statusHistory': [],
  'createdAt': '2026-11-03T15:00:00.000Z',
  'createdBy': 'admin',
  'updatedAt': '2026-11-03T15:00:00.000Z',
  'updatedBy': 'admin',
  'overdue': true,
};

const Map<String, dynamic> recordedNotification = {
  'id': 'alert_1',
  'event': 'GUEST_MESSAGE',
  'level': 'ACTION',
  'category': 'CONCIERGE',
  'title': 'New message',
  'summary': 'Can we get extra towels?',
  'stayId': 'stay_a',
  'villaId': 'v1',
  'villaName': 'Casa Ceiba',
  'guestName': 'Ana Ruiz',
  'createdAt': '2026-11-03T15:00:00.000Z',
  'read': false,
  'readAt': null,
  'playSound': false,
  'targetRef': {'type': 'CONVERSATION', 'id': 'stay_a', 'stayId': 'stay_a'},
};

const Map<String, dynamic> recordedConversationRow = {
  'stayId': 'stay_a',
  'guestName': 'Ana Ruiz',
  'villaName': 'Casa Ceiba',
  'lastMessage': {
    'text': 'Can we get extra towels?',
    'at': '2026-11-03T15:00:00.000Z',
    'from': 'GUEST',
    'hasPhoto': true,
  },
  'unreadCount': 2,
  'awaitingReply': true,
};

const Map<String, dynamic> recordedMessage = {
  'id': 'req_1:0',
  'requestId': 'req_1',
  'from': 'GUEST',
  'senderName': 'Ana Ruiz',
  'text': 'Can we get extra towels?',
  'at': '2026-11-03T15:00:00.000Z',
  'photoUrl': 'https://storage.test/signed/photo.jpg',
};
