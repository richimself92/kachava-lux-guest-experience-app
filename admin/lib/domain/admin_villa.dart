import 'catalog_values.dart';
import 'json_read.dart';

/// A villa created and configured by staff (`/admin/villas`).
class AdminVilla {
  const AdminVilla({
    this.id = '',
    required this.name,
    this.category = '',
    this.capacity,
    this.operationalStatus = '',
    this.housekeepingStatus = '',
    this.maintenanceNote = '',
    this.isActive = true,
    this.currentGuestName,
    this.audit = const AuditInfo(),
  });

  factory AdminVilla.fromJson(Map<String, dynamic> json) => AdminVilla(
        id: JsonRead.requireId(json),
        name: JsonRead.text(json, 'name'),
        category: JsonRead.text(json, 'category'),
        capacity: JsonRead.intOrNull(json, 'capacity'),
        operationalStatus: JsonRead.text(json, 'operationalStatus'),
        housekeepingStatus: JsonRead.text(json, 'housekeepingStatus'),
        maintenanceNote: JsonRead.text(json, 'maintenanceNote'),
        isActive: JsonRead.flag(json, 'isActive', fallback: true),
        currentGuestName: JsonRead.textOrNull(json, 'currentGuestName'),
        audit: AuditInfo.fromJson(json),
      );

  /// Empty until the server assigns it.
  final String id;
  final String name;
  final String category;
  final int? capacity;

  /// `AVAILABLE | OCCUPIED | CLEANING | MAINTENANCE | BLOCKED`.
  final String operationalStatus;

  /// `CLEAN | DIRTY | IN_PROGRESS`.
  final String housekeepingStatus;
  final String maintenanceNote;
  final bool isActive;

  /// Server-derived from the active stay; read-only.
  final String? currentGuestName;
  final AuditInfo audit;

  /// Editable fields only (no id, audit or derived values).
  Map<String, dynamic> toWriteJson() => {
        'name': name,
        'category': category,
        'capacity': capacity,
        'operationalStatus': operationalStatus,
        'housekeepingStatus': housekeepingStatus,
        'maintenanceNote': maintenanceNote,
        'isActive': isActive,
      };
}
