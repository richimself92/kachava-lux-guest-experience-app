import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_guest_portal/core/realtime/realtime_events_port.dart';
import 'package:kachava_guest_portal/domain/realtime_channels.dart';

void main() {
  test('first snapshots connect once; later ones are changes', () async {
    final a = StreamController<Object?>(), b = StreamController<Object?>();
    final got = <RealtimeSignal>[];
    final sub = signalsFromSnapshots([a.stream, b.stream]).listen(got.add);
    a.add(1);
    b.add(1);
    b.add(2);
    a.add(2);
    await pumpEventQueue();
    expect(got.map((s) => s.runtimeType), [
      RealtimeConnected,
      RealtimeChange,
      RealtimeChange,
    ]);
    await sub.cancel();
    expect(a.hasListener || b.hasListener, isFalse);
  });

  test('a listener error reports a disconnection', () async {
    final a = StreamController<Object?>();
    final got = <RealtimeSignal>[];
    final sub = signalsFromSnapshots([a.stream]).listen(got.add);
    a.addError(StateError('permission-denied'));
    await pumpEventQueue();
    expect(got.single, isA<RealtimeDisconnected>());
    await sub.cancel();
  });

  test('stay view realtime ids parse; missing or empty means disabled', () {
    expect(RealtimeChannels.fromJson({'channel': 'c', 'global': 'g'}),
        const RealtimeChannels('c', 'g'));
    expect(RealtimeChannels.fromJson(null), isNull);
    expect(RealtimeChannels.fromJson({'channel': ''}), isNull);
  });
}
