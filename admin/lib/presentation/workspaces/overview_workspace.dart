import 'package:flutter/material.dart';
import '../../application/admin_dashboard_controller.dart';
import '../../application/inspector_selection.dart';
import '../../core/admin_i18n.dart';
import '../../core/admin_theme.dart';
import '../../domain/admin_entities.dart';
import '../../domain/admin_enums.dart';
import '../widgets/semantic_status_badge.dart';

/// Tab 1: `admin-overview` — Live Operational Alerts, Arrivals & Command Center (FR-14).
class OverviewWorkspace extends StatelessWidget {
  const OverviewWorkspace({super.key, required this.controller});

  final AdminDashboardController controller;

  @override
  Widget build(BuildContext context) {
    final alerts = controller.filteredAlerts;
    final isEs = controller.isEs;
    return ListView(
      key: const Key('workspace-admin-overview'),
      padding: const EdgeInsets.all(20),
      children: [
        AdminSectionHeader(
          eyebrow: AdminI18n.tr(
            isEs,
            'SANCTUARY COMMAND CENTER · FR-14',
            'CENTRO DE MANDO DEL SANTUARIO · FR-14',
          ),
          title: AdminI18n.overviewTitle(isEs),
        ),
        const SizedBox(height: 16),
        _buildKpiRow(isEs),
        const SizedBox(height: 14),
        _buildAlertsExplanationBanner(isEs),
        const SizedBox(height: 14),
        _buildCategoryFilterStrip(isEs),
        const SizedBox(height: 12),
        if (alerts.isEmpty)
          AdminEmptyStateBox(
            message: AdminI18n.tr(
              isEs,
              'No active operational alerts. Live guest actions from the Sanctuary Portal will appear here.',
              'No hay alertas operativas activas. Las acciones en vivo del huésped aparecerán aquí.',
            ),
          )
        else
          ...alerts.map((alert) => _buildAlertCard(alert, isEs)),
      ],
    );
  }

  Widget _buildAlertsExplanationBanner(bool isEs) {
    return Container(
      key: const Key('alerts-explanation-banner'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: KachavaAdminColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KachavaAdminColors.borderWarm),
      ),
      child: Text(
        AdminI18n.tr(
          isEs,
          '🔔 LIVE GUEST ALERTS ONLY: Sound and visual alerts trigger exclusively when a Guest submits a request, booking, flight update, or feedback from their Sanctuary Portal link (never on Host Admin actions).',
          '🔔 SOLO ALERTAS DEL HUÉSPED: Las alertas con sonido se activan únicamente cuando un Huésped envía una solicitud, reserva, vuelo o comentario desde su Link Mágico (nunca por acciones de Host Admin).',
        ),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: KachavaAdminColors.zapotePrimary,
        ),
      ),
    );
  }

  Widget _buildKpiRow(bool isEs) {
    final residencySub = controller.stays.isEmpty
        ? AdminI18n.tr(
            isEs, 'All 8 Villas FREE (🟢)', 'Las 8 Villas LIBRES (🟢)')
        : '${controller.stays.first.villaName} · ${controller.stays.first.guestNames}';
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildKpiCard(
          label: AdminI18n.kpiResidencies(isEs),
          value: '${controller.stays.length}',
          subLabel: residencySub,
        ),
        _buildKpiCard(
          label: AdminI18n.kpiConcierge(isEs),
          value: '${controller.openConciergeCount}',
          subLabel: AdminI18n.tr(
              isEs, '4-Stage Dispatch Active', 'Despacho 4 Etapas Activo'),
        ),
        _buildKpiCard(
          label: AdminI18n.kpiBookings(isEs),
          value: '${controller.pendingBookingsAndLarderCount}',
          subLabel: AdminI18n.tr(isEs, 'Galeon 470 Sky & Villa Stocking',
              'Yate Galeon 470 y Minibar'),
        ),
        _buildKpiCard(
          label: AdminI18n.kpiUrgent(isEs),
          value: '${controller.urgentSlaAlertsCount}',
          subLabel: AdminI18n.tr(isEs, '< 7 Min SLA & Allergy Caution',
              '< 7 Min SLA y Alerta de Alergias'),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required String subLabel,
  }) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KachavaAdminColors.surfacePaper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KachavaAdminColors.borderLimestone),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: KachavaAdminColors.mutedBronze),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
                fontFamily: 'Libre Baskerville',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: KachavaAdminColors.zapotePrimary),
          ),
          const SizedBox(height: 2),
          Text(
            subLabel,
            style: const TextStyle(
                fontSize: 11, color: KachavaAdminColors.neutralMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterStrip(bool isEs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(
                  AdminI18n.tr(isEs, 'ALL CATEGORIES', 'TODAS LAS CATEGORÍAS')),
              selected: controller.alertCategoryFilter == null,
              onSelected: (_) => controller.setAlertCategoryFilter(null),
            ),
          ),
          ...AlertCategory.values.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                key: Key('alert-cat-${cat.label}'),
                label: Text(AdminI18n.statusLabel(cat.label, isEs)),
                selected: controller.alertCategoryFilter == cat,
                onSelected: (_) => controller.setAlertCategoryFilter(cat),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(OperationalAlert alert, bool isEs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KachavaAdminColors.surfacePaper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alert.severity == AlertSeverity.urgent && !alert.isAcknowledged
              ? const Color(0xFFBA1A1A)
              : KachavaAdminColors.borderLimestone,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAlertBadgeHeader(alert, isEs),
          const SizedBox(height: 8),
          Text(
            AdminI18n.translateText(alert.title, isEs),
            style: const TextStyle(
                fontFamily: 'Libre Baskerville',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: KachavaAdminColors.obsidian),
          ),
          const SizedBox(height: 4),
          Text(
            AdminI18n.translateText(alert.summary, isEs),
            style: const TextStyle(
                fontSize: 12, color: KachavaAdminColors.neutralMuted),
          ),
          const SizedBox(height: 12),
          _buildAlertActionsRow(alert, isEs),
        ],
      ),
    );
  }

  Widget _buildAlertBadgeHeader(OperationalAlert alert, bool isEs) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SemanticStatusBadge(label: alert.severity.label),
        SemanticStatusBadge(label: alert.category.label),
        if (alert.isAcknowledged)
          SemanticStatusBadge(
            label: AdminI18n.tr(
                isEs, 'ATTENDED BY HOST ADMIN', 'ATENDIDA POR HOST ADMIN'),
            customStyle: KachavaAdminColors.stage4Completed,
          ),
        Text(
          '${alert.villaName} · ${alert.guestNames}',
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: KachavaAdminColors.zapotePrimary),
        ),
        Text(
          alert.createdAtLabel,
          style: const TextStyle(
              fontSize: 11, color: KachavaAdminColors.neutralMuted),
        ),
      ],
    );
  }

  Widget _buildAlertActionsRow(OperationalAlert alert, bool isEs) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (!alert.isAcknowledged)
          OutlinedButton(
            key: Key('acknowledge-alert-${alert.alertId}'),
            onPressed: () => controller.acknowledgeAlert(alert.alertId),
            child: Text(AdminI18n.tr(isEs, 'Acknowledge', 'Confirmar')),
          )
        else
          const SemanticStatusBadge(label: 'CONFIRMED · ACKNOWLEDGED'),
        OutlinedButton.icon(
          key: Key('goto-alert-section-${alert.alertId}'),
          onPressed: () => controller.selectTab(alert.targetTab),
          icon: const Icon(Icons.arrow_forward, size: 14),
          label: Text(AdminI18n.tr(isEs, 'Go to Section →', 'Ir a Atender →')),
        ),
        ElevatedButton(
          key: Key('inspect-alert-${alert.alertId}'),
          style: ElevatedButton.styleFrom(
              backgroundColor: KachavaAdminColors.zapotePrimary,
              foregroundColor: Colors.white),
          onPressed: () => controller.openInspector(
            AdminDrawerSelection(
              type: InspectorRecordType.alert,
              recordId: alert.alertId,
              title: alert.title,
              subtitle: '${alert.villaName} · ${alert.guestNames}',
            ),
          ),
          child: Text(AdminI18n.tr(isEs, 'Inspect & Assign', 'Cambiar Estado')),
        ),
      ],
    );
  }
}
