import '../domain/admin_entities.dart';
import '../domain/admin_enums.dart';
import '../domain/admin_stay_entities.dart';
import 'admin_cached_records.dart';

/// Applies a server-confirmed mutation to the write-through cache lists.
class AdminCacheMutations {
  const AdminCacheMutations._();

  static AdminConciergeTicket applyStageUpdate({
    required List<AdminConciergeTicket> tickets,
    required AdminConciergeTicket current,
    required ConciergeStage stage,
    required StaffMember? staff,
    required String nowIso,
  }) =>
      CachedRecords.replace(
          tickets,
          (t) => t.requestId,
          current.copyWith(
            stage: stage,
            assignedStaffId: staff?.staffId,
            assignedStaffName: staff?.shortName,
            department: staff?.department,
            notifiedAt: nowIso,
          ));

  static AdminConciergeTicket applyReply({
    required List<AdminConciergeTicket> tickets,
    required AdminConciergeTicket current,
    required String senderName,
    required String senderRole,
    required String messageText,
  }) {
    final newMsg = ConciergeChatMessage(
      messageId: 'msg_${current.messages.length + 1}',
      senderName: senderName,
      senderRole: senderRole,
      body: messageText,
      timestampLabel: 'Just now',
      isStaff: true,
    );
    return CachedRecords.replace(tickets, (t) => t.requestId,
        current.copyWith(messages: [...current.messages, newMsg]));
  }

  static AdminMidStayPulse applyPulseUpdate({
    required List<AdminMidStayPulse> pulses,
    required AdminMidStayPulse current,
    required String followUpNote,
    required String staffName,
  }) =>
      CachedRecords.replace(
          pulses,
          (p) => p.checkInId,
          current.copyWith(
            status: 'ATTENDED',
            followUpNote: followUpNote,
            handledByStaffName: staffName,
          ));

  static List<FolioLineItem> applyAddedFolioItem({
    required List<FolioLineItem> items,
    required String title,
    required String categoryLabel,
    required double amountUsd,
  }) {
    items.add(
      FolioLineItem(
        itemId: 'fol_custom_${items.length + 1}',
        title: title,
        categoryLabel: categoryLabel,
        amountUsd: amountUsd,
        isIncludedPrivilege: amountUsd == 0,
      ),
    );
    return List.unmodifiable(items);
  }
}
