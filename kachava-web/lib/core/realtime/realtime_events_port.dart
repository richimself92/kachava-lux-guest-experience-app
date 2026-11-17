import 'dart:async';

import '../../domain/realtime_channels.dart';
import '../config/app_config.dart';
import 'realtime_events_stub.dart'
    if (dart.library.js_interop) 'realtime_events_web.dart';

/// What the Firestore signal listeners report (ADR-012). Signals carry no
/// data; the portal re-reads through REST.
sealed class RealtimeSignal {
  const RealtimeSignal();
}

/// The listeners delivered their first snapshot.
final class RealtimeConnected extends RealtimeSignal {
  const RealtimeConnected();
}

/// A signal doc changed after its first snapshot.
final class RealtimeChange extends RealtimeSignal {
  const RealtimeChange();
}

/// A listener failed (rules, network, init); the caller re-subscribes.
final class RealtimeDisconnected extends RealtimeSignal {
  const RealtimeDisconnected();
}

/// Port over the signal-doc listeners. Cancelling the subscription closes
/// every listener.
abstract interface class RealtimeEventsPort {
  Stream<RealtimeSignal> watch(RealtimeChannels channels);
}

/// No listeners (tests, missing Firebase config): realtime disabled.
class SilentRealtimeEvents implements RealtimeEventsPort {
  const SilentRealtimeEvents();

  @override
  Stream<RealtimeSignal> watch(RealtimeChannels channels) =>
      const Stream.empty();
}

/// Maps doc snapshot streams to signals: the first snapshot of any doc is
/// [RealtimeConnected] (once), every later snapshot a [RealtimeChange].
Stream<RealtimeSignal> signalsFromSnapshots(List<Stream<Object?>> docs) {
  final subs = <StreamSubscription<Object?>>[];
  var connected = false;
  late final StreamController<RealtimeSignal> out;
  void forward(Stream<Object?> doc) {
    var seen = false;
    subs.add(doc.listen((_) {
      if (seen) return out.add(const RealtimeChange());
      seen = true;
      if (!connected) out.add(const RealtimeConnected());
      connected = true;
    }, onError: (Object _) => out.add(const RealtimeDisconnected())));
  }

  out = StreamController<RealtimeSignal>(
    onListen: () => docs.forEach(forward),
    onCancel: () => Future.wait(subs.map((s) => s.cancel())),
  );
  return out.stream;
}

/// Factory returning the platform-appropriate [RealtimeEventsPort].
RealtimeEventsPort createRealtimeEventsPort() =>
    AppConfig.enableNetwork && AppConfig.firebaseConfigured
        ? createPlatformRealtimeEvents()
        : const SilentRealtimeEvents();
