/// Guest rating labels (1–5). A missing rating (`<= 0`) renders as `—`, never
/// as an invented score.
class RatingLabel {
  const RatingLabel._();

  static const String missing = '—';

  /// e.g. `★★★★☆ — 4/5`; ratings above 5 are capped.
  static String stars(int rating) {
    if (rating <= 0) return missing;
    final r = rating.clamp(1, 5);
    return '${'★' * r}${'☆' * (5 - r)} — $r/5';
  }

  /// e.g. `4/5`.
  static String score(int rating) =>
      rating <= 0 ? missing : '${rating.clamp(1, 5)}/5';
}
