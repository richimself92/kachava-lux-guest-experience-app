import 'package:flutter/material.dart';
import '../../application/sanctuary_controller.dart';
import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';
import '../../domain/entities/experience_entities.dart';

/// Screen 7: In-Villa Private Dining (`dining`).
class DiningScreen extends StatefulWidget {
  const DiningScreen({super.key, required this.controller});

  final SanctuaryController controller;

  @override
  State<DiningScreen> createState() => _DiningScreenState();
}

class _DiningScreenState extends State<DiningScreen> {
  bool _showBreakfastMode = false;
  late String _selectedMenuId;
  late String _selectedEvening;
  late String _selectedTime;
  late int _guestCount;
  late final TextEditingController _dietaryNotesCtrl;

  @override
  void initState() {
    super.initState();
    final res = widget.controller.diningReservation;
    _selectedMenuId = res.selectedMenuId;
    _selectedEvening = res.selectedEvening.isEmpty
        ? widget.controller.stay.defaultStayDateLabel
        : res.selectedEvening;
    _selectedTime = res.serviceTime;
    _guestCount = res.guestCount;
    _dietaryNotesCtrl = TextEditingController(
      text: res.bookingStatus.isNotEmpty ? res.dietaryNotes : '',
    );
  }

  @override
  void dispose() {
    _dietaryNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickEveningDate() async {
    final stay = widget.controller.stay;
    final picked = await showDatePicker(
      context: context,
      initialDate: stay.checkInDateTime,
      firstDate: stay.checkInDateTime,
      lastDate: stay.checkOutDateTime,
    );
    if (!mounted || picked == null) return;
    final y = picked.year.toString();
    final m = picked.month.toString().padLeft(2, '0');
    final d = picked.day.toString().padLeft(2, '0');
    setState(() => _selectedEvening = '$y-$m-$d');
  }

  Future<void> _pickCustomTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 20, minute: 0),
    );
    if (!mounted || picked == null) return;
    setState(() => _selectedTime = picked.format(context));
  }

  Future<void> _confirmDining() async {
    final current = widget.controller.diningReservation;
    await widget.controller.confirmDiningReservation(
      current.copyWith(
        selectedMenuId: _selectedMenuId,
        selectedEvening: _selectedEvening,
        serviceTime: _selectedTime,
        guestCount: _guestCount,
        dietaryNotes: _dietaryNotesCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = widget.controller.i18n;
    final dining = widget.controller.diningReservation;
    final isLocked = dining.bookingStatus.isNotEmpty;
    return ListView(
      key: const Key('screen-dining'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 84),
      children: [
        _buildModeSwitcher(),
        const SizedBox(height: 12),
        if (_showBreakfastMode)
          _buildArtisanalBreakfastCard()
        else ...[
          if (isLocked) ...[
            _buildDiningStatusBanner(dining),
            const SizedBox(height: 12),
          ],
          _buildCulinaryHeaderCard(),
          const SizedBox(height: 12),
          _buildEveningAndTimeSelector(isLocked),
          const SizedBox(height: 12),
          ...widget.controller.diningMenus
              .map((m) => _buildMenuCard(m, isLocked)),
          const SizedBox(height: 12),
          ElevatedButton(
            key: const Key('dining-confirm-btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: KachavaColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: isLocked ? null : _confirmDining,
            child: Text(
              isLocked
                  ? i18n.t('REQUEST SENT · LOCKED ✓',
                      'SOLICITUD ENVIADA · BLOQUEADA ✓')
                  : i18n.t(
                      'CONFIRM IN-VILLA DINING (\$0.00) →',
                      'CONFIRMAR CENA EN VILLA (\$0.00) →',
                    ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDiningStatusBanner(DiningReservation dining) {
    final i18n = widget.controller.i18n;
    final status = dining.bookingStatus.toUpperCase();
    final isConfirmed = status == 'CONFIRMED';
    final isCancelled = status == 'CANCELLED';
    final borderColor = isConfirmed
        ? KachavaColors.confirmedGreen
        : (isCancelled ? KachavaColors.errorRed : KachavaColors.secondary);
    final label = isConfirmed
        ? i18n.t(
            '✅ IN-VILLA DINING APPROVED & CONFIRMED BY HOST ADMIN',
            '✅ CENA APROBADA Y CONFIRMADA POR HOST ADMIN',
          )
        : (isCancelled
            ? i18n.t(
                '❌ IN-VILLA DINING CANCELLED BY HOST ADMIN',
                '❌ CENA CANCELADA POR HOST ADMIN',
              )
            : i18n.t(
                '⏳ DINING REQUEST SUBMITTED · PENDING APPROVAL',
                '⏳ SOLICITUD DE CENA ENVIADA · PENDIENTE DE APROBACIÓN',
              ));
    return Container(
      key: const Key('dining-status-banner'),
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
          if (isCancelled && dining.cancellationReason.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${i18n.t("Reason", "Motivo")}: ${dining.cancellationReason}',
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

  Widget _buildModeSwitcher() {
    final i18n = widget.controller.i18n;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        ChoiceChip(
          label: Text(
              i18n.t('In-Villa Chef Experience', 'Cena con Chef en Villa'),
              style: const TextStyle(fontSize: 11)),
          selected: !_showBreakfastMode,
          onSelected: (_) => setState(() => _showBreakfastMode = false),
        ),
        ChoiceChip(
          label: Text(i18n.t('Artisanal Breakfast', 'Desayuno Artesanal'),
              style: const TextStyle(fontSize: 11)),
          selected: _showBreakfastMode,
          onSelected: (_) => setState(() => _showBreakfastMode = true),
        ),
      ],
    );
  }

  Widget _buildArtisanalBreakfastCard() {
    final i18n = widget.controller.i18n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              i18n.t('DAILY ARTISANAL BREAKFAST · 7:00 – 11:30 AM',
                  'DESAYUNO ARTESANAL DIARIO · 7:00 – 11:30 AM'),
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: KachavaColors.secondary),
            ),
            const SizedBox(height: 6),
            Text(
              i18n.t(
                'Prepared daily in your villa with organic tropical fruit, Oaxacan espresso, and gluten-sensitive pastries. ✓ No reservation needed.',
                'Preparado cada mañana en tu villa con fruta tropical orgánica, café de Oaxaca y panadería sin gluten. ✓ No requiere reservación.',
              ),
              style: const TextStyle(fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCulinaryHeaderCard() {
    final i18n = widget.controller.i18n;
    final allergy = widget.controller.preferences.allergyAlerts.trim();
    final hasAllergy = allergy.isNotEmpty && allergy != 'None';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              i18n.t('DEDICATED CULINARY TEAM & HOST ADMIN',
                  'EQUIPO CULINARIO Y HOST ADMIN'),
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: KachavaColors.secondary),
            ),
            const SizedBox(height: 4),
            Text(
              i18n.t(
                'Included Residency Privilege · \$0 Due (Valued at \$650 USD)',
                'Beneficio Incluido en tu Estancia · \$0 por Pagar (Valor \$650 USD)',
              ),
              style: const TextStyle(
                  fontFamily: KachavaTheme.serifFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: KachavaColors.primary),
            ),
            if (hasAllergy) ...[
              const SizedBox(height: 4),
              Text(
                '${i18n.t("Allergy Alert", "Alerta de Alergia")}: $allergy',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: KachavaColors.errorRed),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEveningAndTimeSelector(bool isLocked) {
    final i18n = widget.controller.i18n;
    final dateDisplay = _selectedEvening.isEmpty
        ? widget.controller.stay.defaultStayDateLabel
        : _selectedEvening;
    const presetTimes = ['6:30 PM', '7:30 PM', '8:30 PM', '9:30 PM'];
    final timeSlots =
        (_selectedTime.isNotEmpty && !presetTimes.contains(_selectedTime))
            ? [...presetTimes, _selectedTime]
            : presetTimes;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i18n.t('SELECT EVENING & SERVICE TIME',
                            'ELIGE EL DÍA Y HORA DE TU CENA'),
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: KachavaColors.secondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '📅 $dateDisplay · ⏰ $_selectedTime',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: KachavaColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  key: const Key('pick-dining-date-btn'),
                  onPressed: isLocked ? null : _pickEveningDate,
                  icon: const Icon(Icons.calendar_today, size: 14),
                  label: Text(i18n.t('Calendar', 'Calendario'),
                      style: const TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...timeSlots.map((slot) {
                  return ChoiceChip(
                    key: Key('dining-time-chip-$slot'),
                    label: Text(slot, style: const TextStyle(fontSize: 11)),
                    selected: _selectedTime == slot,
                    onSelected: isLocked
                        ? null
                        : (_) => setState(() => _selectedTime = slot),
                  );
                }),
                ActionChip(
                  key: const Key('pick-dining-time-btn'),
                  onPressed: isLocked ? null : _pickCustomTime,
                  label: Text(
                    i18n.t('⏰ Custom Time', '⏰ Hora personalizada'),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('dining-dietary-notes-input'),
              controller: _dietaryNotesCtrl,
              readOnly: isLocked,
              decoration: InputDecoration(
                labelText: i18n.t(
                    'Dietary & Table Notes', 'Notas Alimentarias y de Mesa'),
                hintText: i18n.t(
                  'e.g. No shellfish, terrace candlelight setup (optional)',
                  'Ej. Sin mariscos, mesa en terraza con velas (opcional)',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(DiningMenuOption menu, bool isLocked) {
    final i18n = widget.controller.i18n;
    final isSelected = menu.id == _selectedMenuId;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected
              ? KachavaColors.primary
              : KachavaColors.surfaceContainerHighest,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        key: Key('dining-menu-${menu.id}'),
        onTap:
            isLocked ? null : () => setState(() => _selectedMenuId = menu.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(i18n.translateContent(menu.title),
                  style: const TextStyle(
                      fontFamily: KachavaTheme.serifFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: KachavaColors.primary)),
              Text(i18n.translateContent(menu.subtitle),
                  style: const TextStyle(fontSize: 11)),
              const SizedBox(height: 6),
              ...menu.courses.map((c) => Text(i18n.translateContent(c),
                  style: const TextStyle(fontSize: 11))),
              const SizedBox(height: 6),
              Text(i18n.translateContent(menu.sommelierPairing),
                  style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: KachavaColors.secondary)),
            ],
          ),
        ),
      ),
    );
  }
}
