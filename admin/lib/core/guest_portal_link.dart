/// Builds guest magic links from the validated guest portal base URL.
///
/// The base URL is a required build-time define (`GUEST_PORTAL_URL`); there is
/// no silent default, so a misconfigured build fails fast at startup instead of
/// handing guests links that point to the wrong host.
class GuestPortalLink {
  const GuestPortalLink._();

  static const String defineName = 'GUEST_PORTAL_URL';
  static String? _baseUrl;

  /// Validates and stores [rawBaseUrl]; throws [AdminConfigException] if invalid.
  static void configure(String rawBaseUrl) {
    _baseUrl = validateBaseUrl(rawBaseUrl);
  }

  /// Returns the normalized absolute http(s) base URL or throws.
  static String validateBaseUrl(String rawBaseUrl) {
    final trimmed = rawBaseUrl.trim();
    final uri = Uri.tryParse(trimmed);
    final isHttp = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    if (!isHttp) {
      throw AdminConfigException(
          '$defineName must be an absolute http(s) URL (got "$trimmed"). '
          'Build with --dart-define-from-file=config/<env>.json.');
    }
    return trimmed.replaceFirst(RegExp(r'/+$'), '');
  }

  /// Full passwordless magic link for [guestTokenUuid].
  static String forToken(String guestTokenUuid) {
    final base = _baseUrl;
    if (base == null) {
      throw StateError('GuestPortalLink.configure() was not called.');
    }
    return '$base/?guestId=$guestTokenUuid';
  }
}

/// Raised when a required build-time configuration value is missing or invalid.
class AdminConfigException implements Exception {
  const AdminConfigException(this.message);

  final String message;

  @override
  String toString() => 'AdminConfigException: $message';
}
