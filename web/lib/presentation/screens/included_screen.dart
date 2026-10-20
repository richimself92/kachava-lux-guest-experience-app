import 'package:flutter/material.dart';
import '../../application/sanctuary_controller.dart';
import '../../core/constants/screen_id.dart';
import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';

/// Screen 4: Included Sanctuary Privileges (`included`).
class IncludedScreen extends StatelessWidget {
  const IncludedScreen({super.key, required this.controller});

  final SanctuaryController controller;

  @override
  Widget build(BuildContext context) {
    final selectedRitual = controller.stay.selectedSignaturePrivilege;
    final i18n = controller.i18n;
    return ListView(
      key: const Key('screen-included'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 84),
      children: [
        _buildZeroDueBanner(),
        const SizedBox(height: 14),
        _buildPrivilegeCard(
          title: i18n.t(
            'Sunrise Cenote Yoga & Artisanal Breakfast',
            'Yoga al Amanecer en Cenote y Desayuno Artesanal',
          ),
          subtitle: i18n.t(
            'Included · Daily 07:00 – 11:30 · No Reservation Required',
            'Incluido · Diario 07:00 – 11:30 · Sin Reservación',
          ),
          actionLabel: i18n.t('Reserve Sunrise Session', 'Reservar Sesión'),
          onTap: () => controller.showToast(
            'Sunrise Cenote Yoga reserved with Sanctuary Wellness Host.',
          ),
        ),
        _buildPrivilegeCard(
          title: i18n.t(
            'Mayan Hydrotherapy Circuit & Private Beach Cabana',
            'Circuito de Hidroterapia Maya y Cabaña de Playa',
          ),
          subtitle: i18n.t(
            'Included · Reserved Oceanfront Cabana',
            'Incluido · Cabaña Privada Frente al Mar',
          ),
          actionLabel:
              i18n.t('Reserve Cabana & Circuit', 'Reservar Cabaña y Spa'),
          onTap: () => controller.showToast(
            'Mayan Hydrotherapy Circuit & Beach Cabana confirmed.',
          ),
        ),
        _buildPrivilegeCard(
          title: i18n.t(
            'Kachava Caribe · Catamaran & Galeon 470 Sky Sail',
            'Kachava Caribe · Catamarán y Yate Galeon 470 Sky',
          ),
          subtitle: i18n.t(
            'Included · 4-Hour Private Cruise (\$2,000 USD Value)',
            'Incluido · Paseo Privado de 4 Horas (Valor \$2,000 USD)',
          ),
          actionLabel: i18n.t('Modify Yacht Charter →', 'Personalizar Yate →'),
          onTap: () => controller.navigateTo(ScreenId.yacht),
        ),
        _buildPrivilegeCard(
          title: i18n.t(
            'Four-Course Culinary Team Dinner',
            'Cena Privada de 4 Tiempos en tu Villa',
          ),
          subtitle: i18n.t(
            'Included · In-Villa Sommelier Paired Degustation',
            'Incluido · Degustación con Maridaje en tu Villa',
          ),
          actionLabel: i18n.t('Custom Menu →', 'Elegir Menú →'),
          onTap: () => controller.navigateTo(ScreenId.dining),
        ),
        const SizedBox(height: 12),
        _buildBespokeRitualSwitcher(selectedRitual),
      ],
    );
  }

  Widget _buildZeroDueBanner() {
    final i18n = controller.i18n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KachavaColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KachavaColors.secondaryContainer),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i18n.t('ALL-INCLUSIVE SANCTUARY TIER',
                      'BENEFICIOS TODO INCLUIDO'),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                    color: KachavaColors.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  i18n.t(
                    'Zero hidden fees · Fully prepaid privilege folio',
                    'Sin cargos ocultos · Beneficios 100% incluidos',
                  ),
                  style: const TextStyle(
                    fontFamily: KachavaTheme.serifFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: KachavaColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            i18n.t('\$0.00 Due', '\$0.00'),
            style: const TextStyle(
              fontFamily: KachavaTheme.serifFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: KachavaColors.confirmedGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivilegeCard({
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: KachavaTheme.serifFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: KachavaColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onTap,
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBespokeRitualSwitcher(String selectedRitual) {
    final i18n = controller.i18n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              i18n.t(
                'BESPOKE SIGNATURE RITUAL SELECTION',
                'ELIGE TU BENEFICIO ESPECIAL INCLUIDO',
              ),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: KachavaColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            _buildRitualOption(
              value: 'massage',
              selectedRitual: selectedRitual,
              label: i18n.t(
                '2 × 60-Min In-Villa Chukum & Obsidian Massages',
                '2 × Masajes de 60 Min en tu Villa (Chukum y Obsidiana)',
              ),
            ),
            _buildRitualOption(
              value: 'golf',
              selectedRitual: selectedRitual,
              label: i18n.t(
                '2 × Rounds at PGA Riviera Maya Championship Golf',
                '2 × Rondas de Golf en PGA Riviera Maya',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRitualOption({
    required String value,
    required String selectedRitual,
    required String label,
  }) {
    final isSelected = selectedRitual == value;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
        size: 18,
        color: isSelected ? KachavaColors.primary : KachavaColors.secondary,
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      onTap: () => controller.switchSignaturePrivilege(value),
    );
  }
}
