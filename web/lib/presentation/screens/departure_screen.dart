import 'package:flutter/material.dart';
import '../../application/sanctuary_controller.dart';
import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';

/// Screen 11: Stay & Departure Summary (`departure`).
class DepartureScreen extends StatelessWidget {
  const DepartureScreen({super.key, required this.controller});

  final SanctuaryController controller;

  @override
  Widget build(BuildContext context) {
    final stay = controller.stay;
    final i18n = controller.i18n;

    return ListView(
      key: const Key('screen-departure'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 84),
      children: [
        Text(
          i18n.t(
            '${stay.stayDates} · ${stay.nights} nights',
            '${stay.stayDates} · ${stay.nights} noches',
          ),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: KachavaColors.secondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          i18n.t(
            'Stay & Departure Summary',
            'Resumen de tu Estancia y Salida',
          ),
          style: const TextStyle(
            fontFamily: KachavaTheme.serifFamily,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: KachavaColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        _buildDatesAndTransferCard(),
        const SizedBox(height: 12),
        _buildActivitiesAndExperiencesCard(),
        const SizedBox(height: 12),
        _buildMinibarAndLarderCard(),
        const SizedBox(height: 14),
        _buildCheckoutCoordinationBanner(),
      ],
    );
  }

  Widget _buildDatesAndTransferCard() {
    final stay = controller.stay;
    final t = controller.transport;
    final i18n = controller.i18n;
    final flightInfo = t.flightNumber.trim().isEmpty
        ? i18n.t('Flight pending registration', 'Vuelo pendiente de registro')
        : '${t.airline} · ${t.flightNumber} (${t.arrivalAirport})';
    final driver =
        t.assignedDriver.trim().isEmpty ? 'HOST ADMIN' : t.assignedDriver;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              i18n.t(
                'STAY DATES & TRANSFER SUMMARY',
                'RESUMEN DE FECHAS Y TRASLADO',
              ),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: KachavaColors.secondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              i18n.t(
                '${stay.stayDates} (${stay.nights} nights) · ${stay.villaTitle}',
                '${stay.stayDates} (${stay.nights} noches) · ${stay.villaTitle}',
              ),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: KachavaColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$flightInfo · ${i18n.t("Chauffeur", "Chofer")}: $driver',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _statusBadge(String rawStatus) {
    final i18n = controller.i18n;
    final s = rawStatus.toUpperCase();
    if (s == 'CONFIRMED') return i18n.t('Approved', 'Aprobado');
    if (s == 'CANCELLED') return i18n.t('Cancelled', 'Cancelado');
    return i18n.t('Submitted', 'Enviado');
  }

  Widget _buildActivitiesAndExperiencesCard() {
    final i18n = controller.i18n;
    final reservedExps =
        controller.experiences.where((e) => e.isReserved).toList();
    final yacht = controller.yachtCharter;
    final dining = controller.diningReservation;
    final hasYacht = yacht.bookingStatus.isNotEmpty || yacht.isConfirmed;
    final hasDining = dining.bookingStatus.isNotEmpty || dining.isConfirmed;
    final isEmpty = reservedExps.isEmpty && !hasYacht && !hasDining;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              i18n.t(
                'REQUESTED ACTIVITIES & EXPERIENCES',
                'RESUMEN DE ACTIVIDADES Y EXPERIENCIAS SOLICITADAS',
              ),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: KachavaColors.secondary,
              ),
            ),
            const Divider(height: 16),
            if (isEmpty)
              Text(
                i18n.t(
                  'No experiences requested yet.',
                  'Sin experiencias solicitadas aún.',
                ),
                style: const TextStyle(fontSize: 12),
              )
            else ...[
              if (hasYacht)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '⛵ ${yacht.vesselModel} · ${yacht.selectedDate} · ${_statusBadge(yacht.bookingStatus)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (hasDining)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '🍽️ ${dining.selectedMenuId} · ${dining.selectedEvening} (${dining.serviceTime}) · ${_statusBadge(dining.bookingStatus)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ...reservedExps.map(
                (exp) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '✨ ${i18n.translateContent(exp.title)} · ${exp.scheduledDate} ${exp.scheduledTimeSlot} · ${_statusBadge(exp.bookingStatus)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMinibarAndLarderCard() {
    final i18n = controller.i18n;
    final ordered = controller.submittedLarderItems.isNotEmpty
        ? controller.submittedLarderItems
        : controller.larderItems.where((i) => i.quantity > 0).toList();
    final status = controller.larderOrderStatus.isEmpty
        ? i18n.t('Pending', 'Pendiente')
        : controller.larderOrderStatus;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    i18n.t(
                      'MINIBAR & PANTRY SUMMARY',
                      'RESUMEN DE MINIBAR Y DESPENSA',
                    ),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: KachavaColors.secondary,
                    ),
                  ),
                ),
                Text(
                  status,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: KachavaColors.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            if (ordered.isEmpty)
              Text(
                i18n.t(
                  'No minibar items requested.',
                  'Sin artículos de minibar solicitados.',
                ),
                style: const TextStyle(fontSize: 12),
              )
            else
              ...ordered.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${item.quantity}x ${i18n.translateContent(item.name)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutCoordinationBanner() {
    final isCheckedOut = controller.isReadOnly;
    final i18n = controller.i18n;
    return Container(
      key: const Key('departure-host-checkout-banner'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KachavaColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCheckedOut
              ? KachavaColors.confirmedGreen
              : KachavaColors.primary,
        ),
      ),
      child: Text(
        isCheckedOut
            ? i18n.t(
                '✓ Check-Out Completed · Safe travels from HOST ADMIN',
                '✓ Check-Out Completado · Buen viaje de parte de HOST ADMIN',
              )
            : i18n.t(
                'Your departure and check-out are coordinated directly by your HOST ADMIN.',
                'Tu salida y Check-Out son coordinados directamente por tu HOST ADMIN.',
              ),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: KachavaColors.primary,
        ),
      ),
    );
  }
}
