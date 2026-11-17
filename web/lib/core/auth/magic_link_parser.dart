/// What the page URL says about the guest link.
enum GuestLinkStatus { missing, invalid, valid }

/// Reads `?guestId=<uuid>`. There is no default guest: without a
/// valid id the portal shows the access screen.
abstract final class MagicLinkParser {
  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  static bool isValidUuid(String candidate) =>
      _uuidRegex.hasMatch(candidate.trim());

  static String rawGuestId(Uri uri) =>
      uri.queryParameters['guestId']?.trim() ?? '';

  static GuestLinkStatus statusOf(Uri uri) {
    final raw = rawGuestId(uri);
    if (raw.isEmpty) return GuestLinkStatus.missing;
    return isValidUuid(raw) ? GuestLinkStatus.valid : GuestLinkStatus.invalid;
  }
}
