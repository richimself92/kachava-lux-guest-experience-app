import 'dart:convert';
import '../../domain/entities/concierge_folio_entities.dart';
import '../../domain/entities/empty_sanctuary.dart';
import '../../domain/entities/stay_entities.dart';
import '../../domain/repositories/sanctuary_repository.dart';
import 'booking_wire_mapper.dart';
import 'larder_wire_mapper.dart';
import 'stay_wire_mapper.dart';

/// Stateless wire-format mapper for NestJS `/api/v1/stays/:guestUuid/*` DTOs
/// and `{ success, data, meta }` envelope unwrapping.
abstract final class SanctuaryWireMapper {
  /// The `data` object of an envelope (or the bare object). `null` when the
  /// body is empty or `data` is not an object. Throws [FormatException] on
  /// invalid JSON.
  static Map<String, dynamic>? unwrapDataMap(String body) {
    if (body.isEmpty) return null;
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return null;
    if (!decoded.containsKey('data')) return decoded;
    final inner = decoded['data'];
    return inner is Map<String, dynamic> ? inner : null;
  }

  /// The `data` list of an envelope (or the bare list); an empty list stays
  /// empty. `null` when the body holds no list.
  static List<Map<String, dynamic>>? unwrapDataList(String body) {
    if (body.isEmpty) return null;
    final decoded = jsonDecode(body);
    final raw = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
    if (raw is! List) return null;
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  static List<Map<String, dynamic>> _asList(Object? raw) =>
      raw is List ? raw.whereType<Map<String, dynamic>>().toList() : const [];

  /// Builds the guest state from a `GET /stays/:uuid` payload and the server
  /// catalogs. Anything the server does not send stays empty.
  static SanctuarySnapshot mapSnapshot(
    String guestUuid,
    Map<String, dynamic> payload, {
    List<Map<String, dynamic>> catalogExperiences = const [],
    List<Map<String, dynamic>> catalogLarder = const [],
  }) {
    final stay = StayWireMapper.mapStay(guestUuid, payload);
    final bookings = _asList(payload['experienceBookings']);
    final date = stay.defaultStayDateLabel;
    return SanctuarySnapshot(
      stay: stay,
      transport: StayWireMapper.mapTransport(payload['flightTransfer']),
      preferences: StayWireMapper.mapPreferences(payload['personalization']),
      checklist: const [],
      larderItems:
          LarderWireMapper.merge(payload['larderOrders'], catalogLarder),
      experiences:
          BookingWireMapper.mergeExperiences(catalogExperiences, bookings),
      yachtPackages: const [],
      yachtCharter: BookingWireMapper.mergeYachtCharter(
          EmptySanctuary.yachtCharter, bookings, date),
      diningMenus: const [],
      diningReservation: BookingWireMapper.mergeDiningReservation(
          EmptySanctuary.diningReservation, bookings, date),
      conciergeRequests: _mapConciergeRequests(payload['conciergeRequests']),
      chatMessages: _mapChatMessages(stay, payload['conciergeRequests']),
      folioItems: _mapFolioItems(payload['folioItems']),
      latestMidStayCheckIn: _mapMidStayFeedback(payload['midstayFeedback']),
    );
  }

  static List<ConciergeRequest> _mapConciergeRequests(Object? raw) {
    return _asList(raw)
        .map((m) => ConciergeRequest(
              id: (m['requestId'] ?? m['id'] ?? 'req-1').toString(),
              title: (m['title'] ?? 'Concierge Request').toString(),
              category: (m['category'] ?? 'Concierge').toString(),
              timestampLabel:
                  (m['timeLabel'] ?? m['timestampLabel'] ?? 'Just now')
                      .toString(),
              stage: _mapStage(m['status'] as String?),
              assignedTo: StayWireMapper.firstText(
                  [m['assignedTo'], m['assignedStaffName']]),
              details: (m['details'] ?? '').toString(),
              photoUrl: m['photoStoragePath'] as String?,
            ))
        .toList();
  }

  static ConciergeStage _mapStage(String? status) => switch (status) {
        'Assigned' => ConciergeStage.assigned,
        'In Progress' => ConciergeStage.inProgress,
        'Completed' => ConciergeStage.completed,
        _ => ConciergeStage.requested,
      };

  /// Only messages the server stored; nothing is pre-written for the guest.
  static List<ChatMessage> _mapChatMessages(
      StaySummary stay, Object? rawRequests) {
    final wire = [
      for (final req in _asList(rawRequests)) ..._asList(req['messages']),
    ];
    return [
      for (final (index, m) in wire.indexed) _mapChatMessage(stay, index, m),
    ];
  }

  static ChatMessage _mapChatMessage(
      StaySummary stay, int index, Map<String, dynamic> m) {
    final isHost = m['sender'] == 'HOST' || m['sender'] == 'CONCIERGE';
    return ChatMessage(
      id: 'msg-${index + 1}',
      senderName: isHost
          ? StayWireMapper.text(m['senderName'])
          : (m['senderName'] ?? stay.guestNames).toString(),
      isFromHost: isHost,
      text: (m['text'] ?? '').toString(),
      timestampLabel: 'Live',
    );
  }

  static MidStayCheckIn? _mapMidStayFeedback(Object? raw) {
    final feedbacks = _asList(raw);
    if (feedbacks.isEmpty) return null;
    final f = feedbacks.first;
    final hkList = f['housekeepingPreferences'];
    final hkWindow = (hkList is List && hkList.isNotEmpty)
        ? hkList.first.toString()
        : (f['housekeepingSchedule'] ?? '').toString();
    final aspects = f['selectedAspects'];
    return MidStayCheckIn(
      rating: ((f['rating'] ?? 0) as num).toInt(),
      sentimentId: (f['selectedSentiment'] ?? f['sentiment'] ?? '').toString(),
      housekeepingWindow: hkWindow,
      focusAreas: aspects is List
          ? aspects.map((e) => e.toString()).toList()
          : const [],
      notes: (f['note'] ?? f['notes'] ?? '').toString(),
      requestPriorityCallback: f['requestPriorityCallback'] == true,
      submittedAtLabel: (f['submittedAt'] ?? 'Submitted').toString(),
    );
  }

  static List<FolioLineItem> _mapFolioItems(Object? rawFolio) {
    return _asList(rawFolio)
        .map((f) => FolioLineItem(
              id: (f['folioItemId'] ?? f['itemId'] ?? f['id'] ?? 'fol')
                  .toString(),
              title: (f['title'] ?? 'Charge').toString(),
              subtitle:
                  (f['subtitle'] ?? f['category'] ?? 'Incidentals').toString(),
              category: (f['category'] ?? 'Incidentals').toString(),
              timestampLabel: (f['dateLabel'] ?? 'Stay').toString(),
              amountUsd: ((f['chargedAmountUSD'] ??
                      f['amountUSD'] ??
                      f['amountUsd'] ??
                      0) as num)
                  .round(),
              isIncludedPrivilege:
                  f['isComplimentary'] == true || f['isComped'] == true,
            ))
        .toList();
  }
}
