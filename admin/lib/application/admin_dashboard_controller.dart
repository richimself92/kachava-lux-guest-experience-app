import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/admin_i18n.dart';
import '../core/alert_chime_port.dart';
import '../domain/admin_entities.dart';
import '../domain/admin_enums.dart';
import '../domain/admin_repository.dart';
import '../domain/admin_stay_entities.dart';
import '../domain/admin_sync_snapshot.dart';
import 'admin_activity_tracker.dart';
import 'admin_dashboard_views.dart';
import 'inspector_selection.dart';
import 'server_confirmed_action.dart';

export 'admin_dashboard_views.dart';

/// Application state controller for the Kachava Lux Admin & Concierge Dashboard.
class AdminDashboardController extends ChangeNotifier {
  AdminDashboardController(
      {required AdminOperationsRepository repository,
      AlertChimePort? alertChime})
      : _repository = repository,
        _chime = alertChime ?? createAlertChimePort();

  final AdminOperationsRepository _repository;
  final AlertChimePort _chime;
  final AdminActivityTracker _activity = AdminActivityTracker();
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
  AdminSyncSnapshot? _snapshot;
  bool _isDisposed = false;
  int _epoch = 0; // bumped when the staff session changes

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
  List<AdminVillaInfo> get villas =>
      List.unmodifiable(_repository.villasFor(_stays));
  List<StaffMember> get staffDirectory => _staffDirectory;
  StaffMember? get activeStaff => _repository.sessionStaff; // signed-in staff
  List<OperationalAlert> get alerts => _alerts;
  List<AdminStayRecord> get stays => _stays;
  List<AdminBookingRecord> get bookings => _bookings;
  List<AdminExperienceCatalogItem> get experienceCatalog => _experienceCatalog;
  List<AdminLarderOrder> get larderOrders => _larderOrders;
  List<AdminLarderCatalogItem> get larderCatalog => _larderCatalog;
  List<AdminConciergeTicket> get conciergeTickets => _conciergeTickets;
  List<AdminMidStayPulse> get midStayPulses => _midStayPulses;
  List<FolioLineItem> get folioItems => _folioItems;

  /// First load: `/sync` must succeed; the staff roster is best-effort (an
  /// empty roster plus a one-line notice when `GET /admin/staff` fails).
  Future<void> initialize() async {
    final epoch = _epoch;
    final snapshot = await _repository.fetchSnapshot();
    final staff = await bestEffortRead(_repository.fetchStaffDirectory);
    if (_isStale(epoch)) return;
    _staffDirectory = staff ?? const [];
    _activity.baseline(_apply(snapshot));
    if (staff != null) return notifyListeners();
    showToast(AdminI18n.tr(
        isEs, 'Staff list unavailable.', 'Lista de personal no disponible.'));
  }

  /// Drops every record of the previous staff session (401 or staff switch).
  void clearSessionData() => _update(() {
        _epoch++;
        _apply(AdminSyncSnapshot.empty);
        _staffDirectory = const [];
        _activity.clear();
        _repository.clearCache();
        _chime.stopChime();
        _inspectorSelection = null;
        _activeLightboxTicketId = _lastToastMessage = null;
        _searchQuery = '';
      });

  AdminSyncSnapshot _apply(AdminSyncSnapshot s) {
    _snapshot = s;
    _stays = s.stays;
    _alerts = s.alerts;
    _bookings = s.bookings;
    _experienceCatalog = s.experienceCatalog;
    _larderOrders = s.larderOrders;
    _larderCatalog = s.larderCatalog;
    _conciergeTickets = s.conciergeTickets;
    _midStayPulses = s.midStayPulses;
    _folioItems = s.folioItems;
    return s;
  }

  /// Applies one sync (a silent identical one is skipped); throws on failure.
  Future<void> refreshFromBackend({bool silent = false}) async {
    final epoch = _epoch, s = await _repository.fetchSnapshot();
    if (_isStale(epoch) || (silent && s.isSameAs(_snapshot))) return;
    final prevUnread = unreadAlertsCount;
    final delta = _activity.absorb(_apply(s));
    final a = _guestUpdateAlert(delta.newAlerts, prevUnread);
    if (a != null) {
      final titleText = AdminI18n.translateText(a.title, isEs);
      return showToast(
          isEs
              ? 'NUEVA ACTUALIZACIÓN DE HUÉSPED · ${a.villaName} — $titleText'
              : 'NEW GUEST UPDATE · ${a.villaName} — ${a.title}',
          playChime: true);
    }
    if (delta.hasNewActivity) {
      return showToast(
          isEs
              ? 'NUEVA SOLICITUD DE HUÉSPED EN VIVO · Revisa las alertas en vivo'
              : 'NEW LIVE GUEST SUBMISSION · Check live alerts',
          playChime: true);
    }
    if (!silent) {
      return showToast(isEs
          ? 'Sincronizado con el servidor en vivo'
          : 'Synced with live backend');
    }
    notifyListeners();
  }

  OperationalAlert? _guestUpdateAlert(
      List<OperationalAlert> fresh, int prevUnread) {
    if (_alerts.isEmpty) return null;
    if (fresh.isNotEmpty) return fresh.first;
    return unreadAlertsCount > prevUnread ? _alerts.first : null;
  }

  Future<void> resetAllOperationalData() => _guard(() async {
        await _live(_repository.resetAllData());
        _activity.clear();
        if (await _reread(_repository.fetchSnapshot) case final s?) _apply(s);
        showToast(isEs
            ? 'Datos reiniciados: Las 8 Villas están LIBRES (🟢) para probar desde cero'
            : 'All data reset: All 8 Villas are FREE (🟢) to test from scratch');
      });

  void _update(VoidCallback fn) {
    if (_isDisposed) return;
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
          _chime.triggerTenSecondChime(onAutoStop: () => _update(() {}));
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

  Future<void> acknowledgeAlert(String alertId) => _guard(() async {
        final u = await _live(_repository.acknowledgeAlert(
            alertId: alertId, staffId: _requireStaff().staffId));
        _alerts = await _reread(_repository.fetchAlerts) ?? _alerts;
        showToast(isEs
            ? 'Alerta atendida por HOST ADMIN: ${u.villaName} — ${AdminI18n.translateText(u.title, true)}'
            : 'Alert attended by HOST ADMIN: ${u.villaName} — ${u.title}');
      });

  Future<void> copyMagicLink(AdminStayRecord stay) async {
    if (!stay.hasGuestLink) return;
    showToast(isEs
        ? 'Link copiado: ${stay.magicLinkUrl}'
        : 'Link copied: ${stay.magicLinkUrl}');
    await Clipboard.setData(ClipboardData(text: stay.magicLinkUrl))
        .catchError((Object _) {});
  }

  Future<void> regenerateMagicLink(String stayId) => _guard(() async {
        final u = await _live(_repository.regenerateGuestUuid(stayId));
        _stays = await _reread(_repository.fetchStays) ?? _patched(u);
        showToast(isEs
            ? 'Nuevo Magic Link generado: ${u.magicLinkUrl}'
            : 'New Magic Link generated: ${u.magicLinkUrl}');
      }, AdminFailureText.rotateToken);

  Future<void> createNewStay({
    required String villaName,
    required String guestNames,
    required String checkInDate,
    required String checkOutDate,
    required String occasion,
    String? wifiSsid,
    String? wifiPasscode,
  }) =>
      _guard(() async {
        final occ = activeStayForVilla(villaName);
        if (occ != null) {
          return showToast(isEs
              ? 'Error: $villaName está ocupada por ${occ.guestNames}. Libera la villa primero.'
              : 'Error: $villaName is occupied by ${occ.guestNames}. Release the villa first.');
        }
        final c = await _live(_repository.createStay(
            villaName: villaName,
            guestNames: guestNames,
            checkInDate: checkInDate,
            checkOutDate: checkOutDate,
            occasion: occasion,
            wifiSsid: wifiSsid,
            wifiPasscode: wifiPasscode));
        _stays = [c, ..._stays.where((s) => s.stayId != c.stayId)];
        showToast(isEs
            ? 'Estancia creada (${c.guestNames} · ${c.villaName}): ${c.magicLinkUrl}'
            : 'Stay created (${c.guestNames} · ${c.villaName}): ${c.magicLinkUrl}');
      }, AdminFailureText.createStay);

  Future<void> updateStayWifi(
          {required String stayId,
          required String wifiSsid,
          required String wifiPasscode}) =>
      _guard(() async {
        final u = await _live(_repository.updateStayWifi(
            stayId: stayId, wifiSsid: wifiSsid, wifiPasscode: wifiPasscode));
        _stays = _patched(u);
        showToast(isEs
            ? 'Red Wi-Fi actualizada (${u.villaName}): ${u.wifiSsid}'
            : 'Wi-Fi updated (${u.villaName}): ${u.wifiSsid}');
      });

  Future<void> checkInGuest(String stayId) => _guard(() async {
        final u = await _live(_repository.updateStayLifecycle(
            stayId: stayId, status: StayLifecycleStatus.activeStay));
        _stays = await _reread(_repository.fetchStays) ?? _patched(u);
        showToast(isEs
            ? 'Llegada registrada (Check-In): ${u.guestNames} en ${u.villaName}'
            : 'Guest checked in: ${u.guestNames} at ${u.villaName}');
      });

  Future<void> checkOutAndReleaseVilla(String stayId) => _guard(() async {
        final u = await _live(_repository.approveExpressCheckout(
            stayId: stayId, approveLateCheckout: false));
        _stays = await _reread(_repository.fetchStays) ?? _patched(u);
        showToast(isEs
            ? 'Salida registrada: Villa liberada y disponible para nuevo huésped'
            : 'Check-out complete: Villa released and available for new guest');
      });

  Future<void> updateTransferDispatch({
    required String stayId,
    required String chauffeurId,
    required String transferStatus,
    String? driverAndVehicle,
    String? meetingPoint,
  }) =>
      _guard(() async {
        final u = await _live(_repository.updateTransferDispatch(
            stayId: stayId,
            chauffeurId: chauffeurId,
            transferStatus: transferStatus,
            driverAndVehicle: driverAndVehicle,
            meetingPoint: meetingPoint));
        _stays = await _reread(_repository.fetchStays) ?? _patched(u);
        final drv =
            AdminI18n.staffLabel(u.transfer.assignedChauffeurName, isEs);
        showToast(isEs
            ? 'Traslado (${u.villaName}) actualizado a: ${AdminI18n.statusLabel(transferStatus, true)}'
            : 'Transfer updated: $drv · $transferStatus (${u.villaName})');
      });

  Future<void> assignAndNotifyBooking({
    required String bookingId,
    String? staffId,
    required String status,
    String? cancellationReason,
  }) =>
      _guard(() async {
        final u = await _live(_repository.assignAndUpdateBooking(
            bookingId: bookingId,
            staffId: staffId ?? _requireStaff().staffId,
            status: status,
            cancellationReason: cancellationReason));
        _bookings = await _reread(_repository.fetchBookings) ?? _bookings;
        showToast(isEs
            ? 'Reserva "${u.title}" actualizada a: ${AdminI18n.statusLabel(u.status, true)} (HOST ADMIN)'
            : 'Booking "${u.title}" — Assigned & Notified ${u.assignedStaffName} (${u.status})');
      });

  Future<void> addExperienceCatalogItem({
    required String title,
    required String category,
    required String duration,
    required double basePriceUSD,
    bool isIncluded = false,
    String description = '',
  }) =>
      _guard(() async {
        final item = await _live(_repository.createExperienceCatalogItem(
            title: title,
            category: category,
            duration: duration,
            basePriceUSD: basePriceUSD,
            isIncluded: isIncluded,
            description: description));
        _experienceCatalog =
            await _reread(_repository.fetchExperienceCatalog) ??
                _experienceCatalog;
        showToast(isEs
            ? 'Experiencia agregada al catálogo: ${item.title}'
            : 'Experience added to catalog: ${item.title}');
      });

  Future<void> deleteExperienceCatalogItem(String id) => _guard(() async {
        await _live(_repository.deleteExperienceCatalogItem(id));
        _experienceCatalog =
            await _reread(_repository.fetchExperienceCatalog) ??
                _experienceCatalog;
        showToast(isEs
            ? 'Experiencia eliminada del catálogo'
            : 'Experience removed from catalog');
      });

  Future<void> updateLarderOrderStatus(
          {required String orderId,
          required String status,
          required String staffId}) =>
      _guard(() async {
        final u = await _live(_repository.updateLarderOrder(
            orderId: orderId, status: status, staffId: staffId));
        _larderOrders =
            await _reread(_repository.fetchLarderOrders) ?? _larderOrders;
        showToast(isEs
            ? 'Pedido de Minibar (${u.villaName}) actualizado a: ${AdminI18n.statusLabel(status, true)}'
            : 'Minibar order (${u.villaName}) marked ${u.status} (${u.assignedStaffName})');
      });

  Future<void> addLarderCatalogItem({
    required String name,
    required String category,
    required double price,
    required String storageType,
    String description = '',
  }) =>
      _guard(() async {
        final item = await _live(_repository.createLarderCatalogItem(
            name: name,
            category: category,
            price: price,
            storageType: storageType,
            description: description));
        _larderCatalog =
            await _reread(_repository.fetchLarderCatalog) ?? _larderCatalog;
        showToast(isEs
            ? 'Producto agregado al catálogo: ${item.name}'
            : 'Product added to minibar catalog: ${item.name}');
      });

  Future<void> deleteLarderCatalogItem(String id) => _guard(() async {
        await _live(_repository.deleteLarderCatalogItem(id));
        _larderCatalog =
            await _reread(_repository.fetchLarderCatalog) ?? _larderCatalog;
        showToast(isEs
            ? 'Producto eliminado del catálogo'
            : 'Product removed from minibar catalog');
      });

  Future<void> advanceConciergeTicketStage(
          {required String requestId,
          required ConciergeStage targetStage,
          String? staffId}) =>
      _guard(() async {
        final u = await _live(_repository.updateConciergeTicket(
            requestId: requestId, stage: targetStage, staffId: staffId));
        _conciergeTickets = await _reread(_repository.fetchConciergeTickets) ??
            _conciergeTickets;
        showToast(isEs
            ? 'Solicitud "${u.title}" actualizada a: ${AdminI18n.statusLabel(u.stage.label, true)}'
            : 'Request "${u.title}" updated to: ${u.stage.label} · ${u.assignedStaffName}');
      });

  Future<void> sendConciergeHostReply(
          {required String requestId, required String messageText}) =>
      _guard(() async {
        if (messageText.trim().isEmpty) return;
        final staff = _requireStaff();
        await _live(_repository.appendConciergeReply(
            requestId: requestId,
            senderName: staff.fullName,
            senderRole: staff.role,
            messageText: messageText.trim()));
        _conciergeTickets = await _reread(_repository.fetchConciergeTickets) ??
            _conciergeTickets;
        showToast(isEs
            ? 'Respuesta enviada al huésped por HOST ADMIN'
            : 'Reply sent to guest by HOST ADMIN');
      });

  Future<void> attendMidStayPulse(
          {required String checkInId, required String followUpNote}) =>
      _guard(() async {
        await _live(_repository.attendMidStayPulse(
            checkInId: checkInId,
            followUpNote: followUpNote,
            staffName: _requireStaff().fullName));
        _midStayPulses =
            await _reread(_repository.fetchMidStayPulses) ?? _midStayPulses;
        showToast(isEs
            ? 'Comentario de estancia atendido por HOST ADMIN'
            : 'Guest stay feedback attended by HOST ADMIN');
      });

  Future<void> approveExpressCheckout(
          {required String stayId, required bool approveLateCheckout}) =>
      _guard(() async {
        final u = await _live(_repository.approveExpressCheckout(
            stayId: stayId, approveLateCheckout: approveLateCheckout));
        _stays = await _reread(_repository.fetchStays) ?? _patched(u);
        showToast(isEs
            ? 'Salida completada: ${u.villaName} ahora está LIBRE'
            : 'Express Checkout settled for ${u.villaName} (${u.paymentStatus})');
      });

  Future<void> _guard(Future<void> Function() run,
          [FailureText failure = AdminFailureText.mutation]) =>
      runServerConfirmed(run, report: showToast, failureMessage: failure(isEs));

  /// Awaits a repository call and aborts the action if disposed or if the
  /// staff session changed meanwhile.
  Future<T> _live<T>(Future<T> pending) async {
    final epoch = _epoch, value = await pending;
    if (_isStale(epoch)) throw const OwnerDisposedException();
    return value;
  }

  bool _isStale(int epoch) => _isDisposed || epoch != _epoch;

  /// Re-read after a server-confirmed mutation: null on failure (the live
  /// sync catches up), so success is still reported exactly once.
  Future<T?> _reread<T>(Future<T> Function() read) =>
      _live(bestEffortRead(read));

  List<AdminStayRecord> _patched(AdminStayRecord u) =>
      [for (final s in _stays) s.stayId == u.stayId ? u : s];

  StaffMember _requireStaff() =>
      activeStaff ?? (throw const NoSessionStaffException());

  @override
  void dispose() {
    _isDisposed = true;
    _chime.dispose();
    _repository.dispose();
    super.dispose();
  }
}
