import 'package:flutter/material.dart';
import '../../application/sanctuary_controller.dart';
import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';

/// Screen 3: Stay Personalization (`personalize`).
class PersonalizeScreen extends StatefulWidget {
  const PersonalizeScreen({super.key, required this.controller});

  final SanctuaryController controller;

  @override
  State<PersonalizeScreen> createState() => _PersonalizeScreenState();
}

class _PersonalizeScreenState extends State<PersonalizeScreen> {
  late String _pillow;
  late String _scent;
  late String _dietary;
  late String _housekeepingCadence;
  late final TextEditingController _allergiesCtrl;
  late final TextEditingController _notesCtrl;

  static String _cleanAllergy(String raw) {
    final v = raw.trim();
    return (v.isEmpty || v == 'None') ? '' : v;
  }

  @override
  void initState() {
    super.initState();
    final prefs = widget.controller.preferences;
    _pillow = prefs.pillowType;
    _scent = prefs.scentProfile;
    _dietary = prefs.dietaryRegimen;
    _housekeepingCadence = prefs.housekeepingCadence;
    _allergiesCtrl =
        TextEditingController(text: _cleanAllergy(prefs.allergyAlerts));
    _notesCtrl = TextEditingController(text: prefs.occasionNote.trim());
  }

  @override
  void dispose() {
    _allergiesCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveCuration() async {
    final current = widget.controller.preferences;
    await widget.controller.savePersonalization(
      current.copyWith(
        pillowType: _pillow,
        scentProfile: _scent,
        dietaryRegimen: _dietary,
        allergyAlerts: _allergiesCtrl.text.trim(),
        occasionNote: _notesCtrl.text.trim(),
        housekeepingCadence: _housekeepingCadence,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = widget.controller.i18n;
    final villaNum = widget.controller.stay.villaNumber;
    return Column(
      key: const Key('screen-personalize'),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            children: [
              Text(
                i18n.t('STAY PREFERENCES & ALLERGIES',
                    'PREFERENCIAS DE ESTANCIA Y ALERGIAS'),
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: KachavaColors.secondary),
              ),
              const SizedBox(height: 4),
              Text(
                i18n.t('Personalize Your Villa $villaNum Stay',
                    'Personaliza tu Estancia en Villa $villaNum'),
                style: const TextStyle(
                    fontFamily: KachavaTheme.serifFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: KachavaColors.primary),
              ),
              const SizedBox(height: 12),
              _buildPillowAndScentCard(),
              const SizedBox(height: 12),
              _buildDietaryAndAllergyCard(),
              const SizedBox(height: 12),
              _buildHousekeepingAndNotesCard(),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          color: KachavaColors.surface,
          child: ElevatedButton(
            key: const Key('personalize-save-btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: KachavaColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _saveCuration,
            child: Text(
                i18n.t('SAVE MY PREFERENCES ✓', 'GUARDAR MIS PREFERENCIAS ✓')),
          ),
        ),
      ],
    );
  }

  Widget _buildPillowAndScentCard() {
    final i18n = widget.controller.i18n;
    const pillows = ['Goose Down', 'Memory Foam', 'Hypoallergenic Firm'];
    const scents = [
      'Copal & Amber',
      'Orange Blossom',
      'White Cedar',
      'Fragrance-Free'
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              i18n.t('Room Comfort & Welcome Scent',
                  'Confort de Habitación y Aroma de Bienvenida'),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: KachavaColors.secondary),
            ),
            const SizedBox(height: 8),
            Text(i18n.t('Pillow Preference', 'Preferencia de Almohada'),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: KachavaColors.primary)),
            const SizedBox(height: 6),
            _buildChoiceWrap(
                pillows, _pillow, (val) => setState(() => _pillow = val)),
            const Divider(height: 18),
            Text(i18n.t('Welcome Villa Scent', 'Aroma de Bienvenida en Villa'),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: KachavaColors.primary)),
            const SizedBox(height: 6),
            _buildChoiceWrap(
                scents, _scent, (val) => setState(() => _scent = val)),
          ],
        ),
      ),
    );
  }

  Widget _buildDietaryAndAllergyCard() {
    final i18n = widget.controller.i18n;
    const diets = [
      'Standard',
      'Pescatarian',
      'Vegetarian',
      'Vegan',
      'Gluten-Free'
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              i18n.t('Dietary & Allergies', 'Dieta y Alergias'),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: KachavaColors.secondary),
            ),
            const SizedBox(height: 8),
            Text(i18n.t('Dietary Profile', 'Perfil Alimenticio'),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: KachavaColors.primary)),
            const SizedBox(height: 6),
            _buildChoiceWrap(
                diets, _dietary, (val) => setState(() => _dietary = val)),
            const SizedBox(height: 12),
            TextField(
              key: const Key('personalize-allergies-input'),
              controller: _allergiesCtrl,
              decoration: InputDecoration(
                labelText: i18n.t('Food Allergies & Restrictions',
                    'Alergias y Restricciones Alimentarias'),
                hintText: i18n.t(
                  'e.g. Shellfish, tree nuts, lactose (leave blank if none)',
                  'Ej. Mariscos, nueces, lactosa (dejar vacío si no aplica)',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHousekeepingAndNotesCard() {
    final i18n = widget.controller.i18n;
    const schedules = [
      '09:00 AM – 11:00 AM',
      '12:00 PM – 02:00 PM',
      '03:00 PM – 05:00 PM',
      'Evening Service (07:00 PM)',
      'On Request',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              i18n.t(
                'Preferred Housekeeping Schedule',
                'Horario Preferido de Limpieza',
              ),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: KachavaColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: schedules.map((slot) {
                return ChoiceChip(
                  label: Text(
                    i18n.optionLabel(slot),
                    style: const TextStyle(fontSize: 11),
                  ),
                  selected: _housekeepingCadence == slot,
                  onSelected: (_) =>
                      setState(() => _housekeepingCadence = slot),
                );
              }).toList(),
            ),
            const Divider(height: 18),
            Text(
              i18n.t(
                'Special Villa Notes & Morning Coffee',
                'Notas Especiales y Café Matutino',
              ),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: KachavaColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('personalize-notes-input'),
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: i18n.t('Special Requests & Schedule',
                    'Solicitudes Especiales y Horarios'),
                hintText: i18n.t(
                  'e.g. Coffee at 8:00 AM, baby crib, afternoon housekeeping',
                  'Ej. Café 8:00 AM, cuna, limpieza por la tarde',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceWrap(
      List<String> options, String selected, ValueChanged<String> onSelected) {
    final i18n = widget.controller.i18n;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: options.map((opt) {
        return ChoiceChip(
          label:
              Text(i18n.optionLabel(opt), style: const TextStyle(fontSize: 11)),
          selected: selected == opt,
          onSelected: (_) => onSelected(opt),
        );
      }).toList(),
    );
  }
}
