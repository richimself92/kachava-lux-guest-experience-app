import 'package:flutter/material.dart';
import '../../application/admin_dashboard_controller.dart';
import '../../core/admin_i18n.dart';
import '../../core/admin_theme.dart';
import '../../domain/admin_entities.dart';
import '../../domain/admin_stay_entities.dart';
import '../widgets/semantic_status_badge.dart';

/// Tab 6: `admin-folio` — Stay Summary, Acquired Services & Guest Feedback (FR-19).
class FolioWorkspace extends StatelessWidget {
  const FolioWorkspace({super.key, required this.controller});

  final AdminDashboardController controller;

  @override
  Widget build(BuildContext context) {
    final pulses = controller.midStayPulses;
    final stays = controller.stays;
    final isEs = controller.isEs;

    return ListView(
      key: const Key('workspace-admin-folio'),
      padding: const EdgeInsets.all(20),
      children: [
        AdminSectionHeader(
          eyebrow: AdminI18n.tr(
            isEs,
            'STAY SUMMARY & GUEST FEEDBACK · FR-19',
            'RESUMEN DE ESTANCIA Y CALIFICACIÓN · FR-19',
          ),
          title: AdminI18n.folioTitle(isEs),
        ),
        const SizedBox(height: 16),
        _buildFeedbackSection(pulses, isEs),
        const SizedBox(height: 20),
        _buildAcquiredServicesSection(stays, isEs),
      ],
    );
  }

  Widget _buildFeedbackSection(List<AdminMidStayPulse> pulses, bool isEs) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: KachavaAdminColors.surfacePaper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KachavaAdminColors.borderLimestone),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AdminI18n.tr(
              isEs,
              'Guest Stay Rating & Feedback ("How Is Your Stay Going?")',
              'Calificación y Comentarios: "¿Cómo va tu estancia?"',
            ),
            style: const TextStyle(
              fontFamily: 'Libre Baskerville',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: KachavaAdminColors.obsidian,
            ),
          ),
          const SizedBox(height: 12),
          if (pulses.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: KachavaAdminColors.canvasLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: KachavaAdminColors.borderWarm),
              ),
              child: Text(
                AdminI18n.tr(
                  isEs,
                  'No guest stay ratings or comments submitted yet.',
                  'El huésped aún no ha enviado su calificación o comentario en "¿Cómo va tu estancia?".',
                ),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: KachavaAdminColors.obsidian,
                ),
              ),
            )
          else
            ...pulses.map((pulse) => _buildMidStayPulseCard(pulse, isEs)),
        ],
      ),
    );
  }

  Widget _buildMidStayPulseCard(AdminMidStayPulse pulse, bool isEs) {
    final clamped = pulse.rating.clamp(1, 5);
    final stars = '${'★' * clamped}${'☆' * (5 - clamped)} — $clamped/5';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KachavaAdminColors.canvasLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KachavaAdminColors.borderWarm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SemanticStatusBadge(label: pulse.status),
              Text(
                '${pulse.villaName} · ${pulse.guestNames}',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              Text(
                stars,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: KachavaAdminColors.zapotePrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AdminI18n.translateText(pulse.sentiment, isEs),
            style: const TextStyle(
              fontFamily: 'Libre Baskerville',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: KachavaAdminColors.obsidian,
            ),
          ),
          if (pulse.guestNote.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(pulse.guestNote, style: const TextStyle(fontSize: 13)),
          ],
          const SizedBox(height: 10),
          ElevatedButton(
            key: Key('attend-pulse-${pulse.checkInId}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: KachavaAdminColors.zapotePrimary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => controller.attendMidStayPulse(
              checkInId: pulse.checkInId,
              followUpNote: 'Atendido por HOST ADMIN',
            ),
            child: Text(
              AdminI18n.tr(
                isEs,
                'Acknowledge & Mark Attended',
                'Confirmar Atención del Host',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcquiredServicesSection(List<AdminStayRecord> stays, bool isEs) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: KachavaAdminColors.surfacePaper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KachavaAdminColors.borderLimestone),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AdminI18n.tr(
              isEs,
              'Acquired Services & Stay Activity Summary',
              'Resumen de lo Adquirido y Solicitado por Estancia',
            ),
            style: const TextStyle(
              fontFamily: 'Libre Baskerville',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: KachavaAdminColors.obsidian,
            ),
          ),
          const SizedBox(height: 12),
          if (stays.isEmpty)
            AdminEmptyStateBox(
              message: AdminI18n.tr(
                isEs,
                'No active guest folio or mid-stay pulse reviews yet. Create a guest stay first.',
                'No hay estancias ni comentarios activos. Crea primero un huésped.',
              ),
            )
          else
            ...stays.map((stay) => _buildStaySummaryCard(stay, isEs)),
        ],
      ),
    );
  }

  Widget _buildStaySummaryCard(AdminStayRecord stay, bool isEs) {
    final orders =
        controller.larderOrders.where((o) => o.stayId == stay.stayId).toList();
    final bookings =
        controller.bookings.where((b) => b.stayId == stay.stayId).toList();
    final tickets = controller.conciergeTickets
        .where((t) => t.stayId == stay.stayId)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KachavaAdminColors.canvasLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KachavaAdminColors.borderWarm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${stay.villaName} · ${stay.guestNames} (${stay.checkInDate} – ${stay.checkOutDate} · ${stay.nights} ${AdminI18n.tr(isEs, "nights", "noches")})',
                style: const TextStyle(
                  fontFamily: 'Libre Baskerville',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: KachavaAdminColors.obsidian,
                ),
              ),
              SemanticStatusBadge(label: stay.lifecycleStatus.label),
            ],
          ),
          const SizedBox(height: 10),
          _buildSubHeading(
            AdminI18n.tr(isEs, 'Minibar & Pantry', 'Minibar y Despensa'),
          ),
          if (orders.isEmpty)
            Text(
              AdminI18n.tr(isEs, 'No minibar orders', 'Sin pedidos de minibar'),
              style: const TextStyle(
                  fontSize: 12, color: KachavaAdminColors.neutralMuted),
            )
          else
            ...orders.expand((order) => order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('${item.quantity}x ${item.name}',
                            style: const TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w600)),
                        SemanticStatusBadge(label: order.status),
                      ]),
                ))),
          const SizedBox(height: 8),
          _buildSubHeading(
            AdminI18n.tr(
              isEs,
              'Experiences, Yacht & Private Dining',
              'Experiencias, Yate y Cena Privada',
            ),
          ),
          if (bookings.isEmpty)
            Text(
              AdminI18n.tr(
                  isEs, 'No bookings registered', 'Sin reservas registradas'),
              style: const TextStyle(
                  fontSize: 12, color: KachavaAdminColors.neutralMuted),
            )
          else
            ...bookings.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('${b.title} (${b.category}) — ${b.scheduledTime}',
                            style: const TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w600)),
                        SemanticStatusBadge(label: b.status),
                        if (b.status == 'Cancelled' &&
                            b.cancellationReason.isNotEmpty)
                          Text('(${b.cancellationReason})',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF93000A))),
                      ]),
                )),
          const SizedBox(height: 8),
          _buildSubHeading(
            AdminI18n.tr(
                isEs, 'Concierge Requests', 'Solicitudes de Concierge'),
          ),
          if (tickets.isEmpty)
            Text(
              AdminI18n.tr(isEs, 'No requests registered',
                  'Sin solicitudes registradas'),
              style: const TextStyle(
                  fontSize: 12, color: KachavaAdminColors.neutralMuted),
            )
          else
            ...tickets.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                      '${t.title} — ${AdminI18n.statusLabel(t.stage.label, isEs)}',
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600)),
                )),
        ],
      ),
    );
  }

  Widget _buildSubHeading(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: KachavaAdminColors.zapotePrimary,
          ),
        ),
      );
}
