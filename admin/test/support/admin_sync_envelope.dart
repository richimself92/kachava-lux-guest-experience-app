import 'dart:convert';

import 'package:http/http.dart' as http;

/// Builds a `GET /api/v1/admin/sync` response envelope for fakes.
Map<String, dynamic> adminSyncEnvelope({
  Object stays = const <Object>[],
  Object alerts = const <Object>[],
  Object bookings = const <Object>[],
  Object larderOrders = const <Object>[],
  Object conciergeRequests = const <Object>[],
  Object midstayFeedback = const <Object>[],
  Object experiences = const <Object>[],
  Object larder = const <Object>[],
}) =>
    {
      'success': true,
      'data': {
        'stays': stays,
        'alerts': alerts,
        'bookings': bookings,
        'larderOrders': larderOrders,
        'conciergeRequests': conciergeRequests,
        'midstayFeedback': midstayFeedback,
        'experiences': experiences,
        'larder': larder,
      },
    };

http.Response jsonResponse(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);

bool isSyncRequest(http.Request request) =>
    request.method == 'GET' && request.url.path.endsWith('/admin/sync');

/// Minimal live stay wire payload as returned by `GET /admin/stays`.
Map<String, dynamic> liveStayWire({
  String stayId = 'stay_live_101',
  String guestTokenUuid = '11111111-2222-3333-4444-555555555555',
  String villaName = 'Villa 101',
  String guestName = 'Sofia & Lucas Vega',
}) =>
    {
      'stayId': stayId,
      'guestTokenUuid': guestTokenUuid,
      'villaId': 'villa-101',
      'villaName': villaName,
      'status': 'PRE_ARRIVAL',
      'guestProfile': {'name': guestName},
      'folioItems': [
        {
          'folioItemId': 'fi_1',
          'title': 'Private Cenote Excursion',
          'category': 'EXCURSION',
          'isComplimentary': false,
          'chargedAmountUSD': 640.0,
        },
      ],
    };
