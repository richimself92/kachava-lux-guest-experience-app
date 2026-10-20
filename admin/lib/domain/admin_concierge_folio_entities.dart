import 'admin_enums.dart';

/// Bidirectional host-to-guest chat message inside a concierge ticket.
class ConciergeChatMessage {
  const ConciergeChatMessage({
    required this.messageId,
    required this.senderName,
    required this.senderRole,
    required this.body,
    required this.timestampLabel,
    required this.isStaff,
  });

  final String messageId;
  final String senderName;
  final String senderRole;
  final String body;
  final String timestampLabel;
  final bool isStaff;
}

/// 24/7 Concierge & Maintenance ticket (`concierge_requests`).
class AdminConciergeTicket {
  const AdminConciergeTicket({
    required this.requestId,
    required this.stayId,
    required this.villaName,
    required this.guestNames,
    required this.category,
    required this.department,
    required this.priority,
    required this.title,
    required this.details,
    required this.stage,
    required this.assignedStaffId,
    required this.assignedStaffName,
    required this.messages,
    this.photoStoragePath,
    this.signedPhotoGetUrl,
    this.notifiedAt,
  });

  final String requestId;
  final String stayId;
  final String villaName;
  final String guestNames;
  final String category;
  final StaffDepartment department;
  final String priority;
  final String title;
  final String details;
  final ConciergeStage stage;
  final String assignedStaffId;
  final String assignedStaffName;
  final List<ConciergeChatMessage> messages;
  final String? photoStoragePath;
  final String? signedPhotoGetUrl;
  final String? notifiedAt;

  bool get hasPhoto => photoStoragePath != null && photoStoragePath!.isNotEmpty;

  AdminConciergeTicket copyWith({
    ConciergeStage? stage,
    String? assignedStaffId,
    String? assignedStaffName,
    StaffDepartment? department,
    List<ConciergeChatMessage>? messages,
    String? notifiedAt,
  }) {
    return AdminConciergeTicket(
      requestId: requestId,
      stayId: stayId,
      villaName: villaName,
      guestNames: guestNames,
      category: category,
      department: department ?? this.department,
      priority: priority,
      title: title,
      details: details,
      stage: stage ?? this.stage,
      assignedStaffId: assignedStaffId ?? this.assignedStaffId,
      assignedStaffName: assignedStaffName ?? this.assignedStaffName,
      messages: messages ?? this.messages,
      photoStoragePath: photoStoragePath,
      signedPhotoGetUrl: signedPhotoGetUrl,
      notifiedAt: notifiedAt ?? this.notifiedAt,
    );
  }
}

/// Proactive Mid-Stay Check-In review with < 7 Min SLA tracking.
class AdminMidStayPulse {
  const AdminMidStayPulse({
    required this.checkInId,
    required this.stayId,
    required this.villaName,
    required this.guestNames,
    required this.sentiment,
    required this.focusChips,
    required this.guestNote,
    required this.slaLabel,
    required this.isUnderSla,
    required this.status,
    required this.followUpNote,
    required this.handledByStaffName,
    this.rating = 5,
  });

  final String checkInId;
  final String stayId;
  final String villaName;
  final String guestNames;
  final String sentiment;
  final List<String> focusChips;
  final String guestNote;
  final String slaLabel;
  final bool isUnderSla;
  final String status;
  final String followUpNote;
  final String handledByStaffName;
  final int rating;

  AdminMidStayPulse copyWith({
    String? status,
    String? followUpNote,
    String? handledByStaffName,
    int? rating,
  }) {
    return AdminMidStayPulse(
      checkInId: checkInId,
      stayId: stayId,
      villaName: villaName,
      guestNames: guestNames,
      sentiment: sentiment,
      focusChips: focusChips,
      guestNote: guestNote,
      slaLabel: slaLabel,
      isUnderSla: isUnderSla,
      status: status ?? this.status,
      followUpNote: followUpNote ?? this.followUpNote,
      handledByStaffName: handledByStaffName ?? this.handledByStaffName,
      rating: rating ?? this.rating,
    );
  }
}

/// Itemized folio charge or included privilege line item.
class FolioLineItem {
  const FolioLineItem({
    required this.itemId,
    required this.title,
    required this.categoryLabel,
    required this.amountUsd,
    required this.isIncludedPrivilege,
  });

  final String itemId;
  final String title;
  final String categoryLabel;
  final double amountUsd;
  final bool isIncludedPrivilege;
}

/// Configurable Experience catalog item (`/api/v1/admin/catalog/experiences`).
class AdminExperienceCatalogItem {
  const AdminExperienceCatalogItem({
    required this.id,
    required this.title,
    required this.category,
    required this.duration,
    required this.location,
    required this.priceText,
    required this.basePriceUSD,
    this.isIncluded = false,
    this.description = '',
  });

  final String id;
  final String title;
  final String category;
  final String duration;
  final String location;
  final String priceText;
  final double basePriceUSD;
  final bool isIncluded;
  final String description;
}

/// Configurable Minibar & Larder catalog item (`/api/v1/admin/catalog/larder`).
class AdminLarderCatalogItem {
  const AdminLarderCatalogItem({
    required this.id,
    required this.name,
    required this.origin,
    required this.price,
    required this.category,
    required this.storageType,
    this.description = '',
  });

  final String id;
  final String name;
  final String origin;
  final double price;
  final String category;
  final String storageType;
  final String description;
}
