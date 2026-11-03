import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/audio/soundscape_port.dart';
import '../core/auth/magic_link_parser.dart';
import '../core/constants/screen_id.dart';
import '../core/i18n/guest_feedback_i18n.dart';
import '../core/i18n/guest_i18n.dart';
import '../domain/entities/concierge_folio_entities.dart';
import '../domain/entities/empty_sanctuary.dart';
import '../domain/entities/experience_entities.dart';
import '../domain/entities/stay_entities.dart';
import '../domain/repositories/sanctuary_repository.dart';
import 'larder_order_state.dart';
import 'poll_merge.dart';
import 'sanctuary_connection.dart';
import 'sanctuary_poller.dart';

/// Application state controller managing all 13 guest sanctuary screens,
/// UUID v4 Magic-Link auth, Step-Up verification, 432Hz Soundscape, and mutations.
class SanctuaryController extends ChangeNotifier {
  SanctuaryController({
    required SanctuaryRepository repository,
    required SoundscapePort soundscape,
    Uri? initialUri,
    bool requireExplicitGuestId = false,
    Duration pollInterval = SanctuaryPoller.defaultInterval,
  })  : _repository = repository,
        _soundscape = soundscape,
        _requireExplicitGuestId = requireExplicitGuestId,
        _authResult = MagicLinkParser.parseUri(initialUri ?? Uri.base) {
    _poller = SanctuaryPoller(
        onPoll: _fetchAndHydrate,
        onError: _onPollError,
        interval: pollInterval);
    _hydrateFromSnapshot(EmptySanctuary.snapshot(_authResult.guestUuid));
  }

  final SanctuaryRepository _repository;
  final SoundscapePort _soundscape;
  final bool _requireExplicitGuestId;
  final MagicLinkParseResult _authResult;
  late final SanctuaryPoller _poller;
  final SanctuaryConnection _connection = SanctuaryConnection();

  ScreenId _currentScreen = ScreenId.home;
  GuestLocale _locale = GuestLocale.en;
  bool _isDrawerOpen = false,
      _isStepUpVerified = false,
      _isDisposed = false,
      _hasUnsavedLarderEdits = false,
      _isLarderOrderConfirmed = false,
      _isToastError = false;
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
      !_connection.isLinkRejected;
  String get guestUuid => _authResult.guestUuid;

  /// A link was given but is malformed or the server rejected it.
  bool get isLinkInvalid =>
      _authResult.errorMessage != null || _connection.isLinkRejected;
  bool get isStepUpVerified => _isStepUpVerified;
  bool get isReadOnly =>
      _stay.lifecycleStatus == StayLifecycleStatus.checkedOut;
  String? get activeToastMessage => _activeToastMessage;
  bool get isToastError => _isToastError;

  /// False until the server answers once; the UI shows a loading screen.
  bool get hasServerData => _connection.hasServerData;

  /// True while the last fetch failed transiently (5xx, 429, network).
  bool get isReconnecting => _connection.isReconnecting;
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
  int get yachtNetUpgradeUsd =>
      _yachtPackages
          .where((p) => p.id == _yachtCharter.selectedPackageId)
          .firstOrNull
          ?.netUpgradeUsd ??
      0;

  /// Paid lines exactly as the server folio lists them.
  int get folioTotalIncidentalsUsd => _folioItems
      .where((i) => !i.isIncludedPrivilege)
      .fold<int>(0, (s, i) => s + i.amountUsd);

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
    _latestMidStayCheckIn = s.latestMidStayCheckIn ?? _latestMidStayCheckIn;
    _applyLarderOrder(s.larderItems);
    _larderItems = PollMerge.larder(s.larderItems,
        unsavedCart: isBackgroundPoll && _hasUnsavedLarderEdits
            ? _larderItems
            : const []);
    _hydrateBookings(s, isBackgroundPoll: isBackgroundPoll);
  }

  void _applyLarderOrder(List<LarderItem> incoming) {
    final order = LarderOrderState.fromServerItems(incoming);
    if (order == null) return;
    _larderOrderStatus = order.status;
    _isLarderOrderConfirmed = order.isConfirmed;
    _submittedLarderItems = order.submittedItems;
  }

  /// A background poll never unlocks a request the guest already made.
  void _hydrateBookings(SanctuarySnapshot s, {required bool isBackgroundPoll}) {
    _experiences = isBackgroundPoll
        ? PollMerge.experiences(s.experiences, _experiences)
        : List.from(s.experiences);
    if (!isBackgroundPoll || s.yachtCharter.bookingStatus.isNotEmpty) {
      _yachtCharter = s.yachtCharter;
    }
    if (!isBackgroundPoll || s.diningReservation.bookingStatus.isNotEmpty) {
      _diningReservation = s.diningReservation;
    }
  }

  /// First load. Shares the poller's in-flight guard with every refresh.
  Future<void> initialize() => _poller.pollNow();

  /// Manual refresh; joins a poll already in flight instead of overlapping.
  Future<void> refreshFromBackend() => _poller.pollNow();

  void startLivePolling() => _poller.start();

  void stopLivePolling() => _poller.stop();

  /// False once the server rejected the link: a rejected link is final.
  bool get _canReachServer => isUuidValid && !_isDisposed;

  Future<void> _fetchAndHydrate() async {
    if (!_canReachServer) return;
    _applyFetchResult(await _repository.fetchLiveSanctuary(guestUuid));
  }

  /// Any unexpected poll error is treated like an unreachable server.
  void _onPollError(Object error, StackTrace stack) =>
      _applyFetchResult(const SanctuaryUnreachable());

  void _applyFetchResult(SanctuaryFetchResult result) {
    if (_isDisposed) return;
    final hadServerData = _connection.hasServerData;
    final (:fresh, :changed) = _connection.record(result);
    if (fresh != null) {
      _hydrateFromSnapshot(fresh, isBackgroundPoll: hadServerData);
    }
    if (_connection.isLinkRejected) _poller.stop();
    if (changed) _notify();
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  void navigateTo(ScreenId screen) {
    _currentScreen = screen;
    _isDrawerOpen = false;
    _notify();
  }

  void setDrawerOpen(bool open) {
    _isDrawerOpen = open;
    _notify();
  }

  void toggleSoundscape() {
    _soundscape.toggle();
    _notify();
  }

  void toggleLocale() {
    _locale = isEs ? GuestLocale.en : GuestLocale.es;
    _notify();
  }

  void showToast(String? message) => _showToast(message);

  /// Sets message and error flag together so listeners never see a mix.
  void _showToast(String? message, {bool isError = false}) {
    _activeToastMessage = message;
    _isToastError = isError;
    _notify();
  }

  /// Awaits the server; on failure shows a one-line error instead of success.
  Future<bool> _serverConfirms(Future<MutationResult> request) async {
    final confirmed = switch (await request) {
      MutationConfirmed() => true,
      MutationFailed() => false,
    };
    if (_isDisposed) return false;
    if (confirmed) return true;
    _showToast(i18n.mutationFailed, isError: true);
    return false;
  }

  void clearToast() => showToast(null);

  /// Verified only when the server issues a step-up token for [answer]
  /// (villa number or last name); the caller shows the failure line.
  Future<bool> verifyStepUp(String answer) async {
    final candidate = answer.trim();
    if (candidate.isEmpty) return false;
    final token = await _repository.verifyStepUpChallenge(guestUuid, candidate);
    if (_isDisposed || token == null || token.isEmpty) return false;
    _isStepUpVerified = true;
    _stepUpSessionToken = token;
    showToast(i18n.identityVerified(_stay.villaTitle));
    return true;
  }

  Future<bool> updateFlightDetails(FlightTransport updated) async {
    if (_guardReadOnly()) return false;
    if (!await _serverConfirms(_repository.syncFlightTransport(
        guestUuid, updated,
        stepUpSession: _stepUpSessionToken))) {
      return false;
    }
    _transport = updated;
    showToast(i18n.flightSynced);
    return true;
  }

  Future<bool> savePersonalization(PersonalizationPreferences updated) async {
    if (_guardReadOnly()) return false;
    if (!await _serverConfirms(_repository.savePersonalization(
        guestUuid, updated,
        stepUpSession: _stepUpSessionToken))) {
      return false;
    }
    _preferences = updated;
    _markChecklistCompleted('chk-1');
    showToast(i18n.personalizationSaved(_stay.villaTitle));
    return true;
  }

  Future<bool> saveStayPersonalization(PersonalizationPreferences updated) =>
      savePersonalization(updated);

  /// Local selection only: no server endpoint stores it yet, so nothing is
  /// announced as saved or coordinated.
  void switchSignaturePrivilege(String privilegeId) {
    if (_guardReadOnly()) return;
    _stay = _stay.copyWith(selectedSignaturePrivilege: privilegeId);
    _notify();
  }

  void toggleExperienceReservation(
    String id, {
    String? scheduledDate,
    String? scheduledTimeSlot,
  }) {
    if (_guardReadOnly()) return;
    final existing = _experiences.where((e) => e.id == id).firstOrNull;
    if (existing == null || existing.bookingStatus.isNotEmpty) return;
    final sDate = _trimmedOr(scheduledDate, _stay.defaultStayDateLabel);
    final sTime = _trimmedOr(scheduledTimeSlot, '');
    if (sDate.isEmpty || sTime.isEmpty) return;
    final fullSlot = '$sDate · $sTime';
    final booked = existing.copyWith(
      isScheduled: true,
      isReserved: true,
      scheduledSlot: fullSlot,
      scheduledDate: sDate,
      scheduledTimeSlot: sTime,
      bookingStatus: 'REQUESTED',
    );
    _experiences = [for (final e in _experiences) e.id == id ? booked : e];
    _notify();
    unawaited(_confirmExperienceRequest(existing, booked, fullSlot));
  }

  static String _trimmedOr(String? value, String fallback) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isNotEmpty ? trimmed : fallback;
  }

  /// Keeps the optimistic lock only if the server confirms; otherwise reverts.
  Future<void> _confirmExperienceRequest(
      ExperienceItem original, ExperienceItem booked, String slot) async {
    if (await _serverConfirms(_repository.saveExperienceBooking(
        guestUuid, booked, slot,
        partySize: _stay.guestsCount, stepUpSession: _stepUpSessionToken))) {
      return showToast(i18n.experienceRequested(slot));
    }
    if (_isDisposed) return;
    _experiences = [
      for (final e in _experiences) e.id == original.id ? original : e
    ];
    _notify();
  }

  void scheduleExperience(String id, String slot) {
    final parts = slot.split('·');
    final sDate = parts.first.trim();
    final sTime = parts.length > 1 ? parts.last.trim() : '';
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
    _notify();
  }

  Future<bool> confirmVillaStocking() async {
    if (_guardReadOnly() || larderTotalCount == 0) return false;
    final orderedItems = _larderItems
        .where((i) => i.quantity > 0)
        .map(
            (i) => i.copyWith(isConfirmed: true, provisioningStatus: 'Pending'))
        .toList();
    final orderedCount = orderedItems.fold<int>(0, (s, i) => s + i.quantity);
    if (!await _serverConfirms(_repository.saveLarderOrder(
        guestUuid, orderedItems,
        stepUpSession: _stepUpSessionToken))) {
      return false;
    }
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
    showToast(i18n.larderStocked(_stay.villaNumber, orderedCount));
    return true;
  }

  Future<bool> confirmLarderSelection() => confirmVillaStocking();

  void updateYachtGuestCount(int count) =>
      _editYachtForm((c) => c.copyWith(guestCount: count.clamp(1, 12)));

  void selectYachtPackage(String packageId) =>
      _editYachtForm((c) => c.copyWith(selectedPackageId: packageId));

  void updateYachtDate(String selectedDate) =>
      _editYachtForm((c) => c.copyWith(selectedDate: selectedDate));

  void updateYachtSlot(String selectedSlot) =>
      _editYachtForm((c) => c.copyWith(selectedSlot: selectedSlot));

  /// The form is editable until the request is sent.
  void _editYachtForm(YachtCharterConfig Function(YachtCharterConfig) edit) {
    if (_guardReadOnly() || _yachtCharter.bookingStatus.isNotEmpty) return;
    _yachtCharter = edit(_yachtCharter);
    _notify();
  }

  Future<bool> submitYachtCharterRequest() async {
    if (_guardReadOnly() || _yachtCharter.bookingStatus.isNotEmpty) {
      return false;
    }
    final effectiveDate = _yachtCharter.selectedDate.trim().isEmpty
        ? _stay.defaultStayDateLabel
        : _yachtCharter.selectedDate.trim();
    final request = _yachtCharter.copyWith(
      selectedDate: effectiveDate,
      isConfirmed: false,
      bookingStatus: 'REQUESTED',
    );
    if (!await _serverConfirms(_repository.saveYachtCharter(guestUuid, request,
        stepUpSession: _stepUpSessionToken))) {
      return false;
    }
    _yachtCharter = request;
    _markChecklistCompleted('chk-3');
    showToast(i18n.yachtRequested);
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
    final request = baseRes.copyWith(
      selectedEvening: effectiveDate,
      isConfirmed: false,
      bookingStatus: 'REQUESTED',
    );
    if (!await _serverConfirms(_repository.saveDiningReservation(
        guestUuid, request,
        stepUpSession: _stepUpSessionToken))) {
      return false;
    }
    _diningReservation = request;
    showToast(i18n.diningRequested);
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
      timestampLabel: i18n.requestedJustNow,
      stage: ConciergeStage.requested,
      assignedTo: '',
      details: details.trim(),
      photoUrl: photoUrl,
    );
    if (!await _serverConfirms(_repository.submitConciergeRequest(
        guestUuid, req,
        stepUpSession: _stepUpSessionToken))) {
      return false;
    }
    await refreshFromBackend();
    if (_isDisposed) return false;
    if (!_conciergeRequests.any((r) => r.title == req.title)) {
      _conciergeRequests = [req, ..._conciergeRequests];
    }
    showToast(i18n.conciergeDispatched);
    return true;
  }

  void advanceConciergeRequestStage(String id) {
    if (_guardReadOnly()) return;
    _conciergeRequests = _conciergeRequests
        .map((r) => r.id == id ? r.copyWith(stage: r.stage.nextStage) : r)
        .toList();
    _notify();
  }

  /// Shows the message at once and removes it if the server does not
  /// confirm it.
  Future<bool> sendChatMessage(String text) async {
    final t = text.trim();
    if (_guardReadOnly() || t.isEmpty) return false;
    final msg = ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      senderName: _stay.guestNames,
      isFromHost: false,
      text: t,
      timestampLabel: i18n.sentJustNow,
    );
    _chatMessages = [..._chatMessages, msg];
    _notify();
    final sent = await _deliverChatMessage(t);
    if (!sent && !_isDisposed) {
      _chatMessages = _chatMessages.where((m) => m.id != msg.id).toList();
      _notify();
    }
    return sent;
  }

  Future<bool> _deliverChatMessage(String text) => _conciergeRequests.isEmpty
      ? createConciergeRequest(
          title: text, category: 'Concierge', details: text)
      : _serverConfirms(_repository.appendConciergeMessage(
          guestUuid,
          _conciergeRequests.first.id,
          text,
          senderName: _stay.guestNames,
          stepUpSession: _stepUpSessionToken,
        ));

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
      submittedAtLabel: i18n.submittedJustNow,
    );
    if (!await _serverConfirms(_repository.submitMidStayCheckIn(
        guestUuid, checkIn,
        stepUpSession: _stepUpSessionToken))) {
      return false;
    }
    _latestMidStayCheckIn = checkIn;
    showToast(i18n.midStayShared);
    return true;
  }

  void toggleDigitalKeycard() {
    if (!_guardReadOnly()) {
      _stay = _stay.copyWith(isDigitalKeyEnabled: !_stay.isDigitalKeyEnabled);
      _notify();
    }
  }

  Future<bool> completeExpressCheckout() async {
    final token = _stepUpSessionToken;
    if (_guardReadOnly() || token == null) return false;
    if (!await _serverConfirms(
        _repository.completeCheckout(guestUuid, stepUpToken: token))) {
      return false;
    }
    _stay = _stay.copyWith(lifecycleStatus: StayLifecycleStatus.checkedOut);
    showToast(i18n.checkoutCompleted(_stay.villaNumber));
    return true;
  }

  void _markChecklistCompleted(String id) {
    _checklist = _checklist
        .map((t) => t.id == id ? t.copyWith(isCompleted: true) : t)
        .toList();
  }

  bool _guardReadOnly() {
    if (!isReadOnly) return false;
    showToast(i18n.readOnlyArchive);
    return true;
  }

  @override
  void dispose() {
    if (!_isDisposed) {
      _isDisposed = true;
      _poller.stop();
      _repository.dispose();
      super.dispose();
    }
  }
}
