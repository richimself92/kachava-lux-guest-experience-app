import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/admin_i18n.dart';
import '../core/alert_chime_port.dart';
import '../data/admin_seed_fixtures.dart';
import '../domain/admin_entities.dart';
import '../domain/admin_enums.dart';
import '../domain/admin_repository.dart';
import '../domain/admin_stay_entities.dart';
import 'inspector_selection.dart';

/// Application state controller for the Kachava Lux Admin & Concierge Dashboard.
class AdminDashboardController extends ChangeNotifier {
  AdminDashboardController(
      {required AdminOperationsRepository repository,
      AlertChimePort? alertChime})
      : _repository = repository,
        _chime = alertChime ?? createAlertChimePort();

  final AdminOperationsRepository _repository;
  final AlertChimePort _chime;
  final Set<String> _seenAlertIds = {};
  List<AdminVillaInfo> _villas = List.of(AdminSeedFixtures.buildVillas());
  List<StaffMember> _staffDirectory = const [];
  List<OperationalAlert> _alerts = const [];
  List<AdminStayRecord> _stays = const [];
  List<AdminBookingRecord> _bookings = const [];
  List<AdminExperienceCatalogItem> _experienceCatalog = const [];
  List<AdminLarderOrder> _larderOrders = const [];
  List<AdminLarderCatalogItem> _larderCatalog = const [];
  List<AdminConciergeTicket> _conciergeTickets = const [];
  List<AdminMidStayPulse> _midStayPulses = const [];
  List<FolioLineItem> _folioItems = const [];
  AdminLocale _locale = AdminLocale.en;
  AdminWorkspaceTab _activeTab = AdminWorkspaceTab.adminOverview;
  String _searchQuery = '',
      _villaFilter = 'All Villas',
      _experienceCategoryFilter = 'All',
      _larderStatusFilter = 'All',
      _larderZoneFilter = 'All';
  bool _urgentOnly = false;
  StayLifecycleStatus? _lifecycleFilter;
  AlertCategory? _alertCategoryFilter;
  ConciergeStage? _conciergeStageFilter;
  StaffDepartment? _conciergeDepartmentFilter;
  AdminDrawerSelection? _inspectorSelection;
  String? _activeLightboxTicketId, _lastToastMessage;

  AdminLocale get locale => _locale;
  bool get isEs => _locale == AdminLocale.es;
  bool get isChimeRinging => _chime.isRinging;
  AdminWorkspaceTab get activeTab => _activeTab;
  String get searchQuery => _searchQuery;
  String get villaFilter => _villaFilter;
  bool get urgentOnly => _urgentOnly;
  StayLifecycleStatus? get lifecycleFilter => _lifecycleFilter;
  AlertCategory? get alertCategoryFilter => _alertCategoryFilter;
  String get experienceCategoryFilter => _experienceCategoryFilter;
  String get larderStatusFilter => _larderStatusFilter;
  String get larderZoneFilter => _larderZoneFilter;
  ConciergeStage? get conciergeStageFilter => _conciergeStageFilter;
  StaffDepartment? get conciergeDepartmentFilter => _conciergeDepartmentFilter;
  AdminDrawerSelection? get inspectorSelection => _inspectorSelection;
  String? get activeLightboxTicketId => _activeLightboxTicketId;
  String? get lastToastMessage => _lastToastMessage;
  List<AdminVillaInfo> get villas => List.unmodifiable(_villas);
  List<StaffMember> get staffDirectory => _staffDirectory;
  StaffMember get activeStaff => _staffDirectory.isNotEmpty
      ? _staffDirectory.first
      : AdminSeedFixtures.buildStaffDirectory().first;
  List<OperationalAlert> get alerts => _alerts;
  List<AdminStayRecord> get stays => _stays;
  List<AdminBookingRecord> get bookings => _bookings;
  List<AdminExperienceCatalogItem> get experienceCatalog => _experienceCatalog;
  List<AdminLarderOrder> get larderOrders => _larderOrders;
  List<AdminLarderCatalogItem> get larderCatalog => _larderCatalog;
  List<AdminConciergeTicket> get conciergeTickets => _conciergeTickets;
  List<AdminMidStayPulse> get midStayPulses => _midStayPulses;
  List<FolioLineItem> get folioItems => _folioItems;
  int get unreadAlertsCount => _alerts.where((a) => !a.isAcknowledged).length;
  int get openConciergeCount => _conciergeTickets
      .where((t) => t.stage != ConciergeStage.completed)
      .length;
  int get pendingBookingsAndLarderCount =>
      _bookings.where((b) => b.status == 'Requested').length +
      _larderOrders.where((o) => o.status != 'Stocked in Villa').length;
  int get urgentSlaAlertsCount => _alerts
      .where((a) => a.severity == AlertSeverity.urgent && !a.isAcknowledged)
      .length;
  List<OperationalAlert> get filteredAlerts => AdminFilterEngine.filterAlerts(
      alerts: _alerts,
      query: _searchQuery,
      villaFilter: _villaFilter,
      urgentOnly: _urgentOnly,
      categoryFilter: _alertCategoryFilter);
  List<AdminStayRecord> get filteredStays => AdminFilterEngine.filterStays(
      stays: _stays,
      query: _searchQuery,
      villaFilter: _villaFilter,
      lifecycleFilter: _lifecycleFilter);
  List<AdminBookingRecord> get filteredBookings =>
      AdminFilterEngine.filterBookings(
          bookings: _bookings,
          query: _searchQuery,
          categoryFilter: _experienceCategoryFilter);
  List<AdminLarderOrder> get filteredLarderOrders =>
      AdminFilterEngine.filterLarderOrders(
          orders: _larderOrders,
          query: _searchQuery,
          statusFilter: _larderStatusFilter,
          zoneFilter: _larderZoneFilter);
  List<AdminConciergeTicket> get filteredConciergeTickets =>
      AdminFilterEngine.filterConciergeTickets(
          tickets: _conciergeTickets,
          query: _searchQuery,
          stageFilter: _conciergeStageFilter,
          departmentFilter: _conciergeDepartmentFilter);
  double get folioIncidentalsTotalUsd => _folioItems
      .where((i) => !i.isIncludedPrivilege)
      .fold(0.0, (sum, item) => sum + item.amountUsd);
  AdminStayRecord? activeStayForVilla(String villaLabel) =>
      AdminFilterEngine.findActiveStayForVilla(_stays, villaLabel);
  bool isVillaOccupied(String villaLabel) =>
      activeStayForVilla(villaLabel) != null;

  Future<void> initialize() async {
    _staffDirectory = await _repository.fetchStaffDirectory();
    await _hydrateCollections();
    _seenAlertIds
      ..clear()
      ..addAll(_alerts.map((a) => a.alertId))
      ..addAll(_unacknowledgedActivityIds());
    notifyListeners();
  }

  Set<String> _unacknowledgedActivityIds() => {
        for (final b in _bookings.where((b) => b.status == 'Requested'))
          'bkg:${b.bookingId}',
        for (final o in _larderOrders.where((o) => o.status == 'Pending'))
          'lrd:${o.orderId}:${o.items.length}',
        for (final t in _conciergeTickets
            .where((t) => t.stage != ConciergeStage.completed))
          'tkt:${t.requestId}:${t.messages.where((m) => !m.isStaff).length}',
        for (final p in _midStayPulses.where((p) => p.status != 'ATTENDED'))
          'pls:${p.checkInId}',
      };

  Future<void> _hydrateCollections() async {
    _stays = await _repository.fetchStays();
    _alerts = await _repository.fetchAlerts();
    _bookings = await _repository.fetchBookings();
    _experienceCatalog = await _repository.fetchExperienceCatalog();
    _larderOrders = await _repository.fetchLarderOrders();
    _larderCatalog = await _repository.fetchLarderCatalog();
    _conciergeTickets = await _repository.fetchConciergeTickets();
    _midStayPulses = await _repository.fetchMidStayPulses();
    _folioItems = _stays.isNotEmpty
        ? await _repository.fetchFolioItems(_stays.first.stayId)
        : const [];
  }

  Future<void> refreshFromBackend({bool silent = false}) async {
    final prevUnread = unreadAlertsCount;
    await _hydrateCollections();
    final newUnread = _alerts
        .where((a) => !a.isAcknowledged && !_seenAlertIds.contains(a.alertId))
        .toList();
    final currentActivity = _unacknowledgedActivityIds();
    final newActivity = currentActivity.difference(_seenAlertIds);
    _seenAlertIds
      ..addAll(_alerts.map((a) => a.alertId))
      ..addAll(currentActivity);
    if ((newUnread.isNotEmpty || unreadAlertsCount > prevUnread) &&
        _alerts.isNotEmpty) {
      final a = newUnread.isNotEmpty ? newUnread.first : _alerts.first;
      final titleText = AdminI18n.translateText(a.title, isEs);
      showToast(
          isEs
              ? 'NUEVA ACTUALIZACIÓN DE HUÉSPED · ${a.villaName} — $titleText'
              : 'NEW GUEST UPDATE · ${a.villaName} — ${a.title}',
          playChime: true);
      return;
    }
    if (newActivity.isNotEmpty) {
      showToast(
          isEs
              ? 'NUEVA SOLICITUD DE HUÉSPED EN VIVO · Revisa las alertas en vivo'
              : 'NEW LIVE GUEST SUBMISSION · Check live alerts',
          playChime: true);
      return;
    }
    if (!silent) {
      return showToast(isEs
          ? 'Sincronizado con el servidor en vivo'
          : 'Synced with live backend');
    }
    notifyListeners();
  }

  Future<void> resetAllOperationalData() async {
    await _repository.resetAllData();
    _seenAlertIds.clear();
    await _hydrateCollections();
    showToast(isEs
        ? 'Datos reiniciados: Las 8 Villas están LIBRES (🟢) para probar desde cero'
        : 'All data reset: All 8 Villas are FREE (🟢) to test from scratch');
  }

  void _update(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  void toggleLocale() => _update(() {
        _locale = isEs ? AdminLocale.en : AdminLocale.es;
        AdminI18n.currentIsEs = isEs;
      });
  void selectTab(AdminWorkspaceTab tab) => _update(() => _activeTab = tab);
  void setSearchQuery(String query) => _update(() => _searchQuery = query);
  void toggleUrgentOnlyFilter(bool val) => _update(() => _urgentOnly = val);
  void setAlertCategoryFilter(AlertCategory? cat) =>
      _update(() => _alertCategoryFilter = cat);
  void setExperienceCategoryFilter(String cat) =>
      _update(() => _experienceCategoryFilter = cat);
  void openInspector(AdminDrawerSelection sel) =>
      _update(() => _inspectorSelection = sel);
  void closeInspector() => _update(() => _inspectorSelection = null);
  void setLightboxTicket(String? id) =>
      _update(() => _activeLightboxTicketId = id);
  void showToast(String msg, {bool playChime = false}) => _update(() {
        _lastToastMessage = msg;
        if (playChime) {
          _chime.triggerTenSecondChime(onAutoStop: notifyListeners);
        }
      });
  void dismissToastAndStopChime() => _update(() {
        _chime.stopChime();
        _lastToastMessage = null;
      });
  void triggerTestAlertSound() => showToast(
      isEs
          ? 'NUEVA SOLICITUD DE HUÉSPED · Requiere atención de HOST ADMIN (Sonando 10s)'
          : 'NEW GUEST REQUEST · Requires HOST ADMIN attention (Ringing 10s)',
      playChime: true);

  void createVilla(
          {required String villaName,
          required String suiteType,
          required String maxGuests,
          String? wifiSsid,
          String? wifiPasscode}) =>
      _update(() {
        final c = AdminVillaInfo(
            villaId: 'villa-${_villas.length + 101}',
            villaName: villaName,
            suiteType: suiteType,
            maxGuests: maxGuests,
            wifiSsid: (wifiSsid != null && wifiSsid.isNotEmpty)
                ? wifiSsid
                : 'Kachava_Sanctuary_102',
            wifiPasscode: (wifiPasscode != null && wifiPasscode.isNotEmpty)
                ? wifiPasscode
                : 'stillness2026');
        _villas = [c, ..._villas];
        _lastToastMessage = isEs
            ? 'Villa creada: ${c.displayLabel}'
            : 'Villa created: ${c.displayLabel}';
      });

  void setQuickFilter(
          {String? villa,
          bool? urgentOnly,
          StayLifecycleStatus? lifecycle,
          bool clearLifecycle = false}) =>
      _update(() {
        if (villa != null) _villaFilter = villa;
        if (urgentOnly != null) _urgentOnly = urgentOnly;
        if (clearLifecycle) _lifecycleFilter = null;
        if (lifecycle != null) _lifecycleFilter = lifecycle;
      });

  void setLarderFilters({String? status, String? zone}) => _update(() {
        if (status != null) _larderStatusFilter = status;
        if (zone != null) _larderZoneFilter = zone;
      });

  void setConciergeFilters(
          {ConciergeStage? stage,
          bool clearStage = false,
          StaffDepartment? department,
          bool clearDepartment = false}) =>
      _update(() {
        if (clearStage) _conciergeStageFilter = null;
        if (stage != null) _conciergeStageFilter = stage;
        if (clearDepartment) _conciergeDepartmentFilter = null;
        if (department != null) _conciergeDepartmentFilter = department;
      });

  Future<void> acknowledgeAlert(String alertId) async {
    final u = await _repository.acknowledgeAlert(
        alertId: alertId, staffId: activeStaff.staffId);
    _alerts = await _repository.fetchAlerts();
    showToast(isEs
        ? 'Alerta atendida por HOST ADMIN: ${u.villaName} — ${AdminI18n.translateText(u.title, true)}'
        : 'Alert attended by HOST ADMIN: ${u.villaName} — ${u.title}');
  }

  Future<void> copyMagicLink(AdminStayRecord stay) async {
    showToast(isEs
        ? 'Link copiado: ${stay.magicLinkUrl}'
        : 'Link copied: ${stay.magicLinkUrl}');
    try {
      await Clipboard.setData(ClipboardData(text: stay.magicLinkUrl));
    } catch (_) {}
  }

  Future<void> regenerateMagicLink(String stayId) async {
    final u = await _repository.regenerateGuestUuid(stayId);
    _stays = await _repository.fetchStays();
    showToast(isEs
        ? 'Nuevo Magic Link generado: ${u.magicLinkUrl}'
        : 'New Magic Link generated: ${u.magicLinkUrl}');
  }

  Future<void> createNewStay({
    required String villaName,
    required String guestNames,
    required String checkInDate,
    required String checkOutDate,
    required String occasion,
    String? wifiSsid,
    String? wifiPasscode,
  }) async {
    final occ = activeStayForVilla(villaName);
    if (occ != null) {
      return showToast(isEs
          ? 'Error: $villaName está ocupada por ${occ.guestNames}. Libera la villa primero.'
          : 'Error: $villaName is occupied by ${occ.guestNames}. Release the villa first.');
    }
    final c = await _repository.createStay(
        villaName: villaName,
        guestNames: guestNames,
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
        occasion: occasion,
        wifiSsid: wifiSsid,
        wifiPasscode: wifiPasscode);
    _stays = [c, ..._stays.where((s) => s.stayId != c.stayId)];
    showToast(isEs
        ? 'Estancia creada (${c.guestNames} · ${c.villaName}): ${c.magicLinkUrl}'
        : 'Stay created (${c.guestNames} · ${c.villaName}): ${c.magicLinkUrl}');
  }

  Future<void> updateStayWifi(
      {required String stayId,
      required String wifiSsid,
      required String wifiPasscode}) async {
    final u = await _repository.updateStayWifi(
        stayId: stayId, wifiSsid: wifiSsid, wifiPasscode: wifiPasscode);
    _stays = _stays.map((s) => s.stayId == stayId ? u : s).toList();
    showToast(isEs
        ? 'Red Wi-Fi actualizada (${u.villaName}): ${u.wifiSsid}'
        : 'Wi-Fi updated (${u.villaName}): ${u.wifiSsid}');
  }

  Future<void> checkInGuest(String stayId) async {
    final u = await _repository.updateStayLifecycle(
        stayId: stayId, status: StayLifecycleStatus.activeStay);
    _stays = await _repository.fetchStays();
    showToast(isEs
        ? 'Llegada registrada (Check-In): ${u.guestNames} en ${u.villaName}'
        : 'Guest checked in: ${u.guestNames} at ${u.villaName}');
  }

  Future<void> checkOutAndReleaseVilla(String stayId) async {
    await _repository.approveExpressCheckout(
        stayId: stayId, approveLateCheckout: false);
    _stays = await _repository.fetchStays();
    showToast(isEs
        ? 'Salida registrada: Villa liberada y disponible para nuevo huésped'
        : 'Check-out complete: Villa released and available for new guest');
  }

  Future<void> updateTransferDispatch({
    required String stayId,
    required String chauffeurId,
    required String transferStatus,
    String? driverAndVehicle,
    String? meetingPoint,
  }) async {
    final u = await _repository.updateTransferDispatch(
        stayId: stayId,
        chauffeurId: chauffeurId,
        transferStatus: transferStatus,
        driverAndVehicle: driverAndVehicle,
        meetingPoint: meetingPoint);
    _stays = await _repository.fetchStays();
    final drv = u.transfer.assignedChauffeurName.isEmpty
        ? 'HOST ADMIN'
        : u.transfer.assignedChauffeurName;
    showToast(isEs
        ? 'Traslado (${u.villaName}) actualizado a: ${AdminI18n.statusLabel(transferStatus, true)}'
        : 'Transfer updated: $drv · $transferStatus (${u.villaName})');
  }

  Future<void> assignAndNotifyBooking({
    required String bookingId,
    required String staffId,
    required String status,
    String? cancellationReason,
  }) async {
    final u = await _repository.assignAndUpdateBooking(
        bookingId: bookingId,
        staffId: staffId,
        status: status,
        cancellationReason: cancellationReason);
    _bookings = await _repository.fetchBookings();
    showToast(isEs
        ? 'Reserva "${u.title}" actualizada a: ${AdminI18n.statusLabel(u.status, true)} (HOST ADMIN)'
        : 'Booking "${u.title}" — Assigned & Notified ${u.assignedStaffName} (${u.status})');
  }

  Future<void> addExperienceCatalogItem({
    required String title,
    required String category,
    required String duration,
    required double basePriceUSD,
    bool isIncluded = false,
    String description = '',
  }) async {
    final item = await _repository.createExperienceCatalogItem(
        title: title,
        category: category,
        duration: duration,
        basePriceUSD: basePriceUSD,
        isIncluded: isIncluded,
        description: description);
    _experienceCatalog = await _repository.fetchExperienceCatalog();
    showToast(isEs
        ? 'Experiencia agregada al catálogo: ${item.title}'
        : 'Experience added to catalog: ${item.title}');
  }

  Future<void> deleteExperienceCatalogItem(String id) async {
    await _repository.deleteExperienceCatalogItem(id);
    _experienceCatalog = await _repository.fetchExperienceCatalog();
    showToast(isEs
        ? 'Experiencia eliminada del catálogo'
        : 'Experience removed from catalog');
  }

  Future<void> updateLarderOrderStatus(
      {required String orderId,
      required String status,
      required String staffId}) async {
    final u = await _repository.updateLarderOrder(
        orderId: orderId, status: status, staffId: staffId);
    _larderOrders = await _repository.fetchLarderOrders();
    showToast(isEs
        ? 'Pedido de Minibar (${u.villaName}) actualizado a: ${AdminI18n.statusLabel(status, true)}'
        : 'Minibar order (${u.villaName}) marked ${u.status} (${u.assignedStaffName})');
  }

  Future<void> addLarderCatalogItem({
    required String name,
    required String category,
    required double price,
    required String storageType,
    String description = '',
  }) async {
    final item = await _repository.createLarderCatalogItem(
        name: name,
        category: category,
        price: price,
        storageType: storageType,
        description: description);
    _larderCatalog = await _repository.fetchLarderCatalog();
    showToast(isEs
        ? 'Producto agregado al catálogo: ${item.name}'
        : 'Product added to minibar catalog: ${item.name}');
  }

  Future<void> deleteLarderCatalogItem(String id) async {
    await _repository.deleteLarderCatalogItem(id);
    _larderCatalog = await _repository.fetchLarderCatalog();
    showToast(isEs
        ? 'Producto eliminado del catálogo'
        : 'Product removed from minibar catalog');
  }

  Future<void> advanceConciergeTicketStage(
      {required String requestId,
      required ConciergeStage targetStage,
      String? staffId}) async {
    final u = await _repository.updateConciergeTicket(
        requestId: requestId, stage: targetStage, staffId: staffId);
    _conciergeTickets = await _repository.fetchConciergeTickets();
    showToast(isEs
        ? 'Solicitud "${u.title}" actualizada a: ${AdminI18n.statusLabel(u.stage.label, true)}'
        : 'Request "${u.title}" updated to: ${u.stage.label} · ${u.assignedStaffName}');
  }

  Future<void> sendConciergeHostReply(
      {required String requestId, required String messageText}) async {
    if (messageText.trim().isEmpty) return;
    await _repository.appendConciergeReply(
        requestId: requestId,
        senderName: activeStaff.fullName,
        senderRole: activeStaff.role,
        messageText: messageText.trim());
    _conciergeTickets = await _repository.fetchConciergeTickets();
    showToast(isEs
        ? 'Respuesta enviada al huésped por HOST ADMIN'
        : 'Reply sent to guest by HOST ADMIN');
  }

  Future<void> attendMidStayPulse(
      {required String checkInId, required String followUpNote}) async {
    await _repository.attendMidStayPulse(
        checkInId: checkInId,
        followUpNote: followUpNote,
        staffName: activeStaff.fullName);
    _midStayPulses = await _repository.fetchMidStayPulses();
    showToast(isEs
        ? 'Comentario de estancia atendido por HOST ADMIN'
        : 'Guest stay feedback attended by HOST ADMIN');
  }

  Future<void> approveExpressCheckout(
      {required String stayId, required bool approveLateCheckout}) async {
    final u = await _repository.approveExpressCheckout(
        stayId: stayId, approveLateCheckout: approveLateCheckout);
    _stays = await _repository.fetchStays();
    showToast(isEs
        ? 'Salida completada: ${u.villaName} ahora está LIBRE'
        : 'Express Checkout settled for ${u.villaName} (${u.paymentStatus})');
  }

  @override
  void dispose() {
    _chime.dispose();
    _repository.dispose();
    super.dispose();
  }
}
