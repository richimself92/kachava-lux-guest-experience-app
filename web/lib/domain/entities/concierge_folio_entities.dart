/// 4-stage lifecycle progress for 24/7 Concierge tickets (`FR-09`).
enum ConciergeStage {
  requested(step: 1, label: 'Requested'),
  assigned(step: 2, label: 'Assigned'),
  inProgress(step: 3, label: 'In Progress'),
  completed(step: 4, label: 'Completed');

  const ConciergeStage({required this.step, required this.label});
  final int step;
  final String label;

  ConciergeStage get nextStage {
    switch (this) {
      case ConciergeStage.requested:
        return ConciergeStage.assigned;
      case ConciergeStage.assigned:
        return ConciergeStage.inProgress;
      case ConciergeStage.inProgress:
      case ConciergeStage.completed:
        return ConciergeStage.completed;
    }
  }
}

/// Live chat message between guest and Concierge HOST ADMIN (`FR-09`).
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderName,
    required this.isFromHost,
    required this.text,
    required this.timestampLabel,
  });

  final String id;
  final String senderName;
  final bool isFromHost;
  final String text;
  final String timestampLabel;
}

/// 24/7 Concierge service request with 4-stage progress & photo URL (`FR-09`).
class ConciergeRequest {
  const ConciergeRequest({
    required this.id,
    required this.title,
    required this.category,
    required this.timestampLabel,
    required this.stage,
    required this.assignedTo,
    required this.details,
    this.photoUrl,
  });

  final String id;
  final String title;
  final String category;
  final String timestampLabel;
  final ConciergeStage stage;
  final String assignedTo;
  final String details;
  final String? photoUrl;

  int get currentStep => stage.step;
  bool get isCompleted => stage == ConciergeStage.completed;

  ConciergeRequest copyWith({ConciergeStage? stage, String? photoUrl}) {
    return ConciergeRequest(
      id: id,
      title: title,
      category: category,
      timestampLabel: timestampLabel,
      stage: stage ?? this.stage,
      assignedTo: assignedTo,
      details: details,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

/// Proactive Mid-Stay Check-In pulse model (`FR-10`).
class MidStayCheckIn {
  const MidStayCheckIn({
    required this.rating,
    required this.sentimentId,
    required this.housekeepingWindow,
    required this.focusAreas,
    required this.notes,
    required this.requestPriorityCallback,
    required this.submittedAtLabel,
  });

  final int rating;
  final String sentimentId;
  final String housekeepingWindow;
  final List<String> focusAreas;
  final String notes;
  final bool requestPriorityCallback;
  final String submittedAtLabel;
}

/// Folio line item separating `$0.00` Included Privileges from paid incidentals (`FR-11`).
class FolioLineItem {
  const FolioLineItem({
    required this.id,
    required this.title,
    String? subtitle,
    this.category = 'Incidentals',
    this.timestampLabel = 'Stay',
    required this.amountUsd,
    required this.isIncludedPrivilege,
    this.retailValuationUsd,
  }) : subtitle = subtitle ??
            (isIncludedPrivilege
                ? 'Included Sanctuary Privilege · $category'
                : '$category · $timestampLabel');

  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String timestampLabel;
  final int amountUsd;
  final bool isIncludedPrivilege;
  final int? retailValuationUsd;
}
