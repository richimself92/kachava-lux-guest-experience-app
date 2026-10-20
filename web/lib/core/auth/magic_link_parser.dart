/// Result of parsing a Passwordless UUID v4 Magic-Link URI.
class MagicLinkParseResult {
  const MagicLinkParseResult({
    required this.guestUuid,
    required this.isValid,
    required this.isDefaultDemo,
    this.errorMessage,
  });

  final String guestUuid;
  final bool isValid;
  final bool isDefaultDemo;
  final String? errorMessage;
}

/// Extracts and validates Passwordless UUID v4 tokens from `?guestId=<uuid>`.
abstract final class MagicLinkParser {
  static const String defaultDemoUuid = '550e8400-e29b-41d4-a716-446655440000';
  static const String secondaryDemoUuid =
      'f47ac10b-58cc-4372-a567-0e02b2c3d479';

  static final RegExp _uuidV4Regex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  static MagicLinkParseResult parseUri(Uri uri) {
    final rawGuestId = uri.queryParameters['guestId']?.trim();
    if (rawGuestId == null || rawGuestId.isEmpty) {
      return const MagicLinkParseResult(
        guestUuid: defaultDemoUuid,
        isValid: true,
        isDefaultDemo: true,
      );
    }

    if (!isValidUuid(rawGuestId)) {
      return MagicLinkParseResult(
        guestUuid: rawGuestId,
        isValid: false,
        isDefaultDemo: false,
        errorMessage:
            'Access Restricted — This sanctuary Magic Link ($rawGuestId) is invalid or has expired.',
      );
    }

    return MagicLinkParseResult(
      guestUuid: rawGuestId.toLowerCase(),
      isValid: true,
      isDefaultDemo: rawGuestId.toLowerCase() == defaultDemoUuid,
    );
  }

  static bool isValidUuid(String candidate) {
    return _uuidV4Regex.hasMatch(candidate.trim());
  }
}
