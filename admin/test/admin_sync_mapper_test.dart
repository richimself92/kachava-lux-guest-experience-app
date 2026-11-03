import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kachava_admin_dashboard/data/admin_api_client.dart';
import 'package:kachava_admin_dashboard/data/admin_sync_mapper.dart';
import 'package:kachava_admin_dashboard/data/api_admin_operations_repository.dart';

import 'support/admin_sync_envelope.dart';
import 'support/signed_in_api_client.dart';

Map<String, dynamic> _fullEnvelope() => adminSyncEnvelope(
      stays: [liveStayWire()],
      alerts: {
        'alerts': [
          {'alertId': 'alt_1', 'stayId': 'stay_live_101', 'title': 'Chat'}
        ],
        'unreadCount': 1,
      },
      bookings: [
        {
          'bookingId': 'bk_1',
          'stayId': 'stay_live_101',
          'bookingType': 'YACHT_CHARTER',
          'title': 'Sunset Cruise',
          'status': 'CONFIRMED',
        }
      ],
      larderOrders: [
        {
          'orderItemId': 'larder-1',
          'stayId': 'stay_live_101',
          'name': 'Mezcal',
          'quantity': 1,
          'provisioningStatus': 'Pending',
        }
      ],
      conciergeRequests: [
        {'requestId': 'req_1', 'stayId': 'stay_live_101', 'title': 'Pillows'}
      ],
      midstayFeedback: [
        {'feedbackId': 'fb_1', 'stayId': 'stay_live_101', 'status': 'NEW'}
      ],
    );

/// `GET /admin/sync` recorded from the live backend with an empty database.
const Map<String, dynamic> _recordedEmptySync = {
  'success': true,
  'data': {
    'stays': [],
    'alerts': {'alerts': [], 'unreadCount': 0},
    'bookings': [],
    'larderOrders': [],
    'conciergeRequests': [],
    'midstayFeedback': [],
  },
  'meta': {
    'timestamp': '2026-11-03T04:09:05.163Z',
    'requestId': 'req_28aaa14a'
  },
};

void main() {
  group('AdminSyncMapper', () {
    test('test_sync_mapper_parses_the_recorded_empty_backend_sync', () {
      final snapshot = AdminSyncMapper.parse(_recordedEmptySync);
      expect(snapshot.stays, isEmpty);
      expect(snapshot.alerts, isEmpty);
      expect(snapshot.bookings, isEmpty);
      expect(snapshot.larderOrders, isEmpty);
      expect(snapshot.conciergeTickets, isEmpty);
      expect(snapshot.midStayPulses, isEmpty);
    });

    test('test_sync_mapper_maps_all_six_keys_with_existing_wire_mappers', () {
      final snapshot = AdminSyncMapper.parse(_fullEnvelope());

      expect(snapshot.stays.single.stayId, 'stay_live_101');
      expect(snapshot.stays.single.guestTokenUuid,
          '11111111-2222-3333-4444-555555555555');
      expect(snapshot.folioItems.single.amountUsd, 640.0);
      expect(snapshot.alerts.single.alertId, 'alt_1');
      expect(snapshot.bookings.single.bookingId, 'bk_1');
      expect(snapshot.bookings.single.guestNames, 'Sofia & Lucas Vega');
      expect(snapshot.larderOrders.single.stayId, 'stay_live_101');
      expect(snapshot.conciergeTickets.single.requestId, 'req_1');
      expect(snapshot.midStayPulses.single.checkInId, 'fb_1');
    });

    test('test_sync_mapper_missing_key_throws_format_exception', () {
      final envelope = _fullEnvelope();
      (envelope['data'] as Map).remove('midstayFeedback');

      expect(() => AdminSyncMapper.parse(envelope),
          throwsA(isA<FormatException>()));
    });
  });

  group('ApiAdminOperationsRepository.fetchSnapshot', () {
    test('test_fetch_snapshot_issues_single_get_admin_sync', () async {
      final requested = <String>[];
      final repo = ApiAdminOperationsRepository(
          apiClient: signedInApiClient(MockClient((request) async {
        requested.add('${request.method} ${request.url.path}');
        return jsonResponse(_fullEnvelope());
      })));

      final snapshot = await repo.fetchSnapshot();

      expect(requested, ['GET /api/v1/admin/sync']);
      expect(snapshot.stays.single.stayId, 'stay_live_101');
      repo.dispose();
    });

    test('test_fetch_snapshot_server_error_propagates_without_seeded_data',
        () async {
      final repo = ApiAdminOperationsRepository(
          apiClient: signedInApiClient(
              MockClient((_) async => http.Response('down', 503))));

      await expectLater(
          repo.fetchSnapshot(), throwsA(isA<AdminApiException>()));
      await expectLater(repo.fetchStays(), throwsA(isA<AdminApiException>()));
      repo.dispose();
    });
  });
}
