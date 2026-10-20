import 'package:flutter/material.dart';
import '../../application/sanctuary_controller.dart';
import '../../core/constants/screen_id.dart';
import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';
import '../../domain/entities/stay_entities.dart';

/// Screen 1: Residency Home (`home`).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final SanctuaryController controller;

  @override
  Widget build(BuildContext context) {
    final stay = controller.stay;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;
        return _buildUnifiedLayout(stay, isDesktop: isDesktop);
      },
    );
  }

  Widget _buildUnifiedLayout(StaySummary stay, {required bool isDesktop}) {
    final i18n = controller.i18n;
    return SingleChildScrollView(
      key: const Key('screen-home'),
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 28 : 16,
        isDesktop ? 20 : 14,
        isDesktop ? 28 : 16,
        84,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeroCard(stay),
          const SizedBox(height: 12),
          _buildResidenceSummaryCard(stay),
          const SizedBox(height: 10),
          _buildStatusAndHostRow(stay),
          const SizedBox(height: 12),
          _buildPreArrivalSection(),
          const SizedBox(height: 12),
          _buildDuringStaySection(),
          const SizedBox(height: 12),
          _buildDepartureAndProfileSection(),
          const SizedBox(height: 12),
          ElevatedButton(
            key: const Key('home-explore-experiences-btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: KachavaColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => controller.navigateTo(ScreenId.explore),
            child: Text(
                i18n.t('EXPLORE EXPERIENCES →', 'EXPLORAR EXPERIENCIAS →')),
          ),
        ],
      ),
    );
  }

  String _transportSubtitle() {
    final t = controller.transport;
    final fn = t.flightNumber.trim();
    if (fn.isEmpty || fn == 'Pending' || fn == 'TBD') {
      return controller.i18n.t(
        'Not registered yet — Tap to enter your arrival flight',
        'Sin registrar — Toca para ingresar tu vuelo',
      );
    }
    final driver = t.assignedDriver.isEmpty ? 'HOST ADMIN' : t.assignedDriver;
    return '$fn · ${controller.i18n.t("Chauffeur", "Chofer")} $driver';
  }

  String _personalizeSubtitle() {
    final p = controller.preferences;
    final i18n = controller.i18n;
    if (p.pillowType.trim().isEmpty && p.dietaryRegimen.trim().isEmpty) {
      return i18n.t(
        'Tap to configure pillows, diet & allergies',
        'Toca para configurar almohadas, dieta y alergias',
      );
    }
    final pillow =
        i18n.optionLabel(p.pillowType.isEmpty ? 'Standard' : p.pillowType);
    final diet = i18n
        .optionLabel(p.dietaryRegimen.isEmpty ? 'Standard' : p.dietaryRegimen);
    return '$pillow · $diet';
  }

  String _larderSubtitle() {
    final count = controller.larderTotalCount;
    if (count == 0) {
      if (controller.submittedLarderItems.isNotEmpty) {
        final sentCount = controller.submittedLarderItems
            .fold<int>(0, (s, i) => s + i.quantity);
        final sentTotal = controller.submittedLarderItems
            .fold<int>(0, (s, i) => s + (i.priceUsd * i.quantity));
        return controller.i18n.t(
          '$sentCount items ordered · \$$sentTotal USD',
          '$sentCount artículos enviados · \$$sentTotal USD',
        );
      }
      return controller.i18n.t(
        'Chilled drinks, fresh fruit & snacks (0 items selected)',
        'Bebidas frías, frutas frescas y snacks (0 seleccionados)',
      );
    }
    return controller.i18n.t(
      '$count items selected · \$${controller.larderTotalAmount} USD',
      '$count artículos · \$${controller.larderTotalAmount} USD',
    );
  }

  Widget _buildPreArrivalSection() {
    final i18n = controller.i18n;
    return _buildStageSection(
      i18n.t('STEP 1 · BEFORE YOU ARRIVE', 'PASO 1 · ANTES DE TU LLEGADA'),
      [
        _stageTile(
            i18n.t('1. Flight & Airport Transfer',
                '1. Registrar Vuelo y Transporte'),
            _transportSubtitle(),
            Icons.flight_land,
            ScreenId.transport),
        _stageTile(
            i18n.t('2. Room Comfort, Diet & Allergies',
                '2. Confort, Aroma, Dieta y Alergias'),
            _personalizeSubtitle(),
            Icons.tune,
            ScreenId.personalize),
        _stageTile(
            i18n.t('3. Minibar & Welcome Drinks', '3. Pedir Bebidas y Minibar'),
            _larderSubtitle(),
            Icons.kitchen_outlined,
            ScreenId.stockVilla),
      ],
    );
  }

  Widget _buildDuringStaySection() {
    final i18n = controller.i18n;
    final diningEve =
        i18n.optionLabel(controller.diningReservation.selectedEvening);
    final diningTime =
        i18n.translateContent(controller.diningReservation.serviceTime);
    return _buildStageSection(
      i18n.t('STEP 2 · DURING YOUR STAY', 'PASO 2 · DURANTE TU ESTANCIA'),
      [
        _stageTile(
            i18n.t('4. Curated Excursions & Tours', '4. Excursiones y Tours'),
            i18n.t('Cenotes, Sian Ka\'an biosphere & local tours',
                'Cenotes, biósfera Sian Ka\'an y tours guiados'),
            Icons.explore_outlined,
            ScreenId.explore),
        _stageTile(
            i18n.t('5. Private Yacht Charter', '5. Reserva de Yate Privado'),
            '${controller.yachtCharter.vesselModel} · ${controller.yachtCharter.selectedDate}',
            Icons.sailing_outlined,
            ScreenId.yacht),
        _stageTile(
            i18n.t('6. In-Villa Private Chef Dining',
                '6. Cena con Chef Privado en Villa'),
            '$diningEve · $diningTime',
            Icons.restaurant_menu_outlined,
            ScreenId.dining),
        _stageTile(
            i18n.t('7. 24/7 Chat & Concierge Requests',
                '7. Chat 24/7 y Solicitudes a Concierge'),
            i18n.t('Live support, housekeeping & request tracker',
                'Atención inmediata, limpieza y solicitudes'),
            Icons.support_agent,
            ScreenId.concierge),
        _stageTile(
            i18n.t('8. Mid-Stay Check-In', '8. ¿Cómo va tu estancia?'),
            i18n.t('Rate your stay & share comments with your Host',
                'Califica tu estancia y comparte tus comentarios'),
            Icons.favorite_border,
            ScreenId.midstay),
      ],
    );
  }

  Widget _buildDepartureAndProfileSection() {
    final i18n = controller.i18n;
    return _buildStageSection(
      i18n.t('STEP 3 · SUMMARY, PROFILE & RESORT',
          'PASO 3 · RESUMEN, PERFIL Y RESORT'),
      [
        _stageTile(
            i18n.t('9. Stay & Departure Summary',
                '9. Resumen de Estancia y Salida'),
            i18n.t('Stay dates, requested activities & minibar summary',
                'Resumen de fechas, actividades solicitadas y minibar'),
            Icons.receipt_long_outlined,
            ScreenId.departure),
        _stageTile(
            i18n.t('10. Guest Profile, Wi-Fi & Allergies',
                '10. Mi Perfil, Wi-Fi y Alergias'),
            'Wi-Fi: ${controller.stay.wifiSsid} · ${controller.stay.guestNames}',
            Icons.person_outline,
            ScreenId.profile),
        _stageTile(
            i18n.t('11. Resort Architecture & Nature',
                '11. Arquitectura y Naturaleza del Resort'),
            i18n.t('Endemic botanicals, Chukum stone & Sian Ka\'an reserve',
                'Botánica endémica, piedra Chukum y reserva Sian Ka\'an'),
            Icons.spa_outlined,
            ScreenId.philosophy),
      ],
    );
  }

  Widget _buildHeroCard(StaySummary stay) {
    final i18n = controller.i18n;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [KachavaColors.primaryDeep, KachavaColors.primary],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(i18n.t('WELCOME TO KACHAVA LUX', 'BIENVENIDOS A KACHAVA LUX'),
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: KachavaColors.onPrimaryContainer)),
          const SizedBox(height: 6),
          Text('${stay.guestNames} — ${stay.celebrationTitle}',
              style: const TextStyle(
                  fontFamily: KachavaTheme.serifFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 4),
          Text(
            i18n.t(
                '${stay.primaryGuestName}, your Tulum stay in ${stay.villaTitle} awaits.',
                '${stay.primaryGuestName}, tu estancia en Tulum en ${stay.villaTitle} te espera.'),
            style: const TextStyle(
                fontSize: 12.5, color: KachavaColors.onPrimaryContainer),
          ),
        ],
      ),
    );
  }

  Widget _buildResidenceSummaryCard(StaySummary stay) {
    final i18n = controller.i18n;
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
                      Text(i18n.t('YOUR RESIDENCE', 'TU RESIDENCIA'),
                          style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: KachavaColors.secondary)),
                      Text(stay.villaTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: KachavaTheme.serifFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: KachavaColors.primary)),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('home-share-stay-btn'),
                  tooltip: i18n.t('Copy reservation magic link',
                      'Copiar enlace de reservación'),
                  onPressed: () => controller.showToast(
                      'Reservation Magic Link copied for ${stay.guestNames}.'),
                  icon: const Icon(Icons.ios_share,
                      size: 18, color: KachavaColors.primary),
                ),
              ],
            ),
            const Divider(height: 14),
            Text(
              i18n.t(
                  '${stay.stayDates} · ${stay.nights} nights · ${stay.guestsCount} guests',
                  '${stay.stayDates} · ${stay.nights} noches · ${stay.guestsCount} huéspedes'),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: KachavaColors.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusAndHostRow(StaySummary stay) {
    final i18n = controller.i18n;
    final statusTitle = switch (stay.lifecycleStatus) {
      StayLifecycleStatus.preArrival => i18n.t('PRE-ARRIVAL', 'PRE-LLEGADA'),
      StayLifecycleStatus.checkedOut => i18n.t('CHECKED OUT', 'FINALIZADA'),
      StayLifecycleStatus.activeStay =>
        i18n.t('ACTIVE STAY', 'ESTANCIA ACTIVA'),
    };
    return Row(
      children: [
        _buildStatCard(i18n.t('STAY STATUS', 'ESTADO DE ESTANCIA'), statusTitle,
            stay.suiteName),
        const SizedBox(width: 8),
        _buildStatCard(
            i18n.t('24/7 CONCIERGE', 'CONCIERGE 24/7'),
            stay.privateHostName,
            stay.privateHostRole,
            KachavaColors.confirmedGreen),
      ],
    );
  }

  Widget _buildStatCard(String label, String title, String subtitle,
      [Color? subtitleColor]) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: KachavaColors.secondary)),
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: KachavaColors.primary)),
              Text(subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: subtitleColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageSection(String header, List<Widget> tiles) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(header,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: KachavaColors.secondary)),
            const SizedBox(height: 4),
            ...tiles,
          ],
        ),
      ),
    );
  }

  Widget _stageTile(
      String title, String subtitle, IconData icon, ScreenId target) {
    return InkWell(
      key: Key('home-nav-${target.wireId}'),
      onTap: () => controller.navigateTo(target),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(icon, size: 17, color: KachavaColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: KachavaColors.primary)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 10.5, color: KachavaColors.mutedMetadata)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 17, color: KachavaColors.secondary),
          ],
        ),
      ),
    );
  }
}
