import 'package:flutter/material.dart';
import '../../application/admin_dashboard_controller.dart';
import '../../application/inspector_selection.dart';
import '../../core/admin_i18n.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../domain/admin_entities.dart';
import '../components/components.dart';
import '../widgets/semantic_status_badge.dart' show AdminEmptyStateBox;

/// `admin-experiences` — guest experience bookings. Hidden from the menu
/// until the Phase 4 catalog replaces it.
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
      padding: const EdgeInsets.all(KachavaTokens.space6),
      children: [
        PageHeader(
          title: AdminI18n.tr(isEs, 'Experiences', 'Experiencias'),
          info: AdminI18n.tr(
            isEs,
            'Yacht, private dining, excursions and included privileges booked by guests, updated live.',
            'Yate, cenas privadas, excursiones y privilegios reservados por huéspedes, en vivo.',
          ),
        ),
        const SizedBox(height: KachavaTokens.space4),
        _buildCategoryTabs(isEs),
        const SizedBox(height: KachavaTokens.space4),
        if (bookings.isEmpty)
          AdminEmptyStateBox(
            message:
                AdminI18n.tr(isEs, 'No bookings yet.', 'Aún no hay reservas.'),
          )
        else
          ...bookings
              .map((booking) => _buildBookingCard(context, booking, isEs)),
      ],
    );
  }

  Widget _buildCategoryTabs(bool isEs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          return Padding(
            padding: const EdgeInsets.only(right: KachavaTokens.space2),
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
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: KachavaTokens.space4),
      padding: const EdgeInsets.all(KachavaTokens.space4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KachavaTokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBookingHeader(context, booking, isEs),
          const SizedBox(height: KachavaTokens.space2),
          Text(booking.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: KachavaTokens.space1),
          Text(
            '${AdminI18n.orDash(booking.villaName)} · ${AdminI18n.orDash(booking.guestNames)} · ${AdminI18n.orDash(booking.scheduledTime)}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          if (booking.allergyWarning != null) ...[
            const SizedBox(height: KachavaTokens.space2),
            StatusChip(label: booking.allergyWarning!, tone: StatusTone.error),
          ],
          if (booking.status == 'Cancelled' &&
              booking.cancellationReason.isNotEmpty) ...[
            const SizedBox(height: KachavaTokens.space2),
            Text(
              '❌ ${AdminI18n.tr(isEs, "Cancellation reason", "Motivo de cancelación")}: ${booking.cancellationReason}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: StatusTone.error.foreground),
            ),
          ],
          const SizedBox(height: KachavaTokens.space3),
          _buildBookingActions(context, booking, isEs),
        ],
      ),
    );
  }

  Widget _buildBookingHeader(
      BuildContext context, AdminBookingRecord booking, bool isEs) {
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        spacing: KachavaTokens.space2,
        runSpacing: KachavaTokens.space2,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Wrap(
            spacing: KachavaTokens.space2,
            runSpacing: KachavaTokens.space2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusChip(
                label: AdminI18n.statusLabel(booking.category, isEs),
                tone: StatusTone.neutral,
              ),
              StatusChip.fromStatus(booking.status),
            ],
          ),
          Text(
            '\$${booking.priceUsd.toStringAsFixed(2)} USD',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingActions(
      BuildContext context, AdminBookingRecord booking, bool isEs) {
    final error = Theme.of(context).colorScheme.error;
    return Wrap(
      spacing: KachavaTokens.space2,
      runSpacing: KachavaTokens.space2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '${AdminI18n.tr(isEs, "Assigned", "Asignado")}: ${AdminI18n.staffLabel(booking.assignedStaffName, isEs)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        ElevatedButton.icon(
          key: Key('assign-booking-${booking.bookingId}'),
          onPressed: () => controller.assignAndNotifyBooking(
            bookingId: booking.bookingId,
            status: 'CONFIRMED',
          ),
          icon: const Icon(Icons.check, size: 18),
          label: Text(
              AdminI18n.tr(isEs, 'Approve / Confirm', 'Aprobar / Confirmar')),
        ),
        OutlinedButton.icon(
          key: Key('cancel-booking-${booking.bookingId}'),
          style: OutlinedButton.styleFrom(foregroundColor: error),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) =>
                _CancelBookingDialog(controller: controller, booking: booking),
          ),
          icon: const Icon(Icons.close, size: 18),
          label: Text(
              AdminI18n.tr(isEs, 'Cancel with Reason', 'Cancelar con Motivo')),
        ),
        TextButton(
          key: Key('inspect-booking-${booking.bookingId}'),
          onPressed: () => controller.openInspector(
            AdminDrawerSelection(
              type: InspectorRecordType.booking,
              recordId: booking.bookingId,
              title: booking.title,
              subtitle: '${booking.villaName} · ${booking.scheduledTime}',
            ),
          ),
          child: Text(AdminI18n.tr(isEs, 'Details', 'Detalles')),
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
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(
        AdminI18n.tr(
          isEs,
          'Cancel Booking with Reason',
          'Cancelar Reserva con Motivo',
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
              'Time slot unavailable',
              'Horario no disponible',
            ),
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
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: _submit,
          child: Text(AdminI18n.tr(
              isEs, 'Confirm Cancellation', 'Confirmar Cancelación')),
        ),
      ],
    );
  }
}
