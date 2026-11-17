import '../domain/staff_member.dart';

/// Maps staff payloads from `GET /admin/staff` and `POST /admin/auth/login`.
///
/// Entries without a `staffId` are dropped: no identity is ever invented.
class AdminStaffMapper {
  const AdminStaffMapper._();

  /// `{ data: [...] }`, a bare list, or `{ staff: [...] }`.
  static List<StaffMember> parseDirectory(Object? raw) {
    final data = raw is Map ? (raw['data'] ?? raw['staff']) : raw;
    if (data is! List) return const [];
    return data.map(tryMap).whereType<StaffMember>().toList();
  }

  static StaffMember? tryMap(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final id = _text(m['staffId']);
    if (id.isEmpty) return null;
    final fullName = _text(m['fullName']);
    return StaffMember(
      staffId: id,
      fullName: fullName,
      shortName:
          _text(m['shortName']).isEmpty ? fullName : _text(m['shortName']),
      role: _text(m['role']),
      department: _department(_text(m['department'])),
      rbacRole: _role(_text(m['rbacRole'])),
      email: _text(m['email']),
      phone: _text(m['phone']),
      isActive: m['isActive'] != false,
    );
  }

  static String _text(Object? v) => v?.toString().trim() ?? '';

  static StaffDepartment _department(String value) => StaffDepartment.values
      .firstWhere((d) => d.apiValue == value.toUpperCase(),
          orElse: () => StaffDepartment.concierge);

  static StaffRole _role(String value) =>
      StaffRole.values.firstWhere((r) => r.apiValue == value.toUpperCase(),
          orElse: () => StaffRole.departmentCoordinator);
}
