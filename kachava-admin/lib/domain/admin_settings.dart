import 'catalog_values.dart';
import 'json_read.dart';

/// One airport configured in Settings (`airports[]`).
class AirportSetting {
  const AirportSetting({
    required this.code,
    required this.name,
    this.departureBufferHours,
    this.isActive = true,
  });

  factory AirportSetting.fromJson(Map<String, dynamic> json) => AirportSetting(
        code: JsonRead.text(json, 'code'),
        name: JsonRead.text(json, 'name'),
        departureBufferHours:
            JsonRead.doubleOrNull(json, 'departureBufferHours'),
        isActive: JsonRead.flag(json, 'isActive', fallback: true),
      );

  /// 3-letter IATA code typed by staff; never hardcoded in the app.
  final String code;
  final String name;

  /// Hours before the flight a departure pickup leaves the villa (0-24).
  final double? departureBufferHours;
  final bool isActive;

  AirportSetting copyWith({bool? isActive}) => AirportSetting(
        code: code,
        name: name,
        departureBufferHours: departureBufferHours,
        isActive: isActive ?? this.isActive,
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'departureBufferHours': departureBufferHours,
        'isActive': isActive,
      };
}

/// Resort settings (`GET/PATCH /admin/settings`). Every value starts unset
/// (`null`): the UI shows "Not set" and links here instead of assuming a
/// default. Durations are whole or fractional hours.
class AdminSettings {
  const AdminSettings({
    this.checkInTime,
    this.checkOutTime,
    this.timeZone,
    this.airports = const [],
    this.transportAlertLeadHours,
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
        transportAlertLeadHours:
            JsonRead.intOrNull(json, 'transportAlertLeadHours'),
        audit: AuditInfo.fromJson(json),
      );

  /// `HH:mm` resort time.
  final String? checkInTime;
  final String? checkOutTime;

  /// IANA zone chosen by staff.
  final String? timeZone;
  final List<AirportSetting> airports;

  /// Alert when a trip this many hours away is still unconfirmed (1-168).
  final int? transportAlertLeadHours;
  final AuditInfo audit;

  bool get isConfigured =>
      checkInTime != null && checkOutTime != null && timeZone != null;

  /// The full editable state; `null` clears a value on the server.
  Map<String, dynamic> toJson() => {
        'checkInTime': checkInTime,
        'checkOutTime': checkOutTime,
        'timeZone': timeZone,
        'airports': [for (final a in airports) a.toJson()],
        'transportAlertLeadHours': transportAlertLeadHours,
      };
}
