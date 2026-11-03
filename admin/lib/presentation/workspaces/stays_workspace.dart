import 'package:flutter/material.dart';
import '../../application/admin_dashboard_controller.dart';
import '../../application/inspector_selection.dart';
import '../../core/admin_i18n.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../domain/admin_enums.dart';
import '../../domain/admin_stay_entities.dart';
import '../components/components.dart';
import 'stay_dialogs.dart';

/// Tab 2: `admin-stays` — stays, guest links, villas and airport transfers.
class StaysWorkspace extends StatelessWidget {
  const StaysWorkspace({super.key, required this.controller});
  final AdminDashboardController controller;

  @override
  Widget build(BuildContext context) {
    final stays = controller.filteredStays;
    final isEs = controller.isEs;
    return ListView(
      key: const Key('workspace-admin-stays'),
      padding: const EdgeInsets.all(KachavaTokens.space6),
      children: [
        PageHeader(
          title: AdminI18n.tr(isEs, 'Reservations', 'Reservas'),
          info: AdminI18n.tr(
              isEs,
              'Pick a free villa to create a stay and copy its guest link. Use Check-Out to release the villa when the guest leaves.',
              'Elige una villa libre para crear la estancia y copiar su link. Usa Dar Salida para liberar la villa cuando el huésped se vaya.'),
          actions: [
            ElevatedButton(
              key: const Key('create-new-stay-btn'),
              onPressed: () => showNewStayDialog(context, controller),
              child: Text(AdminI18n.tr(
                  isEs, '+ New Guest Stay', '+ Nuevo Huésped / Crear Link')),
            ),
          ],
        ),
        const SizedBox(height: KachavaTokens.space6),
        _buildAvailableVillasBar(context),
        const SizedBox(height: KachavaTokens.space6),
        if (stays.isEmpty)
          AsyncStateView(
            state: AsyncViewState.empty,
            emptyMessage: AdminI18n.tr(
              isEs,
              'No active stays. All 8 Villas are FREE.',
              'No hay huéspedes activos. Las 8 Villas están LIBRES.',
            ),
            builder: (_) => const SizedBox.shrink(),
          )
        else
          ...stays.map((stay) => _buildStayCard(context, stay)),
      ],
    );
  }

  Widget _buildAvailableVillasBar(BuildContext context) {
    final isEs = controller.isEs;
    // Villas cannot be created until the API exposes a villas endpoint.
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
          AdminI18n.tr(isEs, 'Villas (${controller.villas.length})',
              'Villas (${controller.villas.length})'),
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: KachavaTokens.space3),
      Wrap(
          spacing: KachavaTokens.space2,
          runSpacing: KachavaTokens.space2,
          children: controller.villas
              .map((v) => _buildVillaStatusChip(context, v, isEs))
              .toList()),
    ]);
  }

  Widget _buildVillaStatusChip(
      BuildContext context, AdminVillaInfo villa, bool isEs) {
    final occupant = controller.activeStayForVilla(villa.displayLabel);
    final isOccupied = occupant != null;
    final code = AdminFilterEngine.extractVillaCode(villa.villaName);
    final isFiltered =
        AdminFilterEngine.extractVillaCode(controller.villaFilter) == code;
    final tone = isOccupied ? StatusTone.neutral : StatusTone.success;
    final label = isOccupied
        ? '${villa.villaName} · ${AdminI18n.tr(isEs, "OCCUPIED", "OCUPADA")} (${occupant.guestNames})'
        : '${villa.displayLabel} · ${AdminI18n.tr(isEs, "FREE", "LIBRE")}';
    return ActionChip(
      key: Key('villa-chip-${villa.villaId}'),
      backgroundColor: tone.background,
      side: isFiltered
          ? BorderSide(color: tone.foreground, width: 2)
          : BorderSide.none,
      onPressed: () => isOccupied
          ? controller.setQuickFilter(
              villa: isFiltered ? 'All Villas' : villa.villaName)
          : showNewStayDialog(context, controller,
              initialVilla: villa.displayLabel),
      label: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: tone.foreground)),
    );
  }

  Widget _buildStayCard(BuildContext context, AdminStayRecord stay) {
    return Container(
      margin: const EdgeInsets.only(bottom: KachavaTokens.space4),
      padding: const EdgeInsets.all(KachavaTokens.space4),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(KachavaTokens.radiusLg),
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildStayHeader(context, stay),
        const SizedBox(height: KachavaTokens.space3),
        _buildMagicLinkManager(context, stay),
        const SizedBox(height: KachavaTokens.space3),
        _buildSimplifiedSummaryRow(context, stay),
        const SizedBox(height: KachavaTokens.space4),
        _buildAviationTransferSection(context, stay),
      ]),
    );
  }

  Widget _buildStayHeader(BuildContext context, AdminStayRecord stay) {
    final isEs = controller.isEs;
    final theme = Theme.of(context);
    final titleColumn =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
          '${AdminI18n.orDash(stay.villaName)} · ${AdminI18n.orDash(stay.guestNames)}',
          style: theme.textTheme.titleLarge),
      const SizedBox(height: KachavaTokens.space1),
      Text(
          '${AdminI18n.orDash(stay.checkInDate)} – ${AdminI18n.orDash(stay.checkOutDate)} (${stay.nights} ${AdminI18n.tr(isEs, "nights", "noches")}) · HOST ADMIN',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    ]);
    return SizedBox(
      width: double.infinity,
      child: Wrap(
          spacing: KachavaTokens.space3,
          runSpacing: KachavaTokens.space2,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            titleColumn,
            _buildStayActionButtons(context, stay, isEs)
          ]),
    );
  }

  Widget _buildStayActionButtons(
      BuildContext context, AdminStayRecord stay, bool isEs) {
    final isCheckedOut = stay.lifecycleStatus == StayLifecycleStatus.checkedOut;
    return Wrap(
        spacing: KachavaTokens.space2,
        runSpacing: KachavaTokens.space2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          StatusChip.fromStatus(stay.lifecycleStatus.label,
              label: AdminI18n.statusLabel(stay.lifecycleStatus.label, isEs)),
          if (stay.lifecycleStatus == StayLifecycleStatus.preArrival)
            OutlinedButton.icon(
                key: Key('checkin-stay-${stay.stayId}'),
                onPressed: () => controller.checkInGuest(stay.stayId),
                icon: const Icon(Icons.login, size: 16),
                label: Text(AdminI18n.tr(isEs, 'Mark Arrived (Check-In)',
                    'Registrar Llegada (Check-In)'))),
          if (!isCheckedOut)
            OutlinedButton.icon(
                key: Key('release-villa-${stay.stayId}'),
                onPressed: () =>
                    showConfirmCheckoutDialog(context, controller, stay),
                icon: const Icon(Icons.logout, size: 16),
                label: Text(AdminI18n.tr(isEs, 'Check-Out / Release Villa',
                    'Dar Salida / Liberar Villa')))
          else
            StatusChip(
                label: AdminI18n.tr(
                    isEs, 'FREE VILLA / CHECKED OUT', 'VILLA LIBRE / SALIDA'),
                tone: StatusTone.neutral),
          TextButton(
              key: Key('open-stay-summary-${stay.stayId}'),
              onPressed: () =>
                  controller.selectTab(AdminWorkspaceTab.adminFolio),
              child: Text(
                  AdminI18n.tr(isEs, 'Stay summary', 'Resumen de estancia'))),
          OutlinedButton(
              key: Key('inspect-stay-${stay.stayId}'),
              onPressed: () => controller.openInspector(AdminDrawerSelection(
                  type: InspectorRecordType.stay,
                  recordId: stay.stayId,
                  title:
                      '${AdminI18n.orDash(stay.villaName)} — ${AdminI18n.orDash(stay.guestNames)}',
                  subtitle: 'Flight ${stay.transfer.inboundFlight}')),
              child:
                  Text(AdminI18n.tr(isEs, 'Update status', 'Cambiar Estado'))),
        ]);
  }

  Widget _buildMagicLinkManager(BuildContext context, AdminStayRecord stay) {
    final isEs = controller.isEs;
    final theme = Theme.of(context);
    return Wrap(
        spacing: KachavaTokens.space2,
        runSpacing: KachavaTokens.space2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(Icons.vpn_key_outlined,
              size: 18, color: theme.colorScheme.onSurfaceVariant),
          if (stay.hasGuestLink) ...[
            SelectableText(stay.magicLinkUrl,
                key: Key('magic-link-text-${stay.stayId}'),
                style: theme.textTheme.bodyMedium),
            ElevatedButton(
                key: Key('copy-magic-link-${stay.stayId}'),
                onPressed: () => controller.copyMagicLink(stay),
                child:
                    Text(AdminI18n.tr(isEs, 'Copy Magic Link', 'Copiar Link'))),
          ],
          OutlinedButton(
              key: Key('rotate-magic-link-${stay.stayId}'),
              onPressed: () => controller.regenerateMagicLink(stay.stayId),
              child: Text(AdminI18n.tr(isEs, 'Rotate link', 'Rotar Link'))),
        ]);
  }

  Widget _buildSimplifiedSummaryRow(
      BuildContext context, AdminStayRecord stay) {
    final isEs = controller.isEs, p = stay.personalization;
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyMedium;
    final dietStr = p.dietaryBadges.isEmpty
        ? AdminI18n.tr(isEs, 'Pending guest selection', 'Sin seleccionar')
        : p.dietaryBadges
            .map((d) => AdminI18n.translatePref(d, isEs))
            .join(', ');
    final allergyStr = p.allergies.isEmpty
        ? AdminI18n.tr(isEs, 'None reported', 'Ninguna reportada')
        : p.allergies.join(', ');
    final hkStr = p.housekeepingCadence.isEmpty
        ? AdminI18n.tr(isEs, 'Not selected', 'Sin seleccionar')
        : AdminI18n.translatePref(p.housekeepingCadence, isEs);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KachavaTokens.space4),
      decoration: BoxDecoration(
          color: KachavaTokens.surface,
          borderRadius: BorderRadius.circular(KachavaTokens.radiusMd)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            AdminI18n.tr(isEs, 'GUEST COMFORT, SCENT, DIET, ALLERGIES & NOTES',
                'CONFORT, AROMA, DIETA, ALERGIAS Y NOTAS DEL HUÉSPED'),
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        if (p.hasCriticalAllergy) ...[
          const SizedBox(height: KachavaTokens.space2),
          Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: KachavaTokens.space3,
                  vertical: KachavaTokens.space2),
              decoration: BoxDecoration(
                  color: StatusTone.error.background,
                  borderRadius: BorderRadius.circular(KachavaTokens.radiusMd)),
              child: Text(
                  '${AdminI18n.tr(isEs, "ALLERGY ALERT", "ALERTA DE ALERGIA")}: ${p.allergies.join(", ")}',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: StatusTone.error.foreground))),
        ],
        const SizedBox(height: KachavaTokens.space2),
        Text(
            '${AdminI18n.tr(isEs, "Pillow", "Almohada")}: ${AdminI18n.translatePref(p.pillowType, isEs)}   ·   ${AdminI18n.tr(isEs, "Welcome Scent", "Aroma de Bienvenida")}: ${AdminI18n.translatePref(p.scentProfile, isEs)}',
            style: body),
        const SizedBox(height: KachavaTokens.space1),
        Text(
            '${AdminI18n.tr(isEs, "Housekeeping Schedule", "Horario de Limpieza")}: $hkStr',
            style: body),
        const SizedBox(height: KachavaTokens.space1),
        Text(
            '${AdminI18n.tr(isEs, "Diet", "Dieta")}: $dietStr   ·   ${AdminI18n.tr(isEs, "Allergies", "Alergias")}: $allergyStr',
            style: body),
        const SizedBox(height: KachavaTokens.space1),
        Text(
            '${AdminI18n.tr(isEs, "Special Notes & Occasion", "Notas Especiales y Motivo")}: ${p.occasion.isEmpty ? AdminI18n.tr(isEs, "None", "Sin notas") : p.occasion}',
            style: body),
        const SizedBox(height: KachavaTokens.space2),
        _buildWifiRow(context, stay, isEs),
      ]),
    );
  }

  Widget _buildWifiRow(BuildContext context, AdminStayRecord stay, bool isEs) {
    return Wrap(
        spacing: KachavaTokens.space3,
        runSpacing: KachavaTokens.space2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (stay.wifiSsid.isNotEmpty)
            Text(
                'Wi-Fi: ${stay.wifiSsid}  (${AdminI18n.tr(isEs, "Passcode", "Contraseña")}: ${stay.wifiPasscode})',
                style: Theme.of(context).textTheme.bodyMedium),
          OutlinedButton.icon(
            key: Key('edit-wifi-btn-${stay.stayId}'),
            onPressed: () => showConfigureWifiDialog(context, controller, stay),
            icon: const Icon(Icons.wifi_password, size: 16),
            label: Text(AdminI18n.tr(isEs, 'Edit Wi-Fi', 'Configurar Wi-Fi')),
          ),
        ]);
  }

  Widget _buildAviationTransferSection(
      BuildContext context, AdminStayRecord stay) {
    final isEs = controller.isEs;
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyMedium;
    final t = stay.transfer;
    final hasFlight = t.inboundFlight.isNotEmpty &&
        t.inboundFlight != 'Pending' &&
        t.inboundFlight != 'TBD';
    const statuses = ['Scheduled', 'Confirmed', 'En Route', 'Completed'];
    final chauffeurLine = AdminI18n.tr(
      isEs,
      'Chauffeur / Vehicle: ${t.assignedChauffeurName} · Meeting Point: ${t.cabinBeverage}',
      'Chofer / Vehículo: ${t.assignedChauffeurName} · Punto de Encuentro: ${t.cabinBeverage}',
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        !hasFlight
            ? AdminI18n.tr(
                isEs,
                'Airport Transfer: Guest has not registered flight details yet',
                'Traslado: El huésped aún no ha registrado datos de su vuelo')
            : '${AdminI18n.tr(isEs, "Airport Transfer", "Traslado Aeropuerto")} · ${AdminI18n.staffLabel(t.assignedChauffeurName, isEs)} · ${AdminI18n.statusLabel(t.transferStatus, isEs)}',
        style: theme.textTheme.titleSmall,
      ),
      if (hasFlight) ...[
        const SizedBox(height: KachavaTokens.space2),
        Text(
            AdminI18n.tr(
              isEs,
              'Date: ${t.arrivalDate} · Airline: ${t.airline} · Flight: ${t.inboundFlight}',
              'Fecha: ${t.arrivalDate} · Aerolínea: ${t.airline} · Vuelo: ${t.inboundFlight}',
            ),
            style: body),
        const SizedBox(height: KachavaTokens.space1),
        Text(
            AdminI18n.tr(
              isEs,
              'Airport: ${t.inboundRoute} · Terminal: ${t.terminal} · Arrival: ${t.inboundEta}',
              'Aeropuerto: ${t.inboundRoute} · Terminal: ${t.terminal} · Llegada: ${t.inboundEta}',
            ),
            style: body),
        const SizedBox(height: KachavaTokens.space1),
        Text(chauffeurLine, style: body),
      ] else if (t.cabinBeverage.isNotEmpty ||
          t.assignedChauffeurName.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: KachavaTokens.space1),
          child: Text(chauffeurLine,
              style: body?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
      const SizedBox(height: KachavaTokens.space2),
      Wrap(
          spacing: KachavaTokens.space2,
          runSpacing: KachavaTokens.space2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...statuses.map((status) => ChoiceChip(
                  key: Key('transfer-status-${stay.stayId}-$status'),
                  label: Text(AdminI18n.statusLabel(status, isEs)),
                  selected: t.transferStatus == status,
                  onSelected: (_) => controller.updateTransferDispatch(
                      stayId: stay.stayId,
                      chauffeurId: t.assignedChauffeurId,
                      transferStatus: status),
                )),
            OutlinedButton.icon(
              key: Key('assign-transfer-btn-${stay.stayId}'),
              onPressed: () =>
                  showAssignTransferDialog(context, controller, stay),
              icon: const Icon(Icons.directions_car_outlined, size: 16),
              label: Text(AdminI18n.tr(isEs, 'Assign Driver & Meeting Point',
                  'Asignar Chofer y Punto de Encuentro')),
            ),
          ]),
    ]);
  }
}
