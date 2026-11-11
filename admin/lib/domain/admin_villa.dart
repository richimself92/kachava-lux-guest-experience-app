import 'catalog_values.dart';
import 'json_read.dart';

/// Wire enums of a villa (`backend/.../resort-config.models.ts`). They are
/// the contract's allowed values, not business data.
abstract final class VillaStatusValues {
  static const List<String> operational = [
    'AVAILABLE',
    'OCCUPIED',
    'CLEANING',
    'MAINTENANCE',
    'BLOCKED',
  ];
  static const List<String> housekeeping = ['CLEAN', 'DIRTY', 'IN_PROGRESS'];
  static const List<String> maintenance = [
    'OK',
    'ISSUE_REPORTED',
    'IN_MAINTENANCE',
  ];

  /// Backend `@Max` of `capacity`.
  static const int maxCapacity = 50;
}

/// A villa created and configured by staff (`/admin/villas`).
class AdminVilla {
  const AdminVilla({
    this.id = '',
    required this.name,
    this.category = '',
    this.capacity,
    this.wifiSsid = '',
    this.wifiPassword = '',
    this.operationalStatus = '',
    this.housekeepingStatus = '',
    this.maintenanceStatus = '',
    this.maintenanceNote = '',
    this.isActive = true,
    this.currentGuestName,
    this.audit = const AuditInfo(),
  });

  factory AdminVilla.fromJson(Map<String, dynamic> json) {
    final wifi = JsonRead.object(json, 'wifi');
    return AdminVilla(
      id: JsonRead.requireId(json),
      name: JsonRead.text(json, 'name'),
      category: JsonRead.text(json, 'category'),
      capacity: JsonRead.intOrNull(json, 'capacity'),
      wifiSsid: JsonRead.text(wifi, 'ssid'),
      wifiPassword: JsonRead.text(wifi, 'password'),
      operationalStatus: JsonRead.text(json, 'operationalStatus'),
      housekeepingStatus: JsonRead.text(json, 'housekeepingStatus'),
      maintenanceStatus: JsonRead.text(json, 'maintenanceStatus'),
      maintenanceNote: JsonRead.text(json, 'maintenanceNote'),
      isActive: JsonRead.flag(json, 'isActive', fallback: true),
      currentGuestName: JsonRead.textOrNull(json, 'currentGuestName'),
      audit: AuditInfo.fromJson(json),
    );
  }

  /// Empty until the server assigns it.
  final String id;
  final String name;
  final String category;

  /// Maximum number of guests (1-50).
  final int? capacity;
  final String wifiSsid;
  final String wifiPassword;

  /// One of [VillaStatusValues.operational].
  final String operationalStatus;

  /// One of [VillaStatusValues.housekeeping].
  final String housekeepingStatus;

  /// One of [VillaStatusValues.maintenance].
  final String maintenanceStatus;
  final String maintenanceNote;
  final bool isActive;

  /// Server-derived from the in-house stay; read-only.
  final String? currentGuestName;
  final AuditInfo audit;

  /// Editable fields only (no id, audit or derived values).
  Map<String, dynamic> toWriteJson() => {
        'name': name,
        'category': category,
        'capacity': capacity,
        'wifi': {'ssid': wifiSsid, 'password': wifiPassword},
        'operationalStatus': operationalStatus,
        'housekeepingStatus': housekeepingStatus,
        'maintenanceStatus': maintenanceStatus,
        'maintenanceNote': maintenanceNote,
        'isActive': isActive,
      };
}
