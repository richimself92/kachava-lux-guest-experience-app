import 'admin_entities.dart';
import 'admin_stay_entities.dart';

/// Server-confirmed state of every live admin collection at one point in time.
class AdminSyncSnapshot {
  const AdminSyncSnapshot({
    required this.stays,
    required this.alerts,
    required this.bookings,
    required this.larderOrders,
    required this.conciergeTickets,
    required this.midStayPulses,
    required this.experienceCatalog,
    required this.larderCatalog,
    required this.folioItems,
    this.fingerprint,
  });

  static const AdminSyncSnapshot empty = AdminSyncSnapshot(
    stays: [],
    alerts: [],
    bookings: [],
    larderOrders: [],
    conciergeTickets: [],
    midStayPulses: [],
    experienceCatalog: [],
    larderCatalog: [],
    folioItems: [],
  );

  final List<AdminStayRecord> stays;
  final List<OperationalAlert> alerts;
  final List<AdminBookingRecord> bookings;
  final List<AdminLarderOrder> larderOrders;
  final List<AdminConciergeTicket> conciergeTickets;
  final List<AdminMidStayPulse> midStayPulses;
  final List<AdminExperienceCatalogItem> experienceCatalog;
  final List<AdminLarderCatalogItem> larderCatalog;
  final List<FolioLineItem> folioItems;

  /// Canonical form of the server payload this snapshot was parsed from, or
  /// null when it did not come from the wire (offline fakes).
  final String? fingerprint;

  /// True when both snapshots come from byte-identical server payloads.
  bool isSameAs(AdminSyncSnapshot? other) =>
      fingerprint != null && fingerprint == other?.fingerprint;
}
