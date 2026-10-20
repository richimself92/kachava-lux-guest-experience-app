import 'admin_entities.dart';
import 'admin_enums.dart';
import 'admin_stay_entities.dart';

/// Clean Architecture Repository contract for Kachava Lux Admin Operations.
abstract class AdminOperationsRepository {
  Future<List<StaffMember>> fetchStaffDirectory();

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

  Future<List<AdminExperienceCatalogItem>> fetchExperienceCatalog();

  Future<AdminExperienceCatalogItem> createExperienceCatalogItem({
    required String title,
    required String category,
    required String duration,
    required double basePriceUSD,
    bool isIncluded = false,
    String description = '',
  });

  Future<void> deleteExperienceCatalogItem(String id);

  Future<List<AdminLarderOrder>> fetchLarderOrders();

  Future<AdminLarderOrder> updateLarderOrder({
    required String orderId,
    required String status,
    required String staffId,
  });

  Future<List<AdminLarderCatalogItem>> fetchLarderCatalog();

  Future<AdminLarderCatalogItem> createLarderCatalogItem({
    required String name,
    required String category,
    required double price,
    required String storageType,
    String description = '',
  });

  Future<void> deleteLarderCatalogItem(String id);

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

  Future<void> resetAllData();

  void dispose();
}
