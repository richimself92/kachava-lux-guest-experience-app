import 'package:flutter/material.dart';
import '../../application/admin_dashboard_controller.dart';
import '../../application/inspector_selection.dart';
import '../../core/admin_i18n.dart';
import '../../core/admin_theme.dart';
import '../../core/responsive_breakpoints.dart';
import '../../domain/admin_enums.dart';
import 'drawer_staff_dropdown.dart';

/// Right 420px Slide-Over Inspector & Status Update Drawer (or mobile bottom sheet).
class SlideOverInspectorDrawer extends StatefulWidget {
  const SlideOverInspectorDrawer({
    super.key,
    required this.controller,
    required this.selection,
  });

  final AdminDashboardController controller;
  final AdminDrawerSelection selection;

  @override
  State<SlideOverInspectorDrawer> createState() =>
      _SlideOverInspectorDrawerState();
}

class _SlideOverInspectorDrawerState extends State<SlideOverInspectorDrawer> {
  String? _selectedStaffId;
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _syncDefaults();
  }

  @override
  void didUpdateWidget(covariant SlideOverInspectorDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selection.recordId != widget.selection.recordId) {
      _syncDefaults();
    }
  }

  void _syncDefaults() {
    final sel = widget.selection;
    _selectedStaffId =
        DrawerStaffDropdown.assignedStaffId(widget.controller, sel);
    _selectedStatus = switch (sel.type) {
      InspectorRecordType.booking => _bookingStatusDefault(sel.recordId),
      InspectorRecordType.larder => 'Stocked in Villa',
      InspectorRecordType.stay => 'En Route',
      InspectorRecordType.alert ||
      InspectorRecordType.concierge =>
        'In Progress',
    };
  }

  String _bookingStatusDefault(String bookingId) {
    final status = widget.controller.bookings
        .where((b) => b.bookingId == bookingId)
        .firstOrNull
        ?.status;
    return (status == null || status == 'Requested') ? 'Confirmed' : status;
  }

  List<String> _statusOptionsForType(InspectorRecordType type) {
    switch (type) {
      case InspectorRecordType.booking:
        return const ['Requested', 'Confirmed', 'Completed'];
      case InspectorRecordType.larder:
        return const ['Pending', 'Assigned', 'Stocked in Villa'];
      case InspectorRecordType.stay:
        return const ['Scheduled', 'En Route', 'At Terminal Bay', 'Completed'];
      case InspectorRecordType.concierge:
      case InspectorRecordType.alert:
        return const ['Requested', 'Assigned', 'In Progress', 'Completed'];
    }
  }

  Future<void> _submitAssignment() async {
    final sel = widget.selection;
    final ctrl = widget.controller;
    switch (sel.type) {
      case InspectorRecordType.booking:
        await ctrl.assignAndNotifyBooking(
          bookingId: sel.recordId,
          staffId: _selectedStaffId,
          status: _selectedStatus,
        );
        break;
      case InspectorRecordType.larder:
        await ctrl.updateLarderOrderStatus(
          orderId: sel.recordId,
          status: _selectedStatus,
          staffId: _selectedStaffId ?? '',
        );
        break;
      case InspectorRecordType.stay:
        await ctrl.updateTransferDispatch(
          stayId: sel.recordId,
          chauffeurId: _selectedStaffId ?? '',
          transferStatus: _selectedStatus,
        );
        break;
      case InspectorRecordType.concierge:
        final stage = ConciergeStage.values.firstWhere(
          (s) => s.label == _selectedStatus,
          orElse: () => ConciergeStage.assigned,
        );
        await ctrl.advanceConciergeTicketStage(
          requestId: sel.recordId,
          targetStage: stage,
          staffId: _selectedStaffId,
        );
        break;
      case InspectorRecordType.alert:
        await _handleAlertDispatch(ctrl, sel.recordId);
        break;
    }
    ctrl.closeInspector();
  }

  Future<void> _handleAlertDispatch(
    AdminDashboardController ctrl,
    String alertId,
  ) async {
    final matching = ctrl.alerts.where((a) => a.alertId == alertId);
    if (matching.isNotEmpty) {
      final alert = matching.first;
      if (alert.targetTab == AdminWorkspaceTab.adminConcierge) {
        final stage = ConciergeStage.values.firstWhere(
          (s) => s.label == _selectedStatus,
          orElse: () => ConciergeStage.inProgress,
        );
        await ctrl.advanceConciergeTicketStage(
          requestId: alert.targetRecordId,
          targetStage: stage,
          staffId: _selectedStaffId,
        );
      }
    }
    await ctrl.acknowledgeAlert(alertId);
  }

  @override
  Widget build(BuildContext context) {
    final isEs = widget.controller.isEs;
    final options = _statusOptionsForType(widget.selection.type);
    if (!options.contains(_selectedStatus)) {
      _selectedStatus = options.first;
    }
    return Container(
      key: const Key('slide-over-inspector-drawer'),
      width: AdminBreakpoints.inspectorDrawerWidth,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: KachavaAdminColors.surfacePaper,
        border: Border(
          left: BorderSide(color: KachavaAdminColors.borderLimestone),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDrawerHeader(isEs),
          const SizedBox(height: 16),
          Text(
            AdminI18n.translateText(widget.selection.title, isEs),
            style: const TextStyle(
              fontFamily: 'Libre Baskerville',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: KachavaAdminColors.obsidian,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.selection.subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: KachavaAdminColors.neutralMuted,
            ),
          ),
          const SizedBox(height: 16),
          KeyedSubtree(
            key: ValueKey('drawer-staff-${widget.selection.recordId}'),
            child: DrawerStaffDropdown(
              staff: widget.controller.staffDirectory,
              value: _selectedStaffId,
              isEs: isEs,
              onChanged: (id) => setState(() => _selectedStaffId = id),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AdminI18n.tr(isEs, 'OPERATIONAL STATUS', 'ESTADO OPERATIVO'),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: KachavaAdminColors.mutedBronze,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            key: const Key('drawer-status-dropdown'),
            isExpanded: true,
            initialValue: _selectedStatus,
            items: options
                .map(
                  (status) => DropdownMenuItem<String>(
                    value: status,
                    child: Text(
                      AdminI18n.statusLabel(status, isEs),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedStatus = val);
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            key: const Key('drawer-assign-notify-btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: KachavaAdminColors.zapotePrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _submitAssignment,
            icon: const Icon(Icons.check_circle_outline, size: 16),
            label: Text(
              AdminI18n.tr(
                isEs,
                'Save & Update Status',
                'Guardar y Actualizar Estado',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(bool isEs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AdminI18n.tr(
            isEs,
            'UPDATE STATUS · HOST ADMIN',
            'CAMBIAR ESTADO · HOST ADMIN',
          ),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
            color: KachavaAdminColors.mutedBronze,
          ),
        ),
        IconButton(
          key: const Key('close-inspector-drawer'),
          tooltip: 'Close inspector drawer',
          onPressed: widget.controller.closeInspector,
          icon: const Icon(Icons.close, size: 18),
        ),
      ],
    );
  }
}
