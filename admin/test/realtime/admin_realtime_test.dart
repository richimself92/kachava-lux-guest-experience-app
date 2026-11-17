import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/application/admin_live_sync.dart';
import 'package:kachava_admin_dashboard/application/admin_realtime.dart';
import 'package:kachava_admin_dashboard/core/realtime_events_port.dart';
import 'package:kachava_admin_dashboard/data/admin_api_client.dart';
import 'package:kachava_admin_dashboard/domain/realtime_change.dart';

import '../support/fake_realtime_port.dart';

void main() {
  late FakeRealtimePort port;
  late List<bool> renewals;
  late int ticks;
  late AdminLiveSync sync;

  AdminRealtime build({Object? loginError, String? channel = 'admin-1'}) {
    final realtime = AdminRealtime(
      port: port,
      channel: ({bool renew = false}) async {
        renewals.add(renew);
        if (loginError != null) throw loginError;
        return channel;
      },
      liveSync: sync,
    );
    addTearDown(realtime.dispose);
    return realtime;
  }

  setUp(() {
    port = FakeRealtimePort();
    renewals = [];
    ticks = 0;
    sync = AdminLiveSync(
        initialLoad: () async => ticks++, refresh: () async => ticks++);
  });
  tearDown(() {
    sync.dispose();
    port.dispose();
  });

  test('reads a signal and ignores malformed data', () {
    final change = RealtimeChange.fromMap(
        {'scope': 'stay', 'stayId': 's1', 'topic': 'messages', 'at': 'x'});
    expect(change?.topic, 'messages');
    expect(change?.stayId, 's1');
    expect(RealtimeChange.tryParse('not json'), isNull);
    expect(RealtimeChange.fromMap({'scope': 'global'}), isNull);
  });

  testWidgets('listens to the admin channel on start', (tester) async {
    await build().start();
    expect(port.connects, ['admin-1']);
    expect(renewals, [false]);
  });

  testWidgets('no channel: real time stays off without retries',
      (tester) async {
    await build(channel: null).start();
    await tester.pump(AdminRealtime.maxRetryDelay * 2);
    expect(port.connects, isEmpty);
    expect(renewals, [false]);
  });

  testWidgets('debounces 250 ms, batches topics and ticks the bell',
      (tester) async {
    final realtime = build();
    final batches = <Set<String>>[];
    realtime.invalidations.listen((i) => batches.add(i.topics));
    await realtime.start();

    port.emit('messages', stayId: 's1');
    await tester.pump(const Duration(milliseconds: 100));
    port.emit('trips');
    await tester.pump(const Duration(milliseconds: 249));
    expect(batches, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(batches, [
      {'messages', 'trips'}
    ]);
    expect(ticks, 1);
  });

  testWidgets('no periodic polling: nothing ticks without a signal',
      (tester) async {
    final realtime = build();
    await realtime.start();
    port.setConnection(RealtimeConnection.open);
    await tester.pump(const Duration(minutes: 10));
    expect(ticks, 0);
  });

  testWidgets('back online after a drop refreshes everything', (tester) async {
    final realtime = build();
    final batches = <RealtimeInvalidation>[];
    realtime.invalidations.listen(batches.add);
    await realtime.start();
    port.setConnection(RealtimeConnection.open);
    await tester.pump();
    expect(batches, isEmpty, reason: 'the first sync is not a catch-up');

    port.setConnection(RealtimeConnection.connecting);
    expect(realtime.connected.value, isFalse);
    port.setConnection(RealtimeConnection.open);
    await tester.pump();
    expect(realtime.connected.value, isTrue);
    expect(batches.single.isEverything, isTrue);
    expect(ticks, 1);
  });

  testWidgets('refreshAll publishes everything and awaits the bell',
      (tester) async {
    final realtime = build();
    final batches = <RealtimeInvalidation>[];
    realtime.invalidations.listen(batches.add);
    port.emit('trips');
    await realtime.refreshAll();
    await tester.pump(const Duration(milliseconds: 300));
    expect(batches.single.isEverything, isTrue);
    expect(batches.single.touches({'anything'}), isTrue);
    expect(ticks, 1);
  });

  testWidgets('a listener failure renews the session and reconnects',
      (tester) async {
    final realtime = build();
    await realtime.start();
    port.setConnection(RealtimeConnection.open);
    port.setConnection(RealtimeConnection.closed);
    await tester.pump(AdminRealtime.retryDelay);
    expect(renewals, [false, true]);
    expect(port.connects, hasLength(2));
  });

  testWidgets('a rejected login stops reconnecting', (tester) async {
    final realtime =
        build(loginError: const AdminLoginRejectedException('HTTP 401'));
    await realtime.start();
    await tester.pump(AdminRealtime.maxRetryDelay * 2);
    expect(renewals, [false]);
    expect(port.connects, isEmpty);
  });
}
