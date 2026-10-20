import 'package:flutter/material.dart';
import '../../application/sanctuary_controller.dart';
import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';

/// Screen 12: The Architecture of Stillness (`philosophy`).
class PhilosophyScreen extends StatelessWidget {
  const PhilosophyScreen({super.key, required this.controller});

  final SanctuaryController controller;

  @override
  Widget build(BuildContext context) {
    final i18n = controller.i18n;
    return ListView(
      key: const Key('screen-philosophy'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 84),
      children: [
        Text(
          i18n.t(
            'KACHAVA ARCHITECTURE TEAM · 6 MIN READ',
            'DISEÑO Y NATURALEZA · LECTURA DE 6 MIN',
          ),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: KachavaColors.secondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          i18n.t(
            'The Architecture of Stillness',
            'Arquitectura y Naturaleza del Resort',
          ),
          style: const TextStyle(
            fontFamily: KachavaTheme.serifFamily,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: KachavaColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        _buildChapterCard(
          eyebrow: i18n.t(
            'CHAPTER 01 · ANCESTRAL MATERIALITY',
            'CAPÍTULO 01 · MATERIALES NATURALES',
          ),
          title: i18n.t(
            'Chukum Plaster, Rammed Earth & Mayan Zapote Timber',
            'Estuco de Chukum, Tierra Compactada y Madera de Zapote',
          ),
          body: i18n.t(
            'Hand-troweled limestone mixed with endemic Chukum tree resin creates a living thermal mass that cools each villa naturally to 23°C alongside open-air cenote cross-ventilation.',
            'La piedra caliza mezclada con resina natural de árbol de Chukum mantiene cada villa fresca a 23°C de forma natural junto con la brisa de los cenotes.',
          ),
        ),
        _buildBiosphereCovenantCard(),
        _buildChapterCard(
          eyebrow: i18n.t(
            'CHAPTER 03 · KITCHEN AS ALTAR',
            'CAPÍTULO 03 · INGREDIENTES LOCALES',
          ),
          title: i18n.t(
            'Flavors Born of Fire, Milpa & Underground Pib',
            'Sabores de Leña, Milpa Maya y Horno Tradicional',
          ),
          body: i18n.t(
            'Every ingredient in each villa is harvested within 40 miles from Mayan milpa cooperatives and sacred Melipona bee sanctuaries.',
            'Cada ingrediente que disfrutas en tu villa proviene de cooperativas mayas locales y santuarios de abeja Melipona a menos de 60 km.',
          ),
        ),
      ],
    );
  }

  Widget _buildChapterCard({
    required String eyebrow,
    required String title,
    required String body,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: KachavaColors.secondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontFamily: KachavaTheme.serifFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: KachavaColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(body, style: const TextStyle(fontSize: 12.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildBiosphereCovenantCard() {
    final i18n = controller.i18n;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KachavaColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            i18n.t(
              'CHAPTER 02 · THE SIAN KA\'AN COVENANT (1% BIOSPHERE)',
              'CAPÍTULO 02 · RESERVA DE LA BIÓSFERA SIAN KA\'AN',
            ),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: KachavaColors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            i18n.t(
              '1,820 ha Preserved Forest · 34 Hives Melipona Bee Colonies',
              '1,820 ha de Selva Protegida · 34 Colmenas de Abeja Melipona',
            ),
            style: const TextStyle(
              fontFamily: KachavaTheme.serifFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
