import 'dart:convert';

import '../domain/admin_sync_snapshot.dart';
import 'admin_wire_mapper.dart';

/// Maps the `GET /api/v1/admin/sync` envelope into an [AdminSyncSnapshot].
///
/// Each key holds exactly the `data` payload of the matching per-collection
/// admin endpoint, so the existing [AdminWireMapper] parsers are reused.
class AdminSyncMapper {
  const AdminSyncMapper._();

  static const List<String> requiredKeys = [
    'stays',
    'alerts',
    'bookings',
    'larderOrders',
    'conciergeRequests',
    'midstayFeedback',
    'experiences',
    'larder',
  ];

  /// Throws [FormatException] for any malformed payload (never an [Error]).
  static AdminSyncSnapshot parse(Map<String, dynamic> raw) {
    final payload = _payloadOf(raw);
    try {
      return _build(payload);
    } on TypeError catch (error) {
      throw FormatException('Malformed admin sync payload: $error');
    }
  }

  static AdminSyncSnapshot _build(Map<String, dynamic> payload) {
    final rawStays = payload['stays'];
    final stays = AdminWireMapper.parseStays(rawStays);
    return AdminSyncSnapshot(
      stays: stays,
      folioItems: AdminWireMapper.parseFolioItemsFromStays(
          AdminWireMapper.extractMapList(rawStays)),
      alerts: AdminWireMapper.parseAlerts(payload['alerts']),
      bookings: AdminWireMapper.parseBookings(payload['bookings'], stays),
      larderOrders:
          AdminWireMapper.parseLarderOrders(payload['larderOrders'], stays),
      conciergeTickets: AdminWireMapper.parseConciergeTickets(
          payload['conciergeRequests'], stays),
      midStayPulses:
          AdminWireMapper.parseMidStayPulses(payload['midstayFeedback'], stays),
      experienceCatalog:
          AdminWireMapper.parseExperienceCatalog(payload['experiences']),
      larderCatalog: AdminWireMapper.parseLarderCatalog(payload['larder']),
      fingerprint: jsonEncode(payload),
    );
  }

  static Map<String, dynamic> _payloadOf(Map<String, dynamic> raw) {
    final inner = raw['data'];
    final payload = inner is Map ? Map<String, dynamic>.from(inner) : raw;
    final missing = requiredKeys.where((k) => payload[k] == null).toList();
    if (missing.isNotEmpty) {
      throw FormatException(
          'Admin sync payload is missing keys: ${missing.join(', ')}');
    }
    return payload;
  }
}
