import 'sanctuary_repository.dart';

/// Outcome of loading the guest's stay from the server.
sealed class SanctuaryFetchResult {
  const SanctuaryFetchResult();
}

/// The server answered with the guest's stay.
final class SanctuaryFetched extends SanctuaryFetchResult {
  const SanctuaryFetched(this.snapshot, {this.revision});

  final SanctuarySnapshot snapshot;

  /// Identifies the server content; equal revisions mean nothing changed.
  /// `null` when unknown, in which case the snapshot is always applied.
  final String? revision;
}

/// The server rejected the magic link definitively (HTTP 401/403/404): it is
/// invalid, revoked, or its post-checkout access window has expired.
final class SanctuaryLinkRejected extends SanctuaryFetchResult {
  const SanctuaryLinkRejected();
}

/// Transient failure (5xx, 429, timeout, network): the link may still be valid.
final class SanctuaryUnreachable extends SanctuaryFetchResult {
  const SanctuaryUnreachable();
}

/// Outcome of a guest mutation sent to the server.
sealed class MutationResult {
  const MutationResult();
}

/// The server confirmed the change (HTTP 2xx).
final class MutationConfirmed extends MutationResult {
  const MutationConfirmed();
}

/// The server did not confirm the change; nothing may be shown as saved.
final class MutationFailed extends MutationResult {
  const MutationFailed();
}
