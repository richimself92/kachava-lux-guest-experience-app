import 'package:flutter/material.dart';
import '../../application/admin_dashboard_controller.dart';
import '../../core/admin_i18n.dart';
import '../../core/admin_theme.dart';
import '../../domain/admin_stay_entities.dart';

export 'stays_dialogs.dart';

/// Opens the Host-Only Check-Out Confirmation Dialog displaying the full Stay Summary.
Future<void> showConfirmCheckoutDialog(
  BuildContext context,
  AdminDashboardController controller,
  AdminStayRecord stay,
) =>
    showDialog<void>(
      context: context,
      builder: (_) =>
          _ConfirmCheckoutDialog(controller: controller, stay: stay),
    );

class _ConfirmCheckoutDialog extends StatelessWidget {
  const _ConfirmCheckoutDialog({
    required this.controller,
    required this.stay,
  });

  final AdminDashboardController controller;
  final AdminStayRecord stay;

  @override
  Widget build(BuildContext context) {
    final isEs = controller.isEs;
    return AlertDialog(
      backgroundColor: KachavaAdminColors.surfacePaper,
      title: Text(
        AdminI18n.tr(
          isEs,
          'Confirm Check-Out & Release ${stay.villaName}?',
          '¿Estás seguro de realizar el Check-Out y liberar ${stay.villaName}?',
        ),
        style: const TextStyle(
          fontFamily: 'Libre Baskerville',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: KachavaAdminColors.obsidian,
        ),
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: _buildStaySummaryBody(isEs),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AdminI18n.tr(isEs, 'Cancel', 'Cancelar')),
        ),
        ElevatedButton(
          key: Key('confirm-release-villa-${stay.stayId}'),
          style: ElevatedButton.styleFrom(
            backgroundColor: KachavaAdminColors.zapotePrimary,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            await controller.checkOutAndReleaseVilla(stay.stayId);
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Text(
            AdminI18n.tr(
              isEs,
              'Confirm Check-Out & Release Villa',
              'Confirmar Check-Out y Liberar Villa',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaySummaryBody(bool isEs) {
    final orders =
        controller.larderOrders.where((o) => o.stayId == stay.stayId).toList();
    final bookings =
        controller.bookings.where((b) => b.stayId == stay.stayId).toList();
    final pulses =
        controller.midStayPulses.where((p) => p.stayId == stay.stayId).toList();
    final larderLines = <String>[
      for (final order in orders)
        for (final item in order.items)
          '${item.quantity}x ${item.name} (${AdminI18n.statusLabel(order.status, isEs)})',
    ];
    final bookingLines = <String>[
      for (final b in bookings)
        '• ${b.title} (${b.scheduledTime}) — ${AdminI18n.statusLabel(b.status, isEs)}',
    ];
    final pulseLines = <String>[
      for (final pulse in pulses)
        '⭐ ${pulse.rating}/5 · "${pulse.sentiment}" — ${pulse.guestNote}',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KachavaAdminColors.canvasLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KachavaAdminColors.borderWarm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AdminI18n.tr(
              isEs,
              'Stay Summary',
              'Resumen de la Estancia',
            ),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: KachavaAdminColors.zapotePrimary,
            ),
          ),
          const SizedBox(height: 10),
          _summarySection(
            AdminI18n.tr(isEs, 'Guest & Stay', 'Huésped y Estancia'),
            [
              '${stay.guestNames} · ${stay.checkInDate} – ${stay.checkOutDate} (${stay.nights} ${AdminI18n.tr(isEs, "nights", "noches")})'
            ],
          ),
          const SizedBox(height: 8),
          _summarySection(
            AdminI18n.tr(
              isEs,
              'Minibar & Pantry Ordered',
              'Minibar y Despensa Solicitados',
            ),
            larderLines.isEmpty
                ? [
                    AdminI18n.tr(
                      isEs,
                      'No minibar orders',
                      'Sin pedidos de minibar',
                    ),
                  ]
                : larderLines,
          ),
          const SizedBox(height: 8),
          _summarySection(
            AdminI18n.tr(
              isEs,
              'Experiences, Yacht & Private Dining',
              'Experiencias, Yate y Cena Privada',
            ),
            bookingLines.isEmpty
                ? [
                    AdminI18n.tr(
                      isEs,
                      'No bookings registered',
                      'Sin reservas registradas',
                    ),
                  ]
                : bookingLines,
          ),
          const SizedBox(height: 8),
          _summarySection(
            AdminI18n.tr(
              isEs,
              'Stay Rating & Feedback Survey',
              'Calificación / Encuesta de Estancia',
            ),
            pulseLines.isEmpty
                ? [
                    AdminI18n.tr(
                      isEs,
                      'No survey submitted',
                      'Sin encuesta enviada',
                    ),
                  ]
                : pulseLines,
          ),
        ],
      ),
    );
  }

  Widget _summarySection(String title, List<String> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: KachavaAdminColors.mutedBronze,
          ),
        ),
        const SizedBox(height: 2),
        ...lines.map(
          (line) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              line,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: KachavaAdminColors.obsidian,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
