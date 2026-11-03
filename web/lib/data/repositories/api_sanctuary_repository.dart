import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../domain/entities/concierge_folio_entities.dart';
import '../../domain/entities/experience_entities.dart';
import '../../domain/entities/stay_entities.dart';
import '../../domain/repositories/sanctuary_repository.dart';
import 'catalog_cache.dart';
import 'sanctuary_request_dto.dart';
import 'sanctuary_wire_mapper.dart';

/// REST repository for `/api/v1/stays/:guestUuid/*` with
/// `Authorization: Bearer <guestUuid>`, `X-StepUp-Session`, and `X-StepUp-Token`.
///
/// Fetches return a typed [SanctuaryFetchResult]: only HTTP 401/403/404
/// reject the link; 5xx, 429, timeouts, network and parse errors are transient.
class ApiSanctuaryRepository implements SanctuaryRepository {
  ApiSanctuaryRepository({
    this.baseUrl = AppConfig.apiBaseUrl,
    this.enableNetwork = AppConfig.enableNetwork,
    http.Client? httpClient,
    Duration? requestTimeout,
  })  : _ownsClient = httpClient == null,
        _client = httpClient ?? http.Client(),
        _timeout = requestTimeout ??
            (httpClient == null
                ? const Duration(seconds: 8)
                : const Duration(milliseconds: 900));

  final String baseUrl;
  final bool enableNetwork;
  final bool _ownsClient;
  final http.Client _client;
  final Duration _timeout;
  final CatalogCache _catalogs = CatalogCache();

  Map<String, String> _buildHeaders(String guestUuid, {String? stepUpSession}) {
    final hasStepUp = stepUpSession != null && stepUpSession.isNotEmpty;
    return <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $guestUuid',
      if (hasStepUp) 'X-StepUp-Session': stepUpSession,
      if (hasStepUp) 'X-StepUp-Token': stepUpSession,
    };
  }

  /// Network failures and unparseable payloads (bad JSON, wrong field types)
  /// are transient: the portal keeps its last data and shows "Reconnecting".
  static bool _isTransient(Object error) =>
      error is TimeoutException ||
      error is http.ClientException ||
      error is FormatException ||
      error is TypeError;

  static bool _isSuccess(int status) => status >= 200 && status < 300;

  Future<http.Response> _get(String path, String guestUuid) => _client
      .get(Uri.parse('$baseUrl/$path'), headers: _buildHeaders(guestUuid))
      .timeout(_timeout);

  @override
  Future<SanctuaryFetchResult> fetchLiveSanctuary(String guestUuid) async {
    if (!enableNetwork) return const SanctuaryUnreachable();
    try {
      final response = await _get('stays/$guestUuid', guestUuid);
      return switch (response.statusCode) {
        401 || 403 || 404 => const SanctuaryLinkRejected(),
        final status when _isSuccess(status) =>
          await _toFetched(guestUuid, response),
        _ => const SanctuaryUnreachable(),
      };
    } catch (error) {
      if (!_isTransient(error)) rethrow;
      return const SanctuaryUnreachable();
    }
  }

  Future<SanctuaryFetchResult> _toFetched(
      String guestUuid, http.Response response) async {
    final payload = SanctuaryWireMapper.unwrapDataMap(_bodyOf(response));
    if (payload == null) return const SanctuaryUnreachable();
    final fresh = await Future.wait([
      _fetchCatalogList(guestUuid, 'experiences'),
      _fetchCatalogList(guestUuid, 'larder'),
    ]);
    final experiences = _catalogs.resolve('experiences', fresh[0]);
    final larder = _catalogs.resolve('larder', fresh[1]);
    return SanctuaryFetched(
      SanctuaryWireMapper.mapSnapshot(guestUuid, payload,
          catalogExperiences: experiences, catalogLarder: larder),
      revision: jsonEncode([payload, experiences, larder]),
    );
  }

  static String _bodyOf(http.Response response) =>
      utf8.decode(response.bodyBytes, allowMalformed: true);

  /// Returns `null` when the catalog could not be read; [CatalogCache] then
  /// keeps the last list the server published.
  Future<List<Map<String, dynamic>>?> _fetchCatalogList(
    String guestUuid,
    String segment,
  ) async {
    try {
      final res = await _get('catalog/$segment', guestUuid);
      if (!_isSuccess(res.statusCode)) return null;
      return SanctuaryWireMapper.unwrapDataList(_bodyOf(res));
    } catch (error) {
      if (!_isTransient(error)) rethrow;
      return null;
    }
  }

  @override
  Future<String?> verifyStepUpChallenge(String guestUuid, String answer) async {
    if (!enableNetwork) return null;
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/stays/$guestUuid/verify-step-up'),
            headers: _buildHeaders(guestUuid),
            body: jsonEncode(SanctuaryRequestDto.toStepUpDto(answer)),
          )
          .timeout(_timeout);
      if (!_isSuccess(response.statusCode)) return null;
      final data = SanctuaryWireMapper.unwrapDataMap(_bodyOf(response));
      final token = data?['stepUpToken'];
      return token is String && token.isNotEmpty ? token : null;
    } catch (error) {
      if (!_isTransient(error)) rethrow;
      return null;
    }
  }

  @override
  Future<MutationResult> syncFlightTransport(
          String guestUuid, FlightTransport transport,
          {String? stepUpSession}) =>
      _dispatchMutation(
        method: 'PATCH',
        guestUuid: guestUuid,
        pathSegment: 'transfer',
        stepUpSession: stepUpSession,
        payload: SanctuaryRequestDto.toTransferDto(transport),
      );

  @override
  Future<MutationResult> savePersonalization(
          String guestUuid, PersonalizationPreferences preferences,
          {String? stepUpSession}) =>
      _dispatchMutation(
        method: 'PATCH',
        guestUuid: guestUuid,
        pathSegment: 'personalization',
        stepUpSession: stepUpSession,
        payload: SanctuaryRequestDto.toPersonalizationDto(preferences),
      );

  @override
  Future<MutationResult> saveLarderOrder(
          String guestUuid, List<LarderItem> items,
          {String? stepUpSession}) =>
      _dispatchMutation(
        method: 'PUT',
        guestUuid: guestUuid,
        pathSegment: 'larder',
        stepUpSession: stepUpSession,
        payload: SanctuaryRequestDto.toLarderDto(items),
      );

  @override
  Future<MutationResult> saveYachtCharter(
          String guestUuid, YachtCharterConfig charter,
          {String? stepUpSession}) =>
      _dispatchMutation(
        method: 'POST',
        guestUuid: guestUuid,
        pathSegment: 'bookings',
        stepUpSession: stepUpSession,
        payload: SanctuaryRequestDto.toYachtBookingDto(charter),
      );

  @override
  Future<MutationResult> saveDiningReservation(
          String guestUuid, DiningReservation reservation,
          {String? stepUpSession}) =>
      _dispatchMutation(
        method: 'POST',
        guestUuid: guestUuid,
        pathSegment: 'bookings',
        stepUpSession: stepUpSession,
        payload: SanctuaryRequestDto.toDiningBookingDto(reservation),
      );

  @override
  Future<MutationResult> saveExperienceBooking(
          String guestUuid, ExperienceItem experience, String slot,
          {int partySize = 2, String? stepUpSession}) =>
      _dispatchMutation(
        method: 'POST',
        guestUuid: guestUuid,
        pathSegment: 'bookings',
        stepUpSession: stepUpSession,
        payload: SanctuaryRequestDto.toExperienceBookingDto(
            experience, slot, partySize),
      );

  @override
  Future<MutationResult> submitConciergeRequest(
          String guestUuid, ConciergeRequest request,
          {String? stepUpSession}) =>
      _dispatchMutation(
        method: 'POST',
        guestUuid: guestUuid,
        pathSegment: 'concierge-requests',
        stepUpSession: stepUpSession,
        payload: SanctuaryRequestDto.toConciergeRequestDto(request),
      );

  @override
  Future<MutationResult> appendConciergeMessage(
          String guestUuid, String requestId, String text,
          {String? senderName, String? stepUpSession}) =>
      _dispatchMutation(
        method: 'POST',
        guestUuid: guestUuid,
        pathSegment: 'concierge-requests/$requestId/messages',
        stepUpSession: stepUpSession,
        payload: {
          'text': text,
          if (senderName != null) 'senderName': senderName
        },
      );

  @override
  Future<MutationResult> submitMidStayCheckIn(
          String guestUuid, MidStayCheckIn checkIn,
          {String? stepUpSession}) =>
      _dispatchMutation(
        method: 'POST',
        guestUuid: guestUuid,
        pathSegment: 'midstay-checkin',
        stepUpSession: stepUpSession,
        payload: SanctuaryRequestDto.toMidStayDto(checkIn),
      );

  @override
  Future<MutationResult> completeCheckout(String guestUuid,
          {required String stepUpToken}) =>
      _dispatchMutation(
        method: 'POST',
        guestUuid: guestUuid,
        pathSegment: 'folio/checkout',
        stepUpSession: stepUpToken,
        payload: {'lateCheckoutRequested': false},
      );

  Future<MutationResult> _dispatchMutation({
    required String method,
    required String guestUuid,
    required String pathSegment,
    required Map<String, dynamic> payload,
    String? stepUpSession,
  }) async {
    if (!enableNetwork) return const MutationFailed();
    final uri = Uri.parse('$baseUrl/stays/$guestUuid/$pathSegment');
    final headers = _buildHeaders(guestUuid, stepUpSession: stepUpSession);
    final body = jsonEncode(payload);
    try {
      final response = await switch (method) {
        'PUT' => _client.put(uri, headers: headers, body: body),
        'POST' => _client.post(uri, headers: headers, body: body),
        _ => _client.patch(uri, headers: headers, body: body),
      }
          .timeout(_timeout);
      return _isSuccess(response.statusCode)
          ? const MutationConfirmed()
          : const MutationFailed();
    } catch (error) {
      if (!_isTransient(error)) rethrow;
      return const MutationFailed();
    }
  }

  @override
  void dispose() {
    if (_ownsClient) _client.close();
  }
}
