import 'package:kachava_admin_dashboard/domain/list_query.dart';
import 'package:kachava_admin_dashboard/domain/paged_result.dart';
import 'package:kachava_admin_dashboard/domain/staff_member.dart';

import 'in_memory_paged_source.dart';

/// A generated roster entry (no business data).
StaffMember testMember(int n,
        {bool isActive = true,
        StaffRole role = StaffRole.conciergeStaff,
        StaffDepartment department = StaffDepartment.concierge}) =>
    StaffMember(
      staffId: 'staff_$n',
      fullName: 'Member $n',
      shortName: 'Member',
      role: '',
      department: department,
      rbacRole: role,
      email: 'member$n@test.local',
      phone: '+52 $n',
      isActive: isActive,
    );

/// Test-only `/admin/staff`: list rules of the backend, unique emails (409
/// as [StaffEmailTakenException]) and recorded writes.
class FakeStaffRoster implements StaffRosterRepository {
  FakeStaffRoster([List<StaffMember> staff = const []])
      : staff = List.of(staff);

  final List<StaffMember> staff;
  final List<StaffMember> created = [];
  final List<StaffMember> updated = [];
  final List<(String, bool)> activations = [];
  final List<ListQuery> queries = [];
  int _ids = 100;

  @override
  Future<PagedResult<StaffMember>> page(ListQuery query) async {
    queries.add(query);
    return InMemoryPagedSource<StaffMember>(
      items: staff,
      searchText: (m) => [m.fullName, m.email],
      sortValue: (m, _) => m.fullName,
      filterValue: (m, key) => switch (key) {
        'isActive' => '${m.isActive}',
        'rbacRole' => m.rbacRole.apiValue,
        'department' => m.department.apiValue,
        _ => null,
      },
    ).page(query);
  }

  void _assertEmailFree(StaffMember m) {
    if (staff.any((s) => s.email == m.email && s.staffId != m.staffId)) {
      throw const StaffEmailTakenException();
    }
  }

  @override
  Future<StaffMember> create(StaffMember member) async {
    _assertEmailFree(member);
    final saved = _copy(member, id: 'staff_${_ids++}');
    created.add(member);
    staff.add(saved);
    return saved;
  }

  @override
  Future<StaffMember> update(StaffMember member) async {
    _assertEmailFree(member);
    updated.add(member);
    staff[staff.indexWhere((s) => s.staffId == member.staffId)] = member;
    return member;
  }

  @override
  Future<StaffMember> setActive(String staffId, bool isActive) async {
    activations.add((staffId, isActive));
    final i = staff.indexWhere((s) => s.staffId == staffId);
    return staff[i] = _copy(staff[i], isActive: isActive);
  }

  static StaffMember _copy(StaffMember m, {String? id, bool? isActive}) =>
      StaffMember(
        staffId: id ?? m.staffId,
        fullName: m.fullName,
        shortName: m.shortName,
        role: m.role,
        department: m.department,
        rbacRole: m.rbacRole,
        email: m.email,
        phone: m.phone,
        isActive: isActive ?? m.isActive,
      );
}
