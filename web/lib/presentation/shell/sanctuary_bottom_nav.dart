import 'package:flutter/material.dart';
import '../../application/sanctuary_controller.dart';
import '../../core/constants/screen_id.dart';
import '../../core/theme/kachava_colors.dart';

/// Persistent 4-Tab Bottom Navigation Bar:
/// `Sanctuary` (`home`), `Experiences` (`explore`), `Concierge` (`concierge`), `Profile` (`profile`).
class SanctuaryBottomNav extends StatelessWidget {
  const SanctuaryBottomNav({super.key, required this.controller});

  final SanctuaryController controller;

  int _resolveActiveTabIndex(ScreenId screen) {
    switch (screen) {
      case ScreenId.home:
      case ScreenId.transport:
      case ScreenId.personalize:
      case ScreenId.included:
      case ScreenId.stockVilla:
      case ScreenId.midstay:
      case ScreenId.departure:
        return 0;
      case ScreenId.explore:
      case ScreenId.yacht:
      case ScreenId.dining:
      case ScreenId.philosophy:
        return 1;
      case ScreenId.concierge:
        return 2;
      case ScreenId.profile:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _resolveActiveTabIndex(controller.currentScreen);
    final i18n = controller.i18n;
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: KachavaColors.surface.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(
            color: KachavaColors.primaryContainer.withValues(alpha: 0.16),
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(112, 88, 54, 0.06),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabItem(
            key: const Key('bottom-nav-home'),
            label: i18n.navSanctuary,
            icon: Icons.villa_outlined,
            activeIcon: Icons.villa,
            isActive: activeIndex == 0,
            onTap: () => controller.navigateTo(ScreenId.home),
          ),
          _buildTabItem(
            key: const Key('bottom-nav-explore'),
            label: i18n.navExperiences,
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore,
            isActive: activeIndex == 1,
            onTap: () => controller.navigateTo(ScreenId.explore),
          ),
          _buildTabItem(
            key: const Key('bottom-nav-concierge'),
            label: i18n.navConcierge,
            icon: Icons.support_agent_outlined,
            activeIcon: Icons.support_agent,
            isActive: activeIndex == 2,
            hasBadgeDot: true,
            onTap: () => controller.navigateTo(ScreenId.concierge),
          ),
          _buildTabItem(
            key: const Key('bottom-nav-profile'),
            label: i18n.navProfile,
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            isActive: activeIndex == 3,
            onTap: () => controller.navigateTo(ScreenId.profile),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required Key key,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required bool isActive,
    required VoidCallback onTap,
    bool hasBadgeDot = false,
  }) {
    final color =
        isActive ? KachavaColors.primary : KachavaColors.mutedMetadata;
    return Expanded(
      child: Semantics(
        button: true,
        selected: isActive,
        label: '$label tab',
        child: Tooltip(
          message: label,
          child: InkWell(
            key: key,
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(isActive ? activeIcon : icon, size: 22, color: color),
                    if (hasBadgeDot)
                      Positioned(
                        right: -3,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: KachavaColors.secondaryContainer,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: KachavaColors.surface,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 1.1,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
