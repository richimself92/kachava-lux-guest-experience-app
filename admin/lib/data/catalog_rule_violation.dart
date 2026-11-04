import 'admin_api_client.dart';

/// A catalog business rule the API refused with HTTP 422, e.g.
/// `Service cannot be active: cover image is required; name.es is required`.
/// [problems] are the backend detail texts (labelled by
/// `ServiceCatalogStrings.problem`).
class CatalogRuleViolation {
  const CatalogRuleViolation(this.problems);

  final List<String> problems;

  /// `null` unless [error] is a 422 from the admin API.
  static CatalogRuleViolation? tryParse(Object error) {
    if (error is! AdminApiException || error.statusCode != 422) return null;
    final message = error.serverMessage;
    if (message.isEmpty) return const CatalogRuleViolation([]);
    final colon = message.indexOf(': ');
    if (colon < 0) return CatalogRuleViolation([message]);
    final details = message
        .substring(colon + 2)
        .split('; ')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    return CatalogRuleViolation(
        details.isEmpty ? [message.substring(0, colon)] : details);
  }
}
