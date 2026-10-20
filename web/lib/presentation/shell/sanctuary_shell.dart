import 'package:flutter/material.dart';
import '../../application/sanctuary_controller.dart';
import '../../core/constants/screen_id.dart';
import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';
import '../screens/concierge_screen.dart';
import '../screens/departure_screen.dart';
import '../screens/dining_screen.dart';
import '../screens/explore_screen.dart';
import '../screens/home_screen.dart';
import '../screens/included_screen.dart';
import '../screens/midstay_screen.dart';
import '../screens/personalize_screen.dart';
import '../screens/philosophy_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/stock_villa_screen.dart';
import '../screens/transport_screen.dart';
import '../screens/yacht_screen.dart';
import 'sanctuary_bottom_nav.dart';
import 'sanctuary_header.dart';
import 'screen_switcher_drawer.dart';

/// Adaptive Sanctuary Shell (`< 768px` exact Mobile canvas, `>= 768px` centered
/// responsive canvas with `maxWidth: 960` and `TextScaler.linear(1.18)`).
class SanctuaryShell extends StatelessWidget {
  const SanctuaryShell({super.key, required this.controller});

  final SanctuaryController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.isUuidValid) {
          return _buildAccessRestrictedScreen();
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 768;
            if (!isDesktop) {
              return Scaffold(
                backgroundColor: KachavaColors.surface,
                body: SafeArea(child: _buildMobileCanvas(context)),
              );
            }
            final mediaQuery = MediaQuery.of(context);
            return Scaffold(
              backgroundColor: KachavaColors.surfaceContainerLow,
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: KachavaColors.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(112, 88, 54, 0.08),
                          blurRadius: 50,
                        ),
                      ],
                    ),
                    child: MediaQuery(
                      data: mediaQuery.copyWith(
                        textScaler: const TextScaler.linear(1.18),
                      ),
                      child: SafeArea(
                        child: _buildMobileCanvas(context, isDesktop: true),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMobileCanvas(BuildContext context, {bool isDesktop = false}) {
    final screenWidget = _buildCurrentScreen();
    return Stack(
      key: const Key('sanctuary-mobile-shell'),
      children: [
        Column(
          children: [
            SanctuaryHeader(controller: controller),
            if (controller.isReadOnly) _buildCheckedOutBanner(),
            if (controller.activeToastMessage != null) _buildToastBanner(),
            Expanded(
              child: isDesktop
                  ? Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 960),
                        child: screenWidget,
                      ),
                    )
                  : screenWidget,
            ),
            Container(
              width: double.infinity,
              color: KachavaColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              alignment: Alignment.centerRight,
              child: _buildPrototypeSwitcherPill(),
            ),
            SanctuaryBottomNav(controller: controller),
          ],
        ),
        if (controller.isDrawerOpen)
          Positioned.fill(
            child: ScreenSwitcherDrawer(controller: controller),
          ),
      ],
    );
  }

  Widget _buildCheckedOutBanner() {
    final text = controller.i18n.t(
      'CHECKED OUT — Read-Only Residency Archive (Mutations Locked)',
      'CHECK-OUT COMPLETADO — Archivo de Estancia de Solo Lectura',
    );
    return Container(
      key: const Key('checked-out-readonly-banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: KachavaColors.surfaceContainerHigh,
      child: Row(
        children: [
          const Icon(Icons.lock_outline,
              size: 15, color: KachavaColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: KachavaColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToastBanner() {
    return Container(
      key: const Key('sanctuary-toast-banner'),
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: KachavaColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              size: 16, color: KachavaColors.secondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              controller.activeToastMessage ?? '',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ),
          Semantics(
            button: true,
            label: 'Dismiss notification',
            child: IconButton(
              tooltip: 'Dismiss notification',
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: const EdgeInsets.all(6),
              onPressed: controller.clearToast,
              icon: const Icon(Icons.close, size: 16, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrototypeSwitcherPill() {
    final label = controller.i18n.t('all screens', 'todas las pantallas');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('open-screen-switcher-btn'),
        onTap: () => controller.setDrawerOpen(true),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xD91C1917),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: KachavaColors.secondaryContainer),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.grid_view_rounded,
                  size: 12, color: KachavaColors.secondaryContainer),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (controller.currentScreen) {
      case ScreenId.home:
        return HomeScreen(controller: controller);
      case ScreenId.transport:
        return TransportScreen(controller: controller);
      case ScreenId.personalize:
        return PersonalizeScreen(controller: controller);
      case ScreenId.included:
        return IncludedScreen(controller: controller);
      case ScreenId.explore:
        return ExploreScreen(controller: controller);
      case ScreenId.yacht:
        return YachtScreen(controller: controller);
      case ScreenId.dining:
        return DiningScreen(controller: controller);
      case ScreenId.stockVilla:
        return StockVillaScreen(controller: controller);
      case ScreenId.concierge:
        return ConciergeScreen(controller: controller);
      case ScreenId.midstay:
        return MidStayScreen(controller: controller);
      case ScreenId.departure:
        return DepartureScreen(controller: controller);
      case ScreenId.philosophy:
        return PhilosophyScreen(controller: controller);
      case ScreenId.profile:
        return ProfileScreen(controller: controller);
    }
  }

  Widget _buildAccessRestrictedScreen() {
    return Scaffold(
      backgroundColor: KachavaColors.surfaceContainerLow,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _buildRestrictedCardBody(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestrictedCardBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.support_agent, size: 44, color: KachavaColors.primary),
        const SizedBox(height: 12),
        const Text(
          'Acceso Restringido — ID de Huésped Obligatorio / Access Restricted — Guest ID Required',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: KachavaTheme.serifFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: KachavaColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          controller.authErrorMessage ??
              'Para ingresar al Portal de Huéspedes es obligatorio utilizar un enlace de invitación válido con ?guestId=<uuid>. / A valid invitation link with ?guestId=<uuid> is required to access the Sanctuary Portal.',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 13, color: KachavaColors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        const Text(
          'Dedicated Concierge: HOST ADMIN · +1 (415) 890-4412',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: KachavaColors.secondary),
        ),
      ],
    );
  }
}
