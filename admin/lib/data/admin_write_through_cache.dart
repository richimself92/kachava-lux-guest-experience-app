import '../domain/admin_entities.dart';
import '../domain/admin_enums.dart';
import '../domain/admin_repository.dart';
import '../domain/admin_stay_entities.dart';
import '../domain/admin_sync_snapshot.dart';
import '../domain/admin_villa_directory.dart';
import 'admin_cache_mutations.dart';
import 'admin_cached_records.dart';
import 'admin_server_confirmation.dart';
import 'admin_wire_mapper.dart';
import 'admin_wire_values.dart';
import 'admin_write_gateway.dart';

/// Write-through cache of server records (starts empty).
///
/// Every mutation is sent to `/api/v1/admin/*` through the [AdminWriteGateway]
/// first and applied locally only after the server confirms; failures
/// propagate and nothing is invented. There is no seeded or offline mode.
class AdminWriteThroughCache implements AdminOperationsRepository {
  AdminWriteThroughCache({
    required AdminWriteGateway gateway,
    AdminSyncSnapshot initialData = AdminSyncSnapshot.empty,
  }) : _gateway = gateway {
    applySnapshot(initialData);
  }

  final AdminWriteGateway _gateway;
  final List<StaffMember> _staff = [];
  final List<AdminStayRecord> _stays = [];
  final List<OperationalAlert> _alerts = [];
  final List<AdminBookingRecord> _bookings = [];
  final List<AdminLarderOrder> _larderOrders = [];
  final List<AdminConciergeTicket> _tickets = [];
  final List<AdminMidStayPulse> _pulses = [];
  final List<FolioLineItem> _folioItems = [];
  final List<AdminExperienceCatalogItem> _experienceCatalog = [];
  final List<AdminLarderCatalogItem> _larderCatalog = [];

  void applySnapshot(AdminSyncSnapshot s) => syncCache(
      stays: s.stays,
      alerts: s.alerts,
      bookings: s.bookings,
      larderOrders: s.larderOrders,
      tickets: s.conciergeTickets,
      pulses: s.midStayPulses,
      folioItems: s.folioItems,
      experienceCatalog: s.experienceCatalog,
      larderCatalog: s.larderCatalog);

  void syncCache({
    List<OperationalAlert>? alerts,
    List<AdminStayRecord>? stays,
    List<AdminBookingRecord>? bookings,
    List<AdminLarderOrder>? larderOrders,
    List<AdminConciergeTicket>? tickets,
    List<AdminMidStayPulse>? pulses,
    List<FolioLineItem>? folioItems,
    List<AdminExperienceCatalogItem>? experienceCatalog,
    List<AdminLarderCatalogItem>? larderCatalog,
  }) {
    _replace(_alerts, alerts);
    _replace(_stays, stays);
    _replace(_bookings, bookings);
    _replace(_larderOrders, larderOrders);
    _replace(_tickets, tickets);
    _replace(_pulses, pulses);
    _replace(_folioItems, folioItems);
    _replace(_experienceCatalog, experienceCatalog);
    _replace(_larderCatalog, larderCatalog);
  }

  static void _replace<T>(List<T> target, List<T>? values) {
    if (values != null) target.replaceRange(0, target.length, values);
  }

  /// Drops every cached record and the roster (e.g. on a staff switch).
  @override
  void clearCache() {
    applySnapshot(AdminSyncSnapshot.empty);
    _staff.clear();
  }

  /// Replaces the cached roster with the server-confirmed one.
  void syncStaff(List<StaffMember> staff) => _replace(_staff, staff);

  void upsertStay(AdminStayRecord stay) {
    _stays.removeWhere((s) => s.stayId == stay.stayId);
    _stays.insert(0, stay);
  }

  @override
  Future<AdminSyncSnapshot> fetchSnapshot() async => AdminSyncSnapshot(
      stays: List.unmodifiable(_stays),
      alerts: List.unmodifiable(_alerts),
      bookings: List.unmodifiable(_bookings),
      larderOrders: List.unmodifiable(_larderOrders),
      conciergeTickets: List.unmodifiable(_tickets),
      midStayPulses: List.unmodifiable(_pulses),
      experienceCatalog: List.unmodifiable(_experienceCatalog),
      larderCatalog: List.unmodifiable(_larderCatalog),
      folioItems: List.unmodifiable(_folioItems));

  @override
  Future<void> resetAllData() async {
    await _syncPost('/reset', {});
    syncCache(
        stays: const [],
        alerts: const [],
        bookings: const [],
        larderOrders: const [],
        tickets: const [],
        pulses: const [],
        folioItems: const []);
  }

  @override
  Future<List<StaffMember>> fetchStaffDirectory() async =>
      List.unmodifiable(_staff);

  /// The signed-in staff member comes from the API session, not the cache.
  @override
  StaffMember? get sessionStaff => null;

  /// Villas known from server stays.
  @override
  List<AdminVillaInfo> villasFor(List<AdminStayRecord> stays) =>
      AdminVillaDirectory.fromStays(stays);
  @override
  Future<List<OperationalAlert>> fetchAlerts() async =>
      List.unmodifiable(_alerts);
  @override
  Future<List<AdminStayRecord>> fetchStays() async => List.unmodifiable(_stays);
  @override
  Future<List<AdminBookingRecord>> fetchBookings() async =>
      List.unmodifiable(_bookings);
  @override
  Future<List<AdminExperienceCatalogItem>> fetchExperienceCatalog() async =>
      List.unmodifiable(_experienceCatalog);
  @override
  Future<List<AdminLarderOrder>> fetchLarderOrders() async =>
      List.unmodifiable(_larderOrders);
  @override
  Future<List<AdminLarderCatalogItem>> fetchLarderCatalog() async =>
      List.unmodifiable(_larderCatalog);
  @override
  Future<List<AdminConciergeTicket>> fetchConciergeTickets() async =>
      List.unmodifiable(_tickets);
  @override
  Future<List<AdminMidStayPulse>> fetchMidStayPulses() async =>
      List.unmodifiable(_pulses);
  @override
  Future<List<FolioLineItem>> fetchFolioItems(String stayId) async =>
      List.unmodifiable(_folioItems);

  @override
  Future<OperationalAlert> acknowledgeAlert(
      {required String alertId, required String staffId}) async {
    final cur = CachedRecords.find(_alerts, (a) => a.alertId, alertId);
    await _syncPatch('/alerts/$alertId/acknowledge', {'staffId': staffId});
    return CachedRecords.replace<OperationalAlert>(_alerts, (a) => a.alertId,
        cur.copyWith(isAcknowledged: true, acknowledgedByStaffId: staffId));
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
    final payload = {
      'guestName': guestNames,
      'villaId': villaName,
      'villaName': villaName,
      'checkIn': checkInDate,
      'checkOut': checkOutDate,
      'occasion': occasion,
      if (wifiSsid != null && wifiSsid.isNotEmpty) 'wifiSsid': wifiSsid,
      if (wifiPasscode != null && wifiPasscode.isNotEmpty)
        'wifiPasscode': wifiPasscode,
    };
    final created = AdminServerConfirmation.createdStay(
        await _gateway.postJson('/stays', payload));
    upsertStay(created);
    return created;
  }

  @override
  Future<AdminStayRecord> regenerateGuestUuid(String stayId) async {
    final cur = _stay(stayId);
    final rotated = AdminServerConfirmation.rotatedToken(
        await _gateway.postJson('/stays/$stayId/regenerate-token', {}));
    return _putStay(cur.copyWith(guestTokenUuid: rotated));
  }

  @override
  Future<AdminStayRecord> updateStayLifecycle(
      {required String stayId, required StayLifecycleStatus status}) async {
    final cur = _stay(stayId);
    await _syncPatch('/stays/$stayId/status', {'status': status.label});
    return _putStay(cur.copyWith(lifecycleStatus: status));
  }

  @override
  Future<AdminStayRecord> updateStayWifi(
      {required String stayId,
      required String wifiSsid,
      required String wifiPasscode}) async {
    final cur = _stay(stayId);
    await _syncPatch('/stays/$stayId/wifi',
        {'wifiSsid': wifiSsid, 'wifiPasscode': wifiPasscode});
    return _putStay(
        cur.copyWith(wifiSsid: wifiSsid, wifiPasscode: wifiPasscode));
  }

  @override
  Future<AdminStayRecord> updateTransferDispatch({
    required String stayId,
    required String chauffeurId,
    required String transferStatus,
    String? driverAndVehicle,
    String? meetingPoint,
  }) async {
    final staff = _findStaff(chauffeurId),
        drv = WireValues.blankToNull(driverAndVehicle),
        meet = WireValues.blankToNull(meetingPoint),
        stay = _stay(stayId);
    await _syncPatch('/stays/$stayId/transfer', {
      'status': transferStatus,
      if (staff != null) 'assignedStaffId': staff.staffId,
      if ((drv ?? staff?.shortName) != null)
        'assignedStaffName': drv ?? staff?.shortName,
      if (drv != null) 'assignedDriver': drv,
      if (drv != null) 'vehicleModel': drv,
      if (meet != null) 'meetingPoint': meet,
      if (meet != null) 'adminDispatchNotes': meet,
    });
    return _putStay(stay.copyWith(
        transfer:
            _dispatched(stay.transfer, staff, drv, meet, transferStatus)));
  }

  static AviationTransferInfo _dispatched(AviationTransferInfo cur,
          StaffMember? staff, String? drv, String? meet, String status) =>
      cur.copyWith(
          assignedChauffeurId: staff?.staffId ?? '',
          assignedChauffeurName: drv ??
              (cur.assignedChauffeurName.isNotEmpty
                  ? cur.assignedChauffeurName
                  : staff?.shortName ?? ''),
          vehicleLabel: drv ?? cur.vehicleLabel,
          cabinBeverage: meet ?? cur.cabinBeverage,
          outboundRoute: meet ?? cur.outboundRoute,
          transferStatus: status);

  @override
  Future<AdminBookingRecord> assignAndUpdateBooking({
    required String bookingId,
    required String staffId,
    required String status,
    String? cancellationReason,
  }) async {
    final staff = _findStaff(staffId),
        upper = status.toUpperCase().replaceAll(' ', '_'),
        cur = CachedRecords.find(_bookings, (b) => b.bookingId, bookingId);
    await _syncPatch('/bookings/$bookingId/assign', {
      'status': upper,
      if (staff != null) ...{
        'assignedStaffId': staff.staffId,
        'assignedStaffName': staff.shortName,
        'assignedDepartment': staff.department.apiValue,
      },
      'notifyStaff': true,
      'cancellationReason': cancellationReason,
    });
    return _putBooking(cur.copyWith(
        status: upper == 'CANCELLED'
            ? 'Cancelled'
            : (upper == 'CONFIRMED' ? 'Confirmed' : status),
        assignedStaffId: staff?.staffId ?? '',
        assignedStaffName: staff?.shortName ?? '',
        assignedDepartment: staff?.department,
        notifiedAt: DateTime.now().toUtc().toIso8601String(),
        cancellationReason: cancellationReason));
  }

  @override
  Future<AdminExperienceCatalogItem> createExperienceCatalogItem({
    required String title,
    required String category,
    required String duration,
    required double basePriceUSD,
    bool isIncluded = false,
    String description = '',
  }) async {
    final priceText =
        isIncluded ? 'Included' : '\$${basePriceUSD.toStringAsFixed(0)} USD';
    final res = await _gateway.postJson('/catalog/experiences', {
      'title': title,
      'category': category,
      'duration': duration,
      'priceText': priceText,
      'basePriceUSD': basePriceUSD,
      'isIncluded': isIncluded,
      'description': description,
    });
    final item = AdminWireMapper.mapExperienceCatalogItem(_confirmedId(res));
    _experienceCatalog.insert(0, item);
    return item;
  }

  @override
  Future<void> deleteExperienceCatalogItem(String id) async {
    await _syncDelete('/catalog/experiences/$id');
    _experienceCatalog.removeWhere((e) => e.id == id);
  }

  @override
  Future<AdminLarderOrder> updateLarderOrder(
      {required String orderId,
      required String status,
      required String staffId}) async {
    final staff = _findStaff(staffId),
        cur = CachedRecords.find(_larderOrders, (o) => o.orderId, orderId);
    await _syncPatch('/larder-orders/$orderId/status', {
      'provisioningStatus': status,
      if (staff != null) 'assignedStaffId': staff.staffId
    });
    final markStocked = status == 'Stocked in Villa';
    return CachedRecords.replace<AdminLarderOrder>(
        _larderOrders,
        (o) => o.orderId,
        cur.copyWith(
            status: status,
            assignedStaffId: staff?.staffId ?? '',
            assignedStaffName: staff?.shortName ?? '',
            items: [
              for (final i in cur.items)
                i.copyWith(isStocked: markStocked || i.isStocked)
            ]));
  }

  @override
  Future<AdminLarderCatalogItem> createLarderCatalogItem({
    required String name,
    required String category,
    required double price,
    required String storageType,
    String description = '',
  }) async {
    final res = await _gateway.postJson('/catalog/larder', {
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'storageType': storageType
    });
    final item = AdminWireMapper.mapLarderCatalogItem(_confirmedId(res));
    _larderCatalog.insert(0, item);
    return item;
  }

  @override
  Future<void> deleteLarderCatalogItem(String id) async {
    await _syncDelete('/catalog/larder/$id');
    _larderCatalog.removeWhere((i) => i.id == id);
  }

  @override
  Future<AdminConciergeTicket> updateConciergeTicket(
      {required String requestId,
      required ConciergeStage stage,
      String? staffId}) async {
    final staff = staffId != null ? _findStaff(staffId) : null,
        nowIso = DateTime.now().toUtc().toIso8601String(),
        cur = CachedRecords.find(_tickets, (t) => t.requestId, requestId);
    await _syncPatch('/concierge-requests/$requestId', {
      'status': stage.label,
      'currentStep': stage.step,
      if (staff != null) 'assignedStaffId': staff.staffId
    });
    return AdminCacheMutations.applyStageUpdate(
        tickets: _tickets,
        current: cur,
        stage: stage,
        staff: staff,
        nowIso: nowIso);
  }

  @override
  Future<AdminConciergeTicket> appendConciergeReply(
      {required String requestId,
      required String senderName,
      required String senderRole,
      required String messageText}) async {
    final cur = CachedRecords.find(_tickets, (t) => t.requestId, requestId);
    await _syncPatch('/concierge-requests/$requestId',
        {'replyMessage': messageText, 'message': messageText});
    return AdminCacheMutations.applyReply(
        tickets: _tickets,
        current: cur,
        senderName: senderName,
        senderRole: senderRole,
        messageText: messageText);
  }

  @override
  Future<AdminMidStayPulse> attendMidStayPulse(
      {required String checkInId,
      required String followUpNote,
      required String staffName}) async {
    final cur = CachedRecords.find(_pulses, (p) => p.checkInId, checkInId);
    await _syncPatch('/midstay-checkins/$checkInId',
        {'status': 'ATTENDED', 'followUpNote': followUpNote});
    return AdminCacheMutations.applyPulseUpdate(
        pulses: _pulses,
        current: cur,
        followUpNote: followUpNote,
        staffName: staffName);
  }

  @override
  Future<List<FolioLineItem>> addFolioItem(
      {required String stayId,
      required String title,
      required String categoryLabel,
      required double amountUsd}) async {
    await _syncPost('/folios/$stayId/items', {
      'title': title,
      'categoryLabel': categoryLabel,
      'amountUsd': amountUsd
    });
    return AdminCacheMutations.applyAddedFolioItem(
        items: _folioItems,
        title: title,
        categoryLabel: categoryLabel,
        amountUsd: amountUsd);
  }

  @override
  Future<AdminStayRecord> approveExpressCheckout(
      {required String stayId, required bool approveLateCheckout}) async {
    final cur = _stay(stayId);
    await _syncPatch('/stays/$stayId/folio/approve-checkout', {
      'paymentStatus': 'SETTLED',
      'lateCheckoutApproved': approveLateCheckout,
      'approveLateCheckout': approveLateCheckout,
      'status': StayLifecycleStatus.checkedOut.label,
    });
    return _putStay(cur.copyWith(
        lifecycleStatus: StayLifecycleStatus.checkedOut,
        paymentStatus: 'SETTLED',
        lateCheckoutApproved: approveLateCheckout));
  }

  AdminStayRecord _stay(String id) =>
      CachedRecords.find(_stays, (s) => s.stayId, id);
  AdminStayRecord _putStay(AdminStayRecord s) =>
      CachedRecords.replace(_stays, (s) => s.stayId, s);
  AdminBookingRecord _putBooking(AdminBookingRecord b) =>
      CachedRecords.replace(_bookings, (x) => x.bookingId, b);

  /// Roster member with [staffId], or `null` (unassigned) when unknown.
  StaffMember? _findStaff(String staffId) {
    if (_staff.isEmpty) {
      throw const AdminUnconfirmedMutationException('Staff roster not loaded.');
    }
    return _staff.where((s) => s.staffId == staffId).firstOrNull;
  }

  static Map<String, dynamic> _confirmedId(Map<String, dynamic> res) {
    AdminServerConfirmation.requireText(res, 'id');
    return res;
  }

  Future<Map<String, dynamic>> _syncPatch(
          String path, Map<String, dynamic> payload) =>
      _gateway.patchJson(path, payload);

  Future<Map<String, dynamic>> _syncPost(
          String path, Map<String, dynamic> payload) =>
      _gateway.postJson(path, payload);

  Future<Map<String, dynamic>> _syncDelete(String path) =>
      _gateway.deleteJson(path);

  @override
  void dispose() => _gateway.dispose();
}
