import 'package:flutter/material.dart';
import '../../application/admin_dashboard_controller.dart';
import '../../application/inspector_selection.dart';
import '../../application/resort_settings_controller.dart';
import '../../core/admin_i18n.dart';
import '../../core/resort_strings.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../domain/admin_entities.dart';
import '../../domain/admin_enums.dart';
import '../components/components.dart';

/// Tab 1: `admin-overview` — live operational alerts and headline counts.
class OverviewWorkspace extends StatelessWidget {
  const OverviewWorkspace({
    super.key,
    required this.controller,
    required this.resortSettings,
  });

  final AdminDashboardController controller;

  /// The dashboard date needs the resort time zone from Settings.
  final ResortSettingsController resortSettings;

  @override
  Widget build(BuildContext context) {
    final alerts = controller.filteredAlerts;
    final isEs = controller.isEs;
    return ListView(
      key: const Key('workspace-admin-overview'),
      padding: const EdgeInsets.all(KachavaTokens.space6),
      children: [
        PageHeader(
          title: AdminI18n.tr(isEs, 'Overview', 'Resumen'),
          info: AdminI18n.tr(
            isEs,
            'Alerts appear only when a guest acts from their guest link, never on staff actions.',
            'Las alertas aparecen solo cuando un huésped actúa desde su link, nunca por acciones del personal.',
          ),
        ),
        _buildSettingsLink(isEs),
        const SizedBox(height: KachavaTokens.space4),
        _buildKpiRow(isEs),
        const SizedBox(height: KachavaTokens.space6),
        _buildCategoryFilterStrip(isEs),
        const SizedBox(height: KachavaTokens.space4),
        if (alerts.isEmpty)
          AsyncStateView(
            state: AsyncViewState.empty,
            emptyMessage: AdminI18n.tr(
                isEs, 'No active alerts.', 'No hay alertas activas.'),
            builder: (_) => const SizedBox.shrink(),
          )
        else
          ...alerts.map((alert) => _buildAlertCard(context, alert, isEs)),
      ],
    );
  }

  /// "Time zone not set · Set up in Settings" until it is configured.
  Widget _buildSettingsLink(bool isEs) => ListenableBuilder(
        listenable: resortSettings,
        builder: (context, _) {
          if (!resortSettings.isMissing(ResortSetting.timeZone)) {
            return const SizedBox.shrink();
          }
          final s = ResortStrings(isEs);
          return Padding(
            padding: const EdgeInsets.only(top: KachavaTokens.space2),
            child: SettingsSetupLink(
              key: const Key('overview-time-zone-missing'),
              message: s.timeZoneMissing,
              linkLabel: s.setUpInSettings,
              onOpenSettings: () =>
                  controller.selectTab(AdminWorkspaceTab.adminSettings),
            ),
          );
        },
      );

  Widget _buildKpiRow(bool isEs) {
    return LayoutBuilder(builder: (context, constraints) {
      const gap = KachavaTokens.space4;
      final columns = constraints.maxWidth >= 4 * 200 + 3 * gap ? 4 : 2;
      final width = (constraints.maxWidth - (columns - 1) * gap) / columns;
      Widget tile(String label, int value, String info) => SizedBox(
            width: width,
            child: KpiTile(value: '$value', label: label, info: info),
          );
      return _kpiWrap(isEs, tile);
    });
  }

  Widget _kpiWrap(
      bool isEs, Widget Function(String label, int value, String info) tile) {
    return Wrap(
      spacing: KachavaTokens.space4,
      runSpacing: KachavaTokens.space4,
      children: [
        tile(
          AdminI18n.kpiResidencies(isEs),
          controller.stays.length,
          AdminI18n.tr(isEs, 'Guest stays registered in the Command Center.',
              'Estancias registradas en el Centro de Mando.'),
        ),
        tile(
          AdminI18n.kpiConcierge(isEs),
          controller.openConciergeCount,
          AdminI18n.tr(isEs, 'Resort Host requests not yet completed.',
              'Solicitudes al Resort Host aún sin completar.'),
        ),
        tile(
          AdminI18n.kpiBookings(isEs),
          controller.pendingBookingsAndLarderCount,
          AdminI18n.tr(
              isEs,
              'Requested bookings plus minibar orders not yet stocked.',
              'Reservas solicitadas más pedidos de minibar sin surtir.'),
        ),
        tile(
          AdminI18n.kpiUrgent(isEs),
          controller.urgentSlaAlertsCount,
          AdminI18n.tr(isEs, 'Urgent alerts not yet acknowledged.',
              'Alertas urgentes aún sin confirmar.'),
        ),
      ],
    );
  }

  Widget _buildCategoryFilterStrip(bool isEs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: KachavaTokens.space2),
            child: ChoiceChip(
              label: Text(
                  AdminI18n.tr(isEs, 'All categories', 'Todas las categorías')),
              selected: controller.alertCategoryFilter == null,
              onSelected: (_) => controller.setAlertCategoryFilter(null),
            ),
          ),
          ...AlertCategory.values.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(right: KachavaTokens.space2),
              child: ChoiceChip(
                key: Key('alert-cat-${cat.label}'),
                label: Text(AdminI18n.alertCategoryLabel(cat, isEs)),
                selected: controller.alertCategoryFilter == cat,
                onSelected: (_) => controller.setAlertCategoryFilter(cat),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(
      BuildContext context, OperationalAlert alert, bool isEs) {
    final theme = Theme.of(context);
    final urgent =
        alert.severity == AlertSeverity.urgent && !alert.isAcknowledged;
    return Container(
      margin: const EdgeInsets.only(bottom: KachavaTokens.space3),
      padding: const EdgeInsets.all(KachavaTokens.space4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(KachavaTokens.radiusLg),
        border: Border.all(
          color: urgent
              ? theme.colorScheme.error
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAlertBadgeHeader(theme, alert, isEs),
          const SizedBox(height: KachavaTokens.space2),
          Text(AdminI18n.translateText(alert.title, isEs),
              style: theme.textTheme.titleMedium),
          const SizedBox(height: KachavaTokens.space1),
          Text(
            AdminI18n.translateText(alert.summary, isEs),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: KachavaTokens.space3),
          _buildAlertActionsRow(alert, isEs),
        ],
      ),
    );
  }

  Widget _buildAlertBadgeHeader(
      ThemeData theme, OperationalAlert alert, bool isEs) {
    return Wrap(
      spacing: KachavaTokens.space2,
      runSpacing: KachavaTokens.space2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        StatusChip.fromStatus(alert.severity.label,
            label: AdminI18n.statusLabel(alert.severity.label, isEs)),
        StatusChip.fromStatus(alert.category.label,
            label: AdminI18n.alertCategoryLabel(alert.category, isEs)),
        if (alert.isAcknowledged)
          StatusChip(
            label: AdminI18n.tr(isEs, 'Attended', 'Atendida'),
            tone: StatusTone.success,
          ),
        Text(
          '${AdminI18n.orDash(alert.villaName)} · ${AdminI18n.orDash(alert.guestNames)}',
          style: theme.textTheme.labelLarge,
        ),
        Text(
          alert.createdAtLabel,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildAlertActionsRow(OperationalAlert alert, bool isEs) {
    return Wrap(
      spacing: KachavaTokens.space2,
      runSpacing: KachavaTokens.space2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (!alert.isAcknowledged)
          OutlinedButton(
            key: Key('acknowledge-alert-${alert.alertId}'),
            onPressed: () => controller.acknowledgeAlert(alert.alertId),
            child: Text(AdminI18n.tr(isEs, 'Acknowledge', 'Confirmar')),
          ),
        OutlinedButton.icon(
          key: Key('goto-alert-section-${alert.alertId}'),
          onPressed: () => controller.selectTab(alert.targetTab),
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: Text(AdminI18n.tr(isEs, 'Go to section', 'Ir a la sección')),
        ),
        ElevatedButton(
          key: Key('inspect-alert-${alert.alertId}'),
          onPressed: () => controller.openInspector(
            AdminDrawerSelection(
              type: InspectorRecordType.alert,
              recordId: alert.alertId,
              title: alert.title,
              subtitle:
                  '${AdminI18n.orDash(alert.villaName)} · ${AdminI18n.orDash(alert.guestNames)}',
            ),
          ),
          child: Text(AdminI18n.tr(isEs, 'Inspect & Assign', 'Cambiar Estado')),
        ),
      ],
    );
  }
}
