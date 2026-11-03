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
}

/// The staff roster (`GET /admin/staff`).
abstract interface class StaffDirectoryRepository {
  Future<List<StaffMember>> list();
}
