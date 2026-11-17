import 'package:flutter/material.dart';

import '../../application/list_query_store.dart';
import '../../application/paged_list_controller.dart';
import '../../core/staff_strings.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../domain/list_query.dart';
import '../../domain/staff_member.dart';
import '../components/components.dart';
import 'staff_detail_panel.dart';

/// Settings › Staff: the roster (name, role, department, email, phone,
/// active) with create, edit and deactivate in the side panel. Every change
/// reloads the owner pickers through [onChanged].
class StaffTab extends StatefulWidget {
  const StaffTab({
    super.key,
    required this.repository,
    required this.onChanged,
    required this.isEs,
    this.queries,
  });

  static const String storeKey = 'staff';
  static const ListQuery initialQuery = ListQuery(sort: ListSort('fullName'));

  final StaffRosterRepository repository;

  /// Runs after any server-confirmed change (e.g. reload the pickers).
  final VoidCallback onChanged;
  final ListQueryStore? queries;
  final bool isEs;

  @override
  State<StaffTab> createState() => _StaffTabState();
}

class _StaffTabState extends State<StaffTab> {
  late final PagedListController<StaffMember> _list = PagedListController(
    fetch: widget.repository.page,
    initialQuery: StaffTab.initialQuery,
    store: widget.queries,
    storeKey: widget.queries == null ? null : StaffTab.storeKey,
  );

  StaffStrings get _s => StaffStrings(widget.isEs);

  @override
  void dispose() {
    _list.dispose();
    super.dispose();
  }

  void _afterChange() {
    _list.load();
    widget.onChanged();
  }

  Widget _activeChip(StaffMember m) => m.isActive
      ? StatusChip(label: _s.active, tone: StatusTone.success)
      : StatusChip(label: _s.inactive, tone: StatusTone.neutral);

  String _dash(String value) => value.isEmpty ? '—' : value;

  @override
  Widget build(BuildContext context) {
    return AdminListScreen<StaffMember>(
      entity: 'staff',
      title: _s.staff,
      info: _s.staffInfo,
      controller: _list,
      columns: [
        AdminTableColumn(
            label: _s.name,
            text: (m) => m.fullName,
            sortField: 'fullName',
            flex: 3),
        AdminTableColumn(
            label: _s.role,
            text: (m) => _s.roleLabel(m.rbacRole),
            sortField: 'rbacRole'),
        AdminTableColumn(
            label: _s.department,
            text: (m) => _s.departmentLabel(m.department),
            sortField: 'department'),
        AdminTableColumn(
            label: _s.email,
            text: (m) => _dash(m.email),
            sortField: 'email',
            flex: 3),
        AdminTableColumn(label: _s.phone, text: (m) => _dash(m.phone)),
        AdminTableColumn(label: _s.active, cell: _activeChip, flex: 1),
      ],
      rowId: (m) => m.staffId,
      compactTitle: (m) => m.fullName,
      compactSubtitle: (m) =>
          '${_s.roleLabel(m.rbacRole)} · ${_s.departmentLabel(m.department)}',
      compactTrailing: _activeChip,
      filters: _filters(),
      emptyMessage: _s.noStaff,
      primaryActionLabel: _s.newStaff,
      detailBuilder: (context, member, close) => StaffDetailPanel(
        member: member,
        repository: widget.repository,
        onClose: close,
        onChanged: _afterChange,
        isEs: widget.isEs,
      ),
      isEs: widget.isEs,
    );
  }

  List<AdminListFilter> _filters() => [
        AdminListFilter(key: 'isActive', label: _s.active, options: [
          AdminFilterOption('true', _s.yes),
          AdminFilterOption('false', _s.no),
        ]),
        AdminListFilter(key: 'rbacRole', label: _s.role, options: [
          for (final r in StaffRole.values)
            AdminFilterOption(r.apiValue, _s.roleLabel(r)),
        ]),
        AdminListFilter(key: 'department', label: _s.department, options: [
          for (final d in StaffDepartment.values)
            AdminFilterOption(d.apiValue, _s.departmentLabel(d)),
        ]),
      ];
}
