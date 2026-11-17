import 'json_read.dart';

/// Ids of the Firestore signal docs (`realtime_signals/<id>`) a guest may
/// listen to, from `realtime: {channel, global}` of the stay view (ADR-012).
class RealtimeChannels {
  const RealtimeChannels(this.channel, this.global);

  /// Null (realtime disabled) when the stay view carries no channel.
  static RealtimeChannels? fromJson(Object? json) {
    if (json is! Map) return null;
    final map = asJson(json);
    final channel = asString(map['channel']);
    if (channel.isEmpty) return null;
    return RealtimeChannels(channel, asString(map['global']));
  }

  final String channel;

  /// Resort-wide doc (catalog, settings…); empty when not offered.
  final String global;

  List<String> get docIds => [channel, if (global.isNotEmpty) global];

  @override
  bool operator ==(Object other) =>
      other is RealtimeChannels &&
      other.channel == channel &&
      other.global == global;

  @override
  int get hashCode => Object.hash(channel, global);

  @override
  String toString() => 'RealtimeChannels($channel, $global)';
}
