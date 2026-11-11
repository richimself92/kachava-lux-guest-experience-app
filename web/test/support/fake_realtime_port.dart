import 'dart:async';

import 'package:kachava_guest_portal/core/realtime/realtime_events_port.dart';
import 'package:kachava_guest_portal/domain/realtime_channels.dart';

/// Test double for the Firestore signal listeners: tests push signals.
class FakeRealtimePort implements RealtimeEventsPort {
  final List<RealtimeChannels> watched = [];
  StreamController<RealtimeSignal>? _controller;
  int cancels = 0;

  bool get isListening => _controller?.hasListener ?? false;

  @override
  Stream<RealtimeSignal> watch(RealtimeChannels channels) {
    watched.add(channels);
    final controller = StreamController<RealtimeSignal>(
      onCancel: () => cancels++,
    );
    _controller = controller;
    return controller.stream;
  }

  void emit(RealtimeSignal signal) => _controller!.add(signal);

  void connect() => emit(const RealtimeConnected());

  void change() => emit(const RealtimeChange());

  void fail() => emit(const RealtimeDisconnected());
}

/// Page visibility the test toggles by hand.
class FakeVisibility {
  final StreamController<void> _visible = StreamController<void>.broadcast();
  Stream<void> get onVisible => _visible.stream;
  void show() => _visible.add(null);
}
