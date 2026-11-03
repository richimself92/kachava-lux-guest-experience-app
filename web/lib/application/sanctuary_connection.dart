import '../domain/repositories/sanctuary_repository.dart';

/// The portal's link to the server: first answer received, reconnecting after
/// a transient failure, or link rejected. Also detects polls whose content
/// did not change, so listeners are not notified for nothing.
class SanctuaryConnection {
  bool _hasServerData = false, _isReconnecting = false, _isLinkRejected = false;
  String? _lastRevision;

  bool get hasServerData => _hasServerData;
  bool get isReconnecting => _isReconnecting;
  bool get isLinkRejected => _isLinkRejected;

  bool get _isSettled => _hasServerData && !_isReconnecting && !_isLinkRejected;

  /// Records [result]. `fresh` is the snapshot to apply (null when there is
  /// no new content); `changed` tells whether anything visible moved.
  ({SanctuarySnapshot? fresh, bool changed}) record(
      SanctuaryFetchResult result) {
    switch (result) {
      case SanctuaryFetched(:final snapshot, :final revision):
        final isSame =
            _isSettled && revision != null && revision == _lastRevision;
        _lastRevision = revision;
        if (isSame) return (fresh: null, changed: false);
        _hasServerData = true;
        _isReconnecting = _isLinkRejected = false;
        return (fresh: snapshot, changed: true);
      case SanctuaryLinkRejected():
        _isLinkRejected = true;
        return (fresh: null, changed: true);
      case SanctuaryUnreachable():
        final changed = !_isReconnecting;
        _isReconnecting = true;
        return (fresh: null, changed: changed);
    }
  }
}
