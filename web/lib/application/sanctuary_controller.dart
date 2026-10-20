import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/audio/soundscape_port.dart';
import '../core/auth/magic_link_parser.dart';
import '../core/constants/screen_id.dart';
import '../core/i18n/guest_i18n.dart';
import '../data/seed/villa_102_seed_data.dart';
import '../domain/entities/concierge_folio_entities.dart';
import '../domain/entities/experience_entities.dart';
import '../domain/entities/stay_entities.dart';
import '../domain/repositories/sanctuary_repository.dart';

/// Application state controller managing all 13 guest sanctuary screens,
/// UUID v4 Magic-Link auth, Step-Up verification, 432Hz Soundscape, and mutations.
class SanctuaryController extends ChangeNotifier {
  SanctuaryController({
    required SanctuaryRepository repository,
    required SoundscapePort soundscape,
    Uri? initialUri,
    bool requireExplicitGuestId = false,
  })  : _repository = repository,
        _soundscape = soundscape,
        _requireExplicitGuestId = requireExplicitGuestId,
        _authResult = MagicLinkParser.parseUri(initialUri ?? Uri.base) {
    _hydrateFromSnapshot(
        Villa102SeedData.buildDefaultSnapshot(_authResult.guestUuid));
  }

  final SanctuaryRepository _repository;
  final SoundscapePort _soundscape;
  final bool _requireExplicitGuestId;
  final MagicLinkParseResult _authResult;

  ScreenId _currentScreen = ScreenId.home;
  GuestLocale _locale = GuestLocale.en;
  bool _isDrawerOpen = false,
      _isStepUpVerified = false,
      _isDisposed = false,
      _hasUnsavedLarderEdits = false,
      _isLarderOrderConfirmed = false,
      _stayNotFoundOnBackend = false;
  String _larderOrderStatus = '';
  String? _stepUpSessionToken, _activeToastMessage;
  MidStayCheckIn? _latestMidStayCheckIn;
  List<LarderItem> _submittedLarderItems = [];

  late StaySummary _stay;
  late FlightTransport _transport;
  late PersonalizationPreferences _preferences;
  late YachtCharterConfig _yachtCharter;
  late DiningReservation _diningReservation;
  late List<ChecklistTask> _checklist;
  late List<LarderItem> _larderItems;
  late List<ExperienceItem> _experiences;
  late List<YachtPackageOption> _yachtPackages;
  late List<DiningMenuOption> _diningMenus;
  late List<ConciergeRequest> _conciergeRequests;
  late List<ChatMessage> _chatMessages;
  late List<FolioLineItem> _folioItems;

  ScreenId get currentScreen => _currentScreen;
  GuestLocale get locale => _locale;
  bool get isEs => _locale == GuestLocale.es;
  GuestI18n get i18n => GuestI18n(_locale);
  bool get isDrawerOpen => _isDrawerOpen;
  bool get isUuidValid =>
      _authResult.isValid &&
      !(_requireExplicitGuestId && _authResult.isDefaultDemo) &&
      !_stayNotFoundOnBackend;
  String get guestUuid => _authResult.guestUuid;
  String? get authErrorMessage => _authResult.errorMessage;
  bool get isStepUpVerified => _isStepUpVerified;
  bool get isReadOnly =>
      _stay.lifecycleStatus == StayLifecycleStatus.checkedOut;
  String? get activeToastMessage => _activeToastMessage;
  bool get isSoundscapeActive => _soundscape.isActive;
  int get soundscapeFrequencyHz => _soundscape.rootFrequencyHz;
  StaySummary get stay => _stay;
  FlightTransport get transport => _transport;
  PersonalizationPreferences get preferences => _preferences;
  List<ChecklistTask> get checklist => List.unmodifiable(_checklist);
  List<LarderItem> get larderItems => List.unmodifiable(_larderItems);
  List<LarderItem> get submittedLarderItems =>
      List.unmodifiable(_submittedLarderItems);
  List<ExperienceItem> get experiences => List.unmodifiable(_experiences);
  List<YachtPackageOption> get yachtPackages =>
      List.unmodifiable(_yachtPackages);
  YachtCharterConfig get yachtCharter => _yachtCharter;
  List<DiningMenuOption> get diningMenus => List.unmodifiable(_diningMenus);
  DiningReservation get diningReservation => _diningReservation;
  List<ConciergeRequest> get conciergeRequests =>
      List.unmodifiable(_conciergeRequests);
  List<ChatMessage> get chatMessages => List.unmodifiable(_chatMessages);
  List<FolioLineItem> get folioItems => List.unmodifiable(_folioItems);
  MidStayCheckIn? get latestMidStayCheckIn => _latestMidStayCheckIn;

  String get larderOrderStatus {
    if (_larderOrderStatus.isNotEmpty) return _larderOrderStatus;
    for (final item in _larderItems) {
      if (item.provisioningStatus.isNotEmpty) return item.provisioningStatus;
    }
    return '';
  }

  bool get isLarderOrderConfirmed =>
      _isLarderOrderConfirmed || _larderItems.any((i) => i.isConfirmed);

  int get completedChecklistCount =>
      _checklist.where((i) => i.isCompleted).length;
  int get larderTotalAmount =>
      _larderItems.fold<int>(0, (s, i) => s + (i.priceUsd * i.quantity));
  int get submittedLarderTotalAmount => _submittedLarderItems.fold<int>(
      0, (s, i) => s + (i.priceUsd * i.quantity));
  int get larderTotalCount =>
      _larderItems.fold<int>(0, (s, i) => s + i.quantity);
  int get yachtNetUpgradeUsd => _yachtPackages
      .firstWhere(
        (p) => p.id == _yachtCharter.selectedPackageId,
        orElse: () => _yachtPackages.first,
      )
      .netUpgradeUsd;
  int get folioTotalIncidentalsUsd =>
      _folioItems
          .where((i) => !i.isIncludedPrivilege && i.id != 'fol-paid-2')
          .fold<int>(0, (s, i) => s + i.amountUsd) +
      (larderTotalAmount > 0 ? larderTotalAmount : submittedLarderTotalAmount) +
      yachtNetUpgradeUsd;

  void _hydrateFromSnapshot(
    SanctuarySnapshot s, {
    bool isBackgroundPoll = false,
  }) {
    _stay = s.stay;
    _transport = s.transport;
    _preferences = s.preferences;
    _checklist = List.from(s.checklist);
    _yachtPackages = List.from(s.yachtPackages);
    _diningMenus = List.from(s.diningMenus);
    _conciergeRequests = List.from(s.conciergeRequests);
    _chatMessages = List.from(s.chatMessages);
    _folioItems = List.from(s.folioItems);
    if (s.latestMidStayCheckIn != null) {
      _latestMidStayCheckIn = s.latestMidStayCheckIn;
    }
    if (!isBackgroundPoll) {
      _experiences = List.from(s.experiences);
      _yachtCharter = s.yachtCharter;
      _diningReservation = s.diningReservation;
      final statusItem = s.larderItems
          .where((i) => i.provisioningStatus.isNotEmpty)
          .firstOrNull;
      if (statusItem != null) {
        final raw = statusItem.provisioningStatus.toLowerCase();
        final isDelivered =
            raw.contains('stocked') || raw.contains('delivered');
        _larderOrderStatus =
            isDelivered ? 'Stocked in Villa' : statusItem.provisioningStatus;
        _isLarderOrderConfirmed = !isDelivered;
        _submittedLarderItems = isDelivered
            ? []
            : s.larderItems.where((i) => i.quantity > 0).toList();
      }
      _larderItems = s.larderItems
          .map((i) => i.copyWith(quantity: 0, isConfirmed: false))
          .toList();
      return;
    }
    _larderItems = _mergePollLarder(s.larderItems);
    _experiences = _mergePollExperiences(s.experiences);
    if (s.yachtCharter.bookingStatus.isNotEmpty) {
      _yachtCharter = s.yachtCharter;
    }
    if (s.diningReservation.bookingStatus.isNotEmpty) {
      _diningReservation = s.diningReservation;
    }
  }

  List<LarderItem> _mergePollLarder(List<LarderItem> incoming) {
    final prevById = {for (final i in _larderItems) i.id: i};
    final incomingStatus = incoming
            .where((i) => i.provisioningStatus.isNotEmpty)
            .firstOrNull
            ?.provisioningStatus ??
        '';
    final isDelivered = incomingStatus.toLowerCase().contains('stocked') ||
        incomingStatus.toLowerCase().contains('delivered');
    if (isDelivered) {
      _submittedLarderItems = [];
      _larderOrderStatus = 'Stocked in Villa';
      _isLarderOrderConfirmed = false;
    } else if (incomingStatus.isNotEmpty) {
      _submittedLarderItems = incoming.where((i) => i.quantity > 0).toList();
      _larderOrderStatus = incomingStatus;
      _isLarderOrderConfirmed = true;
    }
    return incoming.map((item) {
      final prev = prevById[item.id];
      final qty = _hasUnsavedLarderEdits ? (prev?.quantity ?? 0) : 0;
      return item.copyWith(
        quantity: qty,
        isConfirmed: false,
        provisioningStatus: item.provisioningStatus,
      );
    }).toList();
  }

  List<ExperienceItem> _mergePollExperiences(List<ExperienceItem> incoming) {
    final prevById = {for (final e in _experiences) e.id: e};
    return incoming.map((exp) {
      final prev = prevById[exp.id];
      return (!exp.isReserved && prev != null && prev.isReserved) ? prev : exp;
    }).toList();
  }

  Future<void> initialize() => _fetchAndHydrate(isBackgroundPoll: false);
  Future<void> refreshFromBackend() => _fetchAndHydrate(isBackgroundPoll: true);

  Future<void> _fetchAndHydrate({required bool isBackgroundPoll}) async {
    if (!_authResult.isValid ||
        (_requireExplicitGuestId && _authResult.isDefaultDemo) ||
        _isDisposed) {
      return;
    }
    final live = await _repository.fetchLiveSanctuary(guestUuid);
    if (_isDisposed) return;
    if (live == null) {
      if (_requireExplicitGuestId) {
        _stayNotFoundOnBackend = true;
        notifyListeners();
      }
      return;
    }
    _stayNotFoundOnBackend = false;
    _hydrateFromSnapshot(live, isBackgroundPoll: isBackgroundPoll);
    notifyListeners();
  }

  void navigateTo(ScreenId screen) {
    _currentScreen = screen;
    _isDrawerOpen = false;
    notifyListeners();
  }

  void setDrawerOpen(bool open) {
    _isDrawerOpen = open;
    notifyListeners();
  }

  void toggleSoundscape() {
    _soundscape.toggle();
    notifyListeners();
  }

  void toggleLocale() {
    _locale = isEs ? GuestLocale.en : GuestLocale.es;
    notifyListeners();
  }

  void showToast(String? message) {
    _activeToastMessage = message;
    notifyListeners();
  }

  void clearToast() => showToast(null);

  bool verifyStepUp(String challengeInput) {
    final n = challengeInput.trim().toLowerCase(),
        v = _stay.villaNumber.toLowerCase();
    if (n != v && n != 'villa $v' && n != _stay.lastName.toLowerCase()) {
      return false;
    }
    _isStepUpVerified = true;
    _stepUpSessionToken = 'stepup-verified-${_stay.villaNumber}';
    unawaited(_syncStepUpToken(challengeInput.trim()));
    showToast(i18n.t(
      'Identity verified for ${_stay.villaTitle}.',
      'Identidad verificada para ${_stay.villaTitle}.',
    ));
    return true;
  }

  Future<void> _syncStepUpToken(String candidate) async {
    final t = await _repository.verifyStepUpChallenge(
      guestUuid,
      villaNumber: _stay.villaNumber,
      lastName: candidate,
    );
    if (!_isDisposed && t != null && t.isNotEmpty) _stepUpSessionToken = t;
  }

  Future<bool> updateFlightDetails(FlightTransport updated) async {
    if (_guardReadOnly()) return false;
    _transport = updated;
    await _repository.syncFlightTransport(
      guestUuid,
      _transport,
      stepUpSession: _stepUpSessionToken,
    );
    showToast(i18n.t(
      'Flight details updated & synced with HOST ADMIN.',
      'Datos de vuelo actualizados y sincronizados con HOST ADMIN.',
    ));
    return true;
  }

  Future<bool> savePersonalization(PersonalizationPreferences updated) async {
    if (_guardReadOnly()) return false;
    _preferences = updated;
    _markChecklistCompleted('chk-1');
    await _repository.savePersonalization(
      guestUuid,
      _preferences,
      stepUpSession: _stepUpSessionToken,
    );
    showToast(i18n.t(
      'Personalization saved for ${_stay.villaTitle}.',
      'Preferencias guardadas para ${_stay.villaTitle}.',
    ));
    return true;
  }

  Future<bool> saveStayPersonalization(PersonalizationPreferences updated) =>
      savePersonalization(updated);

  void switchSignaturePrivilege(String privilegeId) {
    if (_guardReadOnly()) return;
    _stay = _stay.copyWith(selectedSignaturePrivilege: privilegeId);
    _markChecklistCompleted('chk-2');
    showToast(i18n.t(
      'Included Sanctuary Privilege updated & coordinated with HOST ADMIN.',
      'Beneficio incluido actualizado y coordinado con HOST ADMIN.',
    ));
  }

  void toggleExperienceReservation(
    String id, {
    String? scheduledDate,
    String? scheduledTimeSlot,
  }) {
    if (_guardReadOnly()) return;
    final existing = _experiences.where((e) => e.id == id).firstOrNull;
    if (existing == null || existing.bookingStatus.isNotEmpty) return;
    final sDate = (scheduledDate != null && scheduledDate.trim().isNotEmpty)
        ? scheduledDate.trim()
        : _stay.defaultStayDateLabel;
    final sTime =
        (scheduledTimeSlot != null && scheduledTimeSlot.trim().isNotEmpty)
            ? scheduledTimeSlot.trim()
            : '10:00 AM';
    final fullSlot = '$sDate · $sTime';
    ExperienceItem? booked;
    _experiences = _experiences.map((e) {
      if (e.id != id) return e;
      booked = e.copyWith(
        isScheduled: true,
        isReserved: true,
        scheduledSlot: fullSlot,
        scheduledDate: sDate,
        scheduledTimeSlot: sTime,
        bookingStatus: 'REQUESTED',
      );
      return booked!;
    }).toList();
    if (booked != null) {
      unawaited(_repository.saveExperienceBooking(
        guestUuid,
        booked!,
        fullSlot,
        partySize: _stay.guestsCount,
        stepUpSession: _stepUpSessionToken,
      ));
    }
    showToast(i18n.t(
      'Experience requested for $fullSlot · Pending approval by HOST ADMIN.',
      'Solicitud de experiencia enviada ($fullSlot) · Pendiente de aprobación por HOST ADMIN.',
    ));
  }

  void scheduleExperience(String id, String slot) {
    final parts = slot.split('·');
    final sDate = parts.first.trim();
    final sTime = parts.length > 1 ? parts.last.trim() : '10:00 AM';
    toggleExperienceReservation(
      id,
      scheduledDate: sDate,
      scheduledTimeSlot: sTime,
    );
  }

  void updateLarderQuantity(String itemId, int qty) {
    if (_guardReadOnly()) return;
    final newQuantity = qty.clamp(0, 20);
    final wasStocked = larderOrderStatus.toLowerCase().contains('stocked') ||
        larderOrderStatus.toLowerCase().contains('delivered');
    _hasUnsavedLarderEdits = true;
    if (newQuantity > 0) {
      _isLarderOrderConfirmed = false;
      if (wasStocked) {
        _larderOrderStatus = '';
      }
    }
    _larderItems = _larderItems.map((i) {
      final base = (newQuantity > 0 && wasStocked)
          ? i.copyWith(provisioningStatus: '', isConfirmed: false)
          : i;
      return base.id == itemId ? base.copyWith(quantity: newQuantity) : base;
    }).toList();
    notifyListeners();
  }

  Future<bool> confirmVillaStocking() async {
    if (_guardReadOnly() || larderTotalCount == 0) return false;
    final orderedItems = _larderItems
        .where((i) => i.quantity > 0)
        .map(
            (i) => i.copyWith(isConfirmed: true, provisioningStatus: 'Pending'))
        .toList();
    final orderedCount = orderedItems.fold<int>(0, (s, i) => s + i.quantity);
    _submittedLarderItems = orderedItems;
    _isLarderOrderConfirmed = true;
    _larderOrderStatus = 'Pending';
    _hasUnsavedLarderEdits = false;
    _larderItems = _larderItems
        .map((i) => i.copyWith(
              quantity: 0,
              isConfirmed: false,
              provisioningStatus: 'Pending',
            ))
        .toList();
    notifyListeners();
    await _repository.saveLarderOrder(
      guestUuid,
      orderedItems,
      stepUpSession: _stepUpSessionToken,
    );
    showToast(i18n.t(
      'Villa ${_stay.villaNumber} Larder stocked ($orderedCount items).',
      'Pedido de minibar confirmado para Villa ${_stay.villaNumber} ($orderedCount artículos).',
    ));
    return true;
  }

  Future<bool> confirmLarderSelection() => confirmVillaStocking();

  void updateYachtGuestCount(int count) {
    if (!_guardReadOnly() && _yachtCharter.bookingStatus.isEmpty) {
      _yachtCharter = _yachtCharter.copyWith(guestCount: count.clamp(1, 12));
      notifyListeners();
    }
  }

  void selectYachtPackage(String packageId) {
    if (!_guardReadOnly() && _yachtCharter.bookingStatus.isEmpty) {
      _yachtCharter = _yachtCharter.copyWith(selectedPackageId: packageId);
      notifyListeners();
    }
  }

  void updateYachtDate(String selectedDate) {
    if (!_guardReadOnly() && _yachtCharter.bookingStatus.isEmpty) {
      _yachtCharter = _yachtCharter.copyWith(selectedDate: selectedDate);
      notifyListeners();
    }
  }

  void updateYachtSlot(String selectedSlot) {
    if (!_guardReadOnly() && _yachtCharter.bookingStatus.isEmpty) {
      _yachtCharter = _yachtCharter.copyWith(selectedSlot: selectedSlot);
      notifyListeners();
    }
  }

  Future<bool> submitYachtCharterRequest() async {
    if (_guardReadOnly() || _yachtCharter.bookingStatus.isNotEmpty) {
      return false;
    }
    final effectiveDate = _yachtCharter.selectedDate.trim().isEmpty
        ? _stay.defaultStayDateLabel
        : _yachtCharter.selectedDate.trim();
    _yachtCharter = _yachtCharter.copyWith(
      selectedDate: effectiveDate,
      isConfirmed: false,
      bookingStatus: 'REQUESTED',
    );
    _markChecklistCompleted('chk-3');
    await _repository.saveYachtCharter(
      guestUuid,
      _yachtCharter,
      stepUpSession: _stepUpSessionToken,
    );
    showToast(i18n.t(
      'Solicitud de Yate enviada · Pendiente de aprobación por HOST ADMIN',
      'Solicitud de Yate enviada · Pendiente de aprobación por HOST ADMIN',
    ));
    return true;
  }

  Future<bool> confirmDiningReservation([DiningReservation? updated]) async {
    if (_guardReadOnly() || _diningReservation.bookingStatus.isNotEmpty) {
      return false;
    }
    final baseRes = updated ?? _diningReservation;
    final effectiveDate = baseRes.selectedEvening.trim().isEmpty
        ? _stay.defaultStayDateLabel
        : baseRes.selectedEvening.trim();
    _diningReservation = baseRes.copyWith(
      selectedEvening: effectiveDate,
      isConfirmed: false,
      bookingStatus: 'REQUESTED',
    );
    await _repository.saveDiningReservation(
      guestUuid,
      _diningReservation,
      stepUpSession: _stepUpSessionToken,
    );
    showToast(i18n.t(
      'Solicitud de Cena Privada enviada · Pendiente de aprobación por HOST ADMIN',
      'Solicitud de Cena Privada enviada · Pendiente de aprobación por HOST ADMIN',
    ));
    return true;
  }

  Future<bool> createConciergeRequest({
    required String title,
    required String category,
    required String details,
    String? photoUrl,
  }) async {
    if (_guardReadOnly() || title.trim().isEmpty) return false;
    final req = ConciergeRequest(
      id: 'req-${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      category: category,
      timestampLabel: 'Requested just now',
      stage: ConciergeStage.requested,
      assignedTo: 'HOST ADMIN',
      details: details.trim(),
      photoUrl: photoUrl,
    );
    _conciergeRequests = [req, ..._conciergeRequests];
    await _repository.submitConciergeRequest(
      guestUuid,
      req,
      stepUpSession: _stepUpSessionToken,
    );
    await refreshFromBackend();
    if (!_conciergeRequests.any((r) => r.title == req.title)) {
      _conciergeRequests = [req, ..._conciergeRequests];
    }
    showToast(i18n.t(
      'Concierge request dispatched to HOST ADMIN.',
      'Solicitud enviada a Concierge HOST ADMIN.',
    ));
    return true;
  }

  void advanceConciergeRequestStage(String id) {
    if (_guardReadOnly()) return;
    _conciergeRequests = _conciergeRequests
        .map((r) => r.id == id ? r.copyWith(stage: r.stage.nextStage) : r)
        .toList();
    notifyListeners();
  }

  void sendChatMessage(String text) {
    if (_guardReadOnly() || text.trim().isEmpty) return;
    final t = text.trim(), id = 'msg-${DateTime.now().millisecondsSinceEpoch}';
    final msg = ChatMessage(
      id: id,
      senderName: _stay.guestNames,
      isFromHost: false,
      text: t,
      timestampLabel: 'Just now',
    );
    _chatMessages = [..._chatMessages, msg];
    if (_conciergeRequests.isEmpty) {
      unawaited(
        createConciergeRequest(title: t, category: 'Concierge', details: t),
      );
    } else {
      unawaited(_repository.appendConciergeMessage(
        guestUuid,
        _conciergeRequests.first.id,
        t,
        senderName: _stay.guestNames,
        stepUpSession: _stepUpSessionToken,
      ));
    }
    notifyListeners();
  }

  Future<bool> submitMidStayCheckIn({
    required int rating,
    required String sentimentId,
    required String housekeepingWindow,
    required List<String> focusAreas,
    required String notes,
    required bool requestPriorityCallback,
  }) async {
    if (_guardReadOnly()) return false;
    final checkIn = MidStayCheckIn(
      rating: rating.clamp(1, 5),
      sentimentId: sentimentId,
      housekeepingWindow: housekeepingWindow,
      focusAreas: focusAreas,
      notes: notes.trim(),
      requestPriorityCallback: requestPriorityCallback,
      submittedAtLabel: 'Submitted · Response < 7 Min SLA',
    );
    _latestMidStayCheckIn = checkIn;
    await _repository.submitMidStayCheckIn(
      guestUuid,
      checkIn,
      stepUpSession: _stepUpSessionToken,
    );
    showToast(i18n.t(
      'Mid-Stay pulse shared. HOST ADMIN will respond in < 7 Min.',
      'Comentarios enviados. HOST ADMIN responderá en < 7 min.',
    ));
    return true;
  }

  void toggleDigitalKeycard() {
    if (!_guardReadOnly()) {
      _stay = _stay.copyWith(isDigitalKeyEnabled: !_stay.isDigitalKeyEnabled);
      notifyListeners();
    }
  }

  Future<bool> completeExpressCheckout() async {
    if (_guardReadOnly() || !_isStepUpVerified) return false;
    await _repository.completeCheckout(
      guestUuid,
      stepUpToken: _stepUpSessionToken ?? 'stepup-verified-102',
    );
    _stay = _stay.copyWith(lifecycleStatus: StayLifecycleStatus.checkedOut);
    showToast(i18n.t(
      'Express Check-Out completed. Safe travels from Villa ${_stay.villaNumber}.',
      'Salida Express completada. Buen viaje desde Villa ${_stay.villaNumber}.',
    ));
    return true;
  }

  void _markChecklistCompleted(String id) {
    _checklist = _checklist
        .map((t) => t.id == id ? t.copyWith(isCompleted: true) : t)
        .toList();
  }

  bool _guardReadOnly() {
    if (!isReadOnly) return false;
    showToast(i18n.t(
      'Stay Checked Out — Portal is in Read-Only Archive mode.',
      'Estancia Finalizada — El portal está en modo de solo lectura.',
    ));
    return true;
  }

  @override
  void dispose() {
    if (!_isDisposed) {
      _isDisposed = true;
      _repository.dispose();
      super.dispose();
    }
  }
}
