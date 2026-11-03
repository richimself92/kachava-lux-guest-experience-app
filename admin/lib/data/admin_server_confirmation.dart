import '../domain/admin_stay_entities.dart';
import 'admin_wire_mapper.dart';

/// Extracts server-issued identifiers from mutation responses.
///
/// A 2xx response that lacks the identifiers the UI needs is treated as an
/// unconfirmed mutation: nothing is invented locally.
class AdminServerConfirmation {
  const AdminServerConfirmation._();

  /// Stay returned by `POST /admin/stays`; requires `stayId` + `guestTokenUuid`.
  static AdminStayRecord createdStay(Map<String, dynamic> response) {
    final rawStay = response['stay'];
    if (rawStay is! Map) {
      throw const AdminUnconfirmedMutationException(
          'Create stay response did not include the stay.');
    }
    final stay = Map<String, dynamic>.from(rawStay);
    requireText(stay, 'stayId');
    requireText(stay, 'guestTokenUuid');
    return AdminWireMapper.mapStay(stay);
  }

  /// Token returned by `POST /admin/stays/:id/regenerate-token`.
  static String rotatedToken(Map<String, dynamic> response) =>
      requireText(response, 'guestTokenUuid');

  /// Returns the non-empty string at [key] or throws.
  static String requireText(Map<String, dynamic> map, String key) {
    final value = map[key]?.toString().trim() ?? '';
    if (value.isEmpty) {
      throw AdminUnconfirmedMutationException(
          'Server response did not include "$key".');
    }
    return value;
  }
}

/// Raised when the server accepted a request but did not confirm the result.
class AdminUnconfirmedMutationException implements Exception {
  const AdminUnconfirmedMutationException(this.message);

  final String message;

  @override
  String toString() => 'AdminUnconfirmedMutationException: $message';
}
