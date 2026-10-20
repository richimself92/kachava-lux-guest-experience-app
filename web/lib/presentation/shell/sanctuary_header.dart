import 'package:flutter/material.dart';
import '../../application/sanctuary_controller.dart';
import '../../core/constants/screen_id.dart';
import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';

/// Sticky Luxury Header displaying `KACHAVA LUX`, dynamic Villa title/number,
/// and `EN | ES` language toggle.
class SanctuaryHeader extends StatelessWidget {
  const SanctuaryHeader({super.key, required this.controller});

  final SanctuaryController controller;

  @override
  Widget build(BuildContext context) {
    final screen = controller.currentScreen;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: KachavaColors.surface.withValues(alpha: 0.96),
        border: Border(
          bottom: BorderSide(
            color: KachavaColors.primaryContainer.withValues(alpha: 0.14),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _buildLeftBrandOrBack(screen)),
          _buildLocaleToggle(),
          const SizedBox(width: 8),
          _buildVillaMedallion(),
        ],
      ),
    );
  }

  Widget _buildLeftBrandOrBack(ScreenId screen) {
    final i18n = controller.i18n;
    final label = screen.isSubScreen
        ? i18n.t('Back to Sanctuary Home', 'Volver al Inicio')
        : i18n.t('Sanctuary Home', 'Inicio');
    final subLabel = screen.isSubScreen
        ? i18n.screenShortTitle(screen)
        : controller.stay.villaTitle.toUpperCase();
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: InkWell(
          key: const Key('header-home-or-back-btn'),
          onTap: () => controller.navigateTo(ScreenId.home),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (screen.isSubScreen)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.arrow_back,
                        size: 18, color: KachavaColors.primary),
                  ),
                Flexible(child: _buildBrandTitles(subLabel)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandTitles(String subLabel) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'KACHAVA LUX',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: KachavaTheme.serifFamily,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: KachavaColors.primary,
          ),
        ),
        Text(
          subLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: KachavaColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLocaleToggle() {
    final isEs = controller.isEs;
    final tip = isEs
        ? 'Idioma actual: Español (clic para Inglés)'
        : 'Current language: English (click for Español)';
    return Semantics(
      button: true,
      label: isEs ? 'ES | EN' : 'EN | ES',
      child: Tooltip(
        message: tip,
        child: InkWell(
          key: const Key('guest-locale-toggle-btn'),
          onTap: controller.toggleLocale,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: KachavaColors.surfaceContainer,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: KachavaColors.secondaryContainer),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLocaleSegment(!isEs ? '✓ EN' : 'EN', !isEs),
                _buildLocaleSegment(isEs ? '✓ ES' : 'ES', isEs),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocaleSegment(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: active ? KachavaColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: active ? Colors.white : KachavaColors.secondary,
        ),
      ),
    );
  }

  Widget _buildVillaMedallion() {
    final isProfile = controller.currentScreen == ScreenId.profile;
    final villaNum = controller.stay.villaNumber;
    return Semantics(
      button: true,
      label: 'Open Villa $villaNum Guest Profile & Keycard',
      child: Tooltip(
        message: 'Open Villa $villaNum Guest Profile & Keycard',
        child: InkWell(
          key: const Key('header-profile-medallion'),
          onTap: () => controller.navigateTo(ScreenId.profile),
          borderRadius: BorderRadius.circular(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'VILLA',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: KachavaColors.secondary,
                    ),
                  ),
                  Text(
                    villaNum,
                    style: const TextStyle(
                      fontFamily: KachavaTheme.serifFamily,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: KachavaColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 5),
              _buildMedallionAvatar(isProfile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedallionAvatar(bool isProfile) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: KachavaColors.primary,
        border: Border.all(
          color: isProfile
              ? KachavaColors.secondary
              : KachavaColors.secondaryContainer,
          width: isProfile ? 2.5 : 1.2,
        ),
      ),
      child: const Icon(
        Icons.diamond_outlined,
        size: 15,
        color: KachavaColors.onPrimaryContainer,
      ),
    );
  }
}
