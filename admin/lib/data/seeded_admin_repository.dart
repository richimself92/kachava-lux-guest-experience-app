import '../domain/admin_entities.dart';
import '../domain/admin_enums.dart';
import '../domain/admin_repository.dart';
import '../domain/admin_stay_entities.dart';
import 'admin_api_client.dart';
import 'admin_seed_concierge_folio.dart';
import 'admin_seed_fixtures.dart';
import 'admin_seed_operations.dart';
import 'admin_wire_mapper.dart';

/// Repository implementation pre-populated with Villa 102 and resort operational data,
/// plus optional non-blocking REST synchronization with `/api/v1/admin/*`.
class SeededAdminRepository implements AdminOperationsRepository {
  SeededAdminRepository({AdminApiClient? apiClient}) : _apiClient = apiClient;

  final AdminApiClient? _apiClient;
  final List<StaffMember> _staff =
      List.of(AdminSeedFixtures.buildStaffDirectory());
  final List<AdminStayRecord> _stays = List.of(AdminSeedFixtures.buildStays());
  final List<OperationalAlert> _alerts =
      List.of(AdminSeedOperations.buildAlerts());
  final List<AdminBookingRecord> _bookings =
      List.of(AdminSeedOperations.buildBookings());
  final List<AdminLarderOrder> _larderOrders =
      List.of(AdminSeedOperations.buildLarderOrders());
  final List<AdminConciergeTicket> _tickets =
      List.of(AdminSeedOperations.buildConciergeTickets());
  final List<AdminMidStayPulse> _pulses =
      List.of(AdminSeedOperations.buildMidStayPulses());
  final List<FolioLineItem> _folioItems =
      List.of(AdminSeedOperations.buildFolioItems());
  final List<AdminExperienceCatalogItem> _experienceCatalog =
      List.of(AdminSeedConciergeFolio.buildExperienceCatalog());
  final List<AdminLarderCatalogItem> _larderCatalog =
      List.of(AdminSeedConciergeFolio.buildLarderCatalog());
  int _uuidCounter = 100;

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
    if (alerts != null) {
      _alerts
        ..clear()
        ..addAll(alerts);
    }
    if (stays != null) {
      _stays
        ..clear()
        ..addAll(stays);
    }
    if (bookings != null) {
      _bookings
        ..clear()
        ..addAll(bookings);
    }
    if (larderOrders != null) {
      _larderOrders
        ..clear()
        ..addAll(larderOrders);
    }
    if (tickets != null) {
      _tickets
        ..clear()
        ..addAll(tickets);
    }
    if (pulses != null) {
      _pulses
        ..clear()
        ..addAll(pulses);
    }
    if (folioItems != null) {
      _folioItems
        ..clear()
        ..addAll(folioItems);
    }
    if (experienceCatalog != null) {
      _experienceCatalog
        ..clear()
        ..addAll(experienceCatalog);
    }
    if (larderCatalog != null) {
      _larderCatalog
        ..clear()
        ..addAll(larderCatalog);
    }
  }

  void upsertStay(AdminStayRecord stay) {
    _stays.removeWhere((s) => s.stayId == stay.stayId);
    _stays.insert(0, stay);
  }

  AdminStayRecord createStayLocal({
    required String villaName,
    required String guestNames,
    required String checkInDate,
    required String checkOutDate,
    required String occasion,
    String? wifiSsid,
    String? wifiPasscode,
    String? uuidOverride,
  }) {
    _uuidCounter++;
    final uuid = (uuidOverride != null && uuidOverride.isNotEmpty)
        ? uuidOverride
        : '550e8400-e29b-41d4-a716-446655440$_uuidCounter';
    final created = AdminSeedFixtures.buildCreatedStay(
        counter: _uuidCounter,
        uuid: uuid,
        villaName: villaName,
        guestNames: guestNames,
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
        occasion: occasion,
        wifiSsid: wifiSsid,
        wifiPasscode: wifiPasscode);
    upsertStay(created);
    return created;
  }

  @override
  Future<void> resetAllData() async {
    await _syncPost('/reset', {});
    for (final list in <List<dynamic>>[
      _stays,
      _alerts,
      _bookings,
      _larderOrders,
      _tickets,
      _pulses,
      _folioItems
    ]) {
      list.clear();
    }
  }

  @override
  Future<List<StaffMember>> fetchStaffDirectory() async =>
      List.unmodifiable(_staff);
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
    await _syncPatch('/alerts/$alertId/acknowledge', {'staffId': staffId});
    final index = _alerts.indexWhere((a) => a.alertId == alertId);
    return _alerts[index] = _alerts[index]
        .copyWith(isAcknowledged: true, acknowledgedByStaffId: staffId);
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
    final res = await _syncPost('/stays', {
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
    if (res?['stay'] is Map) {
      final mapped = AdminWireMapper.mapStay(
          Map<String, dynamic>.from(res!['stay'] as Map));
      upsertStay(mapped);
      return mapped;
    }
    return createStayLocal(
        villaName: villaName,
        guestNames: guestNames,
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
        occasion: occasion,
        wifiSsid: wifiSsid,
        wifiPasscode: wifiPasscode,
        uuidOverride: res?['guestTokenUuid'] as String?);
  }

  @override
  Future<AdminStayRecord> regenerateGuestUuid(String stayId) async {
    _uuidCounter++;
    final res = await _syncPost('/stays/$stayId/regenerate-token', {}),
        apiUuid = res?['guestTokenUuid'] as String?;
    final rotated = (apiUuid != null && apiUuid.isNotEmpty)
        ? apiUuid
        : 'a8098c1a-f86e-41da-bd1a-00112444b$_uuidCounter';
    final index = _stays.indexWhere((s) => s.stayId == stayId);
    return _stays[index] = _stays[index].copyWith(guestTokenUuid: rotated);
  }

  @override
  Future<AdminStayRecord> updateStayLifecycle(
      {required String stayId, required StayLifecycleStatus status}) async {
    await _syncPatch('/stays/$stayId/status', {'status': status.label});
    final index = _stays.indexWhere((s) => s.stayId == stayId);
    return _stays[index] = _stays[index].copyWith(lifecycleStatus: status);
  }

  @override
  Future<AdminStayRecord> updateStayWifi(
      {required String stayId,
      required String wifiSsid,
      required String wifiPasscode}) async {
    await _syncPatch('/stays/$stayId/wifi',
        {'wifiSsid': wifiSsid, 'wifiPasscode': wifiPasscode});
    final index = _stays.indexWhere((s) => s.stayId == stayId);
    return _stays[index] =
        _stays[index].copyWith(wifiSsid: wifiSsid, wifiPasscode: wifiPasscode);
  }

  @override
  Future<AdminStayRecord> updateTransferDispatch({
    required String stayId,
    required String chauffeurId,
    required String transferStatus,
    String? driverAndVehicle,
    String? meetingPoint,
  }) async {
    final staff = _findStaff(chauffeurId);
    final drv = (driverAndVehicle != null && driverAndVehicle.trim().isNotEmpty)
        ? driverAndVehicle.trim()
        : null;
    final meet = (meetingPoint != null && meetingPoint.trim().isNotEmpty)
        ? meetingPoint.trim()
        : null;
    await _syncPatch('/stays/$stayId/transfer', {
      'status': transferStatus,
      'assignedStaffId': staff.staffId,
      'assignedStaffName': drv ?? staff.shortName,
      if (drv != null) 'assignedDriver': drv,
      if (drv != null) 'vehicleModel': drv,
      if (meet != null) 'meetingPoint': meet,
      if (meet != null) 'adminDispatchNotes': meet,
    });
    final index = _stays.indexWhere((s) => s.stayId == stayId),
        cur = _stays[index].transfer;
    return _stays[index] = _stays[index].copyWith(
        transfer: cur.copyWith(
            assignedChauffeurId: staff.staffId,
            assignedChauffeurName: drv ??
                (cur.assignedChauffeurName.isNotEmpty
                    ? cur.assignedChauffeurName
                    : staff.shortName),
            vehicleLabel: drv ?? cur.vehicleLabel,
            cabinBeverage: meet ?? cur.cabinBeverage,
            outboundRoute: meet ?? cur.outboundRoute,
            transferStatus: transferStatus));
  }

  @override
  Future<AdminBookingRecord> assignAndUpdateBooking({
    required String bookingId,
    required String staffId,
    required String status,
    String? cancellationReason,
  }) async {
    final staff = _findStaff(staffId),
        nowIso = DateTime.now().toUtc().toIso8601String();
    final upper = status.toUpperCase().replaceAll(' ', '_');
    final normalizedStatus = upper == 'CANCELLED'
        ? 'Cancelled'
        : (upper == 'CONFIRMED' ? 'Confirmed' : status);
    await _syncPatch('/bookings/$bookingId/assign', {
      'status': upper,
      'assignedStaffId': staff.staffId,
      'assignedStaffName': staff.shortName,
      'assignedDepartment': staff.department.apiValue,
      'notifyStaff': true,
      'cancellationReason': cancellationReason,
    });
    final index = _bookings.indexWhere((b) => b.bookingId == bookingId);
    return _bookings[index] = _bookings[index].copyWith(
        status: normalizedStatus,
        assignedStaffId: staff.staffId,
        assignedStaffName: staff.shortName,
        assignedDepartment: staff.department,
        notifiedAt: nowIso,
        cancellationReason: cancellationReason);
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
    _uuidCounter++;
    final priceText =
        isIncluded ? 'Included' : '\$${basePriceUSD.toStringAsFixed(0)} USD';
    final res = await _syncPost('/catalog/experiences', {
      'title': title,
      'category': category,
      'duration': duration,
      'location': 'Riviera Maya',
      'priceText': priceText,
      'basePriceUSD': basePriceUSD,
      'isIncluded': isIncluded,
      'description': description,
    });
    final item = (res != null && res['id'] != null)
        ? AdminWireMapper.mapExperienceCatalogItem(res)
        : AdminExperienceCatalogItem(
            id: 'exp_$_uuidCounter',
            title: title,
            category: category,
            duration: duration,
            location: 'Riviera Maya',
            priceText: priceText,
            basePriceUSD: basePriceUSD,
            isIncluded: isIncluded,
            description: description);
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
    final staff = _findStaff(staffId);
    await _syncPatch('/larder-orders/$orderId/status',
        {'provisioningStatus': status, 'assignedStaffId': staff.staffId});
    final index = _larderOrders.indexWhere((o) => o.orderId == orderId),
        markStocked = status == 'Stocked in Villa';
    final updatedItems = _larderOrders[index]
        .items
        .map((i) => i.copyWith(isStocked: markStocked || i.isStocked))
        .toList();
    return _larderOrders[index] = _larderOrders[index].copyWith(
        status: status,
        assignedStaffId: staff.staffId,
        assignedStaffName: staff.shortName,
        items: updatedItems);
  }

  @override
  Future<AdminLarderCatalogItem> createLarderCatalogItem({
    required String name,
    required String category,
    required double price,
    required String storageType,
    String description = '',
  }) async {
    _uuidCounter++;
    final res = await _syncPost('/catalog/larder', {
      'name': name,
      'origin': 'Riviera Maya Sanctuary',
      'description': description,
      'price': price,
      'category': category,
      'storageType': storageType
    });
    final item = (res != null && res['id'] != null)
        ? AdminWireMapper.mapLarderCatalogItem(res)
        : AdminLarderCatalogItem(
            id: 'lrd_$_uuidCounter',
            name: name,
            origin: 'Riviera Maya Sanctuary',
            price: price,
            category: category,
            storageType: storageType,
            description: description);
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
        nowIso = DateTime.now().toUtc().toIso8601String();
    await _syncPatch('/concierge-requests/$requestId', {
      'status': stage.label,
      'currentStep': stage.step,
      if (staff != null) 'assignedStaffId': staff.staffId
    });
    return AdminSeedConciergeFolio.applyStageUpdate(
        tickets: _tickets,
        requestId: requestId,
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
    await _syncPatch('/concierge-requests/$requestId',
        {'replyMessage': messageText, 'message': messageText});
    return AdminSeedConciergeFolio.applyReply(
        tickets: _tickets,
        requestId: requestId,
        senderName: senderName,
        senderRole: senderRole,
        messageText: messageText);
  }

  @override
  Future<AdminMidStayPulse> attendMidStayPulse(
      {required String checkInId,
      required String followUpNote,
      required String staffName}) async {
    await _syncPatch('/midstay-checkins/$checkInId',
        {'status': 'ATTENDED', 'followUpNote': followUpNote});
    return AdminSeedConciergeFolio.applyPulseUpdate(
        pulses: _pulses,
        checkInId: checkInId,
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
    return AdminSeedConciergeFolio.applyAddedFolioItem(
        items: _folioItems,
        title: title,
        categoryLabel: categoryLabel,
        amountUsd: amountUsd);
  }

  @override
  Future<AdminStayRecord> approveExpressCheckout(
      {required String stayId, required bool approveLateCheckout}) async {
    await _syncPatch('/stays/$stayId/folio/approve-checkout', {
      'paymentStatus': 'SETTLED',
      'lateCheckoutApproved': approveLateCheckout,
      'approveLateCheckout': approveLateCheckout,
      'status': StayLifecycleStatus.checkedOut.label,
    });
    final index = _stays.indexWhere((s) => s.stayId == stayId);
    return _stays[index] = _stays[index].copyWith(
        lifecycleStatus: StayLifecycleStatus.checkedOut,
        paymentStatus: 'SETTLED',
        lateCheckoutApproved: approveLateCheckout);
  }

  StaffMember _findStaff(String staffId) => _staff
      .firstWhere((s) => s.staffId == staffId, orElse: () => _staff.first);

  Future<Map<String, dynamic>?> _syncPatch(
      String path, Map<String, dynamic> payload) async {
    try {
      return await _apiClient?.patchJson(path, payload);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _syncPost(
      String path, Map<String, dynamic> payload) async {
    try {
      return await _apiClient?.postJson(path, payload);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _syncDelete(String path) async {
    try {
      return await _apiClient?.deleteJson(path);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() => _apiClient?.dispose();
}
