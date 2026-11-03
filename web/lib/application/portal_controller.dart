import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/auth/magic_link_parser.dart';
import '../core/i18n/l10n.dart';
import '../core/platform/photo_picker.dart';
import '../core/storage/device_prefs.dart';
import '../data/guest_api.dart';
import '../domain/catalog.dart';
import '../domain/journey.dart';
import '../domain/json_read.dart';
import '../domain/requests.dart';
import '../domain/resort_clock.dart';
import '../domain/stay.dart';
import '../domain/trip.dart';

enum PortalPhase { loading, linkMissing, linkInvalid, linkExpired, ready }

/// App state for one guest link: server data (stay, journey marks, requests),
/// the derived journey and the device-only bits (language, form drafts,
/// last seen message).
class PortalController extends ChangeNotifier {
  PortalController({
    required this.api,
    required this.prefs,
    required Uri initialUri,
    this.clock = const ResortClock(),
    this.onLinkRejected,
    this.pollInterval = const Duration(seconds: 30),
  }) : _guestUuid = MagicLinkParser.rawGuestId(initialUri).toLowerCase() {
    lang = _initialLang();
    _phase = switch (MagicLinkParser.statusOf(initialUri)) {
      GuestLinkStatus.missing => PortalPhase.linkMissing,
      GuestLinkStatus.invalid => PortalPhase.linkInvalid,
      GuestLinkStatus.valid => PortalPhase.loading,
    };
  }

  static const String langKey = 'kachava_lang';

  final GuestApi api;
  final DevicePrefs prefs;
  final ResortClock clock;
  final VoidCallback? onLinkRejected;
  final Duration pollInterval;
  final String _guestUuid;

  late Lang lang;
  L10n get l10n => L10n(lang);

  PortalPhase _phase = PortalPhase.loading;
  PortalPhase get phase => _phase;

  GuestStay? _stay;
  GuestStay? get stay => _stay;
  List<CatalogService> _catalog = const [];
  List<CatalogService> get catalog => _catalog;
  List<GuestTrip> _trips = const [];
  List<GuestTrip> get trips => _trips;

  /// The catalog could not be read and nothing is cached.
  bool catalogFailed = false;
  bool _reconnecting = false;
  bool get isReconnecting => _reconnecting;

  bool _refreshing = false;
  bool _disposed = false;
  Timer? _timer;

  String get guestUuid => _guestUuid;

  List<GuestRequest> get requests => _stay == null
      ? const []
      : composeRequests(stay: _stay!, trips: _trips, catalog: _catalog);

  Journey? get journey {
    final s = _stay;
    if (s == null) return null;
    return buildJourney(
      stay: s,
      catalog: _catalog,
      requests: requests,
      skips: s.skippedTaskIds,
      resortToday: clock.today(),
      drafts: _draftTaskIds(),
      ownArrangements: s.completedTaskIds,
    );
  }

  // ------------------------------------------------------------ loading

  Future<void> start() async {
    if (_phase != PortalPhase.loading) return;
    await refresh();
    _timer ??= Timer.periodic(pollInterval, (_) => refresh());
  }

  /// Reloads stay, catalog and trips; never overlaps another refresh.
  Future<void> refresh() async {
    if (_refreshing || _disposed || _guestUuid.isEmpty) return;
    if (_phase != PortalPhase.loading && _phase != PortalPhase.ready) return;
    _refreshing = true;
    try {
      final results = await Future.wait([
        api.fetchStay(_guestUuid),
        api.fetchCatalog(),
        api.fetchTrips(_guestUuid),
      ]);
      if (_disposed) return;
      final stayResult = results[0] as ApiResult<GuestStay>;
      if (stayResult case ApiFailed(kind: FailureKind.linkRejected)) {
        _expire();
        return;
      }
      if (stayResult case ApiOk(:final value)) {
        _stay = value;
        _phase = PortalPhase.ready;
        _reconnecting = false;
      } else {
        _reconnecting = true;
      }
      switch (results[1] as ApiResult<List<CatalogService>>) {
        case ApiOk(:final value):
          _catalog = value;
          catalogFailed = false;
        case ApiFailed():
          catalogFailed = _catalog.isEmpty;
          _reconnecting = true;
      }
      if (results[2] case ApiOk<List<GuestTrip>>(:final value)) _trips = value;
      notifyListeners();
    } finally {
      _refreshing = false;
    }
  }

  void _expire() {
    _phase = PortalPhase.linkExpired;
    _stay = null;
    _timer?.cancel();
    onLinkRejected?.call();
    notifyListeners();
  }

  /// Runs an awaited write; refreshes on success, expires on a rejected link.
  Future<ApiResult<T>> _write<T>(Future<ApiResult<T>> Function() call) async {
    final result = await call();
    if (_disposed) return result;
    if (result case ApiFailed(kind: FailureKind.linkRejected)) {
      _expire();
    } else if (result is ApiOk<T>) {
      await refresh();
    }
    return result;
  }

  // ------------------------------------------------------------ actions

  Future<ApiResult<void>> saveOrder(OrderPayload payload) =>
      _write(() => api.saveOrder(_guestUuid, payload));

  Future<ApiResult<void>> createBooking(Json payload) =>
      _write(() => api.createBooking(_guestUuid, payload));

  /// New date, time or party of a REQUESTED booking.
  Future<ApiResult<void>> changeBooking(String bookingId, Json change) =>
      _write(() => api.changeBooking(_guestUuid, bookingId, change));

  /// Cancels a request the server still holds in its initial status.
  Future<ApiResult<void>> cancelRequest(GuestRequest request) {
    final booking = request.booking, trip = request.trip;
    if (booking != null) {
      return _write(() => api.cancelBooking(_guestUuid, booking.id));
    }
    if (trip != null) return _write(() => api.cancelTrip(_guestUuid, trip.id));
    return Future.value(const ApiFailed(FailureKind.invalid));
  }

  Future<ApiResult<GuestTrip>> createTrip(Json payload) =>
      _write(() => api.createTrip(_guestUuid, payload));

  Future<ApiResult<void>> savePreferences(
          String dietary, List<String> allergies) =>
      _write(() => api.savePreferences(_guestUuid,
          dietary: dietary, allergies: allergies));

  Future<ApiResult<void>> sendRating(int rating, String note) =>
      _write(() => api.sendRating(_guestUuid, rating, note));

  /// Sends a chat message and/or a real photo to the Resort Host, inside the
  /// open thread when there is one.
  Future<ApiResult<void>> sendToHost(String text, {PickedPhoto? photo}) {
    return _write<void>(() async {
      final body = text.trim();
      final open = openChatThread;
      String? path;
      if (photo != null) {
        final upload =
            await api.uploadPhoto(_guestUuid, photo, threadId: open?.id);
        if (upload case ApiFailed(:final kind, :final message)) {
          return ApiFailed(kind, message);
        }
        path = (upload as ApiOk<String>).value;
      }
      if (open != null) {
        return api.sendHostMessage(_guestUuid, open.id, body,
            photoStoragePath: path);
      }
      final started = await api.startHostThread(_guestUuid,
          text: body, photoStoragePath: path);
      return switch (started) {
        ApiOk() => const ApiOk(null),
        ApiFailed(:final kind, :final message) => ApiFailed(kind, message),
      };
    });
  }

  // ------------------------------------------------------------ host chat

  HostThread? get openChatThread => _stay?.openChatThread;
  List<ChatMessage> get chatMessages => _stay?.chatMessages ?? const [];

  /// A Resort Host message newer than the last one the guest saw.
  bool get hasUnreadHostMessage {
    final hostTimes = [
      for (final t in _stay?.threads ?? const <HostThread>[])
        for (final m in t.messages)
          if (m.sender == MessageSender.host && m.sentAt != null) m.sentAt!,
    ];
    if (hostTimes.isEmpty) return false;
    hostTimes.sort();
    final seen = DateTime.tryParse(prefs.read(_key('host_seen')) ?? '');
    return seen == null || hostTimes.last.isAfter(seen);
  }

  void markHostSeen() {
    if (!hasUnreadHostMessage) return;
    prefs.write(_key('host_seen'), DateTime.now().toUtc().toIso8601String());
    notifyListeners();
  }

  // ------------------------------------------------------------ journey marks

  /// "Not now": stored on the stay; the task then leaves the count and sinks
  /// as Skipped (after the server confirms).
  Future<ApiResult<void>> skip(JourneyTask task) {
    final current = _stay?.skippedTaskIds ?? const <String>{};
    return _write(() => api
        .saveJourney(_guestUuid, skippedTaskIds: {...current, task.skipKey}));
  }

  /// "I arrange my own" transfer, stored on the stay.
  Future<ApiResult<void>> markOwnArrangement(CoreTask core) {
    final current = _stay?.completedTaskIds ?? const <String>{};
    return _write(() =>
        api.saveJourney(_guestUuid, completedTaskIds: {...current, core.id}));
  }

  // ------------------------------------------------------------ device state

  void setLang(Lang value) {
    if (lang == value) return;
    lang = value;
    prefs.write(langKey, value.name);
    notifyListeners();
  }

  Lang _initialLang() {
    final stored = prefs.read(langKey);
    if (stored == 'es') return Lang.es;
    if (stored == 'en') return Lang.en;
    return prefs.browserLanguage.toLowerCase().startsWith('es')
        ? Lang.es
        : Lang.en;
  }

  String _key(String name) => 'kachava_${name}_$_guestUuid';

  Set<String> _readSet(String name) {
    try {
      final raw = jsonDecode(prefs.read(_key(name)) ?? '[]');
      return raw is List ? raw.map((e) => '$e').toSet() : <String>{};
    } on FormatException {
      return <String>{};
    }
  }

  void _writeSet(String name, Set<String> values) =>
      prefs.write(_key(name), jsonEncode(values.toList()));

  /// Wizard/cart drafts saved per guest and task.
  Json? readDraft(String taskId) {
    try {
      final raw = prefs.read(_key('draft_$taskId'));
      return raw == null ? null : asJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  void saveDraft(String taskId, Json draft) {
    prefs.write(_key('draft_$taskId'), jsonEncode(draft));
    _drafts = {..._draftTaskIds(), taskId};
    _writeSet('drafts', _drafts!);
  }

  void clearDraft(String taskId) {
    prefs.remove(_key('draft_$taskId'));
    _drafts = {..._draftTaskIds()}..remove(taskId);
    _writeSet('drafts', _drafts!);
    notifyListeners();
  }

  Set<String>? _drafts;
  Set<String> _draftTaskIds() => _drafts ??= _readSet('drafts');

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

typedef OrderPayload = Json;
