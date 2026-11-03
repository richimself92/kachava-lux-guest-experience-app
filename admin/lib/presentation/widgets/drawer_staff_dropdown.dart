import 'package:flutter/material.dart';
import '../../application/admin_dashboard_controller.dart';
import '../../application/inspector_selection.dart';
import '../../core/admin_i18n.dart';
import '../../domain/admin_stay_entities.dart';

/// Staff picker for the inspector drawer.
///
/// Options come only from the server staff roster; nothing is preselected
/// unless the record is already assigned to a known staff member.
class DrawerStaffDropdown extends StatelessWidget {
  const DrawerStaffDropdown({
    super.key,
    required this.staff,
    required this.value,
    required this.isEs,
    required this.onChanged,
  });

  final List<StaffMember> staff;
  final String? value;
  final bool isEs;
  final ValueChanged<String?> onChanged;

  /// Server-assigned staff id for [sel], or `null` when unknown/unassigned.
  static String? assignedStaffId(
      AdminDashboardController c, AdminDrawerSelection sel) {
    final id = switch (sel.type) {
      InspectorRecordType.booking => c.bookings
          .where((b) => b.bookingId == sel.recordId)
          .firstOrNull
          ?.assignedStaffId,
      InspectorRecordType.larder => c.larderOrders
          .where((o) => o.orderId == sel.recordId)
          .firstOrNull
          ?.assignedStaffId,
      InspectorRecordType.stay => c.stays
          .where((s) => s.stayId == sel.recordId)
          .firstOrNull
          ?.transfer
          .assignedChauffeurId,
      InspectorRecordType.concierge => c.conciergeTickets
          .where((t) => t.requestId == sel.recordId)
          .firstOrNull
          ?.assignedStaffId,
      InspectorRecordType.alert => null,
    };
    return c.staffDirectory.any((s) => s.staffId == id) ? id : null;
  }

  @override
  Widget build(BuildContext context) {
    final unassigned = AdminI18n.staffLabel('', isEs);
    return DropdownButtonFormField<String>(
      key: const Key('drawer-staff-dropdown'),
      isExpanded: true,
      initialValue: value,
      hint: Text(unassigned, style: const TextStyle(fontSize: 12)),
      disabledHint: Text(unassigned, style: const TextStyle(fontSize: 12)),
      decoration: InputDecoration(
          labelText: AdminI18n.tr(isEs, 'Assigned to', 'Responsable'),
          border: const OutlineInputBorder()),
      items: [
        for (final s in staff)
          DropdownMenuItem<String>(
            value: s.staffId,
            child: Text(
                AdminI18n.staffLabel(
                    s.fullName.isNotEmpty ? s.fullName : s.shortName, isEs),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12)),
          ),
      ],
      onChanged: staff.isEmpty ? null : onChanged,
    );
  }
}
