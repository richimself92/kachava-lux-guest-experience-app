import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_guest_portal/application/portal_controller.dart';
import 'package:kachava_guest_portal/core/storage/device_prefs.dart';
import 'package:kachava_guest_portal/domain/json_read.dart';
import 'package:kachava_guest_portal/domain/realtime_channels.dart';

import 'support/fake_guest_api.dart';
import 'support/fake_realtime_port.dart';
import 'support/fixtures.dart';

const _debounce = Duration(milliseconds: 250);

Json _stay(String channel) => {
      ...stayJson(),
      'realtime': {'channel': channel, 'global': 'global'},
    };

class _Rig {
  _Rig({Json? stay})
      : api = FakeGuestApi(stay: stay ?? _stay('ch-1')),
        port = FakeRealtimePort(),
        visibility = FakeVisibility();
  final FakeGuestApi api;
  final FakeRealtimePort port;
  final FakeVisibility visibility;
  late final PortalController c = PortalController(
    api: api,
    prefs: MemoryDevicePrefs(),
    initialUri: portalUri(),
    realtime: port,
    onPageVisible: visibility.onVisible,
    realtimeRetry: const Duration(seconds: 5),
  );

  /// Starts and connects; returns the fetch count after the first load.
  Future<int> start(WidgetTester tester) async {
    await c.start();
    await tester.pump();
    port.connect();
    await tester.pump(const Duration(seconds: 1));
    return api.stayFetches;
  }
}

void main() {
  testWidgets('listens to the channel and global docs of the stay',
      (tester) async {
    final r = _Rig();
    await r.start(tester);
    expect(r.port.watched, [const RealtimeChannels('ch-1', 'global')]);
    expect(r.api.stayFetches, 1, reason: 'first snapshot is not a change');
    r.c.dispose();
    expect(r.port.cancels, 1, reason: 'listeners closed on dispose');
  });

  testWidgets('a stay without realtime ids disables realtime', (tester) async {
    final r = _Rig(stay: stayJson());
    await r.c.start();
    await tester.pump();
    expect(r.port.watched, isEmpty);
    r.c.dispose();
  });

  testWidgets('no periodic polling at all', (tester) async {
    final r = _Rig();
    final base = await r.start(tester);
    await tester.pump(const Duration(hours: 2));
    expect(r.api.stayFetches, base);
    r.c.dispose();
  });

  testWidgets('a change triggers exactly one refresh after the debounce',
      (tester) async {
    final r = _Rig();
    final base = await r.start(tester);
    r.port.change();
    await tester.pump(const Duration(milliseconds: 200));
    expect(r.api.stayFetches, base, reason: 'still debouncing');
    await tester.pump(const Duration(milliseconds: 60));
    expect(r.api.stayFetches, base + 1);
    await tester.pump(const Duration(seconds: 1));
    expect(r.api.stayFetches, base + 1);
    r.c.dispose();
  });

  testWidgets('a burst of changes causes a single refresh', (tester) async {
    final r = _Rig();
    final base = await r.start(tester);
    for (var i = 0; i < 5; i++) {
      r.port.change();
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(_debounce);
    await tester.pump(const Duration(seconds: 1));
    expect(r.api.stayFetches, base + 1);
    r.c.dispose();
  });

  testWidgets('a change during an in-flight refresh queues one follow-up',
      (tester) async {
    final r = _Rig();
    final base = await r.start(tester);
    r.api.stayGate = Completer<void>();
    unawaited(r.c.refresh());
    await tester.pump();
    r.port.change();
    await tester.pump(_debounce);
    r.port.change();
    await tester.pump(_debounce);
    expect(r.api.stayFetches, base + 1, reason: 'no overlap');
    final gate = r.api.stayGate!;
    r.api.stayGate = null;
    gate.complete();
    await tester.pump(const Duration(seconds: 1));
    expect(r.api.stayFetches, base + 2, reason: 'exactly one follow-up');
    r.c.dispose();
  });

  testWidgets('a rotated channel id re-subscribes', (tester) async {
    final r = _Rig();
    await r.start(tester);
    r.api.stayJsonValue = _stay('ch-2');
    await r.c.refresh();
    await tester.pump();
    expect(r.port.watched.last, const RealtimeChannels('ch-2', 'global'));
    expect(r.port.cancels, 1, reason: 'old listener closed');
    r.c.dispose();
  });

  testWidgets('a failed listener re-subscribes and refreshes once',
      (tester) async {
    final r = _Rig();
    final base = await r.start(tester);
    r.port.fail();
    await tester.pump(const Duration(seconds: 5));
    expect(r.port.watched, hasLength(2));
    r.port.connect();
    await tester.pump(const Duration(seconds: 1));
    expect(r.api.stayFetches, base + 1);
    r.c.dispose();
  });

  testWidgets('the tab becoming visible again refreshes', (tester) async {
    final r = _Rig();
    final base = await r.start(tester);
    r.visibility.show();
    await tester.pump(const Duration(seconds: 1));
    expect(r.api.stayFetches, base + 1);
    r.c.dispose();
  });

  testWidgets('manual refresh exposes a busy state', (tester) async {
    final r = _Rig();
    final base = await r.start(tester);
    r.api.stayGate = Completer<void>();
    final done = r.c.refreshNow();
    expect(r.c.isRefreshing, isTrue);
    r.api.stayGate!.complete();
    await done;
    expect(r.c.isRefreshing, isFalse);
    expect(r.api.stayFetches, base + 1);
    r.c.dispose();
  });
}
