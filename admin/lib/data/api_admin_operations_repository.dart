import '../domain/admin_entities.dart';
import '../domain/admin_enums.dart';
import '../domain/admin_repository.dart';
import '../domain/admin_stay_entities.dart';
import 'admin_api_client.dart';
import 'admin_wire_mapper.dart';
import 'seeded_admin_repository.dart';

/// Offline-resilient hybrid repository that communicates with `/api/v1/admin/*`
/// and deterministically falls back to [SeededAdminRepository] when offline.
class ApiAdminOperationsRepository implements AdminOperationsRepository {
  ApiAdminOperationsRepository({
    AdminApiClient? apiClient,
    SeededAdminRepository? fallbackRepository,
    this.enableNetwork = true,
  }) : _apiClient = apiClient ?? AdminApiClient() {
    _fallback = fallbackRepository ??
        SeededAdminRepository(apiClient: enableNetwork ? _apiClient : null);
  }

  final AdminApiClient _apiClient;
  late final SeededAdminRepository _fallback;
  final bool enableNetwork;

  @override
  Future<void> resetAllData() async {
    if (enableNetwork) {
      try {
        await _apiClient.postJson('/reset', {});
      } catch (_) {}
    }
    await _fallback.resetAllData();
  }

  @override
  Future<List<StaffMember>> fetchStaffDirectory() async {
    if (enableNetwork) {
      try {
        await _apiClient.getJson('/staff');
      } catch (_) {}
    }
    return _fallback.fetchStaffDirectory();
  }

  @override
  Future<List<OperationalAlert>> fetchAlerts() async {
    if (!enableNetwork) return _fallback.fetchAlerts();
    try {
      final parsed =
          AdminWireMapper.parseAlerts(await _apiClient.getJson('/alerts'));
      _fallback.syncCache(alerts: parsed);
      return parsed;
    } catch (_) {
      return _fallback.fetchAlerts();
    }
  }

  @override
  Future<OperationalAlert> acknowledgeAlert(
          {required String alertId, required String staffId}) =>
      _fallback.acknowledgeAlert(alertId: alertId, staffId: staffId);

  @override
  Future<List<AdminStayRecord>> fetchStays() async {
    if (!enableNetwork) return _fallback.fetchStays();
    try {
      final raw = await _apiClient.getJson('/stays');
      final parsed = AdminWireMapper.parseStays(raw);
      final folios = AdminWireMapper.parseFolioItemsFromStays(
          AdminWireMapper.extractMapList(raw));
      _fallback.syncCache(stays: parsed, folioItems: folios);
      return parsed;
    } catch (_) {
      return _fallback.fetchStays();
    }
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
  }) async {
    if (!enableNetwork) {
      return _fallback.createStay(
          villaName: villaName,
          guestNames: guestNames,
          checkInDate: checkInDate,
          checkOutDate: checkOutDate,
          occasion: occasion,
          wifiSsid: wifiSsid,
          wifiPasscode: wifiPasscode);
    }
    try {
      final res = await _apiClient.postJson('/stays', {
        'guestName': guestNames,
        'villaId': villaName,
        'villaName': villaName,
        'checkIn': checkInDate,
        'checkOut': checkOutDate,
        'occasion': occasion,
        if (wifiSsid != null && wifiSsid.isNotEmpty) 'wifiSsid': wifiSsid,
        if (wifiPasscode != null && wifiPasscode.isNotEmpty)
          'wifiPasscode': wifiPasscode,
      });
      if (res['stay'] is Map) {
        final mapped = AdminWireMapper.mapStay(
            Map<String, dynamic>.from(res['stay'] as Map));
        _fallback.upsertStay(mapped);
        return mapped;
      }
      return _fallback.createStayLocal(
          villaName: villaName,
          guestNames: guestNames,
          checkInDate: checkInDate,
          checkOutDate: checkOutDate,
          occasion: occasion,
          wifiSsid: wifiSsid,
          wifiPasscode: wifiPasscode,
          uuidOverride: res['guestTokenUuid'] as String?);
    } catch (_) {
      return _fallback.createStayLocal(
          villaName: villaName,
          guestNames: guestNames,
          checkInDate: checkInDate,
          checkOutDate: checkOutDate,
          occasion: occasion,
          wifiSsid: wifiSsid,
          wifiPasscode: wifiPasscode);
    }
  }

  @override
  Future<AdminStayRecord> regenerateGuestUuid(String stayId) =>
      _fallback.regenerateGuestUuid(stayId);

  @override
  Future<AdminStayRecord> updateStayLifecycle(
          {required String stayId, required StayLifecycleStatus status}) =>
      _fallback.updateStayLifecycle(stayId: stayId, status: status);

  @override
  Future<AdminStayRecord> updateStayWifi({
    required String stayId,
    required String wifiSsid,
    required String wifiPasscode,
  }) =>
      _fallback.updateStayWifi(
          stayId: stayId, wifiSsid: wifiSsid, wifiPasscode: wifiPasscode);

  @override
  Future<AdminStayRecord> updateTransferDispatch({
    required String stayId,
    required String chauffeurId,
    required String transferStatus,
    String? driverAndVehicle,
    String? meetingPoint,
  }) =>
      _fallback.updateTransferDispatch(
          stayId: stayId,
          chauffeurId: chauffeurId,
          transferStatus: transferStatus,
          driverAndVehicle: driverAndVehicle,
          meetingPoint: meetingPoint);

  @override
  Future<List<AdminBookingRecord>> fetchBookings() async {
    if (!enableNetwork) return _fallback.fetchBookings();
    try {
      final raw = await _apiClient.getJson('/bookings');
      final parsed =
          AdminWireMapper.parseBookings(raw, await _fallback.fetchStays());
      _fallback.syncCache(bookings: parsed);
      return parsed;
    } catch (_) {
      return _fallback.fetchBookings();
    }
  }

  @override
  Future<AdminBookingRecord> assignAndUpdateBooking({
    required String bookingId,
    required String staffId,
    required String status,
    String? cancellationReason,
  }) =>
      _fallback.assignAndUpdateBooking(
          bookingId: bookingId,
          staffId: staffId,
          status: status,
          cancellationReason: cancellationReason);

  @override
  Future<List<AdminExperienceCatalogItem>> fetchExperienceCatalog() async {
    if (!enableNetwork) return _fallback.fetchExperienceCatalog();
    try {
      final parsed = AdminWireMapper.parseExperienceCatalog(
          await _apiClient.getJson('/catalog/experiences'));
      if (parsed.isNotEmpty) _fallback.syncCache(experienceCatalog: parsed);
      return parsed.isNotEmpty
          ? parsed
          : await _fallback.fetchExperienceCatalog();
    } catch (_) {
      return _fallback.fetchExperienceCatalog();
    }
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
      _fallback.createExperienceCatalogItem(
          title: title,
          category: category,
          duration: duration,
          basePriceUSD: basePriceUSD,
          isIncluded: isIncluded,
          description: description);

  @override
  Future<void> deleteExperienceCatalogItem(String id) =>
      _fallback.deleteExperienceCatalogItem(id);

  @override
  Future<List<AdminLarderOrder>> fetchLarderOrders() async {
    if (!enableNetwork) return _fallback.fetchLarderOrders();
    try {
      final raw = await _apiClient.getJson('/larder-orders');
      final parsed =
          AdminWireMapper.parseLarderOrders(raw, await _fallback.fetchStays());
      _fallback.syncCache(larderOrders: parsed);
      return parsed;
    } catch (_) {
      return _fallback.fetchLarderOrders();
    }
  }

  @override
  Future<AdminLarderOrder> updateLarderOrder({
    required String orderId,
    required String status,
    required String staffId,
  }) =>
      _fallback.updateLarderOrder(
          orderId: orderId, status: status, staffId: staffId);

  @override
  Future<List<AdminLarderCatalogItem>> fetchLarderCatalog() async {
    if (!enableNetwork) return _fallback.fetchLarderCatalog();
    try {
      final parsed = AdminWireMapper.parseLarderCatalog(
          await _apiClient.getJson('/catalog/larder'));
      if (parsed.isNotEmpty) _fallback.syncCache(larderCatalog: parsed);
      return parsed.isNotEmpty ? parsed : await _fallback.fetchLarderCatalog();
    } catch (_) {
      return _fallback.fetchLarderCatalog();
    }
  }

  @override
  Future<AdminLarderCatalogItem> createLarderCatalogItem({
    required String name,
    required String category,
    required double price,
    required String storageType,
    String description = '',
  }) =>
      _fallback.createLarderCatalogItem(
          name: name,
          category: category,
          price: price,
          storageType: storageType,
          description: description);

  @override
  Future<void> deleteLarderCatalogItem(String id) =>
      _fallback.deleteLarderCatalogItem(id);

  @override
  Future<List<AdminConciergeTicket>> fetchConciergeTickets() async {
    if (!enableNetwork) return _fallback.fetchConciergeTickets();
    try {
      final raw = await _apiClient.getJson('/concierge-requests');
      final parsed = AdminWireMapper.parseConciergeTickets(
          raw, await _fallback.fetchStays());
      _fallback.syncCache(tickets: parsed);
      return parsed;
    } catch (_) {
      return _fallback.fetchConciergeTickets();
    }
  }

  @override
  Future<AdminConciergeTicket> updateConciergeTicket({
    required String requestId,
    required ConciergeStage stage,
    String? staffId,
  }) =>
      _fallback.updateConciergeTicket(
          requestId: requestId, stage: stage, staffId: staffId);

  @override
  Future<AdminConciergeTicket> appendConciergeReply({
    required String requestId,
    required String senderName,
    required String senderRole,
    required String messageText,
  }) =>
      _fallback.appendConciergeReply(
          requestId: requestId,
          senderName: senderName,
          senderRole: senderRole,
          messageText: messageText);

  @override
  Future<List<AdminMidStayPulse>> fetchMidStayPulses() async {
    if (!enableNetwork) return _fallback.fetchMidStayPulses();
    try {
      final raw = await _apiClient.getJson('/midstay-feedback');
      final parsed =
          AdminWireMapper.parseMidStayPulses(raw, await _fallback.fetchStays());
      _fallback.syncCache(pulses: parsed);
      return parsed;
    } catch (_) {
      return _fallback.fetchMidStayPulses();
    }
  }

  @override
  Future<AdminMidStayPulse> attendMidStayPulse({
    required String checkInId,
    required String followUpNote,
    required String staffName,
  }) =>
      _fallback.attendMidStayPulse(
          checkInId: checkInId,
          followUpNote: followUpNote,
          staffName: staffName);

  @override
  Future<List<FolioLineItem>> fetchFolioItems(String stayId) async {
    if (!enableNetwork) return _fallback.fetchFolioItems(stayId);
    try {
      final raw = await _apiClient.getJson('/stays');
      final parsed = AdminWireMapper.parseFolioItemsFromStays(
          AdminWireMapper.extractMapList(raw));
      _fallback.syncCache(folioItems: parsed);
      return parsed;
    } catch (_) {
      return _fallback.fetchFolioItems(stayId);
    }
  }

  @override
  Future<List<FolioLineItem>> addFolioItem({
    required String stayId,
    required String title,
    required String categoryLabel,
    required double amountUsd,
  }) =>
      _fallback.addFolioItem(
          stayId: stayId,
          title: title,
          categoryLabel: categoryLabel,
          amountUsd: amountUsd);

  @override
  Future<AdminStayRecord> approveExpressCheckout(
          {required String stayId, required bool approveLateCheckout}) =>
      _fallback.approveExpressCheckout(
          stayId: stayId, approveLateCheckout: approveLateCheckout);

  @override
  void dispose() {
    _apiClient.dispose();
    _fallback.dispose();
  }
}
