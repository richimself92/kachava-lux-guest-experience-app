import 'admin_enums.dart';
export 'admin_concierge_folio_entities.dart';

/// Live operational alert (`operational_alerts/{alertId}`).
class OperationalAlert {
  const OperationalAlert({
    required this.alertId,
    required this.stayId,
    required this.villaId,
    required this.villaName,
    required this.guestNames,
    required this.category,
    required this.severity,
    required this.title,
    required this.summary,
    required this.targetTab,
    required this.targetRecordId,
    required this.assignedDepartment,
    required this.createdAtLabel,
    this.isAcknowledged = false,
    this.acknowledgedByStaffId,
  });

  final String alertId;
  final String stayId;
  final String villaId;
  final String villaName;
  final String guestNames;
  final AlertCategory category;
  final AlertSeverity severity;
  final String title;
  final String summary;
  final AdminWorkspaceTab targetTab;
  final String targetRecordId;
  final StaffDepartment assignedDepartment;
  final String createdAtLabel;
  final bool isAcknowledged;
  final String? acknowledgedByStaffId;

  OperationalAlert copyWith({
    bool? isAcknowledged,
    String? acknowledgedByStaffId,
  }) {
    return OperationalAlert(
      alertId: alertId,
      stayId: stayId,
      villaId: villaId,
      villaName: villaName,
      guestNames: guestNames,
      category: category,
      severity: severity,
      title: title,
      summary: summary,
      targetTab: targetTab,
      targetRecordId: targetRecordId,
      assignedDepartment: assignedDepartment,
      createdAtLabel: createdAtLabel,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      acknowledgedByStaffId:
          acknowledgedByStaffId ?? this.acknowledgedByStaffId,
    );
  }
}

/// Experience, Yacht Charter, Private Dining, or Privilege reservation.
class AdminBookingRecord {
  const AdminBookingRecord({
    required this.bookingId,
    required this.stayId,
    required this.villaName,
    required this.guestNames,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.scheduledTime,
    required this.addOns,
    required this.allergyWarning,
    required this.priceUsd,
    required this.status,
    required this.assignedStaffId,
    required this.assignedStaffName,
    required this.assignedDepartment,
    this.notifiedAt,
    this.cancellationReason = '',
  });

  final String bookingId;
  final String stayId;
  final String villaName;
  final String guestNames;
  final String category;
  final String title;
  final String subtitle;
  final String scheduledTime;
  final List<String> addOns;
  final String? allergyWarning;
  final double priceUsd;
  final String status;
  final String assignedStaffId;
  final String assignedStaffName;
  final StaffDepartment assignedDepartment;
  final String? notifiedAt;
  final String cancellationReason;

  AdminBookingRecord copyWith({
    String? status,
    String? assignedStaffId,
    String? assignedStaffName,
    StaffDepartment? assignedDepartment,
    String? notifiedAt,
    String? cancellationReason,
  }) {
    return AdminBookingRecord(
      bookingId: bookingId,
      stayId: stayId,
      villaName: villaName,
      guestNames: guestNames,
      category: category,
      title: title,
      subtitle: subtitle,
      scheduledTime: scheduledTime,
      addOns: addOns,
      allergyWarning: allergyWarning,
      priceUsd: priceUsd,
      status: status ?? this.status,
      assignedStaffId: assignedStaffId ?? this.assignedStaffId,
      assignedStaffName: assignedStaffName ?? this.assignedStaffName,
      assignedDepartment: assignedDepartment ?? this.assignedDepartment,
      notifiedAt: notifiedAt ?? this.notifiedAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}

/// Individual larder line item with physical villa placement zone.
class LarderOrderItem {
  const LarderOrderItem({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.priceUsd,
    required this.placementZone,
    this.isStocked = false,
  });

  final String itemId;
  final String name;
  final int quantity;
  final double priceUsd;
  final String placementZone;
  final bool isStocked;

  LarderOrderItem copyWith({bool? isStocked}) {
    return LarderOrderItem(
      itemId: itemId,
      name: name,
      quantity: quantity,
      priceUsd: priceUsd,
      placementZone: placementZone,
      isStocked: isStocked ?? this.isStocked,
    );
  }
}

/// Villa stocking and larder provisioning order (`larder_orders`).
class AdminLarderOrder {
  const AdminLarderOrder({
    required this.orderId,
    required this.stayId,
    required this.villaName,
    required this.guestNames,
    required this.targetDeadline,
    required this.totalUsd,
    required this.status,
    required this.assignedStaffId,
    required this.assignedStaffName,
    required this.items,
    required this.complimentaryStaples,
  });

  final String orderId;
  final String stayId;
  final String villaName;
  final String guestNames;
  final String targetDeadline;
  final double totalUsd;
  final String status;
  final String assignedStaffId;
  final String assignedStaffName;
  final List<LarderOrderItem> items;
  final List<String> complimentaryStaples;

  AdminLarderOrder copyWith({
    String? status,
    String? assignedStaffId,
    String? assignedStaffName,
    List<LarderOrderItem>? items,
  }) {
    return AdminLarderOrder(
      orderId: orderId,
      stayId: stayId,
      villaName: villaName,
      guestNames: guestNames,
      targetDeadline: targetDeadline,
      totalUsd: totalUsd,
      status: status ?? this.status,
      assignedStaffId: assignedStaffId ?? this.assignedStaffId,
      assignedStaffName: assignedStaffName ?? this.assignedStaffName,
      items: items ?? this.items,
      complimentaryStaples: complimentaryStaples,
    );
  }
}
