import '../domain/admin_entities.dart';
import '../domain/admin_enums.dart';
import '../domain/admin_repository.dart';
import '../domain/admin_stay_entities.dart';
import '../domain/admin_sync_snapshot.dart';
import '../domain/admin_villa_directory.dart';
import 'admin_api_client.dart';
import 'admin_staff_mapper.dart';
import 'admin_sync_mapper.dart';
import 'admin_wire_mapper.dart';
import 'admin_write_through_cache.dart';

/// Live repository for `/api/v1/admin/*`.
///
/// Reads always come from the server and failures propagate: no seeded or
/// fixture data is ever presented as live. Mutations go through a
/// write-through cache that starts empty and only applies server-confirmed
/// changes.
class ApiAdminOperationsRepository implements AdminOperationsRepository {
  ApiAdminOperationsRepository({AdminApiClient? apiClient})
      : _apiClient = apiClient ?? AdminApiClient() {
    _cache = AdminWriteThroughCache(gateway: _apiClient);
  }

  final AdminApiClient _apiClient;
  late final AdminWriteThroughCache _cache;

  @override
  Future<AdminSyncSnapshot> fetchSnapshot() async {
    final snapshot = AdminSyncMapper.parse(await _apiClient.getJson('/sync'));
    _cache.applySnapshot(snapshot);
    return snapshot;
  }

  @override
  Future<void> resetAllData() => _cache.resetAllData();

  /// Live staff roster from `GET /admin/staff`.
  @override
  Future<List<StaffMember>> fetchStaffDirectory() async {
    final staff =
        AdminStaffMapper.parseDirectory(await _apiClient.getJson('/staff'));
    _cache.syncStaff(staff);
    return staff;
  }

  @override
  StaffMember? get sessionStaff => _apiClient.session.staff;

  /// Derived from server stays until the API exposes a villas endpoint.
  @override
  List<AdminVillaInfo> villasFor(List<AdminStayRecord> stays) =>
      AdminVillaDirectory.fromStays(stays);

  @override
  Future<List<OperationalAlert>> fetchAlerts() async {
    final parsed =
        AdminWireMapper.parseAlerts(await _apiClient.getJson('/alerts'));
    _cache.syncCache(alerts: parsed);
    return parsed;
  }

  @override
  Future<OperationalAlert> acknowledgeAlert(
          {required String alertId, required String staffId}) =>
      _cache.acknowledgeAlert(alertId: alertId, staffId: staffId);

  @override
  Future<List<AdminStayRecord>> fetchStays() async {
    final raw = await _apiClient.getJson('/stays');
    final parsed = AdminWireMapper.parseStays(raw);
    _cache.syncCache(
        stays: parsed,
        folioItems: AdminWireMapper.parseFolioItemsFromStays(
            AdminWireMapper.extractMapList(raw)));
    return parsed;
  }

  @override
  Future<AdminStayRecord> createStay({
    required String villaName,
    required String guestNames,
    required String checkInDate,
    required String checkOutDate,
    required String occasion,
    String? wifiSsid,
    String? wifiPasscode,
  }) =>
      _cache.createStay(
          villaName: villaName,
          guestNames: guestNames,
          checkInDate: checkInDate,
          checkOutDate: checkOutDate,
          occasion: occasion,
          wifiSsid: wifiSsid,
          wifiPasscode: wifiPasscode);

  @override
  Future<AdminStayRecord> regenerateGuestUuid(String stayId) =>
      _cache.regenerateGuestUuid(stayId);

  @override
  Future<AdminStayRecord> updateStayLifecycle(
          {required String stayId, required StayLifecycleStatus status}) =>
      _cache.updateStayLifecycle(stayId: stayId, status: status);

  @override
  Future<AdminStayRecord> updateStayWifi({
    required String stayId,
    required String wifiSsid,
    required String wifiPasscode,
  }) =>
      _cache.updateStayWifi(
          stayId: stayId, wifiSsid: wifiSsid, wifiPasscode: wifiPasscode);

  @override
  Future<AdminStayRecord> updateTransferDispatch({
    required String stayId,
    required String chauffeurId,
    required String transferStatus,
    String? driverAndVehicle,
    String? meetingPoint,
  }) =>
      _cache.updateTransferDispatch(
          stayId: stayId,
          chauffeurId: chauffeurId,
          transferStatus: transferStatus,
          driverAndVehicle: driverAndVehicle,
          meetingPoint: meetingPoint);

  @override
  Future<List<AdminBookingRecord>> fetchBookings() async {
    final parsed = AdminWireMapper.parseBookings(
        await _apiClient.getJson('/bookings'), await _cache.fetchStays());
    _cache.syncCache(bookings: parsed);
    return parsed;
  }

  @override
  Future<AdminBookingRecord> assignAndUpdateBooking({
    required String bookingId,
    required String staffId,
    required String status,
    String? cancellationReason,
  }) =>
      _cache.assignAndUpdateBooking(
          bookingId: bookingId,
          staffId: staffId,
          status: status,
          cancellationReason: cancellationReason);

  @override
  Future<List<AdminExperienceCatalogItem>> fetchExperienceCatalog() async {
    final parsed = AdminWireMapper.parseExperienceCatalog(
        await _apiClient.getJson('/catalog/experiences'));
    _cache.syncCache(experienceCatalog: parsed);
    return parsed;
  }

  @override
  Future<AdminExperienceCatalogItem> createExperienceCatalogItem({
    required String title,
    required String category,
    required String duration,
    required double basePriceUSD,
    bool isIncluded = false,
    String description = '',
  }) =>
      _cache.createExperienceCatalogItem(
          title: title,
          category: category,
          duration: duration,
          basePriceUSD: basePriceUSD,
          isIncluded: isIncluded,
          description: description);

  @override
  Future<void> deleteExperienceCatalogItem(String id) =>
      _cache.deleteExperienceCatalogItem(id);

  @override
  Future<List<AdminLarderOrder>> fetchLarderOrders() async {
    final parsed = AdminWireMapper.parseLarderOrders(
        await _apiClient.getJson('/larder-orders'), await _cache.fetchStays());
    _cache.syncCache(larderOrders: parsed);
    return parsed;
  }

  @override
  Future<AdminLarderOrder> updateLarderOrder({
    required String orderId,
    required String status,
    required String staffId,
  }) =>
      _cache.updateLarderOrder(
          orderId: orderId, status: status, staffId: staffId);

  @override
  Future<List<AdminLarderCatalogItem>> fetchLarderCatalog() async {
    final parsed = AdminWireMapper.parseLarderCatalog(
        await _apiClient.getJson('/catalog/larder'));
    _cache.syncCache(larderCatalog: parsed);
    return parsed;
  }

  @override
  Future<AdminLarderCatalogItem> createLarderCatalogItem({
    required String name,
    required String category,
    required double price,
    required String storageType,
    String description = '',
  }) =>
      _cache.createLarderCatalogItem(
          name: name,
          category: category,
          price: price,
          storageType: storageType,
          description: description);

  @override
  Future<void> deleteLarderCatalogItem(String id) =>
      _cache.deleteLarderCatalogItem(id);

  @override
  Future<List<AdminConciergeTicket>> fetchConciergeTickets() async {
    final parsed = AdminWireMapper.parseConciergeTickets(
        await _apiClient.getJson('/concierge-requests'),
        await _cache.fetchStays());
    _cache.syncCache(tickets: parsed);
    return parsed;
  }

  @override
  Future<AdminConciergeTicket> updateConciergeTicket({
    required String requestId,
    required ConciergeStage stage,
    String? staffId,
  }) =>
      _cache.updateConciergeTicket(
          requestId: requestId, stage: stage, staffId: staffId);

  @override
  Future<AdminConciergeTicket> appendConciergeReply({
    required String requestId,
    required String senderName,
    required String senderRole,
    required String messageText,
  }) =>
      _cache.appendConciergeReply(
          requestId: requestId,
          senderName: senderName,
          senderRole: senderRole,
          messageText: messageText);

  @override
  Future<List<AdminMidStayPulse>> fetchMidStayPulses() async {
    final parsed = AdminWireMapper.parseMidStayPulses(
        await _apiClient.getJson('/midstay-feedback'),
        await _cache.fetchStays());
    _cache.syncCache(pulses: parsed);
    return parsed;
  }

  @override
  Future<AdminMidStayPulse> attendMidStayPulse({
    required String checkInId,
    required String followUpNote,
    required String staffName,
  }) =>
      _cache.attendMidStayPulse(
          checkInId: checkInId,
          followUpNote: followUpNote,
          staffName: staffName);

  @override
  Future<List<FolioLineItem>> fetchFolioItems(String stayId) async {
    await fetchStays();
    return _cache.fetchFolioItems(stayId);
  }

  @override
  Future<List<FolioLineItem>> addFolioItem({
    required String stayId,
    required String title,
    required String categoryLabel,
    required double amountUsd,
  }) =>
      _cache.addFolioItem(
          stayId: stayId,
          title: title,
          categoryLabel: categoryLabel,
          amountUsd: amountUsd);

  @override
  Future<AdminStayRecord> approveExpressCheckout(
          {required String stayId, required bool approveLateCheckout}) =>
      _cache.approveExpressCheckout(
          stayId: stayId, approveLateCheckout: approveLateCheckout);

  @override
  void clearCache() => _cache.clearCache();

  @override
  void dispose() => _cache.dispose();
}
