import '../../domain/entities/empty_sanctuary.dart';
import '../../domain/entities/stay_entities.dart';

/// Maps the stay, transfer and personalization blocks of `GET /stays/:uuid`.
///
/// Only server values are used: a missing field stays empty, never seeded.
abstract final class StayWireMapper {
  static StaySummary mapStay(String guestUuid, Map<String, dynamic> payload) {
    final base = EmptySanctuary.stay(guestUuid).copyWith(
      lifecycleStatus: StayLifecycleStatus.fromWire(
          (payload['status'] ?? payload['lifecycleStatus']) as String?),
    );
    return _withAccess(
      _withVilla(_withGuest(base, asMap(payload['guestProfile'])), payload),
      asMap(payload['villaAccess']),
      payload,
    );
  }

  static StaySummary _withGuest(StaySummary base, Map<String, dynamic> p) {
    final guestName = text(p['name']);
    final words = guestName.split(RegExp(r'[\s&]+')).where((w) => w.isNotEmpty);
    return base.copyWith(
      guestNames: guestName,
      primaryGuestName: words.firstOrNull ?? '',
      partnerName: text(p['partner']),
      lastName: firstText([p['lastNameNormalized'], words.lastOrNull]),
      celebrationTitle: text(p['celebration']),
      folioCardLabel: text(p['folioCard']),
    );
  }

  static StaySummary _withVilla(StaySummary base, Map<String, dynamic> p) {
    final villaName = text(p['villaName']);
    final stayDates = text(p['stayDatesLabel']);
    final host = asMap(p['hostInfo']);
    return base.copyWith(
      villaNumber: RegExp(r'\d+').firstMatch(villaName)?.group(0) ?? '',
      villaTitle: villaName,
      suiteName: text(p['suiteName']),
      stayDates: stayDates,
      nights:
          StaySummary.computeNightsFromLabel(stayDates) ?? _int(p['nights']),
      guestsCount: _int(p['guestsCount']),
      privateHostName: firstText([host['name'], p['privateHostName']]),
      privateHostRole: firstText([host['role'], p['privateHostRole']]),
      selectedSignaturePrivilege: text(p['selectedSignaturePrivilege']),
    );
  }

  static StaySummary _withAccess(StaySummary base, Map<String, dynamic> access,
          Map<String, dynamic> payload) =>
      base.copyWith(
        wifiSsid: firstText([access['wifiSsid'], payload['wifiSsid']]),
        wifiPassphrase: firstText([
          access['wifiPasscode'],
          access['wifiPassphrase'],
          payload['wifiPassphrase'],
        ]),
        isDigitalKeyEnabled: access['digitalKeyStatus'] == 'ACTIVE',
      );

  static FlightTransport mapTransport(Object? raw) {
    if (raw is! Map<String, dynamic>) return EmptySanctuary.transport;
    return FlightTransport(
      arrivalDate: text(raw['arrivalDate']),
      arrivalAirport: text(raw['arrivalAirport']),
      airline: text(raw['airline']),
      flightNumber: text(raw['flightNumber']),
      estimatedLanding:
          firstText([raw['estimatedLanding'], raw['arrivalTime']]),
      terminalBay: text(raw['terminal']),
      partySize: _int(raw['partySize']),
      luggageChecked: _int(raw['luggageChecked']),
      luggageCarryOn: _int(raw['luggageCarryOn']),
      status: firstText([raw['status'], 'Not Requested']),
      assignedDriver: firstText([
        raw['assignedDriver'],
        raw['assignedStaffName'],
        raw['chauffeurName'],
      ]),
      vehicleModel: text(raw['vehicleModel']),
      meetingPoint: firstText([raw['meetingPoint'], raw['adminDispatchNotes']]),
    );
  }

  static PersonalizationPreferences mapPreferences(Object? raw) {
    const empty = EmptySanctuary.preferences;
    if (raw is! Map<String, dynamic>) return empty;
    final interests = raw['selectedInterests'];
    return empty.copyWith(
      tripPurpose: text(raw['tripPurpose']),
      occasionNote: text(raw['occasionDetails']),
      interests: interests is List
          ? interests.map((e) => e.toString()).toList()
          : const <String>[],
      pillowType: text(raw['pillowType']),
      scentProfile: text(raw['scentProfile']),
      circadianLighting: text(raw['lightingRhythm']),
      dietaryRegimen: text(raw['dietary']),
      allergyAlerts: text(raw['allergies']),
      communicationChannel: text(raw['commChannel']),
      housekeepingCadence: text(raw['housekeepingCadence']),
    );
  }

  static Map<String, dynamic> asMap(Object? raw) =>
      raw is Map<String, dynamic> ? raw : const {};

  /// Trimmed string value, or empty when absent or blank.
  static String text(Object? raw) => raw is String ? raw.trim() : '';

  /// First non-blank text among [candidates], or empty.
  static String firstText(List<Object?> candidates) =>
      candidates.map(text).firstWhere((v) => v.isNotEmpty, orElse: () => '');

  static int _int(Object? raw) => raw is num ? raw.toInt() : 0;
}
