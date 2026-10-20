/// Lifecycle state machine for guest stay tokens (`FR-01`, Section 3.2).
enum StayLifecycleStatus {
  preArrival('PRE_ARRIVAL'),
  activeStay('ACTIVE_STAY'),
  checkedOut('CHECKED_OUT');

  const StayLifecycleStatus(this.wireValue);
  final String wireValue;

  static StayLifecycleStatus fromWire(String? raw) {
    for (final status in StayLifecycleStatus.values) {
      if (status.wireValue == raw || status.name == raw) {
        return status;
      }
    }
    return StayLifecycleStatus.activeStay;
  }
}

/// Flight and private aviation/chauffeur transfer details (`FR-02`).
class FlightTransport {
  const FlightTransport({
    this.arrivalDate = '',
    required this.arrivalAirport,
    required this.airline,
    required this.flightNumber,
    required this.estimatedLanding,
    required this.terminalBay,
    required this.partySize,
    required this.luggageChecked,
    required this.luggageCarryOn,
    required this.status,
    required this.assignedDriver,
    required this.vehicleModel,
    this.meetingPoint = '',
  });

  final String arrivalDate, arrivalAirport, airline, flightNumber;
  final String estimatedLanding, terminalBay, status, assignedDriver;
  final String vehicleModel, meetingPoint;
  final int partySize, luggageChecked, luggageCarryOn;

  FlightTransport copyWith({
    String? arrivalDate,
    String? arrivalAirport,
    String? airline,
    String? flightNumber,
    String? estimatedLanding,
    String? terminalBay,
    int? partySize,
    int? luggageChecked,
    int? luggageCarryOn,
    String? status,
    String? assignedDriver,
    String? vehicleModel,
    String? meetingPoint,
  }) =>
      FlightTransport(
        arrivalDate: arrivalDate ?? this.arrivalDate,
        arrivalAirport: arrivalAirport ?? this.arrivalAirport,
        airline: airline ?? this.airline,
        flightNumber: flightNumber ?? this.flightNumber,
        estimatedLanding: estimatedLanding ?? this.estimatedLanding,
        terminalBay: terminalBay ?? this.terminalBay,
        partySize: partySize ?? this.partySize,
        luggageChecked: luggageChecked ?? this.luggageChecked,
        luggageCarryOn: luggageCarryOn ?? this.luggageCarryOn,
        status: status ?? this.status,
        assignedDriver: assignedDriver ?? this.assignedDriver,
        vehicleModel: vehicleModel ?? this.vehicleModel,
        meetingPoint: meetingPoint ?? this.meetingPoint,
      );
}

/// 3-step pre-arrival stay personalization preferences (`FR-03`).
class PersonalizationPreferences {
  const PersonalizationPreferences({
    required this.tripPurpose,
    required this.occasionNote,
    required this.interests,
    required this.pillowType,
    required this.ambientTempCelsius,
    required this.scentProfile,
    required this.circadianLighting,
    required this.dietaryRegimen,
    required this.allergyAlerts,
    required this.communicationChannel,
    this.housekeepingCadence = '',
  });

  final String tripPurpose;
  final String occasionNote;
  final List<String> interests;
  final String pillowType;
  final int ambientTempCelsius;
  final String scentProfile;
  final String circadianLighting;
  final String dietaryRegimen;
  final String allergyAlerts;
  final String communicationChannel;
  final String housekeepingCadence;

  PersonalizationPreferences copyWith({
    String? tripPurpose,
    String? occasionNote,
    List<String>? interests,
    String? pillowType,
    int? ambientTempCelsius,
    String? scentProfile,
    String? circadianLighting,
    String? dietaryRegimen,
    String? allergyAlerts,
    String? communicationChannel,
    String? housekeepingCadence,
  }) {
    return PersonalizationPreferences(
      tripPurpose: tripPurpose ?? this.tripPurpose,
      occasionNote: occasionNote ?? this.occasionNote,
      interests: interests ?? this.interests,
      pillowType: pillowType ?? this.pillowType,
      ambientTempCelsius: ambientTempCelsius ?? this.ambientTempCelsius,
      scentProfile: scentProfile ?? this.scentProfile,
      circadianLighting: circadianLighting ?? this.circadianLighting,
      dietaryRegimen: dietaryRegimen ?? this.dietaryRegimen,
      allergyAlerts: allergyAlerts ?? this.allergyAlerts,
      communicationChannel: communicationChannel ?? this.communicationChannel,
      housekeepingCadence: housekeepingCadence ?? this.housekeepingCadence,
    );
  }
}

/// Pre-arrival checklist task displayed on Residency Home (`FR-01`).
class ChecklistTask {
  const ChecklistTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.targetScreenId,
    required this.isCompleted,
  });

  final String id;
  final String title;
  final String subtitle;
  final String targetScreenId;
  final bool isCompleted;

  ChecklistTask copyWith({bool? isCompleted}) {
    return ChecklistTask(
      id: id,
      title: title,
      subtitle: subtitle,
      targetScreenId: targetScreenId,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Core residency summary for Villa 102 — Ceiba Suite (`FR-01`, `FR-13`).
class StaySummary {
  const StaySummary({
    required this.guestUuid,
    required this.guestNames,
    required this.primaryGuestName,
    required this.partnerName,
    required this.lastName,
    required this.villaNumber,
    required this.villaTitle,
    required this.suiteName,
    required this.celebrationTitle,
    required this.stayDates,
    required this.nights,
    required this.guestsCount,
    required this.villaClimateCelsius,
    required this.weatherSummary,
    required this.privateHostName,
    required this.privateHostRole,
    required this.wifiSsid,
    required this.wifiPassphrase,
    required this.folioCardLabel,
    required this.selectedSignaturePrivilege,
    required this.isDigitalKeyEnabled,
    required this.lifecycleStatus,
  });

  final String guestUuid, guestNames, primaryGuestName, partnerName, lastName;
  final String villaNumber, villaTitle, suiteName, celebrationTitle, stayDates;
  final int nights, guestsCount, villaClimateCelsius;
  final String weatherSummary, privateHostName, privateHostRole;
  final String wifiSsid,
      wifiPassphrase,
      folioCardLabel,
      selectedSignaturePrivilege;
  final bool isDigitalKeyEnabled;
  final StayLifecycleStatus lifecycleStatus;

  DateTime get checkInDateTime =>
      parseStayDateBounds(stayDates, fallbackNights: nights).$1;

  DateTime get checkOutDateTime =>
      parseStayDateBounds(stayDates, fallbackNights: nights).$2;

  String get defaultStayDateLabel => formatShortDate(checkInDateTime);

  bool isDateWithinStay(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    final start = checkInDateTime;
    final end = checkOutDateTime;
    return !target.isBefore(start) && !target.isAfter(end);
  }

  static String formatShortDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  static int? computeNightsFromLabel(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final parsed = _tryParseDateRange(raw);
    if (parsed == null) return null;
    final diff = parsed.$2.difference(parsed.$1).inDays;
    return diff > 0 ? diff : null;
  }

  static (DateTime, DateTime) parseStayDateBounds(
    String raw, {
    int fallbackNights = 4,
  }) {
    final parsed = _tryParseDateRange(raw);
    if (parsed != null && parsed.$2.difference(parsed.$1).inDays > 0) {
      return parsed;
    }
    final start = parsed?.$1 ?? DateTime(2026, 11, 12);
    final safeNights = fallbackNights > 0 ? fallbackNights : 3;
    return (start, start.add(Duration(days: safeNights)));
  }

  static (DateTime, DateTime)? _tryParseDateRange(String raw) {
    final isoMatch =
        RegExp(r'(\d{4}-\d{2}-\d{2})\D+(\d{4}-\d{2}-\d{2})').firstMatch(raw);
    if (isoMatch != null) {
      final d1 = DateTime.tryParse(isoMatch.group(1)!);
      final d2 = DateTime.tryParse(isoMatch.group(2)!);
      if (d1 != null && d2 != null) {
        return (
          DateTime(d1.year, d1.month, d1.day),
          DateTime(d2.year, d2.month, d2.day),
        );
      }
    }
    final yearMatch = RegExp(r'\b(20\d{2})\b').firstMatch(raw);
    final defaultYear = int.tryParse(yearMatch?.group(1) ?? '') ?? 2026;
    final parts = raw.split(
      RegExp(r'\s*[–—]\s*|\s+-\s+|\s+to\s+|(?<=\d)-(?=\d)'),
    );
    if (parts.length < 2) return null;
    final inDate = _parseSingleMonthDay(parts[0], defaultYear: defaultYear);
    if (inDate == null) return null;
    final outDate = _parseSingleMonthDay(
      parts[1],
      defaultYear: inDate.year,
      fallbackMonth: inDate.month,
    );
    if (outDate == null) return null;
    return (inDate, outDate);
  }

  static DateTime? _parseSingleMonthDay(
    String rawPart, {
    required int defaultYear,
    int? fallbackMonth,
  }) {
    final trimmed = rawPart.trim();
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);
    const monthTokens = <String, int>{
      'jan': 1,
      'ene': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'abr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'ago': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
      'dic': 12,
    };
    final lower = trimmed.toLowerCase();
    int? month;
    for (final entry in monthTokens.entries) {
      if (lower.contains(entry.key)) {
        month = entry.value;
        break;
      }
    }
    month ??= fallbackMonth;
    if (month == null) return null;
    final yearMatch = RegExp(r'\b(20\d{2})\b').firstMatch(trimmed);
    final year = int.tryParse(yearMatch?.group(1) ?? '') ?? defaultYear;
    final withoutYear = trimmed.replaceAll(RegExp(r'\b20\d{2}\b'), '');
    final dayMatch = RegExp(r'\b([0-3]?\d)\b').firstMatch(withoutYear);
    final day = int.tryParse(dayMatch?.group(1) ?? '');
    if (day == null || day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }

  StaySummary copyWith({
    String? guestNames,
    String? primaryGuestName,
    String? lastName,
    String? villaNumber,
    String? villaTitle,
    String? suiteName,
    String? celebrationTitle,
    String? stayDates,
    int? nights,
    String? privateHostName,
    String? privateHostRole,
    String? wifiSsid,
    String? wifiPassphrase,
    String? selectedSignaturePrivilege,
    bool? isDigitalKeyEnabled,
    StayLifecycleStatus? lifecycleStatus,
    int? villaClimateCelsius,
  }) =>
      StaySummary(
        guestUuid: guestUuid,
        guestNames: guestNames ?? this.guestNames,
        primaryGuestName: primaryGuestName ?? this.primaryGuestName,
        partnerName: partnerName,
        lastName: lastName ?? this.lastName,
        villaNumber: villaNumber ?? this.villaNumber,
        villaTitle: villaTitle ?? this.villaTitle,
        suiteName: suiteName ?? this.suiteName,
        celebrationTitle: celebrationTitle ?? this.celebrationTitle,
        stayDates: stayDates ?? this.stayDates,
        nights: nights ?? this.nights,
        guestsCount: guestsCount,
        villaClimateCelsius: villaClimateCelsius ?? this.villaClimateCelsius,
        weatherSummary: weatherSummary,
        privateHostName: privateHostName ?? this.privateHostName,
        privateHostRole: privateHostRole ?? this.privateHostRole,
        wifiSsid: wifiSsid ?? this.wifiSsid,
        wifiPassphrase: wifiPassphrase ?? this.wifiPassphrase,
        folioCardLabel: folioCardLabel,
        selectedSignaturePrivilege:
            selectedSignaturePrivilege ?? this.selectedSignaturePrivilege,
        isDigitalKeyEnabled: isDigitalKeyEnabled ?? this.isDigitalKeyEnabled,
        lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
      );
}
