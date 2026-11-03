import 'admin_entities.dart';
import 'admin_enums.dart';
import 'admin_stay_entities.dart';
import 'admin_sync_snapshot.dart';

/// Clean Architecture Repository contract for Kachava Lux Admin Operations.
abstract class AdminOperationsRepository {
  /// One server-confirmed read of every live collection (`GET /admin/sync`).
  Future<AdminSyncSnapshot> fetchSnapshot();

  Future<List<StaffMember>> fetchStaffDirectory();

  /// Staff member of the open session (the one mutations are attributed to),
  /// or null when no signed-in staff is known.
  StaffMember? get sessionStaff;

  /// Villas this source knows about, given the current [stays].
  List<AdminVillaInfo> villasFor(List<AdminStayRecord> stays);

  Future<List<OperationalAlert>> fetchAlerts();

  Future<OperationalAlert> acknowledgeAlert({
    required String alertId,
    required String staffId,
  });

  Future<List<AdminStayRecord>> fetchStays();

  Future<AdminStayRecord> createStay({
    required String villaName,
    required String guestNames,
    required String checkInDate,
    required String checkOutDate,
    required String occasion,
    String? wifiSsid,
    String? wifiPasscode,
  });

  Future<AdminStayRecord> regenerateGuestUuid(String stayId);

  Future<AdminStayRecord> updateStayLifecycle({
    required String stayId,
    required StayLifecycleStatus status,
  });

  Future<AdminStayRecord> updateStayWifi({
    required String stayId,
    required String wifiSsid,
    required String wifiPasscode,
  });

  Future<AdminStayRecord> updateTransferDispatch({
    required String stayId,
    required String chauffeurId,
    required String transferStatus,
    String? driverAndVehicle,
    String? meetingPoint,
  });

  Future<List<AdminBookingRecord>> fetchBookings();

  Future<AdminBookingRecord> assignAndUpdateBooking({
    required String bookingId,
    required String staffId,
    required String status,
    String? cancellationReason,
  });

  Future<List<AdminLarderOrder>> fetchLarderOrders();

  Future<AdminLarderOrder> updateLarderOrder({
    required String orderId,
    required String status,
    required String staffId,
  });

  Future<List<AdminConciergeTicket>> fetchConciergeTickets();

  Future<AdminConciergeTicket> updateConciergeTicket({
    required String requestId,
    required ConciergeStage stage,
    String? staffId,
  });

  Future<AdminConciergeTicket> appendConciergeReply({
    required String requestId,
    required String senderName,
    required String senderRole,
    required String messageText,
  });

  Future<List<AdminMidStayPulse>> fetchMidStayPulses();

  Future<AdminMidStayPulse> attendMidStayPulse({
    required String checkInId,
    required String followUpNote,
    required String staffName,
  });

  Future<List<FolioLineItem>> fetchFolioItems(String stayId);

  Future<List<FolioLineItem>> addFolioItem({
    required String stayId,
    required String title,
    required String categoryLabel,
    required double amountUsd,
  });

  Future<AdminStayRecord> approveExpressCheckout({
    required String stayId,
    required bool approveLateCheckout,
  });

  /// Drops every cached record of the previous staff session.
  void clearCache();

  void dispose();
}
