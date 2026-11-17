import 'list_query.dart';
import 'paged_result.dart';

/// Role-Based Access Control (RBAC) roles enforced by AdminAuthGuard & RolesGuard.
enum StaffRole {
  hostAdmin('HOST_ADMIN'),
  conciergeStaff('CONCIERGE_STAFF'),
  departmentCoordinator('DEPARTMENT_COORDINATOR');

  const StaffRole(this.apiValue);
  final String apiValue;
}

/// Operational departments.
enum StaffDepartment {
  concierge('CONCIERGE'),
  culinary('CULINARY'),
  marine('MARINE'),
  transport('TRANSPORT'),
  housekeeping('HOUSEKEEPING'),
  engineering('ENGINEERING'),
  wellness('WELLNESS');

  const StaffDepartment(this.apiValue);
  final String apiValue;
}

/// Staff member record from `staff_members/{staffId}` (`GET /admin/staff`).
class StaffMember {
  const StaffMember({
    required this.staffId,
    required this.fullName,
    required this.shortName,
    required this.role,
    required this.department,
    required this.rbacRole,
    required this.email,
    required this.phone,
    this.isActive = true,
  });

  final String staffId;
  final String fullName;
  final String shortName;
  final String role;
  final StaffDepartment department;
  final StaffRole rbacRole;
  final String email;
  final String phone;
  final bool isActive;

  /// Editable fields of `POST/PATCH /admin/staff` (`isActive` via PATCH).
  Map<String, dynamic> toWriteJson() => {
        'fullName': fullName,
        'rbacRole': rbacRole.apiValue,
        'department': department.apiValue,
        'email': email,
        'phone': phone,
        'role': role,
      };
}

/// Active staff for the owner pickers (`GET /admin/staff?isActive=true`).
abstract interface class StaffDirectoryRepository {
  Future<List<StaffMember>> list();
}

/// The whole roster, managed in Settings › Staff (`/admin/staff`). Filters
/// `isActive`, `rbacRole`, `department`; sort `fullName`, `department`,
/// `rbacRole`, `email`.
abstract interface class StaffRosterRepository {
  Future<PagedResult<StaffMember>> page(ListQuery query);
  Future<StaffMember> create(StaffMember member);
  Future<StaffMember> update(StaffMember member);

  /// Deactivates (`false`) or reactivates; sends only `isActive`.
  Future<StaffMember> setActive(String staffId, bool isActive);
}

/// Another staff member already uses the email (HTTP 409).
class StaffEmailTakenException implements Exception {
  const StaffEmailTakenException();
}
