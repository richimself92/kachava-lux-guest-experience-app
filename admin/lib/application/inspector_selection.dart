import '../domain/admin_entities.dart';
import '../domain/admin_enums.dart';
import '../domain/admin_stay_entities.dart';

/// Discriminated union of inspectable items for the Slide-Over Assignment Drawer.
enum InspectorRecordType {
  alert,
  stay,
  booking,
  larder,
  concierge,
}

/// Holds the active selection inside the 420px Right Slide-Over Inspector Drawer.
class AdminDrawerSelection {
  const AdminDrawerSelection({
    required this.type,
    required this.recordId,
    required this.title,
    required this.subtitle,
  });

  final InspectorRecordType type;
  final String recordId;
  final String title;
  final String subtitle;
}

/// Pure filtering helpers for Admin Dashboard collections.
class AdminFilterEngine {
  const AdminFilterEngine._();

  static String extractVillaCode(String label) => label.split('—').first.trim();

  static AdminStayRecord? findActiveStayForVilla(
    List<AdminStayRecord> stays,
    String villaLabel,
  ) {
    final code = extractVillaCode(villaLabel);
    for (final stay in stays) {
      if (extractVillaCode(stay.villaName) == code &&
          stay.lifecycleStatus != StayLifecycleStatus.checkedOut &&
          stay.lifecycleStatus != StayLifecycleStatus.expired) {
        return stay;
      }
    }
    return null;
  }

  static bool matchesQuery(String query, List<String> fields) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return true;
    }
    return fields.any((field) => field.toLowerCase().contains(trimmed));
  }

  static List<OperationalAlert> filterAlerts({
    required List<OperationalAlert> alerts,
    required String query,
    required String villaFilter,
    required bool urgentOnly,
    required AlertCategory? categoryFilter,
  }) {
    final targetCode = extractVillaCode(villaFilter);
    return alerts.where((alert) {
      if (urgentOnly && alert.severity != AlertSeverity.urgent) {
        return false;
      }
      if (villaFilter != 'All Villas' &&
          extractVillaCode(alert.villaName) != targetCode) {
        return false;
      }
      if (categoryFilter != null && alert.category != categoryFilter) {
        return false;
      }
      return matchesQuery(query, [
        alert.alertId,
        alert.villaName,
        alert.guestNames,
        alert.title,
        alert.summary,
        alert.category.label,
      ]);
    }).toList();
  }

  static List<AdminStayRecord> filterStays({
    required List<AdminStayRecord> stays,
    required String query,
    required String villaFilter,
    required StayLifecycleStatus? lifecycleFilter,
  }) {
    final targetCode = extractVillaCode(villaFilter);
    return stays.where((stay) {
      if (villaFilter != 'All Villas' &&
          extractVillaCode(stay.villaName) != targetCode) {
        return false;
      }
      if (lifecycleFilter != null && stay.lifecycleStatus != lifecycleFilter) {
        return false;
      }
      return matchesQuery(query, [
        stay.stayId,
        stay.villaName,
        stay.guestNames,
        stay.guestTokenUuid,
        stay.transfer.inboundFlight,
        stay.transfer.outboundFlight,
      ]);
    }).toList();
  }

  static List<AdminBookingRecord> filterBookings({
    required List<AdminBookingRecord> bookings,
    required String query,
    required String categoryFilter,
  }) {
    return bookings.where((booking) {
      if (categoryFilter != 'All' && booking.category != categoryFilter) {
        return false;
      }
      return matchesQuery(query, [
        booking.bookingId,
        booking.title,
        booking.villaName,
        booking.guestNames,
        booking.assignedStaffName,
      ]);
    }).toList();
  }

  static List<AdminLarderOrder> filterLarderOrders({
    required List<AdminLarderOrder> orders,
    required String query,
    required String statusFilter,
    required String zoneFilter,
  }) {
    return orders.where((ord) {
      if (statusFilter != 'All' && ord.status != statusFilter) {
        return false;
      }
      if (zoneFilter != 'All' &&
          !ord.items.any((i) => i.placementZone == zoneFilter)) {
        return false;
      }
      return matchesQuery(
        query,
        [ord.orderId, ord.villaName, ord.guestNames, ord.assignedStaffName],
      );
    }).toList();
  }

  static List<AdminConciergeTicket> filterConciergeTickets({
    required List<AdminConciergeTicket> tickets,
    required String query,
    required ConciergeStage? stageFilter,
    required StaffDepartment? departmentFilter,
  }) {
    return tickets.where((ticket) {
      if (stageFilter != null && ticket.stage != stageFilter) {
        return false;
      }
      if (departmentFilter != null && ticket.department != departmentFilter) {
        return false;
      }
      return matchesQuery(query, [
        ticket.requestId,
        ticket.title,
        ticket.category,
        ticket.villaName,
        ticket.guestNames,
      ]);
    }).toList();
  }
}
