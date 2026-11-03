import 'package:flutter/material.dart';
import '../../application/admin_dashboard_controller.dart';
import '../../core/admin_i18n.dart';
import '../../core/rating_label.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../domain/admin_entities.dart';
import '../../domain/admin_enums.dart';
import '../../domain/admin_stay_entities.dart';
import '../components/components.dart';
import '../widgets/semantic_status_badge.dart' show AdminEmptyStateBox;

/// `admin-folio` — "Stay summary": guest feedback and services per stay.
/// Reached from a stay, so it offers a way back to Reservations.
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
      padding: const EdgeInsets.all(KachavaTokens.space6),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const Key('stay-summary-back-btn'),
            onPressed: () => controller.selectTab(AdminWorkspaceTab.adminStays),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text(AdminI18n.tr(isEs, 'Reservations', 'Reservas')),
          ),
        ),
        const SizedBox(height: KachavaTokens.space2),
        PageHeader(
          title: AdminI18n.tr(isEs, 'Stay summary', 'Resumen de estancia'),
          info: AdminI18n.tr(
            isEs,
            'Guest feedback and everything ordered, booked or requested per stay. No billing.',
            'Comentarios del huésped y todo lo pedido, reservado o solicitado por estancia. Sin cobros.',
          ),
        ),
        const SizedBox(height: KachavaTokens.space6),
        _buildFeedbackSection(context, pulses, isEs),
        const SizedBox(height: KachavaTokens.space8),
        _buildAcquiredServicesSection(context, stays, isEs),
      ],
    );
  }

  Widget _buildFeedbackSection(
      BuildContext context, List<AdminMidStayPulse> pulses, bool isEs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Flexible(
            child: Text(
              AdminI18n.tr(isEs, 'Guest feedback', 'Comentarios del huésped'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          InfoTooltip(AdminI18n.tr(
            isEs,
            'Answers to "How is your stay going?"',
            'Respuestas a "¿Cómo va tu estancia?"',
          )),
        ]),
        const SizedBox(height: KachavaTokens.space2),
        if (pulses.isEmpty)
          AdminEmptyStateBox(
            message: AdminI18n.tr(
                isEs, 'No feedback yet.', 'Aún no hay comentarios.'),
          )
        else
          ...pulses
              .map((pulse) => _buildMidStayPulseCard(context, pulse, isEs)),
      ],
    );
  }

  Widget _buildMidStayPulseCard(
      BuildContext context, AdminMidStayPulse pulse, bool isEs) {
    final theme = Theme.of(context);
    final stars = RatingLabel.stars(pulse.rating);
    return Container(
      margin: const EdgeInsets.only(bottom: KachavaTokens.space3),
      padding: const EdgeInsets.all(KachavaTokens.space4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KachavaTokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: KachavaTokens.space2,
            runSpacing: KachavaTokens.space2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusChip.fromStatus(pulse.status),
              Text(
                '${AdminI18n.orDash(pulse.villaName)} · ${AdminI18n.orDash(pulse.guestNames)}',
                style: theme.textTheme.titleMedium,
              ),
              Text(stars, style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: KachavaTokens.space2),
          Text(
            AdminI18n.translateText(pulse.sentiment, isEs),
            style: theme.textTheme.bodyLarge,
          ),
          if (pulse.guestNote.isNotEmpty) ...[
            const SizedBox(height: KachavaTokens.space1),
            Text(pulse.guestNote,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
          const SizedBox(height: KachavaTokens.space3),
          ElevatedButton(
            key: Key('attend-pulse-${pulse.checkInId}'),
            onPressed: () => controller.attendMidStayPulse(
              checkInId: pulse.checkInId,
              followUpNote: 'Atendido por HOST ADMIN',
            ),
            child: Text(
              AdminI18n.tr(isEs, 'Mark attended', 'Marcar atendido'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcquiredServicesSection(
      BuildContext context, List<AdminStayRecord> stays, bool isEs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AdminI18n.tr(isEs, 'Services by stay', 'Servicios por estancia'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: KachavaTokens.space3),
        if (stays.isEmpty)
          AdminEmptyStateBox(
            message:
                AdminI18n.tr(isEs, 'No stays yet.', 'Aún no hay estancias.'),
          )
        else
          ...stays.map((stay) => _buildStaySummaryCard(context, stay, isEs)),
      ],
    );
  }

  Widget _buildStaySummaryCard(
      BuildContext context, AdminStayRecord stay, bool isEs) {
    final theme = Theme.of(context);
    final itemStyle = theme.textTheme.bodyMedium;
    final emptyStyle = theme.textTheme.bodyMedium
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final orders =
        controller.larderOrders.where((o) => o.stayId == stay.stayId).toList();
    final bookings =
        controller.bookings.where((b) => b.stayId == stay.stayId).toList();
    final tickets = controller.conciergeTickets
        .where((t) => t.stayId == stay.stayId)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: KachavaTokens.space3),
      padding: const EdgeInsets.all(KachavaTokens.space4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KachavaTokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: KachavaTokens.space3,
            runSpacing: KachavaTokens.space2,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${AdminI18n.orDash(stay.villaName)} · ${AdminI18n.orDash(stay.guestNames)} (${AdminI18n.orDash(stay.checkInDate)} – ${AdminI18n.orDash(stay.checkOutDate)} · ${stay.nights} ${AdminI18n.tr(isEs, "nights", "noches")})',
                style: theme.textTheme.titleMedium,
              ),
              StatusChip.fromStatus(stay.lifecycleStatus.label),
            ],
          ),
          const SizedBox(height: KachavaTokens.space3),
          _buildSubHeading(
            context,
            AdminI18n.tr(isEs, 'Minibar & Pantry', 'Minibar y Despensa'),
          ),
          if (orders.isEmpty)
            Text(
              AdminI18n.tr(isEs, 'No minibar orders', 'Sin pedidos de minibar'),
              style: emptyStyle,
            )
          else
            ...orders.expand((order) => order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: KachavaTokens.space1),
                  child: Wrap(
                      spacing: KachavaTokens.space2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('${item.quantity}x ${item.name}',
                            style: itemStyle),
                        StatusChip.fromStatus(order.status),
                      ]),
                ))),
          const SizedBox(height: KachavaTokens.space3),
          _buildSubHeading(
            context,
            AdminI18n.tr(isEs, 'Experiences', 'Experiencias'),
          ),
          if (bookings.isEmpty)
            Text(
              AdminI18n.tr(
                  isEs, 'No bookings registered', 'Sin reservas registradas'),
              style: emptyStyle,
            )
          else
            ...bookings.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: KachavaTokens.space1),
                  child: Wrap(
                      spacing: KachavaTokens.space2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('${b.title} (${b.category}) — ${b.scheduledTime}',
                            style: itemStyle),
                        StatusChip.fromStatus(b.status),
                        if (b.status == 'Cancelled' &&
                            b.cancellationReason.isNotEmpty)
                          Text('(${b.cancellationReason})',
                              style: itemStyle?.copyWith(
                                  color: StatusTone.error.foreground)),
                      ]),
                )),
          const SizedBox(height: KachavaTokens.space3),
          _buildSubHeading(
            context,
            AdminI18n.tr(isEs, 'Tasks', 'Tareas'),
          ),
          if (tickets.isEmpty)
            Text(
              AdminI18n.tr(isEs, 'No requests registered',
                  'Sin solicitudes registradas'),
              style: emptyStyle,
            )
          else
            ...tickets.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: KachavaTokens.space1),
                  child: Text(
                      '${t.title} — ${AdminI18n.statusLabel(t.stage.label, isEs)}',
                      style: itemStyle),
                )),
        ],
      ),
    );
  }

  Widget _buildSubHeading(BuildContext context, String label) => Padding(
        padding: const EdgeInsets.only(bottom: KachavaTokens.space1),
        child: Text(label, style: Theme.of(context).textTheme.titleSmall),
      );
}
