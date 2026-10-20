import 'package:flutter/material.dart';
import '../../application/admin_dashboard_controller.dart';
import '../../application/inspector_selection.dart';
import '../../core/admin_i18n.dart';
import '../../core/admin_theme.dart';
import '../../domain/admin_enums.dart';
import '../../domain/admin_stay_entities.dart';
import '../widgets/semantic_status_badge.dart';
import 'stay_dialogs.dart';

/// Tab 2: `admin-stays` — Stays, Magic Links, Villas Management & Airport Transfers (FR-15).
class StaysWorkspace extends StatelessWidget {
  const StaysWorkspace({super.key, required this.controller});
  final AdminDashboardController controller;

  @override
  Widget build(BuildContext context) {
    final stays = controller.filteredStays;
    final isEs = controller.isEs;
    return ListView(
      key: const Key('workspace-admin-stays'),
      padding: const EdgeInsets.all(20),
      children: [
        AdminSectionHeader(
          eyebrow: AdminI18n.tr(
              isEs,
              'RESIDENCIES, MAGIC LINKS & TRANSFERS · FR-15',
              'RESIDENCIAS, LINKS MÁGICOS Y TRASLADOS · FR-15'),
          title: AdminI18n.staysTitle(isEs),
          trailing: ElevatedButton.icon(
            key: const Key('create-new-stay-btn'),
            style: ElevatedButton.styleFrom(
                backgroundColor: KachavaAdminColors.zapotePrimary,
                foregroundColor: Colors.white),
            onPressed: () => showNewStayDialog(context, controller),
            icon: const Icon(Icons.add, size: 16),
            label: Text(AdminI18n.tr(
                isEs, '+ New Guest Stay', '+ Nuevo Huésped / Crear Link')),
          ),
        ),
        const SizedBox(height: 10),
        _buildFlowGuideBanner(isEs),
        const SizedBox(height: 12),
        _buildAvailableVillasBar(context),
        const SizedBox(height: 16),
        if (stays.isEmpty)
          AdminEmptyStateBox(
            message: AdminI18n.tr(
              isEs,
              'No active guest stays yet. All 8 Villas are FREE (🟢). Click "+ New Guest Stay" above to create your first guest and Magic Link.',
              'No hay huéspedes activos. Las 8 Villas están LIBRES (🟢). Haz clic en "+ Nuevo Huésped / Crear Link" arriba para empezar desde cero.',
            ),
          )
        else
          ...stays.map((stay) => _buildStayCard(context, stay)),
      ],
    );
  }

  Widget _buildFlowGuideBanner(bool isEs) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: KachavaAdminColors.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: KachavaAdminColors.borderWarm)),
        child: Text(
            AdminI18n.tr(
                isEs,
                'FLOW: Step 1: Click a FREE Villa (🟢) → Step 2: Create Guest & Copy Link → Step 3: When guest leaves, click "Check-Out / Release Villa"',
                'FLUJO: Paso 1: Pulsa una Villa LIBRE (🟢) → Paso 2: Crea el Huésped y copia su Link → Paso 3: Al terminar su estancia, pulsa "Dar Salida / Liberar Villa"'),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: KachavaAdminColors.zapotePrimary)),
      );

  Widget _buildAvailableVillasBar(BuildContext context) {
    final isEs = controller.isEs;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: KachavaAdminColors.surfacePaper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: KachavaAdminColors.borderLimestone)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                  AdminI18n.tr(isEs, 'SANCTUARY VILLAS INVENTORY (8 VILLAS)',
                      'INVENTARIO DE VILLAS (8 VILLAS)'),
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: KachavaAdminColors.mutedBronze)),
              OutlinedButton.icon(
                key: const Key('create-new-villa-btn'),
                onPressed: () => showNewVillaDialog(context, controller),
                icon: const Icon(Icons.add_home_work_outlined, size: 15),
                label: Text(AdminI18n.tr(isEs, '+ New Villa', '+ Nueva Villa')),
              ),
            ]),
        const SizedBox(height: 10),
        Wrap(
            spacing: 8,
            runSpacing: 6,
            children: controller.villas
                .map((v) => _buildVillaStatusChip(context, v, isEs))
                .toList()),
      ]),
    );
  }

  Widget _buildVillaStatusChip(
      BuildContext context, AdminVillaInfo villa, bool isEs) {
    final occupant = controller.activeStayForVilla(villa.displayLabel);
    final isOccupied = occupant != null;
    final code = AdminFilterEngine.extractVillaCode(villa.villaName);
    final isFiltered =
        AdminFilterEngine.extractVillaCode(controller.villaFilter) == code;
    final label = isOccupied
        ? '🔴 ${villa.villaName} · ${AdminI18n.tr(isEs, "OCCUPIED", "OCUPADA")} (${occupant.guestNames})'
        : '🟢 ${villa.displayLabel} · ${AdminI18n.tr(isEs, "FREE", "LIBRE")}';
    return ActionChip(
      key: Key('villa-chip-${villa.villaId}'),
      backgroundColor:
          isOccupied ? const Color(0xFFFFF1F0) : const Color(0xFFECFDF5),
      side: BorderSide(
          color: isOccupied ? const Color(0xFFBA1A1A) : const Color(0xFF10B981),
          width: isFiltered ? 2.0 : 1.0),
      onPressed: () => isOccupied
          ? controller.setQuickFilter(
              villa: isFiltered ? 'All Villas' : villa.villaName)
          : showNewStayDialog(context, controller,
              initialVilla: villa.displayLabel),
      label: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isOccupied
                  ? const Color(0xFF93000A)
                  : const Color(0xFF065F46))),
    );
  }

  Widget _buildStayCard(BuildContext context, AdminStayRecord stay) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: KachavaAdminColors.surfacePaper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KachavaAdminColors.borderLimestone)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildStayHeader(context, stay),
        const SizedBox(height: 12),
        _buildMagicLinkManager(stay),
        const SizedBox(height: 12),
        _buildSimplifiedSummaryRow(context, stay),
        const SizedBox(height: 12),
        _buildAviationTransferSection(context, stay),
      ]),
    );
  }

  Widget _buildStayHeader(BuildContext context, AdminStayRecord stay) {
    final isEs = controller.isEs;
    final titleColumn =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${stay.villaName} · ${stay.guestNames}',
          style: const TextStyle(
              fontFamily: 'Libre Baskerville',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: KachavaAdminColors.obsidian)),
      const SizedBox(height: 4),
      Text(
          '${stay.checkInDate} – ${stay.checkOutDate} (${stay.nights} ${AdminI18n.tr(isEs, "nights", "noches")}) · HOST ADMIN',
          style: const TextStyle(
              fontSize: 12, color: KachavaAdminColors.neutralMuted)),
    ]);
    return SizedBox(
      width: double.infinity,
      child: Wrap(
          spacing: 12,
          runSpacing: 8,
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
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SemanticStatusBadge(label: stay.lifecycleStatus.label),
          if (stay.lifecycleStatus == StayLifecycleStatus.preArrival)
            OutlinedButton.icon(
                key: Key('checkin-stay-${stay.stayId}'),
                onPressed: () => controller.checkInGuest(stay.stayId),
                icon: const Icon(Icons.login, size: 14),
                label: Text(AdminI18n.tr(isEs, 'Mark Arrived (Check-In)',
                    'Registrar Llegada (Check-In)'))),
          if (!isCheckedOut)
            OutlinedButton.icon(
                key: Key('release-villa-${stay.stayId}'),
                onPressed: () =>
                    showConfirmCheckoutDialog(context, controller, stay),
                icon: const Icon(Icons.logout, size: 14),
                label: Text(AdminI18n.tr(isEs, 'Check-Out / Release Villa',
                    'Dar Salida / Liberar Villa')))
          else
            SemanticStatusBadge(
                label: AdminI18n.tr(
                    isEs, 'FREE VILLA / CHECKED OUT', 'VILLA LIBRE / SALIDA'),
                customStyle: KachavaAdminColors.stage4Completed),
          OutlinedButton(
              key: Key('inspect-stay-${stay.stayId}'),
              onPressed: () => controller.openInspector(AdminDrawerSelection(
                  type: InspectorRecordType.stay,
                  recordId: stay.stayId,
                  title: '${stay.villaName} — ${stay.guestNames}',
                  subtitle: 'Flight ${stay.transfer.inboundFlight}')),
              child:
                  Text(AdminI18n.tr(isEs, 'Assign Drawer', 'Cambiar Estado'))),
        ]);
  }

  Widget _buildMagicLinkManager(AdminStayRecord stay) {
    final isEs = controller.isEs;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: KachavaAdminColors.canvasLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KachavaAdminColors.borderWarm)),
      child: Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(Icons.vpn_key,
                size: 16, color: KachavaAdminColors.zapotePrimary),
            SelectableText(stay.magicLinkUrl,
                key: Key('magic-link-text-${stay.stayId}'),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: KachavaAdminColors.zapotePrimary)),
            ElevatedButton(
                key: Key('copy-magic-link-${stay.stayId}'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: KachavaAdminColors.zapotePrimary,
                    foregroundColor: Colors.white),
                onPressed: () => controller.copyMagicLink(stay),
                child:
                    Text(AdminI18n.tr(isEs, 'Copy Magic Link', 'Copiar Link'))),
            OutlinedButton(
                key: Key('rotate-magic-link-${stay.stayId}'),
                onPressed: () => controller.regenerateMagicLink(stay.stayId),
                child: Text(
                    AdminI18n.tr(isEs, 'Rotate UUID Token', 'Rotar Link'))),
          ]),
    );
  }

  Widget _buildSimplifiedSummaryRow(
      BuildContext context, AdminStayRecord stay) {
    final isEs = controller.isEs, p = stay.personalization;
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: KachavaAdminColors.canvasLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KachavaAdminColors.borderWarm, width: 1.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            AdminI18n.tr(
                isEs,
                '🛏️ GUEST COMFORT, SCENT, DIET, ALLERGIES & NOTES',
                '🛏️ CONFORT, AROMA, DIETA, ALERGIAS Y NOTAS DEL HUÉSPED'),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: KachavaAdminColors.zapotePrimary)),
        if (p.hasCriticalAllergy) ...[
          const SizedBox(height: 8),
          Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFDAD6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBA1A1A))),
              child: Text(
                  '⚠️ ${AdminI18n.tr(isEs, "ALLERGY ALERT", "ALERTA DE ALERGIA")}: ${p.allergies.join(", ")}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF93000A)))),
        ],
        const SizedBox(height: 8),
        Text(
            '🛏️ ${AdminI18n.tr(isEs, "Pillow", "Almohada")}: ${AdminI18n.translatePref(p.pillowType, isEs)}   ·   🌿 ${AdminI18n.tr(isEs, "Welcome Scent", "Aroma de Bienvenida")}: ${AdminI18n.translatePref(p.scentProfile, isEs)}',
            style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: KachavaAdminColors.obsidian)),
        const SizedBox(height: 6),
        Text(
            '🧹 ${AdminI18n.tr(isEs, "Housekeeping Schedule", "Horario de Limpieza")}: $hkStr',
            style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: KachavaAdminColors.obsidian)),
        const SizedBox(height: 6),
        Text(
            '🥗 ${AdminI18n.tr(isEs, "Diet", "Dieta")}: $dietStr   ·   ⚠️ ${AdminI18n.tr(isEs, "Allergies", "Alergias")}: $allergyStr',
            style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: KachavaAdminColors.obsidian)),
        const SizedBox(height: 6),
        Text(
            '📝 ${AdminI18n.tr(isEs, "Special Notes & Occasion", "Notas Especiales y Motivo")}: ${p.occasion.isEmpty ? AdminI18n.tr(isEs, "None", "Sin notas") : p.occasion}',
            style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: KachavaAdminColors.obsidian)),
        const SizedBox(height: 8),
        _buildWifiRow(context, stay, isEs),
      ]),
    );
  }

  Widget _buildWifiRow(BuildContext context, AdminStayRecord stay, bool isEs) {
    return Wrap(
        spacing: 12,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
              '📶 Wi-Fi: ${stay.wifiSsid}  (${AdminI18n.tr(isEs, "Passcode", "Contraseña")}: ${stay.wifiPasscode})',
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: KachavaAdminColors.zapotePrimary)),
          OutlinedButton.icon(
            key: Key('edit-wifi-btn-${stay.stayId}'),
            onPressed: () => showConfigureWifiDialog(context, controller, stay),
            icon: const Icon(Icons.wifi_password, size: 15),
            label: Text(AdminI18n.tr(isEs, 'Edit Wi-Fi', 'Configurar Wi-Fi')),
          ),
        ]);
  }

  Widget _buildAviationTransferSection(
      BuildContext context, AdminStayRecord stay) {
    final isEs = controller.isEs;
    final t = stay.transfer;
    final hasFlight = t.inboundFlight.isNotEmpty &&
        t.inboundFlight != 'Pending' &&
        t.inboundFlight != 'TBD';
    const statuses = ['Scheduled', 'Confirmed', 'En Route', 'Completed'];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: KachavaAdminColors.surfaceContainer,
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          !hasFlight
              ? AdminI18n.tr(
                  isEs,
                  '✈️ Airport Transfer: Guest has not registered flight details yet',
                  '✈️ Traslado: El huésped aún no ha registrado datos de su vuelo')
              : '${AdminI18n.tr(isEs, "Airport Transfer", "Traslado Aeropuerto")} · ${t.assignedChauffeurName.isEmpty ? "HOST ADMIN" : t.assignedChauffeurName} · ${AdminI18n.statusLabel(t.transferStatus, isEs)}',
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: KachavaAdminColors.obsidian),
        ),
        if (hasFlight) ...[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: KachavaAdminColors.canvasLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: KachavaAdminColors.borderWarm),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  AdminI18n.tr(
                    isEs,
                    '📅 Date: ${t.arrivalDate} · ✈️ Airline: ${t.airline} · Flight: ${t.inboundFlight}',
                    '📅 Fecha: ${t.arrivalDate} · ✈️ Aerolínea: ${t.airline} · Vuelo: ${t.inboundFlight}',
                  ),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: KachavaAdminColors.obsidian)),
              const SizedBox(height: 4),
              Text(
                  AdminI18n.tr(
                    isEs,
                    '🛬 Airport: ${t.inboundRoute} · Terminal: ${t.terminal} · ⏰ Arrival: ${t.inboundEta}',
                    '🛬 Aeropuerto: ${t.inboundRoute} · Terminal: ${t.terminal} · ⏰ Llegada: ${t.inboundEta}',
                  ),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: KachavaAdminColors.obsidian)),
              const SizedBox(height: 4),
              Text(
                  AdminI18n.tr(
                    isEs,
                    '🚘 Chauffeur / Vehicle: ${t.assignedChauffeurName} · 📍 Meeting Point: ${t.cabinBeverage}',
                    '🚘 Chofer / Vehículo: ${t.assignedChauffeurName} · 📍 Punto de Encuentro: ${t.cabinBeverage}',
                  ),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: KachavaAdminColors.zapotePrimary)),
            ]),
          ),
        ] else if (t.cabinBeverage.isNotEmpty ||
            t.assignedChauffeurName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
                AdminI18n.tr(
                  isEs,
                  '🚘 Chauffeur / Vehicle: ${t.assignedChauffeurName} · 📍 Meeting Point: ${t.cabinBeverage}',
                  '🚘 Chofer / Vehículo: ${t.assignedChauffeurName} · 📍 Punto de Encuentro: ${t.cabinBeverage}',
                ),
                style: const TextStyle(
                    fontSize: 11,
                    color: KachavaAdminColors.zapotePrimary,
                    fontWeight: FontWeight.w600)),
          ),
        const SizedBox(height: 8),
        Wrap(
            spacing: 8,
            runSpacing: 6,
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
                icon: const Icon(Icons.directions_car_outlined, size: 15),
                label: Text(AdminI18n.tr(isEs, 'Assign Driver & Meeting Point',
                    'Asignar Chofer y Punto de Encuentro')),
              ),
            ]),
      ]),
    );
  }
}
