import 'dart:convert';

/// Topics of a real-time signal (ADR-012).
abstract final class RealtimeTopic {
  static const String stay = 'stay';
  static const String messages = 'messages';
  static const String requests = 'requests';
  static const String bookings = 'bookings';
  static const String orders = 'orders';
  static const String trips = 'trips';
  static const String tasks = 'tasks';
  static const String notifications = 'notifications';
  static const String catalog = 'catalog';
  static const String settings = 'settings';
  static const String villas = 'villas';
  static const String staff = 'staff';
  static const String providers = 'providers';

  /// Unknown or coalesced changes: concerns every screen.
  static const String any = '*';
}

/// One "something changed" signal. It carries no data: screens re-fetch
/// through the REST endpoints (ADR-012, guest-safe ADR-007).
class RealtimeChange {
  const RealtimeChange({required this.scope, required this.topic, this.stayId});

  /// `stay`, `global` or `admin-only`.
  final String scope;
  final String topic;
  final String? stayId;

  bool get isAny => topic == RealtimeTopic.any;

  /// Reads a signal (`{scope, stayId?, topic, at}`); null without a topic.
  static RealtimeChange? fromMap(Map<String, Object?> data) => switch (data) {
        {'topic': final String topic} => RealtimeChange(
            scope: data['scope'] is String ? data['scope'] as String : '',
            topic: topic,
            stayId: data['stayId'] is String ? data['stayId'] as String : null,
          ),
        _ => null,
      };

  /// Parses a JSON-encoded signal; null when malformed.
  static RealtimeChange? tryParse(String data) {
    try {
      final json = jsonDecode(data);
      return json is Map<String, Object?> ? fromMap(json) : null;
    } on FormatException {
      return null;
    }
  }
}

/// The changes collected during one debounce window.
/// [RealtimeInvalidation.everything] (manual refresh, tab visible again,
/// listener reconnected) concerns every screen.
class RealtimeInvalidation {
  RealtimeInvalidation(Iterable<RealtimeChange> changes)
      : changes = List.unmodifiable(changes),
        isEverything = false;

  RealtimeInvalidation.everything()
      : changes = const [],
        isEverything = true;

  final List<RealtimeChange> changes;
  final bool isEverything;

  Set<String> get topics => {for (final c in changes) c.topic};

  /// Whether any change has one of [topics]; null [topics] means any.
  bool touches(Set<String>? topics) =>
      isEverything ||
      topics == null ||
      changes.any((c) => c.isAny || topics.contains(c.topic));

  /// Whether a change of [topics] may concern [stayId] (a change without a
  /// stay may concern any stay).
  bool touchesStay(String stayId, Set<String> topics) =>
      isEverything ||
      changes.any((c) =>
          c.isAny ||
          (topics.contains(c.topic) &&
              (c.stayId == null || c.stayId == stayId)));
}

/// Turns successive snapshots of one signal document (`{at, topic, seq}`,
/// ADR-012) into changes. The first snapshot is the baseline. The backend
/// rewrites the document in place, so quick writes may arrive coalesced: a
/// `seq` gap (or a signal without topic) becomes [RealtimeTopic.any].
class RealtimeSignalTracker {
  bool _hasBaseline = false;
  String? _lastSignature;
  num? _lastSeq;

  bool get hasBaseline => _hasBaseline;

  /// The change carried by [data], or null (baseline / unchanged / deleted).
  RealtimeChange? read(Map<String, Object?>? data) {
    final signature = data?.toString() ?? '';
    final seq = data?['seq'] is num ? data!['seq'] as num : null;
    final previousSeq = _lastSeq;
    if (seq != null) _lastSeq = seq;
    if (!_hasBaseline) {
      _hasBaseline = true;
      _lastSignature = signature;
      return null;
    }
    if (signature == _lastSignature || data == null) return null;
    _lastSignature = signature;
    final gap = seq != null && previousSeq != null && seq - previousSeq > 1;
    final change = RealtimeChange.fromMap(data);
    if (gap || change == null) {
      return const RealtimeChange(scope: '', topic: RealtimeTopic.any);
    }
    return change;
  }

  void reset() {
    _hasBaseline = false;
    _lastSignature = null;
    _lastSeq = null;
  }
}
