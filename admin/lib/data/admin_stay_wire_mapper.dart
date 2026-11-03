import '../domain/admin_enums.dart';
import '../domain/admin_stay_entities.dart';
import 'admin_wire_values.dart';

/// Maps `/api/v1/admin/stays` items into [AdminStayRecord]s.
///
/// A stay without a `stayId` is rejected; every other missing field stays
/// empty so the UI can show `—` instead of an invented value.
class AdminStayWireMapper {
  const AdminStayWireMapper._();

  static const _t = WireValues.text;

  /// Returns `null` for a stay without `stayId`.
  static AdminStayRecord? tryMap(Map<String, dynamic> m) {
    final id = WireValues.id(m, const ['stayId']);
    return id == null ? null : _map(id, m);
  }

  /// Throws [FormatException] for a stay without `stayId`.
  static AdminStayRecord map(Map<String, dynamic> m) =>
      tryMap(m) ?? (throw const FormatException('Stay without stayId.'));

  static AdminStayRecord _map(String stayId, Map<String, dynamic> m) {
    final gp = WireValues.asMap(m['guestProfile']),
        fs = WireValues.asMap(m['folioSummary']),
        va = WireValues.asMap(m['villaAccess']);
    final (checkIn, checkOut) = _dates(m);
    return AdminStayRecord(
      stayId: stayId,
      guestTokenUuid: _t([m['guestTokenUuid']]),
      villaId: _t([m['villaId']]),
      villaName: _villaLabel(m),
      guestNames: _t([gp['name'], m['guestNames'], m['guestName']]),
      checkInDate: checkIn,
      checkOutDate: checkOut,
      nights: WireValues.nights(checkIn, checkOut, m['nights']),
      lifecycleStatus: _parseLifecycle(m['status']?.toString()),
      assignedMajordomoName: '',
      personalization:
          _mapPersonalization(WireValues.asMap(m['personalization']), gp),
      transfer:
          _mapTransfer(WireValues.asMap(m['flightTransfer'] ?? m['transfer'])),
      cardReference: _t([gp['folioCard'], m['cardReference']]),
      wifiSsid: _t([va['wifiSsid'], m['wifiSsid']]),
      wifiPasscode: _t([va['wifiPasscode'], m['wifiPasscode']]),
      lateCheckoutApproved: m['lateCheckoutApproved'] == true,
      paymentStatus: _t([fs['paymentStatus'], m['paymentStatus']]),
    );
  }

  static String _villaLabel(Map<String, dynamic> m) {
    final vName = _t([m['villaName']]), sName = _t([m['suiteName']]);
    return (vName.isNotEmpty && sName.isNotEmpty && !vName.contains('—'))
        ? '$vName — $sName'
        : vName;
  }

  static (String, String) _dates(Map<String, dynamic> m) {
    final label = _t([m['stayDatesLabel']]);
    final parts = label.contains('–') ? label.split('–') : [label, ''];
    return (
      _t([m['checkInDate'], parts.first]),
      _t([m['checkOutDate'], parts.last])
    );
  }

  static StayLifecycleStatus _parseLifecycle(String? s) =>
      StayLifecycleStatus.values.firstWhere((e) => e.label == s?.toUpperCase(),
          orElse: () => StayLifecycleStatus.preArrival);

  static GuestPersonalizationProfile _mapPersonalization(
      Map<String, dynamic> p, Map<String, dynamic> gp) {
    final dietary = _t([p['dietary']]),
        allergies =
            WireValues.toStrList(p['dietaryAllergies'] ?? p['allergies']);
    return GuestPersonalizationProfile(
      pillowType: _t([p['pillowType'], p['pillowSelection']]),
      dayTemp: _t([p['dayTemp']]),
      nightTemp: _t([p['nightTemp']]),
      scentProfile: _t([p['scentProfile'], p['villaScent']]),
      lightingScene: _t([p['lightingRhythm'], p['lightingScene']]),
      occasion: _t([p['occasionDetails'], p['tripPurpose'], gp['celebration']]),
      morningCoffee: _t([p['morningCoffee']]),
      housekeepingCadence: _t([p['housekeepingCadence']]),
      dietaryBadges: dietary.isEmpty ? const [] : [dietary],
      allergies: allergies
          .where((a) => a.toLowerCase() != 'none' && a.trim().isNotEmpty)
          .toList(),
      interests: WireValues.toStrList(p['selectedInterests'] ?? p['interests']),
    );
  }

  static AviationTransferInfo _mapTransfer(Map<String, dynamic> ft) {
    final meetingPoint =
        _t([ft['meetingPoint'], ft['adminDispatchNotes'], ft['notes']]);
    return AviationTransferInfo(
      arrivalDate: _t([ft['arrivalDate']]),
      airline: _t([ft['airline']]),
      terminal: _t([ft['terminal']]),
      inboundFlight: _t([ft['flightNumber'], ft['inboundFlight']]),
      inboundRoute: _t([ft['arrivalAirport'], ft['inboundRoute']]),
      inboundEta:
          _t([ft['estimatedLanding'], ft['arrivalTime'], ft['inboundEta']]),
      outboundFlight: _t([ft['departureFlightNumber'], ft['outboundFlight']]),
      outboundRoute:
          _t([meetingPoint, ft['departureRoute'], ft['outboundRoute']]),
      outboundEtd: _t([ft['departureTimeLabel'], ft['outboundEtd']]),
      cabinTemp: _t([ft['cabinTemp']]),
      cabinBeverage: meetingPoint,
      cabinAudio: _t([ft['cabinAudio']]),
      assignedChauffeurId: _t([ft['assignedStaffId']]),
      assignedChauffeurName:
          _t([ft['assignedDriver'], ft['assignedStaffName']]),
      vehicleLabel: [
        _t([ft['fleetNumber']]),
        _t([ft['vehicleModel']])
      ].where((s) => s.isNotEmpty).join(' '),
      transferStatus: _normalizeTransferStatus(ft['status']?.toString()),
    );
  }

  static String _normalizeTransferStatus(String? s) {
    final v = s?.trim() ?? '';
    if (v.isEmpty || v == 'Not Requested' || v == 'Pending Guest Info') {
      return 'Not Requested';
    }
    final u = v.toUpperCase();
    if (u.contains('ROUTE')) return 'En Route';
    return switch (u) {
      'COMPLETED' => 'Completed',
      'CONFIRMED' => 'Confirmed',
      'PENDING' => 'Pending',
      _ => 'Scheduled',
    };
  }
}
