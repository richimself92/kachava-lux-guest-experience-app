import 'package:flutter/material.dart';
import '../../application/sanctuary_controller.dart';
import '../../core/constants/screen_id.dart';
import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';

/// Modal Drawer allowing instant jump to any of the 13 experience screens.
class ScreenSwitcherDrawer extends StatelessWidget {
  const ScreenSwitcherDrawer({super.key, required this.controller});

  final SanctuaryController controller;

  static const List<ScreenId> _orderedScreens = [
    ScreenId.home,
    ScreenId.transport,
    ScreenId.personalize,
    ScreenId.stockVilla,
    ScreenId.explore,
    ScreenId.yacht,
    ScreenId.dining,
    ScreenId.concierge,
    ScreenId.midstay,
    ScreenId.departure,
    ScreenId.profile,
    ScreenId.philosophy,
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;
    return Container(
      color: Colors.black54,
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: BoxConstraints(maxWidth: isDesktop ? 680 : 448),
        decoration: const BoxDecoration(
          color: KachavaColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: _orderedScreens
                      .map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _buildScreenTile(s),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final i18n = controller.i18n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: KachavaColors.surfaceContainerLow,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          bottom: BorderSide(color: KachavaColors.surfaceContainerHighest),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i18n.t('Sanctuary Screen Switcher', 'Menú de Pantallas'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: KachavaTheme.serifFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: KachavaColors.primary,
                  ),
                ),
                Text(
                  i18n.t('13 INTERACTIVE MODULES', '13 MÓDULOS INTERACTIVOS'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: KachavaColors.mutedMetadata,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('close-screen-switcher-btn'),
            tooltip: i18n.t('Close screen switcher', 'Cerrar menú'),
            onPressed: () => controller.setDrawerOpen(false),
            icon: const Icon(Icons.close, color: KachavaColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenTile(ScreenId screen) {
    final isActive = controller.currentScreen == screen;
    final i18n = controller.i18n;
    return InkWell(
      key: Key('drawer-screen-${screen.wireId}'),
      onTap: () => controller.navigateTo(screen),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? KachavaColors.primary
              : KachavaColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? KachavaColors.primary
                : KachavaColors.surfaceContainerHighest,
          ),
        ),
        child: Row(
          children: [
            Icon(
              screen.icon,
              size: 18,
              color: isActive
                  ? KachavaColors.onPrimaryContainer
                  : KachavaColors.secondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    i18n.screenTitle(screen),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : KachavaColors.primary,
                    ),
                  ),
                  Text(
                    i18n.screenSubtitle(screen),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isActive
                          ? Colors.white70
                          : KachavaColors.mutedMetadata,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
