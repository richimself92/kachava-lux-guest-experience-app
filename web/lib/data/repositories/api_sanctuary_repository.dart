import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../domain/entities/concierge_folio_entities.dart';
import '../../domain/entities/experience_entities.dart';
import '../../domain/entities/stay_entities.dart';
import '../../domain/repositories/sanctuary_repository.dart';
import '../seed/villa_102_seed_data.dart';
import 'sanctuary_wire_mapper.dart';

/// REST API + Offline Seeded Repository talking to `/api/v1/stays/:guestUuid/*`
/// with `Authorization: Bearer <guestUuid>`, `X-StepUp-Session`, and `X-StepUp-Token`.
class ApiSanctuaryRepository implements SanctuaryRepository {
  ApiSanctuaryRepository({
    this.baseUrl = AppConfig.apiBaseUrl,
    this.enableNetwork = AppConfig.enableNetwork,
    http.Client? httpClient,
  })  : _ownsClient = httpClient == null,
        _client = httpClient ?? http.Client();

  final String baseUrl;
  final bool enableNetwork;
  final bool _ownsClient;
  final http.Client _client;

  Duration get _timeout => _ownsClient
      ? const Duration(seconds: 8)
      : const Duration(milliseconds: 900);

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

  @override
  Future<SanctuarySnapshot> loadSanctuary(String guestUuid) async =>
      (await fetchLiveSanctuary(guestUuid)) ??
      Villa102SeedData.buildDefaultSnapshot(guestUuid);

  @override
  Future<SanctuarySnapshot?> fetchLiveSanctuary(String guestUuid) async {
    if (!enableNetwork) return null;
    final fallback = Villa102SeedData.buildDefaultSnapshot(guestUuid);
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/stays/$guestUuid'),
              headers: _buildHeaders(guestUuid))
          .timeout(_timeout);
      if (response.statusCode != 200) return null;
      final rawBody = utf8.decode(response.bodyBytes, allowMalformed: true);
      final payload = SanctuaryWireMapper.unwrapDataMap(rawBody);
      if (payload == null) return null;
      final catalogs = await Future.wait([
        _fetchCatalogList(guestUuid, 'experiences'),
        _fetchCatalogList(guestUuid, 'larder'),
      ]);
      return SanctuaryWireMapper.mergeSnapshot(
        fallback,
        payload,
        catalogExperiences: catalogs[0],
        catalogLarder: catalogs[1],
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> _fetchCatalogList(
    String guestUuid,
    String segment,
  ) async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/catalog/$segment'),
              headers: _buildHeaders(guestUuid))
          .timeout(_timeout);
      if (res.statusCode != 200) return null;
      final body = utf8.decode(res.bodyBytes, allowMalformed: true);
      return SanctuaryWireMapper.unwrapDataList(body);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> verifyStepUpChallenge(
    String guestUuid, {
    String? villaNumber,
    String? lastName,
  }) async {
    if (!enableNetwork) return 'stepup-verified-102';
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/stays/$guestUuid/verify-step-up'),
            headers: _buildHeaders(guestUuid),
            body: jsonEncode({
              if (villaNumber != null) 'villaNumber': villaNumber,
              if (lastName != null) 'lastName': lastName,
            }),
          )
          .timeout(_timeout);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = SanctuaryWireMapper.unwrapDataMap(response.body);
        final token = data?['stepUpToken'] as String?;
        if (token != null && token.isNotEmpty) return token;
      }
    } catch (_) {
      // Offline fallback token.
    }
    return 'stepup-verified-102';
  }

  @override
  Future<void> syncFlightTransport(String guestUuid, FlightTransport transport,
          {String? stepUpSession}) =>
      _dispatchMutation(
        method: 'PATCH',
        guestUuid: guestUuid,
        pathSegment: 'transfer',
        stepUpSession: stepUpSession,
        payload: SanctuaryWireMapper.toTransferDto(transport),
      );

  @override
  Future<void> savePersonalization(
          String guestUuid, PersonalizationPreferences preferences,
          {String? stepUpSession}) =>
      _dispatchMutation(
        method: 'PATCH',
        guestUuid: guestUuid,
        pathSegment: 'personalization',
        stepUpSession: stepUpSession,
        payload: SanctuaryWireMapper.toPersonalizationDto(preferences),
      );

  @override
  Future<void> saveLarderOrder(String guestUuid, List<LarderItem> items,
          {String? stepUpSession}) =>
      _dispatchMutation(
        method: 'PUT',
        guestUuid: guestUuid,
        pathSegment: 'larder',
        stepUpSession: stepUpSession,
        payload: SanctuaryWireMapper.toLarderDto(items),
      );

  @override
  Future<void> saveYachtCharter(String guestUuid, YachtCharterConfig charter,
          {String? stepUpSession}) =>
      _dispatchMutation(
        method: 'POST',
        guestUuid: guestUuid,
        pathSegment: 'bookings',
        stepUpSession: stepUpSession,
        payload: SanctuaryWireMapper.toYachtBookingDto(charter),
      );

  @override
  Future<void> saveDiningReservation(
          String guestUuid, DiningReservation reservation,
          {String? stepUpSession}) =>
      _dispatchMutation(
        method: 'POST',
        guestUuid: guestUuid,
        pathSegment: 'bookings',
        stepUpSession: stepUpSession,
        payload: SanctuaryWireMapper.toDiningBookingDto(reservation),
      );

  @override
  Future<void> saveExperienceBooking(
          String guestUuid, ExperienceItem experience, String slot,
          {int partySize = 2, String? stepUpSession}) =>
      _dispatchMutation(
        method: 'POST',
        guestUuid: guestUuid,
        pathSegment: 'bookings',
        stepUpSession: stepUpSession,
        payload: SanctuaryWireMapper.toExperienceBookingDto(
            experience, slot, partySize),
      );

  @override
  Future<void> submitConciergeRequest(
          String guestUuid, ConciergeRequest request,
          {String? stepUpSession}) =>
      _dispatchMutation(
        method: 'POST',
        guestUuid: guestUuid,
        pathSegment: 'concierge-requests',
        stepUpSession: stepUpSession,
        payload: SanctuaryWireMapper.toConciergeRequestDto(request),
      );

  @override
  Future<void> appendConciergeMessage(
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
  Future<void> submitMidStayCheckIn(String guestUuid, MidStayCheckIn checkIn,
          {String? stepUpSession}) =>
      _dispatchMutation(
        method: 'POST',
        guestUuid: guestUuid,
        pathSegment: 'midstay-checkin',
        stepUpSession: stepUpSession,
        payload: SanctuaryWireMapper.toMidStayDto(checkIn),
      );

  @override
  Future<void> completeCheckout(String guestUuid,
          {required String stepUpToken}) =>
      _dispatchMutation(
        method: 'POST',
        guestUuid: guestUuid,
        pathSegment: 'folio/checkout',
        stepUpSession: stepUpToken,
        payload: {'lateCheckoutRequested': false},
      );

  Future<void> _dispatchMutation({
    required String method,
    required String guestUuid,
    required String pathSegment,
    required Map<String, dynamic> payload,
    String? stepUpSession,
  }) async {
    if (!enableNetwork) return;
    final uri = Uri.parse('$baseUrl/stays/$guestUuid/$pathSegment');
    final headers = _buildHeaders(guestUuid, stepUpSession: stepUpSession);
    final body = jsonEncode(payload);
    try {
      final future = switch (method) {
        'PUT' => _client.put(uri, headers: headers, body: body),
        'POST' => _client.post(uri, headers: headers, body: body),
        _ => _client.patch(uri, headers: headers, body: body),
      };
      await future.timeout(_timeout);
    } catch (_) {
      // Offline resilient fallback.
    }
  }

  @override
  void dispose() {
    if (_ownsClient) _client.close();
  }
}
