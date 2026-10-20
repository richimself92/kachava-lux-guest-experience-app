import '../domain/admin_entities.dart';
import '../domain/admin_enums.dart';
import '../domain/admin_stay_entities.dart';

/// Maps `/api/v1/admin/*` REST JSON payloads into Admin domain entities.
class AdminWireMapper {
  const AdminWireMapper._();

  static List<Map<String, dynamic>> extractMapList(Object? raw) {
    if (raw is List) {
      return raw.whereType<Map>().map(Map<String, dynamic>.from).toList();
    }
    if (raw is Map) {
      if (raw['alerts'] is List) return extractMapList(raw['alerts']);
      if (raw['items'] is List) return extractMapList(raw['items']);
      if (raw['stays'] is List) return extractMapList(raw['stays']);
      if (raw['bookings'] is List) return extractMapList(raw['bookings']);
      if (raw['orders'] is List) return extractMapList(raw['orders']);
      if (raw['requests'] is List) return extractMapList(raw['requests']);
      if (raw['feedback'] is List) return extractMapList(raw['feedback']);
      if (raw['data'] != null && raw['data'] != raw) {
        return extractMapList(raw['data']);
      }
    }
    return const [];
  }

  static List<OperationalAlert> parseAlerts(Object? raw) =>
      extractMapList(raw).map(_mapAlert).toList();

  static OperationalAlert _mapAlert(Map<String, dynamic> m) {
    final category = _parseAlertCategory(m['category']?.toString());
    return OperationalAlert(
      alertId: (m['alertId'] ?? 'alt_1').toString(),
      stayId: (m['stayId'] ?? '').toString(),
      villaId: (m['villaId'] ?? 'villa-102').toString(),
      villaName: (m['villaName'] ?? 'Villa 102').toString(),
      guestNames: (m['guestNames'] ?? m['guestName'] ?? 'Guest').toString(),
      category: category,
      severity: _parseAlertSeverity(m['severity']?.toString()),
      title: (m['title'] ?? 'Sanctuary Update').toString(),
      summary: (m['summary'] ?? '').toString(),
      targetTab: _targetTabFor(category),
      targetRecordId:
          (m['targetRecordId'] ?? m['sourceDocumentPath'] ?? m['stayId'] ?? '')
              .toString(),
      assignedDepartment: _parseDepartment(m['assignedDepartment']?.toString()),
      createdAtLabel:
          (m['createdAtLabel'] ?? m['createdAt'] ?? 'Just now').toString(),
      isAcknowledged: m['isAcknowledged'] == true,
      acknowledgedByStaffId: m['acknowledgedByStaffId']?.toString(),
    );
  }

  static List<AdminStayRecord> parseStays(Object? raw) =>
      extractMapList(raw).map(mapStay).toList();

  static AdminStayRecord mapStay(Map<String, dynamic> m) {
    final gp = _asMap(m['guestProfile']),
        fs = _asMap(m['folioSummary']),
        va = _asMap(m['villaAccess']);
    final vName = (m['villaName'] ?? 'Villa 102').toString(),
        sName = (m['suiteName'] ?? '').toString().trim();
    final fullVilla =
        (sName.isNotEmpty && !vName.contains('—')) ? '$vName — $sName' : vName;
    final dates = (m['stayDatesLabel'] ?? '').toString();
    final parts = dates.contains('–') ? dates.split('–') : [dates, ''];
    final checkIn = _nonEmpty([m['checkInDate'], parts.first]);
    final checkOut = _nonEmpty([m['checkOutDate'], parts.last]);
    return AdminStayRecord(
      stayId: (m['stayId'] ?? 'stay_1').toString(),
      guestTokenUuid: (m['guestTokenUuid'] ?? '').toString(),
      villaId: (m['villaId'] ?? 'villa-102').toString(),
      villaName: fullVilla,
      guestNames:
          _nonEmpty([gp['name'], m['guestNames'], m['guestName']], 'Guest'),
      checkInDate: checkIn,
      checkOutDate: checkOut,
      nights: _computeNights(checkIn, checkOut, m['nights']),
      lifecycleStatus: _parseLifecycle(m['status']?.toString()),
      assignedMajordomoName: 'HOST ADMIN',
      personalization: _mapPersonalization(_asMap(m['personalization']), gp),
      transfer: _mapTransfer(_asMap(m['flightTransfer'] ?? m['transfer'])),
      cardReference:
          _nonEmpty([gp['folioCard'], m['cardReference']], 'Visa •••• 8412'),
      wifiSsid:
          _nonEmpty([va['wifiSsid'], m['wifiSsid']], 'Kachava_Sanctuary_102'),
      wifiPasscode:
          _nonEmpty([va['wifiPasscode'], m['wifiPasscode']], 'stillness2026'),
      lateCheckoutApproved: m['lateCheckoutApproved'] == true,
      paymentStatus: _nonEmpty(
          [fs['paymentStatus'], m['paymentStatus']], 'PRE_AUTHORIZED'),
    );
  }

  static GuestPersonalizationProfile _mapPersonalization(
      Map<String, dynamic> p, Map<String, dynamic> gp) {
    final dietary = _nonEmpty([p['dietary']]),
        allergies = _toStrList(p['dietaryAllergies'] ?? p['allergies']);
    return GuestPersonalizationProfile(
      pillowType: _nonEmpty([p['pillowType'], p['pillowSelection']]),
      dayTemp: _nonEmpty([p['dayTemp']]),
      nightTemp: _nonEmpty([p['nightTemp']]),
      scentProfile: _nonEmpty([p['scentProfile'], p['villaScent']]),
      lightingScene: _nonEmpty([p['lightingRhythm'], p['lightingScene']]),
      occasion: _nonEmpty(
          [p['occasionDetails'], p['tripPurpose'], gp['celebration']]),
      morningCoffee: _nonEmpty([p['morningCoffee']]),
      housekeepingCadence: _nonEmpty([p['housekeepingCadence']]),
      dietaryBadges: dietary.isEmpty ? const [] : [dietary],
      allergies: allergies
          .where((a) => a.toLowerCase() != 'none' && a.trim().isNotEmpty)
          .toList(),
      interests: _toStrList(p['selectedInterests'] ?? p['interests']),
    );
  }

  static AviationTransferInfo _mapTransfer(Map<String, dynamic> ft) {
    final meetingPoint =
        _nonEmpty([ft['meetingPoint'], ft['adminDispatchNotes'], ft['notes']]);
    final vehicleParts = [
      _nonEmpty([ft['fleetNumber']]),
      _nonEmpty([ft['vehicleModel']])
    ].where((s) => s.isNotEmpty).join(' ');
    return AviationTransferInfo(
      arrivalDate: _nonEmpty([ft['arrivalDate']]),
      airline: _nonEmpty([ft['airline']]),
      terminal: _nonEmpty([ft['terminal']]),
      inboundFlight: _nonEmpty([ft['flightNumber'], ft['inboundFlight']]),
      inboundRoute: _nonEmpty([ft['arrivalAirport'], ft['inboundRoute']]),
      inboundEta: _nonEmpty(
          [ft['estimatedLanding'], ft['arrivalTime'], ft['inboundEta']]),
      outboundFlight:
          _nonEmpty([ft['departureFlightNumber'], ft['outboundFlight']]),
      outboundRoute:
          _nonEmpty([meetingPoint, ft['departureRoute'], ft['outboundRoute']]),
      outboundEtd: _nonEmpty([ft['departureTimeLabel'], ft['outboundEtd']]),
      cabinTemp: _nonEmpty([ft['cabinTemp']]),
      cabinBeverage: meetingPoint,
      cabinAudio: _nonEmpty([ft['cabinAudio']]),
      assignedChauffeurId: _nonEmpty([ft['assignedStaffId']], 'staff_carlos'),
      assignedChauffeurName:
          _nonEmpty([ft['assignedDriver'], ft['assignedStaffName']]),
      vehicleLabel: vehicleParts,
      transferStatus: _normalizeTransferStatus(ft['status']?.toString()),
    );
  }

  static List<AdminBookingRecord> parseBookings(
          Object? raw, List<AdminStayRecord> stays) =>
      extractMapList(raw).map((m) => _mapBooking(m, stays)).toList();

  static AdminBookingRecord _mapBooking(
      Map<String, dynamic> m, List<AdminStayRecord> stays) {
    final stay = _findStay(stays, m['stayId']?.toString());
    final date = (m['scheduledDate'] ?? '').toString(),
        slot = (m['scheduledTimeSlot'] ?? m['scheduledTime'] ?? '').toString();
    final timeLabel = (date.isNotEmpty && slot.isNotEmpty)
        ? '$date · $slot'
        : (slot.isNotEmpty ? slot : date);
    return AdminBookingRecord(
      bookingId: (m['bookingId'] ?? 'bkg_1').toString(),
      stayId: (m['stayId'] ?? '').toString(),
      villaName:
          (m['villaName'] ?? stay?.villaName ?? m['villaId'] ?? 'Villa 102')
              .toString(),
      guestNames:
          (m['guestNames'] ?? m['guestName'] ?? stay?.guestNames ?? 'Guest')
              .toString(),
      category: _normalizeBookingCategory(
          (m['bookingType'] ?? m['category'] ?? '').toString()),
      title: (m['title'] ?? 'Sanctuary Experience').toString(),
      subtitle:
          (m['subtitle'] ?? m['adminNotes'] ?? 'Curated Experience').toString(),
      scheduledTime: timeLabel,
      addOns: _toStrList(m['addOns']),
      allergyWarning: (m['dietaryNotes'] ?? m['allergyWarning'])?.toString(),
      priceUsd: _toDouble(
          m['priceTotalUsd'] ?? m['priceChargedUSD'] ?? m['priceUsd'] ?? 0),
      status: _normalizeBookingStatus((m['status'] ?? 'Requested').toString()),
      assignedStaffId: (m['assignedStaffId'] ?? 'staff_eduardo').toString(),
      assignedStaffName: (m['assignedStaffName'] ?? 'HOST ADMIN').toString(),
      assignedDepartment: _parseDepartment(m['assignedDepartment']?.toString()),
      notifiedAt: m['notifiedAt']?.toString(),
      cancellationReason: (m['cancellationReason'] ?? '').toString(),
    );
  }

  static List<AdminLarderOrder> parseLarderOrders(
      Object? raw, List<AdminStayRecord> stays) {
    final list = extractMapList(raw);
    if (list.isEmpty) return const [];
    final byStay = <String, List<Map<String, dynamic>>>{};
    for (final item in list) {
      byStay
          .putIfAbsent((item['stayId'] ?? 'stay_1').toString(), () => [])
          .add(item);
    }
    return byStay.entries
        .map((e) => _mapLarderGroup(e.key, e.value, stays))
        .toList();
  }

  static AdminLarderOrder _mapLarderGroup(String stayId,
      List<Map<String, dynamic>> group, List<AdminStayRecord> stays) {
    final first = group.first, stay = _findStay(stays, stayId);
    final status = _normalizeLarderStatus(
        (first['provisioningStatus'] ?? first['status'] ?? 'Pending')
            .toString());
    final items = group
        .map((im) => LarderOrderItem(
              itemId: (im['orderItemId'] ??
                      im['orderId'] ??
                      im['itemId'] ??
                      'larder-1')
                  .toString(),
              name: (im['name'] ?? 'Curated Item').toString(),
              quantity:
                  (im['quantity'] is num ? (im['quantity'] as num).toInt() : 1),
              priceUsd: _toDouble(im['lineTotalUSD'] ??
                  im['unitPriceUSD'] ??
                  im['priceUsd'] ??
                  0),
              placementZone: (im['storageType'] ??
                      im['placementZone'] ??
                      'CHILLED IN LARDER')
                  .toString(),
              isStocked:
                  status == 'Stocked in Villa' || im['isStocked'] == true,
            ))
        .toList();
    return AdminLarderOrder(
      orderId: (first['orderId'] ?? first['orderItemId'] ?? 'larder_$stayId')
          .toString(),
      stayId: stayId,
      villaName:
          (first['villaName'] ?? stay?.villaName ?? 'Villa 102').toString(),
      guestNames: (first['guestNames'] ??
              first['guestName'] ??
              stay?.guestNames ??
              'Guest')
          .toString(),
      targetDeadline: 'Pre-Arrival Provisioning',
      totalUsd: items.fold<double>(0, (s, i) => s + i.priceUsd),
      status: status,
      assignedStaffId: (first['assignedStaffId'] ?? 'staff_sofia').toString(),
      assignedStaffName:
          (first['assignedStaffName'] ?? 'HOST ADMIN').toString(),
      items: items,
      complimentaryStaples: const [
        'Still & Sparkling Limestone Mineral Water',
        'Young Coconuts'
      ],
    );
  }

  static List<AdminConciergeTicket> parseConciergeTickets(
          Object? raw, List<AdminStayRecord> stays) =>
      extractMapList(raw).map((m) => _mapTicket(m, stays)).toList();

  static AdminConciergeTicket _mapTicket(
      Map<String, dynamic> m, List<AdminStayRecord> stays) {
    final stay = _findStay(stays, m['stayId']?.toString()),
        path = m['photoStoragePath']?.toString();
    return AdminConciergeTicket(
      requestId: (m['requestId'] ?? 'req_1').toString(),
      stayId: (m['stayId'] ?? '').toString(),
      villaName: (m['villaName'] ?? stay?.villaName ?? 'Villa 102').toString(),
      guestNames:
          (m['guestNames'] ?? m['guestName'] ?? stay?.guestNames ?? 'Guest')
              .toString(),
      category: (m['category'] ?? 'Concierge').toString(),
      department: _parseDepartment(m['assignedDepartment']?.toString()),
      priority: (m['priority'] ?? 'NORMAL').toString(),
      title: (m['title'] ?? 'Guest Request').toString(),
      details: (m['details'] ?? m['notes'] ?? '').toString(),
      stage: _parseStage(m['status']?.toString()),
      assignedStaffId: (m['assignedStaffId'] ?? 'staff_eduardo').toString(),
      assignedStaffName:
          (m['assignedTo'] ?? m['assignedStaffName'] ?? 'HOST ADMIN')
              .toString(),
      photoStoragePath: path,
      signedPhotoGetUrl: m['signedPhotoGetUrl']?.toString() ??
          (path != null && path.isNotEmpty
              ? 'https://storage.googleapis.com/kachava-lux$path'
              : null),
      messages: extractMapList(m['messages']).map(_mapMessage).toList(),
    );
  }

  static ConciergeChatMessage _mapMessage(Map<String, dynamic> msg) =>
      ConciergeChatMessage(
        messageId: (msg['messageId'] ?? 'msg_1').toString(),
        senderName: (msg['senderName'] ?? 'Guest').toString(),
        senderRole: (msg['senderRole'] ?? msg['sender'] ?? 'GUEST').toString(),
        body: (msg['body'] ?? msg['text'] ?? '').toString(),
        timestampLabel:
            (msg['timestampLabel'] ?? msg['sentAt'] ?? 'Just now').toString(),
        isStaff: msg['isStaff'] == true || msg['sender'] == 'CONCIERGE',
      );

  static List<AdminMidStayPulse> parseMidStayPulses(
          Object? raw, List<AdminStayRecord> stays) =>
      extractMapList(raw).map((m) => _mapPulse(m, stays)).toList();

  static AdminMidStayPulse _mapPulse(
      Map<String, dynamic> m, List<AdminStayRecord> stays) {
    final stay = _findStay(stays, m['stayId']?.toString());
    return AdminMidStayPulse(
      checkInId: (m['checkInId'] ?? m['feedbackId'] ?? 'pulse_1').toString(),
      stayId: (m['stayId'] ?? '').toString(),
      villaName: (m['villaName'] ?? stay?.villaName ?? 'Villa 102').toString(),
      guestNames:
          (m['guestNames'] ?? m['guestName'] ?? stay?.guestNames ?? 'Guest')
              .toString(),
      sentiment:
          (m['sentiment'] ?? m['selectedSentiment'] ?? 'Tuned').toString(),
      focusChips: _toStrList(
          m['focusAreas'] ?? m['selectedAspects'] ?? m['focusChips']),
      guestNote: (m['notes'] ?? m['note'] ?? m['guestNote'] ?? '').toString(),
      slaLabel: '< 7 Min SLA',
      isUnderSla: true,
      status: (m['status'] ?? 'OPEN').toString(),
      followUpNote:
          (m['followUpNote'] ?? 'Awaiting Host Admin follow-up').toString(),
      handledByStaffName: (m['handledByStaffName'] ?? 'HOST ADMIN').toString(),
      rating: (m['rating'] as num?)?.toInt() ?? 5,
    );
  }

  static List<FolioLineItem> parseFolioItemsFromStays(List<dynamic> rawStays) =>
      [
        for (final s in extractMapList(rawStays))
          for (final fi in extractMapList(s['folioItems']))
            FolioLineItem(
              itemId: (fi['folioItemId'] ?? fi['itemId'] ?? 'fol_1').toString(),
              title: (fi['title'] ?? 'Folio Item').toString(),
              categoryLabel:
                  (fi['categoryLabel'] ?? fi['category'] ?? 'INCIDENTAL')
                      .toString(),
              amountUsd:
                  _toDouble(fi['amountUsd'] ?? fi['chargedAmountUSD'] ?? 0),
              isIncludedPrivilege: fi['isIncludedPrivilege'] == true ||
                  fi['isComplimentary'] == true,
            ),
      ];

  static List<AdminExperienceCatalogItem> parseExperienceCatalog(Object? raw) =>
      extractMapList(raw).map(mapExperienceCatalogItem).toList();

  static AdminExperienceCatalogItem mapExperienceCatalogItem(
      Map<String, dynamic> m) {
    final price = _toDouble(m['basePriceUSD'] ?? m['price'] ?? 0),
        inc = m['isIncluded'] == true || price == 0;
    return AdminExperienceCatalogItem(
      id: _nonEmpty([m['id'], m['experienceId']], 'exp_1'),
      title: _nonEmpty([m['title'], m['name']], 'Experience'),
      category: _nonEmpty([m['category']], 'Excursions'),
      duration: _nonEmpty([m['duration']], 'Half-Day'),
      location: _nonEmpty([m['location']], 'Riviera Maya'),
      priceText: _nonEmpty([m['priceText']],
          inc ? 'Included' : '\$${price.toStringAsFixed(0)} USD'),
      basePriceUSD: price,
      isIncluded: inc,
      description: _nonEmpty([m['description']]),
    );
  }

  static List<AdminLarderCatalogItem> parseLarderCatalog(Object? raw) =>
      extractMapList(raw).map(mapLarderCatalogItem).toList();

  static AdminLarderCatalogItem mapLarderCatalogItem(Map<String, dynamic> m) =>
      AdminLarderCatalogItem(
        id: _nonEmpty([m['id'], m['itemId']], 'lrd_1'),
        name: _nonEmpty([m['name'], m['title']], 'Larder Item'),
        origin: _nonEmpty([m['origin']], 'Riviera Maya Sanctuary'),
        price: _toDouble(m['price'] ?? m['unitPriceUSD'] ?? m['priceUsd'] ?? 0),
        category: _nonEmpty([m['category']], 'Artisanal Spirits'),
        storageType: _nonEmpty(
            [m['storageType'], m['placementZone']], 'CHILLED IN LARDER'),
        description: _nonEmpty([m['description']]),
      );

  static int _computeNights(
      String checkIn, String checkOut, Object? rawNights) {
    final dIn = _parseDate(checkIn), dOut = _parseDate(checkOut);
    if (dIn != null && dOut != null && dOut.difference(dIn).inDays > 0) {
      return dOut.difference(dIn).inDays;
    }
    return (rawNights as num?)?.toInt() ?? 3;
  }

  static DateTime? _parseDate(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    final iso = DateTime.tryParse(s);
    if (iso != null) return DateTime.utc(iso.year, iso.month, iso.day);
    const months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12
    };
    final withYear = RegExp(r'\b20\d{2}\b').hasMatch(s) ? s : '$s, 2026';
    final match = RegExp(r'([A-Za-z]{3})[a-z]*\s+(\d{1,2})(?:,?\s*(\d{4}))?')
        .firstMatch(withYear);
    if (match == null) return null;
    final m = months[match.group(1)!.toLowerCase()],
        d = int.tryParse(match.group(2)!),
        y = int.tryParse(match.group(3) ?? '2026') ?? 2026;
    return (m != null && d != null) ? DateTime.utc(y, m, d) : null;
  }

  static String _nonEmpty(List<Object?> vals, [String fallback = '']) {
    for (final v in vals) {
      final s = v?.toString().trim() ?? '';
      if (s.isNotEmpty) return s;
    }
    return fallback;
  }

  static AdminStayRecord? _findStay(List<AdminStayRecord> stays, String? id) =>
      id == null ? null : stays.where((s) => s.stayId == id).firstOrNull;
  static Map<String, dynamic> _asMap(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : const {};
  static double _toDouble(Object? v) =>
      v is num ? v.toDouble() : (double.tryParse('$v') ?? 0.0);
  static List<String> _toStrList(Object? v) => v is List
      ? v.map((e) => e.toString()).toList()
      : (v is String && v.trim().isNotEmpty ? [v.trim()] : const []);
  static AlertCategory _parseAlertCategory(String? s) =>
      AlertCategory.values.firstWhere((e) => e.label == s?.toUpperCase(),
          orElse: () => AlertCategory.concierge);
  static AlertSeverity _parseAlertSeverity(String? s) =>
      AlertSeverity.values.firstWhere((e) => e.label == s?.toUpperCase(),
          orElse: () => AlertSeverity.normal);
  static StaffDepartment _parseDepartment(String? s) =>
      StaffDepartment.values.firstWhere((e) => e.apiValue == s?.toUpperCase(),
          orElse: () => StaffDepartment.concierge);
  static StayLifecycleStatus _parseLifecycle(String? s) =>
      StayLifecycleStatus.values.firstWhere((e) => e.label == s?.toUpperCase(),
          orElse: () => StayLifecycleStatus.preArrival);
  static ConciergeStage _parseStage(String? s) => ConciergeStage.values
      .firstWhere((e) => e.label.toLowerCase() == s?.toLowerCase(),
          orElse: () => ConciergeStage.requested);
  static AdminWorkspaceTab _targetTabFor(AlertCategory c) => switch (c) {
        AlertCategory.concierge => AdminWorkspaceTab.adminConcierge,
        AlertCategory.booking ||
        AlertCategory.dietary =>
          AdminWorkspaceTab.adminExperiences,
        AlertCategory.larder => AdminWorkspaceTab.adminLarder,
        AlertCategory.transfer => AdminWorkspaceTab.adminStays,
        AlertCategory.midstay ||
        AlertCategory.checkout =>
          AdminWorkspaceTab.adminFolio,
      };
  static String _normalizeTransferStatus(String? s) {
    final v = s?.trim() ?? '';
    if (v.isEmpty || v == 'Not Requested' || v == 'Pending Guest Info') {
      return 'Not Requested';
    }
    final u = v.toUpperCase();
    return u.contains('ROUTE')
        ? 'En Route'
        : (u == 'COMPLETED'
            ? 'Completed'
            : (u == 'CONFIRMED'
                ? 'Confirmed'
                : (u == 'PENDING' ? 'Pending' : 'Scheduled')));
  }

  static String _normalizeBookingCategory(String s) =>
      s.toUpperCase().contains('YACHT')
          ? 'Yacht Charters'
          : (s.toUpperCase().contains('DINING')
              ? 'Private Dining'
              : (s.toUpperCase().contains('PRIVILEGE') ||
                      s.toUpperCase().contains('INCLUDED')
                  ? 'Included Privileges'
                  : 'Excursions'));
  static String _normalizeBookingStatus(String s) {
    final u = s.toUpperCase();
    return u == 'CONFIRMED'
        ? 'Confirmed'
        : (u == 'COMPLETED'
            ? 'Completed'
            : ((u == 'CANCELLED' || u == 'CANCELED')
                ? 'Cancelled'
                : 'Requested'));
  }

  static String _normalizeLarderStatus(String s) =>
      s.toUpperCase().contains('STOCKED')
          ? 'Stocked in Villa'
          : (s.toUpperCase().contains('ASSIGNED') ? 'Assigned' : 'Pending');
}
