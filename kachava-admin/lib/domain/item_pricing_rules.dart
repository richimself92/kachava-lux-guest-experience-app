/// Admin-side checks of the pre-stocking item fields (same limits as the
/// backend contract; the server stays the authority).
abstract final class ItemPricingRules {
  static const int maxSku = 40;
  static const int maxUrl = 500;
  static const double maxAmount = 1000000;
  static const int minOz = 1;
  static const int maxOz = 64;
  static const int maxOzEntries = 10;

  /// Oz per portion offered when an item switches to weight pricing.
  static const List<int> defaultOzOptions = [6, 8, 10, 12, 14];

  static bool skuOk(String? sku) => (sku ?? '').trim().length <= maxSku;

  static bool urlOk(String? url) {
    final text = (url ?? '').trim();
    if (text.isEmpty) return true;
    final uri = Uri.tryParse(text);
    return text.length <= maxUrl &&
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  /// A non-negative amount up to [maxAmount] with at most [decimals].
  static bool amountOk(String raw, {required int decimals}) {
    final pattern = RegExp('^\\d{1,7}(\\.\\d{1,$decimals})?\$');
    final text = raw.trim();
    return pattern.hasMatch(text) && double.parse(text) <= maxAmount;
  }

  /// Comma separated whole oz → sorted unique list; `null` when invalid.
  static List<int>? parseOz(String raw) {
    final parts = [
      for (final p in raw.split(','))
        if (p.trim().isNotEmpty) p.trim()
    ];
    final values = <int>{};
    for (final p in parts) {
      final v = int.tryParse(p);
      if (v == null || v < minOz || v > maxOz) return null;
      values.add(v);
    }
    if (values.isEmpty || values.length > maxOzEntries) return null;
    return values.toList()..sort();
  }
}
