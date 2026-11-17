import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../domain/realtime_channels.dart';
import '../config/app_config.dart';
import 'realtime_events_port.dart';

/// Browser implementation: Firestore `snapshots()` on the stay channel and
/// global docs of `realtime_signals` (ADR-012), without Firebase Auth.
class FirestoreRealtimeEvents implements RealtimeEventsPort {
  static const String _collection = 'realtime_signals';
  static const String _appName = 'kachava-realtime';

  Future<FirebaseFirestore>? _db;

  @override
  Stream<RealtimeSignal> watch(RealtimeChannels channels) =>
      Stream.fromFuture(_open()).asyncExpand((db) => signalsFromSnapshots([
            for (final id in channels.docIds)
              db.collection(_collection).doc(id).snapshots(),
          ]));

  /// Initializes once; a failed init is retried on the next subscription.
  Future<FirebaseFirestore> _open() {
    final pending = _db ??= _init();
    pending.then<void>((_) {}, onError: (Object _) {
      if (identical(_db, pending)) _db = null;
    });
    return pending;
  }

  static Future<FirebaseFirestore> _init() async {
    final app = await Firebase.initializeApp(
      name: _appName,
      options: const FirebaseOptions(
        apiKey: AppConfig.firebaseApiKey,
        appId: AppConfig.firebaseAppId,
        messagingSenderId: AppConfig.firebaseMessagingSenderId,
        projectId: AppConfig.firebaseProjectId,
      ),
    );
    final db = FirebaseFirestore.instanceFor(
        app: app, databaseId: AppConfig.firestoreDatabaseId);
    final emulator = Uri.tryParse('http://${AppConfig.firestoreEmulatorHost}');
    if (AppConfig.firestoreEmulatorHost.isNotEmpty && emulator != null) {
      db.useFirestoreEmulator(emulator.host, emulator.port);
    }
    return db;
  }
}

RealtimeEventsPort createPlatformRealtimeEvents() => FirestoreRealtimeEvents();
