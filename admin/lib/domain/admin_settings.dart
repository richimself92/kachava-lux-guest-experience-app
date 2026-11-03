import 'catalog_values.dart';
import 'json_read.dart';

/// One airport configured in Settings.
class AirportSetting {
  const AirportSetting({
    required this.code,
    required this.name,
    this.departureMarginMinutes,
    this.isActive = true,
  });

  factory AirportSetting.fromJson(Map<String, dynamic> json) => AirportSetting(
        code: JsonRead.text(json, 'code'),
        name: JsonRead.text(json, 'name'),
        departureMarginMinutes:
            JsonRead.intOrNull(json, 'departureMarginMinutes'),
        isActive: JsonRead.flag(json, 'isActive', fallback: true),
      );

  /// IATA code, e.g. typed by staff; never hardcoded in the app.
  final String code;
  final String name;

  /// Minutes before the flight a departure pickup must leave the villa.
  final int? departureMarginMinutes;
  final bool isActive;

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'departureMarginMinutes': departureMarginMinutes,
        'isActive': isActive,
      };
}

/// Resort settings (`GET/PATCH /admin/settings`). Every value is optional:
/// an unset value means "not configured" and the UI links to Settings
/// instead of assuming a default.
class AdminSettings {
  const AdminSettings({
    this.checkInTime,
    this.checkOutTime,
    this.timeZone,
    this.airports = const [],
    this.tripAlertLeadMinutes,
    this.audit = const AuditInfo(),
  });

  factory AdminSettings.fromJson(Map<String, dynamic> json) => AdminSettings(
        checkInTime: JsonRead.textOrNull(json, 'checkInTime'),
        checkOutTime: JsonRead.textOrNull(json, 'checkOutTime'),
        timeZone: JsonRead.textOrNull(json, 'timeZone'),
        airports: [
          for (final a in JsonRead.objects(json, 'airports'))
            AirportSetting.fromJson(a)
        ],
        tripAlertLeadMinutes: JsonRead.intOrNull(json, 'tripAlertLeadMinutes'),
        audit: AuditInfo.fromJson(json),
      );

  /// `HH:mm` resort time.
  final String? checkInTime;
  final String? checkOutTime;

  /// IANA zone, e.g. chosen by staff.
  final String? timeZone;
  final List<AirportSetting> airports;

  /// Alert when a trip this close is still unconfirmed.
  final int? tripAlertLeadMinutes;
  final AuditInfo audit;

  bool get isConfigured =>
      checkInTime != null && checkOutTime != null && timeZone != null;

  Map<String, dynamic> toJson() => {
        'checkInTime': checkInTime,
        'checkOutTime': checkOutTime,
        'timeZone': timeZone,
        'airports': [for (final a in airports) a.toJson()],
        'tripAlertLeadMinutes': tripAlertLeadMinutes,
      };
}
