import '../domain/admin_entities.dart';
import '../domain/admin_enums.dart';
import '../domain/admin_stay_entities.dart';
import 'admin_catalog_wire_mapper.dart';
import 'admin_stay_wire_mapper.dart';
import 'admin_wire_values.dart';

/// Maps `/api/v1/admin/*` REST JSON payloads into Admin domain entities.
///
/// Records without their identifier are skipped (never given a fake id) and
/// missing guest/villa/staff/time fields stay empty: the UI shows `—` or
/// "Unassigned" instead of an invented value.
class AdminWireMapper {
  const AdminWireMapper._();

  static const _t = WireValues.text;
  static const _listKeys = [
    'alerts',
    'items',
    'stays',
    'bookings',
    'orders',
    'requests',
    'feedback'
  ];

  static List<Map<String, dynamic>> extractMapList(Object? raw) {
    if (raw is List) {
      return raw.whereType<Map>().map(Map<String, dynamic>.from).toList();
    }
    if (raw is Map) {
      for (final key in _listKeys) {
        if (raw[key] is List) return extractMapList(raw[key]);
      }
      if (raw['data'] != null && raw['data'] != raw) {
        return extractMapList(raw['data']);
      }
    }
    return const [];
  }

  /// Throws [FormatException] (never a [TypeError]) for a malformed record.
  static List<T> _parse<T>(Object? raw, T? Function(Map<String, dynamic>) f) {
    try {
      return extractMapList(raw).map(f).whereType<T>().toList();
    } on TypeError catch (error) {
      throw FormatException('Malformed admin $T payload: $error');
    }
  }

  static List<OperationalAlert> parseAlerts(Object? raw) =>
      _parse(raw, _mapAlert);

  static OperationalAlert? _mapAlert(Map<String, dynamic> m) {
    final id = WireValues.id(m, const ['alertId']);
    if (id == null) return null;
    final category = _parseAlertCategory(m['category']?.toString());
    return OperationalAlert(
      alertId: id,
      stayId: _t([m['stayId']]),
      villaId: _t([m['villaId']]),
      villaName: _t([m['villaName']]),
      guestNames: _t([m['guestNames'], m['guestName']]),
      category: category,
      severity: _parseAlertSeverity(m['severity']?.toString()),
      title: _t([m['title']]),
      summary: _t([m['summary']]),
      targetTab: _targetTabFor(category),
      targetRecordId:
          _t([m['targetRecordId'], m['sourceDocumentPath'], m['stayId']]),
      assignedDepartment: _parseDepartment(m['assignedDepartment']?.toString()),
      createdAtLabel: _t([m['createdAtLabel'], m['createdAt']]),
      isAcknowledged: m['isAcknowledged'] == true,
      acknowledgedByStaffId: m['acknowledgedByStaffId']?.toString(),
    );
  }

  /// Stays without a `stayId` are skipped.
  static List<AdminStayRecord> parseStays(Object? raw) =>
      _parse(raw, AdminStayWireMapper.tryMap);

  /// Throws [FormatException] when the stay has no `stayId`.
  static AdminStayRecord mapStay(Map<String, dynamic> m) =>
      AdminStayWireMapper.map(m);

  static List<AdminBookingRecord> parseBookings(
          Object? raw, List<AdminStayRecord> stays) =>
      _parse(raw, (m) => _mapBooking(m, stays));

  static AdminBookingRecord? _mapBooking(
      Map<String, dynamic> m, List<AdminStayRecord> stays) {
    final id = WireValues.id(m, const ['bookingId']);
    if (id == null) return null;
    final stay = WireValues.findStay(stays, m['stayId']?.toString());
    return AdminBookingRecord(
      bookingId: id,
      stayId: _t([m['stayId']]),
      villaName: _t([m['villaName'], stay?.villaName, m['villaId']]),
      guestNames: _t([m['guestNames'], m['guestName'], stay?.guestNames]),
      category:
          WireValues.bookingCategory(_t([m['bookingType'], m['category']])),
      title: _t([m['title']]),
      subtitle: _t([m['subtitle'], m['adminNotes']]),
      scheduledTime: _scheduleLabel(m),
      addOns: WireValues.toStrList(m['addOns']),
      allergyWarning: (m['dietaryNotes'] ?? m['allergyWarning'])?.toString(),
      priceUsd: WireValues.toDouble(
          m['priceTotalUsd'] ?? m['priceChargedUSD'] ?? m['priceUsd']),
      status: WireValues.bookingStatus(_t([m['status']])),
      assignedStaffId: _t([m['assignedStaffId']]),
      assignedStaffName: _t([m['assignedStaffName']]),
      assignedDepartment: _parseDepartment(m['assignedDepartment']?.toString()),
      notifiedAt: m['notifiedAt']?.toString(),
      cancellationReason: _t([m['cancellationReason']]),
    );
  }

  static String _scheduleLabel(Map<String, dynamic> m) {
    final date = _t([m['scheduledDate']]),
        slot = _t([m['scheduledTimeSlot'], m['scheduledTime']]);
    if (date.isEmpty || slot.isEmpty) return slot.isNotEmpty ? slot : date;
    return '$date · $slot';
  }

  /// Groups line items per stay; groups without an order id are skipped.
  static List<AdminLarderOrder> parseLarderOrders(
      Object? raw, List<AdminStayRecord> stays) {
    final byStay = <String, List<Map<String, dynamic>>>{};
    for (final item in extractMapList(raw)) {
      byStay.putIfAbsent(_t([item['stayId']]), () => []).add(item);
    }
    return byStay.entries
        .map((e) => _mapLarderGroup(e.key, e.value, stays))
        .whereType<AdminLarderOrder>()
        .toList();
  }

  static AdminLarderOrder? _mapLarderGroup(String stayId,
      List<Map<String, dynamic>> group, List<AdminStayRecord> stays) {
    final first = group.first, stay = WireValues.findStay(stays, stayId);
    final orderId = WireValues.id(first, const ['orderId', 'orderItemId']);
    if (orderId == null) return null;
    final status = WireValues.larderStatus(
        _t([first['provisioningStatus'], first['status']]));
    final items = [
      for (final im in group) _mapLarderItem(im, status),
    ].whereType<LarderOrderItem>().toList();
    return AdminLarderOrder(
      orderId: orderId,
      stayId: stayId,
      villaName: _t([first['villaName'], stay?.villaName]),
      guestNames:
          _t([first['guestNames'], first['guestName'], stay?.guestNames]),
      targetDeadline: _t([first['targetDeadline']]),
      totalUsd: items.fold<double>(0, (s, i) => s + i.priceUsd),
      status: status,
      assignedStaffId: _t([first['assignedStaffId']]),
      assignedStaffName: _t([first['assignedStaffName']]),
      items: items,
      complimentaryStaples: WireValues.toStrList(first['complimentaryStaples']),
    );
  }

  static LarderOrderItem? _mapLarderItem(
      Map<String, dynamic> im, String status) {
    final id = WireValues.id(im, const ['orderItemId', 'orderId', 'itemId']);
    if (id == null) return null;
    final zone = _t([im['storageType'], im['placementZone']]);
    return LarderOrderItem(
      itemId: id,
      name: _t([im['name']]),
      quantity: im['quantity'] is num ? (im['quantity'] as num).toInt() : 1,
      priceUsd: WireValues.toDouble(
          im['lineTotalUSD'] ?? im['unitPriceUSD'] ?? im['priceUsd']),
      placementZone: zone.isEmpty ? 'CHILLED IN LARDER' : zone,
      isStocked: status == 'Stocked in Villa' || im['isStocked'] == true,
    );
  }

  static List<AdminConciergeTicket> parseConciergeTickets(
          Object? raw, List<AdminStayRecord> stays) =>
      _parse(raw, (m) => _mapTicket(m, stays));

  static AdminConciergeTicket? _mapTicket(
      Map<String, dynamic> m, List<AdminStayRecord> stays) {
    final id = WireValues.id(m, const ['requestId']);
    if (id == null) return null;
    final stay = WireValues.findStay(stays, m['stayId']?.toString()),
        path = m['photoStoragePath']?.toString();
    return AdminConciergeTicket(
      requestId: id,
      stayId: _t([m['stayId']]),
      villaName: _t([m['villaName'], stay?.villaName]),
      guestNames: _t([m['guestNames'], m['guestName'], stay?.guestNames]),
      category: _t([m['category']]),
      department: _parseDepartment(m['assignedDepartment']?.toString()),
      priority: _t([m['priority']]).isEmpty ? 'NORMAL' : _t([m['priority']]),
      title: _t([m['title']]),
      details: _t([m['details'], m['notes']]),
      stage: _parseStage(m['status']?.toString()),
      assignedStaffId: _t([m['assignedStaffId']]),
      assignedStaffName: _t([m['assignedTo'], m['assignedStaffName']]),
      photoStoragePath: path,
      signedPhotoGetUrl: m['signedPhotoGetUrl']?.toString(),
      messages: extractMapList(m['messages']).map(_mapMessage).toList(),
    );
  }

  static ConciergeChatMessage _mapMessage(Map<String, dynamic> msg) =>
      ConciergeChatMessage(
        messageId: _t([msg['messageId']]),
        senderName: _t([msg['senderName']]),
        senderRole: _t([msg['senderRole'], msg['sender']]).isEmpty
            ? 'GUEST'
            : _t([msg['senderRole'], msg['sender']]),
        body: _t([msg['body'], msg['text']]),
        timestampLabel: _t([msg['timestampLabel'], msg['sentAt']]),
        isStaff: msg['isStaff'] == true || msg['sender'] == 'CONCIERGE',
      );

  static List<AdminMidStayPulse> parseMidStayPulses(
          Object? raw, List<AdminStayRecord> stays) =>
      _parse(raw, (m) => _mapPulse(m, stays));

  static AdminMidStayPulse? _mapPulse(
      Map<String, dynamic> m, List<AdminStayRecord> stays) {
    final id = WireValues.id(m, const ['checkInId', 'feedbackId']);
    if (id == null) return null;
    final stay = WireValues.findStay(stays, m['stayId']?.toString());
    return AdminMidStayPulse(
      checkInId: id,
      stayId: _t([m['stayId']]),
      villaName: _t([m['villaName'], stay?.villaName]),
      guestNames: _t([m['guestNames'], m['guestName'], stay?.guestNames]),
      sentiment: _t([m['sentiment'], m['selectedSentiment']]),
      focusChips: WireValues.toStrList(
          m['focusAreas'] ?? m['selectedAspects'] ?? m['focusChips']),
      guestNote: _t([m['notes'], m['note'], m['guestNote']]),
      slaLabel: '< 7 Min SLA',
      isUnderSla: true,
      status: _t([m['status']]).isEmpty ? 'OPEN' : _t([m['status']]),
      followUpNote: _t([m['followUpNote']]),
      handledByStaffName: _t([m['handledByStaffName']]),
      rating: (m['rating'] as num?)?.toInt() ?? 0,
    );
  }

  static List<FolioLineItem> parseFolioItemsFromStays(List<dynamic> rawStays) =>
      [
        for (final s in extractMapList(rawStays))
          ..._parse(s['folioItems'], AdminCatalogWireMapper.folioItem),
      ];

  static AlertCategory _parseAlertCategory(String? s) =>
      AlertCategory.values.firstWhere((e) => e.label == s?.toUpperCase(),
          orElse: () => AlertCategory.concierge);
  static AlertSeverity _parseAlertSeverity(String? s) =>
      AlertSeverity.values.firstWhere((e) => e.label == s?.toUpperCase(),
          orElse: () => AlertSeverity.normal);
  static StaffDepartment _parseDepartment(String? s) =>
      StaffDepartment.values.firstWhere((e) => e.apiValue == s?.toUpperCase(),
          orElse: () => StaffDepartment.concierge);
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
}
