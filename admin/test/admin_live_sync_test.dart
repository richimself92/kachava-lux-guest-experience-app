import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kachava_admin_dashboard/application/admin_live_sync.dart';

/// Records calls and lets the test decide when each request completes.
class _FakeServer {
  int initialLoads = 0;
  int refreshes = 0;
  Completer<void>? pending;
  bool fail = false;

  Future<void> initialLoad() {
    initialLoads++;
    return fail
        ? Future.error(http.ClientException('offline'))
        : Future.value();
  }

  Future<void> refresh() {
    refreshes++;
    if (fail) return Future.error(http.ClientException('offline'));
    return (pending = Completer<void>()).future;
  }
}

void main() {
  test('test_live_sync_default_interval_is_five_seconds', () {
    expect(AdminLiveSync.defaultInterval, const Duration(seconds: 5));
  });

  test('test_live_sync_first_tick_loads_then_ticks_refresh', () async {
    final server = _FakeServer();
    final sync =
        AdminLiveSync(initialLoad: server.initialLoad, refresh: server.refresh);

    await sync.tick();
    final second = sync.tick();
    server.pending!.complete();
    await second;

    expect(server.initialLoads, 1);
    expect(server.refreshes, 1);
    sync.dispose();
  });

  test('test_live_sync_tick_while_in_flight_is_skipped', () async {
    final server = _FakeServer();
    final sync =
        AdminLiveSync(initialLoad: server.initialLoad, refresh: server.refresh);
    await sync.tick();

    final inFlight = sync.tick();
    await sync.tick();
    await sync.tick();
    server.pending!.complete();
    await inFlight;

    expect(server.refreshes, 1);
    sync.dispose();
  });

  test('test_live_sync_failure_sets_reconnecting_and_success_clears_it',
      () async {
    final server = _FakeServer()..fail = true;
    final sync =
        AdminLiveSync(initialLoad: server.initialLoad, refresh: server.refresh);

    await sync.tick();
    expect(sync.status.value, AdminSyncStatus.reconnecting);

    server.fail = false;
    await sync.tick();
    expect(sync.status.value, AdminSyncStatus.live);
    expect(server.initialLoads, 2, reason: 'initial load retried');
    sync.dispose();
  });

  testWidgets('test_live_sync_polls_every_5s_and_never_overlaps',
      (tester) async {
    final server = _FakeServer();
    final sync =
        AdminLiveSync(initialLoad: server.initialLoad, refresh: server.refresh);
    await sync.tick();
    sync.startPolling();

    await tester.pump(const Duration(seconds: 4));
    expect(server.refreshes, 0);
    await tester.pump(const Duration(seconds: 1));
    expect(server.refreshes, 1);
    await tester.pump(const Duration(seconds: 15));
    expect(server.refreshes, 1, reason: 'request still in flight');

    server.pending!.complete();
    await tester.pump(const Duration(seconds: 5));
    expect(server.refreshes, 2);
    server.pending!.complete();
    sync.dispose();
  });
}
