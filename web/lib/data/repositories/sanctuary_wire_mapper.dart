import 'dart:convert';
import '../../domain/entities/concierge_folio_entities.dart';
import '../../domain/entities/experience_entities.dart';
import '../../domain/entities/stay_entities.dart';
import '../../domain/repositories/sanctuary_repository.dart';

/// Stateless wire-format mapper for NestJS `/api/v1/stays/:guestUuid/*` DTOs
/// and `{ success, data, meta }` envelope unwrapping.
abstract final class SanctuaryWireMapper {
  static Map<String, dynamic>? unwrapDataMap(String body) {
    if (body.isEmpty) return null;
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      final inner = decoded['data'];
      return inner is Map<String, dynamic> ? inner : decoded;
    }
    return null;
  }

  static List<Map<String, dynamic>>? unwrapDataList(String body) {
    if (body.isEmpty) return null;
    final decoded = jsonDecode(body);
    final raw = decoded is Map<String, dynamic> ? decoded['data'] : decoded;
    if (raw is! List || raw.isEmpty) return null;
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  static List<Map<String, dynamic>> _asList(Object? raw) =>
      raw is List ? raw.whereType<Map<String, dynamic>>().toList() : const [];

  static SanctuarySnapshot mergeSnapshot(
    SanctuarySnapshot fallback,
    Map<String, dynamic> payload, {
    List<Map<String, dynamic>>? catalogExperiences,
    List<Map<String, dynamic>>? catalogLarder,
  }) {
    final ft = payload['flightTransfer'];
    final mergedStay = _mergeStay(fallback.stay, payload);
    final bookings = _asList(payload['experienceBookings']);
    final defaultDate = mergedStay.defaultStayDateLabel;
    return SanctuarySnapshot(
      stay: mergedStay,
      transport: _mergeTransport(
          fallback.transport, ft is Map<String, dynamic> ? ft : null),
      preferences:
          _mergePreferences(fallback.preferences, payload['personalization']),
      checklist: fallback.checklist,
      larderItems: _mergeLarderItems(
          fallback.larderItems, payload['larderOrders'], catalogLarder),
      experiences:
          _mergeExperiences(fallback.experiences, bookings, catalogExperiences),
      yachtPackages: fallback.yachtPackages,
      yachtCharter:
          _mergeYachtCharter(fallback.yachtCharter, bookings, defaultDate),
      diningMenus: fallback.diningMenus,
      diningReservation: _mergeDiningReservation(
          fallback.diningReservation, bookings, defaultDate),
      conciergeRequests: _mergeConciergeRequests(
          fallback.conciergeRequests, payload['conciergeRequests']),
      chatMessages:
          _mergeChatMessages(mergedStay, payload['conciergeRequests']),
      folioItems: _mergeFolioItems(fallback.folioItems, payload['folioItems']),
      latestMidStayCheckIn: _mergeMidStayFeedback(
          fallback.latestMidStayCheckIn, payload['midstayFeedback']),
    );
  }

  static List<ConciergeRequest> _mergeConciergeRequests(
      List<ConciergeRequest> fallback, Object? raw) {
    if (raw is! List) return fallback;
    if (raw.isEmpty) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((m) => ConciergeRequest(
              id: (m['requestId'] ?? m['id'] ?? 'req-1').toString(),
              title: (m['title'] ?? 'Concierge Request').toString(),
              category: (m['category'] ?? 'Concierge').toString(),
              timestampLabel:
                  (m['timeLabel'] ?? m['timestampLabel'] ?? 'Just now')
                      .toString(),
              stage: _mapStage(m['status'] as String?),
              assignedTo: 'HOST ADMIN',
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

  static List<ChatMessage> _mergeChatMessages(
      StaySummary mergedStay, Object? rawRequests) {
    final messages = <ChatMessage>[
      ChatMessage(
        id: 'msg-1',
        senderName: '${mergedStay.privateHostName} (Concierge)',
        isFromHost: true,
        text:
            'Welcome to ${mergedStay.villaTitle}, ${mergedStay.guestNames}. HOST ADMIN is at your service 24/7.',
        timestampLabel: '1:45 PM',
      ),
    ];
    if (rawRequests is! List) return messages;
    var idx = 2;
    for (final req in rawRequests.whereType<Map<String, dynamic>>()) {
      final wireMsgs = req['messages'];
      if (wireMsgs is! List) continue;
      for (final msgMap in wireMsgs.whereType<Map<String, dynamic>>()) {
        final isHost =
            msgMap['sender'] == 'HOST' || msgMap['sender'] == 'CONCIERGE';
        messages.add(ChatMessage(
          id: 'msg-${idx++}',
          senderName: isHost
              ? 'HOST ADMIN'
              : (msgMap['senderName'] ?? mergedStay.guestNames).toString(),
          isFromHost: isHost,
          text: (msgMap['text'] ?? '').toString(),
          timestampLabel: 'Live',
        ));
      }
    }
    return messages;
  }

  static List<LarderItem> _mergeLarderItems(
    List<LarderItem> fallback,
    Object? rawOrders,
    List<Map<String, dynamic>>? catalogLarder,
  ) {
    final baseList = (catalogLarder != null && catalogLarder.isNotEmpty)
        ? catalogLarder.map(_mapCatalogLarderItem).toList()
        : fallback;
    if (rawOrders is! List) return baseList;
    if (rawOrders.isEmpty) {
      return baseList
          .map((i) => i.copyWith(
              quantity: 0, isConfirmed: false, provisioningStatus: ''))
          .toList();
    }
    final orders = rawOrders.whereType<Map<String, dynamic>>().toList();
    final orderStatus = orders.isNotEmpty
        ? (orders.first['provisioningStatus'] ??
                orders.first['status'] ??
                'Pending')
            .toString()
        : 'Pending';
    final isDelivered = orderStatus.toLowerCase().contains('stocked') ||
        orderStatus.toLowerCase().contains('delivered');
    final qtyById = <String, int>{};
    for (final o in orders) {
      final id =
          (o['catalogItemId'] ?? o['itemId'] ?? o['id'] ?? '').toString();
      if (id.isNotEmpty) qtyById[id] = ((o['quantity'] ?? 0) as num).toInt();
    }
    if (isDelivered) {
      final matchedAny = baseList.any((i) => (qtyById[i.id] ?? 0) > 0);
      var idx = 0;
      return baseList.map((i) {
        final markDelivered =
            (qtyById[i.id] ?? 0) > 0 || (!matchedAny && idx == 0);
        idx++;
        return i.copyWith(
          quantity: 0,
          isConfirmed: false,
          provisioningStatus: markDelivered ? 'Stocked in Villa' : '',
        );
      }).toList();
    }
    return baseList.map((i) {
      final qty = qtyById[i.id] ?? 0;
      return i.copyWith(
        quantity: qty,
        isConfirmed: qty > 0,
        provisioningStatus: qty > 0 ? orderStatus : '',
      );
    }).toList();
  }

  static LarderItem _mapCatalogLarderItem(Map<String, dynamic> c) => LarderItem(
        id: (c['id'] ?? c['itemId'] ?? 'larder-item').toString(),
        name: (c['name'] ?? c['title'] ?? 'Artisanal Item').toString(),
        origin: (c['origin'] ?? c['subtitle'] ?? 'Riviera Maya').toString(),
        description: (c['description'] ?? '').toString(),
        priceUsd: ((c['price'] ?? c['priceUSD'] ?? c['priceUsd'] ?? 0) as num)
            .round(),
        category: (c['category'] ?? 'Cellar Selection').toString(),
        quantity: 0,
        tag: (c['tag'] ?? 'CURATED SELECTION').toString(),
        storageType: (c['storageType'] ?? 'CHILLED IN LARDER').toString(),
        dietaryBadge: (c['dietary'] ?? c['dietaryBadge']) as String?,
      );

  static List<ExperienceItem> _mergeExperiences(
    List<ExperienceItem> fallback,
    List<Map<String, dynamic>> bookings,
    List<Map<String, dynamic>>? catalogExperiences,
  ) {
    final baseList =
        (catalogExperiences != null && catalogExperiences.isNotEmpty)
            ? catalogExperiences.map(_mapCatalogExperience).toList()
            : fallback;
    if (bookings.isEmpty) return baseList;
    return baseList.map((exp) {
      for (final b in bookings) {
        if (b['catalogRefId'] == exp.id || b['title'] == exp.title) {
          final status = (b['status'] ?? 'REQUESTED').toString().toUpperCase();
          final sDate = (b['scheduledDate'] ?? '').toString();
          final sTime = (b['scheduledTimeSlot'] ?? '').toString();
          final slot = '$sDate · $sTime'.trim();
          return exp.copyWith(
            isScheduled: true,
            isReserved: true,
            scheduledSlot: slot,
            scheduledDate: sDate,
            scheduledTimeSlot: sTime,
            bookingStatus: status,
            cancellationReason: (b['cancellationReason'] ?? '').toString(),
          );
        }
      }
      return exp;
    }).toList();
  }

  static YachtCharterConfig _mergeYachtCharter(
    YachtCharterConfig current,
    List<Map<String, dynamic>> bookings,
    String defaultDate,
  ) {
    Map<String, dynamic>? match;
    for (final b in bookings) {
      final type = (b['bookingType'] ?? '').toString().toUpperCase();
      final cat = (b['category'] ?? '').toString().toLowerCase();
      if (type == 'YACHT_CHARTER' || cat.contains('yacht')) {
        match = b;
      }
    }
    if (match != null) {
      final status = (match['status'] ?? 'REQUESTED').toString().toUpperCase();
      final sDate = (match['scheduledDate'] ?? '').toString();
      final sSlot = (match['scheduledTimeSlot'] ?? '').toString();
      return current.copyWith(
        selectedDate: sDate.isNotEmpty ? sDate : defaultDate,
        selectedSlot: sSlot.isNotEmpty ? sSlot : current.selectedSlot,
        guestCount: (match['partySize'] as num?)?.toInt(),
        isConfirmed: status == 'CONFIRMED',
        bookingStatus: status,
        cancellationReason: (match['cancellationReason'] ?? '').toString(),
      );
    }
    if (current.bookingStatus.isEmpty) {
      return current.copyWith(
        selectedDate:
            current.selectedDate.isEmpty ? defaultDate : current.selectedDate,
        isConfirmed: false,
        bookingStatus: '',
        cancellationReason: '',
      );
    }
    return current;
  }

  static DiningReservation _mergeDiningReservation(
    DiningReservation current,
    List<Map<String, dynamic>> bookings,
    String defaultDate,
  ) {
    Map<String, dynamic>? match;
    for (final b in bookings) {
      final type = (b['bookingType'] ?? '').toString().toUpperCase();
      final cat = (b['category'] ?? '').toString().toLowerCase();
      if (type == 'PRIVATE_DINING' || cat.contains('dining')) {
        match = b;
      }
    }
    if (match != null) {
      final status = (match['status'] ?? 'REQUESTED').toString().toUpperCase();
      final sDate = (match['scheduledDate'] ?? '').toString();
      final sTime = (match['scheduledTimeSlot'] ?? '').toString();
      return current.copyWith(
        selectedDate: sDate.isNotEmpty ? sDate : defaultDate,
        selectedTime: sTime.isNotEmpty ? sTime : current.selectedTime,
        guestCount: (match['partySize'] as num?)?.toInt(),
        isConfirmed: status == 'CONFIRMED',
        bookingStatus: status,
        cancellationReason: (match['cancellationReason'] ?? '').toString(),
      );
    }
    if (current.bookingStatus.isEmpty) {
      return current.copyWith(
        selectedDate:
            current.selectedDate.isEmpty ? defaultDate : current.selectedDate,
        isConfirmed: false,
        bookingStatus: '',
        cancellationReason: '',
      );
    }
    return current;
  }

  static MidStayCheckIn? _mergeMidStayFeedback(
    MidStayCheckIn? fallback,
    Object? raw,
  ) {
    final feedbacks = _asList(raw);
    if (feedbacks.isEmpty) return fallback;
    final f = feedbacks.first;
    final hkList = f['housekeepingPreferences'];
    final hkWindow = (hkList is List && hkList.isNotEmpty)
        ? hkList.first.toString()
        : (f['housekeepingSchedule'] ?? '').toString();
    final aspects = f['selectedAspects'];
    return MidStayCheckIn(
      rating: ((f['rating'] ?? 5) as num).toInt(),
      sentimentId: (f['selectedSentiment'] ?? f['sentiment'] ?? 'transcendent')
          .toString(),
      housekeepingWindow: hkWindow,
      focusAreas: aspects is List
          ? aspects.map((e) => e.toString()).toList()
          : const [],
      notes: (f['note'] ?? f['notes'] ?? '').toString(),
      requestPriorityCallback: f['requestPriorityCallback'] == true,
      submittedAtLabel: (f['submittedAt'] ?? 'Submitted').toString(),
    );
  }

  static ExperienceItem _mapCatalogExperience(Map<String, dynamic> c) {
    final price = ((c['basePriceUSD'] ??
            c['priceUSD'] ??
            c['priceUsd'] ??
            c['price'] ??
            0) as num)
        .round();
    final included = c['isIncluded'] == true || price == 0;
    return ExperienceItem(
      id: (c['id'] ?? c['catalogId'] ?? 'exp').toString(),
      title: (c['title'] ?? c['name'] ?? 'Experience').toString(),
      subtitle: (c['subtitle'] ?? c['category'] ?? 'Sanctuary').toString(),
      duration: (c['duration'] ?? '2 Hours').toString(),
      location: (c['location'] ?? 'Kachava Sanctuary').toString(),
      priceText:
          (c['priceText'] ?? (included ? 'Included with Stay' : '\$$price USD'))
              .toString(),
      priceUsd: price,
      isIncluded: included,
      category: (c['category'] ?? 'Wellness').toString(),
      description: (c['description'] ?? '').toString(),
      amenities: (c['amenities'] is List)
          ? (c['amenities'] as List).map((e) => e.toString()).toList()
          : const ['Private Host Coordination'],
      isScheduled: false,
      targetScreenWireId:
          (c['actionScreen'] ?? c['targetScreenWireId']) as String?,
    );
  }

  static List<FolioLineItem> _mergeFolioItems(
      List<FolioLineItem> fallback, Object? rawFolio) {
    if (rawFolio is! List) return fallback;
    if (rawFolio.isEmpty) return const [];
    return rawFolio
        .whereType<Map<String, dynamic>>()
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

  static StaySummary _mergeStay(
      StaySummary base, Map<String, dynamic> payload) {
    final statusWire =
        (payload['status'] ?? payload['lifecycleStatus']) as String?;
    final profile = payload['guestProfile'] is Map<String, dynamic>
        ? payload['guestProfile'] as Map<String, dynamic>
        : null;
    final hostInfo = payload['hostInfo'] is Map<String, dynamic>
        ? payload['hostInfo'] as Map<String, dynamic>
        : null;
    final va = payload['villaAccess'] is Map<String, dynamic>
        ? payload['villaAccess'] as Map<String, dynamic>
        : null;
    final guestName = _nonEmpty(profile?['name']);
    final villaName = _nonEmpty(payload['villaName']);
    final numberMatch =
        villaName != null ? RegExp(r'\d+').firstMatch(villaName) : null;
    final words =
        guestName?.split(RegExp(r'[\s&]+')).where((w) => w.isNotEmpty).toList();
    final rawHost =
        _nonEmpty(hostInfo?['name']) ?? _nonEmpty(payload['privateHostName']);
    final stayDatesLabel = _nonEmpty(payload['stayDatesLabel']);
    final parsedNights = StaySummary.computeNightsFromLabel(stayDatesLabel);
    final resolvedNights =
        parsedNights ?? (payload['nights'] as num?)?.toInt() ?? base.nights;
    return base.copyWith(
      lifecycleStatus: StayLifecycleStatus.fromWire(statusWire),
      guestNames: guestName,
      primaryGuestName:
          (words != null && words.isNotEmpty) ? words.first : null,
      lastName: _nonEmpty(profile?['lastNameNormalized']) ??
          ((words != null && words.isNotEmpty) ? words.last : null),
      villaNumber: numberMatch?.group(0),
      villaTitle: villaName,
      suiteName: _nonEmpty(payload['suiteName']),
      celebrationTitle: _nonEmpty(profile?['celebration']),
      stayDates: stayDatesLabel,
      nights: resolvedNights,
      privateHostName:
          (rawHost != null && rawHost.toLowerCase().startsWith('edu'))
              ? 'HOST ADMIN'
              : rawHost,
      privateHostRole:
          _nonEmpty(hostInfo?['role']) ?? _nonEmpty(payload['privateHostRole']),
      wifiSsid: _nonEmpty(va?['wifiSsid']) ?? _nonEmpty(payload['wifiSsid']),
      wifiPassphrase: _nonEmpty(va?['wifiPasscode']) ??
          _nonEmpty(va?['wifiPassphrase']) ??
          _nonEmpty(payload['wifiPassphrase']),
    );
  }

  static String? _nonEmpty(Object? raw) =>
      raw is String && raw.trim().isNotEmpty ? raw.trim() : null;

  static FlightTransport _mergeTransport(
      FlightTransport base, Map<String, dynamic>? wire) {
    if (wire == null) return base;
    return FlightTransport(
      arrivalDate: (wire['arrivalDate'] ?? '').toString(),
      arrivalAirport: (wire['arrivalAirport'] ?? '').toString(),
      airline: (wire['airline'] ?? '').toString(),
      flightNumber: (wire['flightNumber'] ?? '').toString(),
      estimatedLanding:
          (wire['estimatedLanding'] ?? wire['arrivalTime'] ?? '').toString(),
      terminalBay: (wire['terminal'] ?? '').toString(),
      partySize: (wire['partySize'] as num?)?.toInt() ?? base.partySize,
      luggageChecked:
          (wire['luggageChecked'] as num?)?.toInt() ?? base.luggageChecked,
      luggageCarryOn:
          (wire['luggageCarryOn'] as num?)?.toInt() ?? base.luggageCarryOn,
      status: (wire['status'] ?? 'Not Requested').toString(),
      assignedDriver: (wire['assignedDriver'] ??
              wire['assignedStaffName'] ??
              wire['chauffeurName'] ??
              '')
          .toString(),
      vehicleModel: (wire['vehicleModel'] ?? '').toString(),
      meetingPoint:
          (wire['meetingPoint'] ?? wire['adminDispatchNotes'] ?? '').toString(),
    );
  }

  static PersonalizationPreferences _mergePreferences(
      PersonalizationPreferences base, Object? raw) {
    if (raw is! Map<String, dynamic>) return base;
    return base.copyWith(
      pillowType: (raw['pillowType'] ?? '').toString(),
      scentProfile: (raw['scentProfile'] ?? '').toString(),
      dietaryRegimen: (raw['dietary'] ?? '').toString(),
      allergyAlerts: (raw['allergies'] ?? '').toString(),
      occasionNote: (raw['occasionDetails'] ?? '').toString(),
      housekeepingCadence:
          (raw['housekeepingCadence'] ?? base.housekeepingCadence).toString(),
    );
  }

  static Map<String, dynamic> toTransferDto(FlightTransport t) => {
        'arrivalDate': t.arrivalDate,
        'arrivalAirport': t.arrivalAirport,
        'airline': t.airline,
        'flightNumber': t.flightNumber,
        'estimatedLanding': t.estimatedLanding,
        'terminal': t.terminalBay,
        'partySize': t.partySize,
        'luggageChecked': t.luggageChecked,
        'luggageCarryOn': t.luggageCarryOn,
      };

  static Map<String, dynamic> toPersonalizationDto(
          PersonalizationPreferences p) =>
      {
        'tripPurpose': p.tripPurpose,
        'occasionDetails': p.occasionNote,
        'selectedInterests': p.interests,
        'pillowType': p.pillowType,
        'temperatureCurve': '${p.ambientTempCelsius}°C',
        'scentProfile': p.scentProfile,
        'lightingRhythm': p.circadianLighting,
        'dietary': p.dietaryRegimen,
        'allergies': p.allergyAlerts,
        'commChannel': p.communicationChannel,
        'housekeepingCadence': p.housekeepingCadence,
      };

  static Map<String, dynamic> toLarderDto(List<LarderItem> items) => {
        'items': items
            .where((i) => i.quantity > 0)
            .map((i) => {'itemId': i.id, 'quantity': i.quantity})
            .toList(),
      };

  static Map<String, dynamic> toYachtBookingDto(YachtCharterConfig charter) => {
        'bookingType': 'YACHT_CHARTER',
        'category': 'yacht',
        'catalogRefId': charter.selectedPackageId,
        'title': charter.vesselModel,
        'scheduledDate': charter.selectedDate,
        'scheduledTimeSlot': charter.departureWindow,
        'partySize': charter.guestCount,
        'metadata': {
          'destinationId': charter.selectedDestinationId,
          'selectedAddOns': charter.selectedAddOns,
        },
      };

  static Map<String, dynamic> toDiningBookingDto(
          DiningReservation reservation) =>
      {
        'bookingType': 'PRIVATE_DINING',
        'category': 'dining',
        'catalogRefId': reservation.selectedMenuId,
        'title': reservation.selectedMenuId,
        'scheduledDate': reservation.selectedEvening,
        'scheduledTimeSlot': reservation.serviceTime,
        'partySize': reservation.guestCount,
        'metadata': {
          'tableSetting': reservation.tableSetting,
          'dietaryNotes': reservation.dietaryNotes,
        },
      };

  static Map<String, dynamic> toExperienceBookingDto(
          ExperienceItem exp, String slot, int partySize) =>
      {
        'bookingType': 'EXCURSION',
        'category': 'Excursions',
        'catalogRefId': exp.id,
        'title': exp.title,
        'scheduledDate': exp.scheduledDate.isNotEmpty
            ? exp.scheduledDate
            : slot.split('·').first.trim(),
        'scheduledTimeSlot': exp.scheduledTimeSlot.isNotEmpty
            ? exp.scheduledTimeSlot
            : (slot.contains('·') ? slot.split('·').last.trim() : '10:00 AM'),
        'partySize': partySize,
      };

  static Map<String, dynamic> toConciergeRequestDto(ConciergeRequest req) => {
        'type': 'request',
        'category': req.category,
        'title': req.title,
        'details': req.details,
        if (req.photoUrl != null) 'photoStoragePath': req.photoUrl,
      };

  static Map<String, dynamic> toMidStayDto(MidStayCheckIn checkIn) => {
        'rating': checkIn.rating,
        'selectedSentiment': checkIn.sentimentId,
        'selectedAspects': checkIn.focusAreas,
        'housekeepingPreferences': [checkIn.housekeepingWindow],
        'note': checkIn.notes,
      };
}
