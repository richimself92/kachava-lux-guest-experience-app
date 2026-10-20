import 'package:flutter/material.dart';
import '../../application/sanctuary_controller.dart';
import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';
import '../../domain/entities/experience_entities.dart';

/// Screen 6: Private Yacht Charter (`yacht`).
class YachtScreen extends StatelessWidget {
  const YachtScreen({super.key, required this.controller});

  final SanctuaryController controller;

  @override
  Widget build(BuildContext context) {
    final charter = controller.yachtCharter;
    final dateLabel = charter.selectedDate.isEmpty
        ? controller.stay.defaultStayDateLabel
        : charter.selectedDate;
    return ListView(
      key: const Key('screen-yacht'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        _buildMaritimeBanner(charter.vesselModel),
        if (charter.bookingStatus.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildYachtStatusBanner(charter),
        ],
        const SizedBox(height: 8),
        _buildCaptainCard(),
        const SizedBox(height: 8),
        _buildCharterDateCard(
            context, dateLabel, charter.bookingStatus.isNotEmpty),
        const SizedBox(height: 8),
        _buildPackagesSection(
            charter.selectedPackageId, charter.bookingStatus.isNotEmpty),
        const SizedBox(height: 8),
        _buildGuestManifestCard(
            charter.guestCount, charter.bookingStatus.isNotEmpty),
        const SizedBox(height: 8),
        _buildBookingSummaryBar(charter.bookingStatus.isNotEmpty),
      ],
    );
  }

  Widget _buildYachtStatusBanner(YachtCharterConfig yacht) {
    final i18n = controller.i18n;
    final status = yacht.bookingStatus.toUpperCase();
    final isConfirmed = status == 'CONFIRMED';
    final isCancelled = status == 'CANCELLED';
    final borderColor = isConfirmed
        ? KachavaColors.confirmedGreen
        : (isCancelled ? KachavaColors.errorRed : KachavaColors.secondary);
    final label = isConfirmed
        ? i18n.t(
            '✅ YACHT CHARTER APPROVED & CONFIRMED BY HOST ADMIN',
            '✅ YATE APROBADO Y CONFIRMADO POR HOST ADMIN',
          )
        : (isCancelled
            ? i18n.t(
                '❌ YACHT CHARTER REQUEST CANCELLED',
                '❌ SOLICITUD DE YATE CANCELADA',
              )
            : i18n.t(
                '⏳ REQUEST SUBMITTED · PENDING HOST ADMIN APPROVAL',
                '⏳ SOLICITUD ENVIADA · PENDIENTE DE APROBACIÓN POR HOST ADMIN',
              ));
    return Container(
      key: const Key('yacht-status-banner'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KachavaColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: borderColor,
            ),
          ),
          if (isCancelled && yacht.cancellationReason.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${i18n.t("Reason", "Motivo")}: ${yacht.cancellationReason}',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: KachavaColors.errorRed,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickCharterDate(BuildContext context) async {
    final stay = controller.stay;
    final picked = await showDatePicker(
      context: context,
      initialDate: stay.checkInDateTime,
      firstDate: stay.checkInDateTime,
      lastDate: stay.checkOutDateTime,
    );
    if (!context.mounted || picked == null) return;
    final y = picked.year.toString();
    final m = picked.month.toString().padLeft(2, '0');
    final d = picked.day.toString().padLeft(2, '0');
    controller.updateYachtDate('$y-$m-$d');
  }

  Widget _buildCharterDateCard(
    BuildContext context,
    String selectedDate,
    bool isLocked,
  ) {
    final i18n = controller.i18n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                size: 16, color: KachavaColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${i18n.t("CHARTER DATE", "FECHA")}: $selectedDate',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: KachavaColors.primary),
              ),
            ),
            TextButton.icon(
              key: const Key('yacht-date-picker-btn'),
              onPressed: isLocked ? null : () => _pickCharterDate(context),
              icon: const Icon(Icons.edit_calendar, size: 15),
              label: Text(i18n.t('Select Date', 'Elegir Fecha')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaritimeBanner(String vesselModel) {
    final i18n = controller.i18n;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KachavaColors.maritimeNavy,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KachavaColors.maritimeGold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KACHAVA CARIBE · PUERTO CANCÚN MARINA',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: KachavaColors.maritimeCyan),
          ),
          const SizedBox(height: 4),
          Text(
            vesselModel,
            style: const TextStyle(
                fontFamily: KachavaTheme.serifFamily,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            i18n.t(
              '47 ft 3 in · 19 ft Beach Mode Beam · Up to 12 Guests + 2 Crew',
              '47 pies · Terraza sobre el Mar · Hasta 12 Pasajeros + 2 Tripulantes',
            ),
            style: const TextStyle(
                fontSize: 11.5, color: KachavaColors.maritimeGold),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptainCard() {
    final i18n = controller.i18n;
    return Card(
      color: KachavaColors.maritimeDeep,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              i18n.t('MARINE TEAM & HOST ADMIN',
                  'TRIPULACIÓN MARINA Y HOST ADMIN'),
              style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: KachavaColors.maritimeGold),
            ),
            const SizedBox(height: 2),
            Text(
              i18n.t('Kachava Marine Crew · 19 Years at Sea',
                  'Tripulación Marina Kachava · 19 Años en el Mar'),
              style: const TextStyle(
                  fontFamily: KachavaTheme.serifFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(
              i18n.t(
                '"When our guests step on board, their only concern should be what drink to order."',
                '"Cuando nuestros huéspedes suben a bordo, su única preocupación es qué bebida disfrutar."',
              ),
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackagesSection(String selectedId, bool isLocked) {
    final i18n = controller.i18n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          i18n.t('CURATED CHARTER PACKAGES', 'PAQUETES DE NAVEGACIÓN'),
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: KachavaColors.secondary),
        ),
        const SizedBox(height: 6),
        ...controller.yachtPackages.map(
          (pkg) => _buildPackageCard(pkg, pkg.id == selectedId, isLocked),
        ),
      ],
    );
  }

  Widget _buildPackageCard(
    YachtPackageOption pkg,
    bool isSelected,
    bool isLocked,
  ) {
    final i18n = controller.i18n;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? KachavaColors.maritimeCyan
              : KachavaColors.surfaceContainerHighest,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        key: Key('yacht-pkg-${pkg.id}'),
        onTap: isLocked ? null : () => controller.selectYachtPackage(pkg.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      i18n.translateContent(pkg.title),
                      style: const TextStyle(
                          fontFamily: KachavaTheme.serifFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: KachavaColors.primary),
                    ),
                  ),
                  Text('${pkg.durationHours}h',
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: KachavaColors.secondary)),
                ],
              ),
              const SizedBox(height: 2),
              Text(i18n.translateContent(pkg.priceLabel),
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: KachavaColors.confirmedGreen)),
              const SizedBox(height: 2),
              Text(i18n.translateContent(pkg.description),
                  style: const TextStyle(fontSize: 11.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestManifestCard(int guestCount, bool isLocked) {
    final i18n = controller.i18n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    i18n.t('GUEST MANIFEST (MAX CAPACITY 12)',
                        'NÚMERO DE PASAJEROS (MÁX. 12)'),
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: KachavaColors.secondary),
                  ),
                  Text(
                    i18n.t('Onboard Catering Synced with Guest Profile',
                        'Menú a bordo sincronizado con tus preferencias'),
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  key: const Key('yacht-guest-dec-btn'),
                  tooltip: 'Decrease yacht guest count',
                  onPressed: isLocked
                      ? null
                      : () => controller.updateYachtGuestCount(guestCount - 1),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  i18n.t('$guestCount Guests', '$guestCount Pasajeros'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: KachavaColors.primary),
                ),
                IconButton(
                  key: const Key('yacht-guest-inc-btn'),
                  tooltip: 'Increase yacht guest count',
                  onPressed: isLocked
                      ? null
                      : () => controller.updateYachtGuestCount(guestCount + 1),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSummaryBar(bool isLocked) {
    final netDue = controller.yachtNetUpgradeUsd;
    final i18n = controller.i18n;
    return ElevatedButton(
      key: const Key('yacht-reserve-btn'),
      style: ElevatedButton.styleFrom(
        backgroundColor: KachavaColors.maritimeNavy,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: isLocked ? null : controller.submitYachtCharterRequest,
      child: Text(
        isLocked
            ? i18n.t(
                'REQUEST SENT · LOCKED ✓', 'SOLICITUD ENVIADA · BLOQUEADA ✓')
            : i18n.t(
                'RESERVE YACHT CHARTER (\$$netDue.00 USD DUE) →',
                'RESERVAR YATE (\$$netDue.00 USD ADICIONALES) →',
              ),
      ),
    );
  }
}
