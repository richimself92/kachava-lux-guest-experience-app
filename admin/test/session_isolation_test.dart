import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:kachava_admin_dashboard/application/admin_live_sync.dart';
import 'package:kachava_admin_dashboard/data/admin_api_client.dart';
import 'package:kachava_admin_dashboard/data/admin_cached_records.dart';
import 'package:kachava_admin_dashboard/data/api_admin_operations_repository.dart';

import 'support/admin_sync_envelope.dart';
import 'support/signed_in_api_client.dart';

void main() {
  group('AdminLiveSync.reset', () {
    test('test_liveSync_reset_nextTickRunsInitialLoadAndStatusLive', () async {
      var initialLoads = 0;
      final sync = AdminLiveSync(
          initialLoad: () async {
            initialLoads++;
            if (initialLoads == 1) return;
            throw const AdminForbiddenException('403');
          },
          refresh: () async {});
      await sync.tick();
      await sync.tick();
      expect(initialLoads, 1);

      sync.reset();
      expect(sync.status.value, AdminSyncStatus.live);
      await sync.tick();

      expect(initialLoads, 2);
      expect(sync.status.value, AdminSyncStatus.noAccess);
      sync.dispose();
    });

    test('test_liveSync_tickInFlightDuringReset_isDiscarded', () async {
      final gate = Completer<void>();
      var initialLoads = 0;
      final sync = AdminLiveSync(
          initialLoad: () {
            initialLoads++;
            return initialLoads == 1 ? gate.future : Future.value();
          },
          refresh: () async => throw StateError('must not refresh'));
      sync.startPolling();
      final stale = sync.tick();

      sync.reset();
      final fresh = sync.tick();
      gate.completeError(const AdminForbiddenException('403'));
      await Future.wait([stale, fresh]);

      expect(initialLoads, 2);
      expect(sync.status.value, AdminSyncStatus.live);
      expect(sync.isPolling, isTrue);
      sync.dispose();
    });
  });

  group('Repository cache clearing', () {
    test('test_apiRepository_clearCache_dropsRecordsAndSendsNoMutation',
        () async {
      final requests = <String>[];
      final repo = ApiAdminOperationsRepository(
          apiClient: signedInApiClient(MockClient((request) async {
        requests.add('${request.method} ${request.url.path}');
        return jsonResponse(adminSyncEnvelope(stays: [liveStayWire()]));
      })));
      await repo.fetchSnapshot();

      repo.clearCache();

      await expectLater(repo.regenerateGuestUuid('stay_live_101'),
          throwsA(isA<AdminRecordNotLoadedException>()));
      expect(requests, ['GET /api/v1/admin/sync']);
    });
  });
}
