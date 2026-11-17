import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../domain/realtime_change.dart';
import 'app_config.dart';
import 'realtime_events_port.dart';
import 'realtime_events_stub.dart';

/// Firestore listener on `realtime_signals/<channel>` (ADR-012). The first
/// snapshot is the baseline; every later data change is one signal. The
/// SDK reconnects by itself (served from cache = `connecting`); a listener
/// error (e.g. permission denied) ends `closed` and is left to the caller.
class FirestoreRealtimeEventsAdapter implements RealtimeEventsPort {
  static const String collection = 'realtime_signals';

  final StreamController<RealtimeChange> _changes =
      StreamController<RealtimeChange>.broadcast();
  final ValueNotifier<RealtimeConnection> _connection =
      ValueNotifier(RealtimeConnection.closed);
  Future<FirebaseFirestore>? _db;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  final RealtimeSignalTracker _tracker = RealtimeSignalTracker();
  int _generation = 0;

  @override
  Stream<RealtimeChange> get changes => _changes.stream;

  @override
  ValueListenable<RealtimeConnection> get connection => _connection;

  @override
  void connect(String channel) {
    _stop();
    final generation = ++_generation;
    _connection.value = RealtimeConnection.connecting;
    (_db ??= _openFirestore()).then((db) {
      if (generation != _generation) return;
      _sub = db
          .collection(collection)
          .doc(channel)
          .snapshots(includeMetadataChanges: true)
          .listen(_onSnapshot, onError: _onError);
    }, onError: (Object error) {
      _db = null; // A failed Firebase start is retried on the next connect.
      _onError(error);
    });
  }

  static Future<FirebaseFirestore> _openFirestore() async {
    final app = await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: AdminAppConfig.firebaseApiKey,
        appId: AdminAppConfig.firebaseAppId,
        messagingSenderId: AdminAppConfig.firebaseMessagingSenderId,
        projectId: AdminAppConfig.firebaseProjectId,
      ),
    );
    final db = FirebaseFirestore.instanceFor(
        app: app, databaseId: AdminAppConfig.firestoreDatabaseId);
    const emulator = AdminAppConfig.firestoreEmulatorHost;
    if (emulator.isNotEmpty) {
      final at = emulator.lastIndexOf(':');
      db.useFirestoreEmulator(
          emulator.substring(0, at), int.parse(emulator.substring(at + 1)));
    }
    return db;
  }

  /// The first server snapshot is the baseline (see [RealtimeSignalTracker]);
  /// cached snapshots only move the state.
  void _onSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final cached = snapshot.metadata.isFromCache;
    _connection.value =
        cached ? RealtimeConnection.connecting : RealtimeConnection.open;
    if (cached && !_tracker.hasBaseline) return;
    final change = _tracker.read(snapshot.data());
    if (change != null && !_changes.isClosed) _changes.add(change);
  }

  void _onError(Object error) {
    debugPrint('Realtime listener failed: $error');
    _stop();
    _connection.value = RealtimeConnection.closed;
  }

  void _stop() {
    _sub?.cancel();
    _sub = null;
    _tracker.reset();
  }

  @override
  void close() {
    _generation++;
    _stop();
    _connection.value = RealtimeConnection.closed;
  }

  @override
  void dispose() {
    close();
    _changes.close();
    _connection.dispose();
  }
}

RealtimeEventsPort createPlatformRealtimeEventsPort() =>
    AdminAppConfig.realtimeConfigured
        ? FirestoreRealtimeEventsAdapter()
        : StubRealtimeEventsAdapter();
