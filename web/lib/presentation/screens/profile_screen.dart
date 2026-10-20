import 'package:flutter/material.dart';
import '../../application/sanctuary_controller.dart';
import '../../core/constants/screen_id.dart';
import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';

/// Screen 13: Guest Profile, Wi-Fi & Stay Summary (`profile`).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.controller});

  final SanctuaryController controller;

  @override
  Widget build(BuildContext context) {
    final stay = controller.stay;
    final prefs = controller.preferences;
    final i18n = controller.i18n;

    return ListView(
      key: const Key('screen-profile'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 84),
      children: [
        _buildGuestReservationSummaryCard(stay),
        const SizedBox(height: 10),
        _buildWifiCard(stay.wifiSsid, stay.wifiPassphrase),
        const SizedBox(height: 10),
        _buildDietaryAndAllergyCard(prefs.dietaryRegimen, prefs.allergyAlerts),
        const SizedBox(height: 10),
        _buildPaymentAndEmergencyCard(
            stay.folioCardLabel, stay.privateHostName),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          key: const Key('profile-open-switcher-btn'),
          onPressed: () => controller.setDrawerOpen(true),
          icon: const Icon(Icons.grid_view_rounded, size: 16),
          label: Text(
              i18n.t('OPEN ALL 13 SANCTUARY SCREENS', 'VER LAS 13 PANTALLAS')),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: KachavaColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () => controller.navigateTo(ScreenId.concierge),
          child: Text(i18n.t('CONTACT CONCIERGE HOST ADMIN',
              'CONTACTAR A CONCIERGE HOST ADMIN')),
        ),
      ],
    );
  }

  Widget _buildGuestReservationSummaryCard(dynamic stay) {
    final i18n = controller.i18n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: KachavaColors.primary,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    i18n.t(
                      'GUEST & VILLA RESERVATION · VILLA ${stay.villaNumber}',
                      'RESERVACIÓN Y HUÉSPED · VILLA ${stay.villaNumber}',
                    ),
                    style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: KachavaColors.secondary),
                  ),
                  Text(
                    '${stay.guestNames} · ${stay.villaTitle}',
                    style: const TextStyle(
                        fontFamily: KachavaTheme.serifFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: KachavaColors.primary),
                  ),
                  Text('${stay.stayDates} · ${stay.celebrationTitle}',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWifiCard(String ssid, String pass) {
    final i18n = controller.i18n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.wifi, color: KachavaColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    i18n.t('VILLA WI-FI NETWORK & PASSCODE',
                        'RED WI-FI Y CONTRASEÑA DE LA VILLA'),
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: KachavaColors.secondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    i18n.t(
                      'Wi-Fi Sanctuary Network: $ssid (Passphrase: $pass)',
                      'Red Wi-Fi: $ssid (Contraseña: $pass)',
                    ),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: KachavaColors.onSurface),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              key: const Key('profile-copy-wifi-btn'),
              onPressed: () => controller.showToast(
                i18n.t('Wi-Fi passcode "$pass" copied.',
                    'Contraseña Wi-Fi "$pass" copiada.'),
              ),
              icon: const Icon(Icons.copy, size: 15),
              label: Text(i18n.t('Copy', 'Copiar')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDietaryAndAllergyCard(String dietary, String allergies) {
    final i18n = controller.i18n;
    final cleanAllergy = allergies.trim();
    final hasAllergy = cleanAllergy.isNotEmpty && cleanAllergy != 'None';
    final allergyLabel = hasAllergy
        ? cleanAllergy
        : i18n.t('No allergies registered', 'Sin alergias registradas');
    final dietLabel = dietary.trim().isEmpty
        ? i18n.t('Standard / Not specified', 'Estándar / Sin especificar')
        : dietary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              i18n.t('REGISTERED DIETARY & ALLERGY SUMMARY',
                  'RESUMEN DE DIETA Y ALERGIAS'),
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: KachavaColors.secondary),
            ),
            const SizedBox(height: 6),
            Text(
              '${i18n.t("Dietary Profile", "Perfil Alimenticio")}: $dietLabel',
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: KachavaColors.primary),
            ),
            const SizedBox(height: 6),
            Text(
              '${i18n.t("Allergies", "Alergias")}: $allergyLabel',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: hasAllergy
                    ? KachavaColors.errorRed
                    : KachavaColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('profile-edit-preferences-btn'),
              onPressed: () => controller.navigateTo(ScreenId.personalize),
              icon: const Icon(Icons.tune, size: 16),
              label: Text(
                i18n.t('Edit Preferences & Allergies',
                    'Editar Preferencias y Alergias'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentAndEmergencyCard(String cardLabel, String hostName) {
    final i18n = controller.i18n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              i18n.t(
                '24/7 Sanctuary Security & Medical Escort · Host: $hostName (+1 415-890-4412)',
                'Seguridad y Asistencia 24/7 · Anfitrión: $hostName (+1 415-890-4412)',
              ),
              style: const TextStyle(fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}
