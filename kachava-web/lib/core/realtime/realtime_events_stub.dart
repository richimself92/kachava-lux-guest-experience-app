import 'realtime_events_port.dart';

/// Headless platforms (`flutter test`) have no Firestore: realtime disabled.
RealtimeEventsPort createPlatformRealtimeEvents() =>
    const SilentRealtimeEvents();
