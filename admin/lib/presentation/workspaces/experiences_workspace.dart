import 'package:flutter/material.dart';
import '../../application/admin_dashboard_controller.dart';
import '../../application/inspector_selection.dart';
import '../../core/admin_i18n.dart';
import '../../core/admin_theme.dart';
import '../../domain/admin_entities.dart';
import '../widgets/semantic_status_badge.dart';
import 'catalog_dialogs.dart';

/// Tab 3: `admin-experiences` — Yacht, Private Dining, Excursions & Privileges (FR-16).
class ExperiencesWorkspace extends StatelessWidget {
  const ExperiencesWorkspace({super.key, required this.controller});

  final AdminDashboardController controller;

  static const List<String> _categories = [
    'All',
    'Yacht Charters',
    'Private Dining',
    'Excursions',
    'Included Privileges',
  ];

  @override
  Widget build(BuildContext context) {
    final bookings = controller.filteredBookings;
    final isEs = controller.isEs;
    return ListView(
      key: const Key('workspace-admin-experiences'),
      padding: const EdgeInsets.all(20),
      children: [
        AdminSectionHeader(
          eyebrow: AdminI18n.tr(
            isEs,
            'EXPERIENCES, MARITIME & CULINARY · FR-16',
            'EXPERIENCIAS, YATE Y GASTRONOMÍA · FR-16',
          ),
          title: AdminI18n.experiencesTitle(isEs),
          trailing: ElevatedButton.icon(
            key: const Key('add-catalog-experience-btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: KachavaAdminColors.zapotePrimary,
              foregroundColor: Colors.white,
            ),
            onPressed: () =>
                showAddExperienceCatalogDialog(context, controller),
            icon: const Icon(Icons.add, size: 16),
            label: Text(AdminI18n.tr(isEs, '+ Add Experience to Catalog',
                '+ Nueva Experiencia al Catálogo')),
          ),
        ),
        const SizedBox(height: 12),
        _buildCatalogStrip(isEs),
        const SizedBox(height: 14),
        _buildCategoryTabs(isEs),
        const SizedBox(height: 16),
        if (bookings.isEmpty)
          AdminEmptyStateBox(
            message: AdminI18n.tr(
              isEs,
              'No experience or yacht bookings yet. Guest reservations from the Sanctuary Portal will appear here live.',
              'Aún no hay reservas de experiencias o yate. Las reservas que haga el huésped aparecerán aquí en vivo.',
            ),
          )
        else
          ...bookings
              .map((booking) => _buildBookingCard(context, booking, isEs)),
      ],
    );
  }

  Widget _buildCatalogStrip(bool isEs) {
    final items = controller.experienceCatalog;
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KachavaAdminColors.surfacePaper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KachavaAdminColors.borderLimestone),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AdminI18n.tr(isEs, 'LIVE EXPERIENCES CATALOG (${items.length})',
                'CATÁLOGO DE EXPERIENCIAS EN VIVO (${items.length})'),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: KachavaAdminColors.mutedBronze,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: items
                .map((item) => InputChip(
                      key: Key('catalog-experience-chip-${item.id}'),
                      label: Text('${item.title} (${item.priceText})',
                          style: const TextStyle(fontSize: 11)),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () =>
                          controller.deleteExperienceCatalogItem(item.id),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(bool isEs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              key: Key('exp-cat-$cat'),
              label: Text(AdminI18n.statusLabel(cat, isEs)),
              selected: controller.experienceCategoryFilter == cat,
              onSelected: (_) => controller.setExperienceCategoryFilter(cat),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBookingCard(
      BuildContext context, AdminBookingRecord booking, bool isEs) {
    final isYacht = booking.category == 'Yacht Charters';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KachavaAdminColors.surfacePaper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KachavaAdminColors.borderLimestone),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBookingHeader(booking, isYacht),
          const SizedBox(height: 10),
          Text(
            booking.title,
            style: const TextStyle(
              fontFamily: 'Libre Baskerville',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: KachavaAdminColors.obsidian,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${booking.villaName} · ${booking.guestNames} · ${booking.scheduledTime}',
            style: const TextStyle(
                fontSize: 12, color: KachavaAdminColors.neutralMuted),
          ),
          if (booking.allergyWarning != null) ...[
            const SizedBox(height: 8),
            SemanticStatusBadge(
              label: booking.allergyWarning!,
              customStyle: KachavaAdminColors.criticalAllergySla,
            ),
          ],
          if (booking.status == 'Cancelled' &&
              booking.cancellationReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDAD6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBA1A1A)),
              ),
              child: Text(
                '❌ ${AdminI18n.tr(isEs, "Cancellation reason", "Motivo de cancelación")}: ${booking.cancellationReason}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF93000A),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildBookingActions(context, booking, isEs),
        ],
      ),
    );
  }

  Widget _buildBookingHeader(AdminBookingRecord booking, bool isYacht) {
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SemanticStatusBadge(
                label: booking.category,
                customStyle:
                    isYacht ? KachavaAdminColors.maritimeCharter : null,
              ),
              SemanticStatusBadge(label: booking.status),
            ],
          ),
          Text(
            '\$${booking.priceUsd.toStringAsFixed(2)} USD',
            style: const TextStyle(
              fontFamily: 'Libre Baskerville',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: KachavaAdminColors.zapotePrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingActions(
      BuildContext context, AdminBookingRecord booking, bool isEs) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '${AdminI18n.tr(isEs, "Assigned", "Asignado")}: ${booking.assignedStaffName}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        ElevatedButton.icon(
          key: Key('assign-booking-${booking.bookingId}'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF065F46),
            foregroundColor: Colors.white,
          ),
          onPressed: () => controller.assignAndNotifyBooking(
            bookingId: booking.bookingId,
            staffId: controller.activeStaff.staffId,
            status: 'CONFIRMED',
          ),
          icon: const Icon(Icons.check_circle_outline, size: 15),
          label: Text(
              AdminI18n.tr(isEs, 'Approve / Confirm', 'Aprobar / Confirmar')),
        ),
        OutlinedButton.icon(
          key: Key('cancel-booking-${booking.bookingId}'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF93000A),
            side: const BorderSide(color: Color(0xFFBA1A1A)),
          ),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) =>
                _CancelBookingDialog(controller: controller, booking: booking),
          ),
          icon: const Icon(Icons.cancel_outlined, size: 15),
          label: Text(
              AdminI18n.tr(isEs, 'Cancel with Reason', 'Cancelar con Motivo')),
        ),
        ElevatedButton(
          key: Key('inspect-booking-${booking.bookingId}'),
          style: ElevatedButton.styleFrom(
            backgroundColor: KachavaAdminColors.zapotePrimary,
            foregroundColor: Colors.white,
          ),
          onPressed: () => controller.openInspector(
            AdminDrawerSelection(
              type: InspectorRecordType.booking,
              recordId: booking.bookingId,
              title: booking.title,
              subtitle: '${booking.villaName} · ${booking.scheduledTime}',
            ),
          ),
          child: Text(
              AdminI18n.tr(isEs, 'Inspect & Assign Staff', 'Inspeccionar')),
        ),
      ],
    );
  }
}

class _CancelBookingDialog extends StatefulWidget {
  const _CancelBookingDialog({required this.controller, required this.booking});

  final AdminDashboardController controller;
  final AdminBookingRecord booking;

  @override
  State<_CancelBookingDialog> createState() => _CancelBookingDialogState();
}

class _CancelBookingDialogState extends State<_CancelBookingDialog> {
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reasonCtrl.text.trim();
    await widget.controller.assignAndNotifyBooking(
      bookingId: widget.booking.bookingId,
      staffId: widget.controller.activeStaff.staffId,
      status: 'CANCELLED',
      cancellationReason: reason.isEmpty
          ? AdminI18n.tr(
              widget.controller.isEs,
              'Time slot unavailable',
              'Horario no disponible',
            )
          : reason,
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEs = widget.controller.isEs;
    return AlertDialog(
      backgroundColor: KachavaAdminColors.surfacePaper,
      title: Text(
        AdminI18n.tr(
          isEs,
          'Cancel Booking with Reason',
          'Cancelar Reserva con Motivo',
        ),
        style: const TextStyle(
          fontFamily: 'Libre Baskerville',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: KachavaAdminColors.obsidian,
        ),
      ),
      content: SizedBox(
        width: 420,
        child: TextField(
          key: const Key('cancel-booking-reason-input'),
          controller: _reasonCtrl,
          decoration: InputDecoration(
            labelText: AdminI18n.tr(
              isEs,
              'Cancellation reason',
              'Motivo de cancelación',
            ),
            hintText: AdminI18n.tr(
              isEs,
              'e.g. Offshore weather conditions / Time slot unavailable',
              'Ej. Condiciones climáticas en altamar / Horario no disponible',
            ),
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AdminI18n.tr(isEs, 'Cancel', 'Volver')),
        ),
        ElevatedButton(
          key: const Key('confirm-cancel-booking-btn'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF93000A),
            foregroundColor: Colors.white,
          ),
          onPressed: _submit,
          child: Text(AdminI18n.tr(
              isEs, 'Confirm Cancellation', 'Confirmar Cancelación')),
        ),
      ],
    );
  }
}
