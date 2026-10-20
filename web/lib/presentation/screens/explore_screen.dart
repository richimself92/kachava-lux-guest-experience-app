import 'package:flutter/material.dart';
import '../../application/sanctuary_controller.dart';
import '../../core/i18n/guest_i18n.dart';
import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';
import '../../domain/entities/experience_entities.dart';

/// Screen 5: Curated Excursions & Discovery (`explore`).
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, required this.controller});

  final SanctuaryController controller;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<ExperienceItem> _filteredExperiences() {
    return widget.controller.experiences
        .where((e) =>
            e.targetScreenWireId != 'yacht' &&
            e.category.toLowerCase() != 'yacht')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final items = _filteredExperiences();
    return ListView(
      key: const Key('screen-explore'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 84),
      children: [
        Text(
          GuestI18n.tr(
            controller.isEs,
            'CURATED SANCTUARY EXCURSIONS',
            'EXCURSIONES Y EXPERIENCIAS',
          ),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: KachavaColors.secondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          GuestI18n.tr(
            controller.isEs,
            'Explore Your Sanctuary',
            'Explora Experiencias y Actividades',
          ),
          style: const TextStyle(
            fontFamily: KachavaTheme.serifFamily,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: KachavaColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map(_buildExperienceCard),
      ],
    );
  }

  Widget _buildExperienceCard(ExperienceItem item) {
    final i18n = widget.controller.i18n;
    final isEs = widget.controller.isEs;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(item, i18n),
            const SizedBox(height: 8),
            Text(
              i18n.translateContent(item.title),
              style: const TextStyle(
                fontFamily: KachavaTheme.serifFamily,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: KachavaColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              i18n.translateContent(item.description),
              style: const TextStyle(fontSize: 12),
            ),
            if (item.bookingStatus.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildBookingStatusBanner(item),
            ],
            const SizedBox(height: 10),
            _buildCardFooter(item, i18n, isEs),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingStatusBanner(ExperienceItem exp) {
    final i18n = widget.controller.i18n;
    final status = exp.bookingStatus.toUpperCase();
    final isConfirmed = status == 'CONFIRMED';
    final isCancelled = status == 'CANCELLED';
    final badgeColor = isConfirmed
        ? KachavaColors.confirmedGreen
        : (isCancelled ? KachavaColors.errorRed : KachavaColors.secondary);
    final statusLabel = isConfirmed
        ? i18n.t('✅ APPROVED & CONFIRMED BY HOST ADMIN',
            '✅ APROBADO / CONFIRMADO POR HOST ADMIN')
        : (isCancelled
            ? i18n.t('❌ CANCELLED BY HOST ADMIN', '❌ CANCELADO POR HOST ADMIN')
            : i18n.t('⏳ SUBMITTED · PENDING APPROVAL',
                '⏳ ENVIADO · PENDIENTE DE APROBACIÓN'));
    final datePart = exp.scheduledDate.isNotEmpty
        ? exp.scheduledDate
        : widget.controller.stay.defaultStayDateLabel;
    final timePart =
        exp.scheduledTimeSlot.isNotEmpty ? exp.scheduledTimeSlot : '10:00 AM';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: KachavaColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: badgeColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📅 $datePart · ⏰ $timePart',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: KachavaColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            statusLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: badgeColor,
            ),
          ),
          if (isCancelled && exp.cancellationReason.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${i18n.t("Reason", "Motivo")}: ${exp.cancellationReason}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: KachavaColors.errorRed,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardHeader(ExperienceItem item, GuestI18n i18n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: item.isIncluded
                ? KachavaColors.primary
                : KachavaColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            i18n.translateContent(item.priceText),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: item.isIncluded ? Colors.white : KachavaColors.primary,
            ),
          ),
        ),
        Text(
          i18n.translateContent(item.duration),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: KachavaColors.mutedMetadata,
          ),
        ),
      ],
    );
  }

  Widget _buildCardFooter(ExperienceItem item, GuestI18n i18n, bool isEs) {
    final isLocked = item.bookingStatus.isNotEmpty;
    return Row(
      children: [
        Expanded(
          child: Text(
            i18n.translateContent(item.location),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: KachavaColors.secondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          key: Key('reserve-exp-${item.id}'),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isLocked ? KachavaColors.inputBorder : KachavaColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: isLocked ? null : () => _openReservationDialog(item),
          child: Text(
            isLocked
                ? GuestI18n.tr(isEs, 'Requested ✓', 'Enviado ✓')
                : GuestI18n.tr(isEs, 'Reserve', 'Reservar'),
          ),
        ),
      ],
    );
  }

  Future<void> _openReservationDialog(ExperienceItem exp) async {
    final stay = widget.controller.stay;
    final i18n = widget.controller.i18n;
    var pickedDate = stay.defaultStayDateLabel;
    var pickedTime = '09:00 AM';
    const slots = ['09:00 AM', '11:00 AM', '02:00 PM', '04:30 PM'];

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              title: Text(
                i18n.translateContent(exp.title),
                style: const TextStyle(
                  fontFamily: KachavaTheme.serifFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: KachavaColors.primary,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '📅 $pickedDate · ⏰ $pickedTime',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: KachavaColors.primary,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        key: Key('pick-exp-date-${exp.id}'),
                        onPressed: () async {
                          final selected = await showDatePicker(
                            context: ctx,
                            initialDate: stay.checkInDateTime,
                            firstDate: stay.checkInDateTime,
                            lastDate: stay.checkOutDateTime,
                          );
                          if (!ctx.mounted || selected == null) return;
                          setModalState(() {
                            pickedDate =
                                '${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
                          });
                        },
                        icon: const Icon(Icons.calendar_today, size: 15),
                        label: Text(i18n.t('Calendar', 'Calendario')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...{...slots, pickedTime}.map((slot) {
                        return ChoiceChip(
                          label:
                              Text(slot, style: const TextStyle(fontSize: 11)),
                          selected: pickedTime == slot,
                          onSelected: (_) =>
                              setModalState(() => pickedTime = slot),
                        );
                      }),
                      TextButton.icon(
                        key: Key('pick-exp-custom-time-${exp.id}'),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: const TimeOfDay(hour: 10, minute: 0),
                          );
                          if (!ctx.mounted || picked == null) return;
                          setModalState(() => pickedTime = picked.format(ctx));
                        },
                        icon: const Icon(Icons.access_time, size: 15),
                        label: Text(
                          i18n.t('⏰ Custom Time', '⏰ Hora personalizada'),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(i18n.t('Cancel', 'Cancelar')),
                ),
                ElevatedButton(
                  key: Key('confirm-exp-dialog-${exp.id}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KachavaColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    widget.controller.toggleExperienceReservation(
                      exp.id,
                      scheduledDate: pickedDate,
                      scheduledTimeSlot: pickedTime,
                    );
                    Navigator.of(ctx).pop();
                  },
                  child: Text(
                    i18n.t(
                      'Confirm Reservation Request',
                      'Confirmar Solicitud de Reserva',
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
