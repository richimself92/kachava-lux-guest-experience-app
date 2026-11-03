import 'package:flutter/material.dart';

import '../../application/portal_controller.dart';
import '../../core/i18n/l10n.dart';
import '../../core/platform/photo_picker.dart';
import '../../core/pwa/install_prompt_port.dart';
import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';
import '../../domain/journey.dart';
import '../common/labels.dart';
import '../common/widgets.dart';
import '../home/home_tab.dart';
import '../host/host_tab.dart';
import '../requests/requests_tab.dart';
import '../services/service_actions.dart';
import '../services/services_tab.dart';
import 'access_restricted_screen.dart';
import 'reconnecting_indicator.dart';
import 'refresh_button.dart';

/// Root screen: access screen, loading skeleton or the 4-tab portal.
class PortalRoot extends StatelessWidget {
  const PortalRoot({
    super.key,
    required this.controller,
    required this.installPrompt,
    required this.photoPicker,
  });

  final PortalController controller;
  final InstallPromptPort installPrompt;
  final PhotoPicker photoPicker;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => switch (controller.phase) {
        PortalPhase.loading => LoadingSkeleton(controller: controller),
        PortalPhase.ready => PortalShell(
            controller: controller,
            installPrompt: installPrompt,
            photoPicker: photoPicker,
          ),
        final phase =>
          AccessRestrictedScreen(l10n: controller.l10n, phase: phase),
      },
    );
  }
}

enum PortalTab { home, services, requests, host }

class PortalShell extends StatefulWidget {
  const PortalShell({
    super.key,
    required this.controller,
    required this.installPrompt,
    required this.photoPicker,
  });

  final PortalController controller;
  final InstallPromptPort installPrompt;
  final PhotoPicker photoPicker;

  @override
  State<PortalShell> createState() => _PortalShellState();
}

class _PortalShellState extends State<PortalShell> {
  PortalTab _tab = PortalTab.home;
  ServicesFocus? _focus;
  String? _hostPrefill;

  PortalController get _c => widget.controller;

  void _select(PortalTab tab) {
    setState(() {
      _tab = tab;
      if (tab != PortalTab.services) _focus = null;
    });
    if (tab == PortalTab.host) _c.markHostSeen();
    if (tab == PortalTab.home) _c.refresh();
  }

  void _openTask(JourneyTask task) {
    if (task.core != null) {
      openCoreTask(context, _c, task);
      return;
    }
    setState(() {
      _focus = ServicesFocus(
          section: task.section!, title: taskTitle(_c.l10n, task));
      _tab = PortalTab.services;
    });
  }

  void _askHost([String? about]) {
    setState(() => _hostPrefill = about);
    _select(PortalTab.host);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _c.l10n;
    final stay = _c.stay!;
    return Scaffold(
      backgroundColor: KachavaColors.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: KachavaColors.surface,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Text(stay.villaName.isEmpty ? 'Kachava Lux' : stay.villaName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontFamily: KachavaTheme.serifFamily,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: KachavaColors.primary)),
        actions: [
          RefreshButton(controller: _c),
          LanguageToggle(controller: _c),
          const SizedBox(width: 8),
        ],
        bottom: _c.isReconnecting
            ? PreferredSize(
                preferredSize: const Size.fromHeight(32),
                child: ReconnectingIndicator(label: l10n.reconnecting),
              )
            : null,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: IndexedStack(
          index: _tab.index,
          children: [
            HomeTab(
                controller: _c,
                installPrompt: widget.installPrompt,
                onOpenTask: _openTask),
            ServicesTab(
              controller: _c,
              focus: _focus,
              onBack: () => _select(PortalTab.home),
              onAskHost: _askHost,
            ),
            RequestsTab(
              controller: _c,
              onBrowse: () => _select(PortalTab.services),
              onAskHost: _askHost,
            ),
            HostTab(
                controller: _c,
                photoPicker: widget.photoPicker,
                prefill: _hostPrefill),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        key: const Key('portal-tabs'),
        selectedIndex: _tab.index,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) => _select(PortalTab.values[i]),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_outlined), label: l10n.tabHome),
          NavigationDestination(
              icon: const Icon(Icons.room_service_outlined),
              label: l10n.tabServices),
          NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              label: l10n.tabRequests),
          NavigationDestination(
            icon: Badge(
              key: const Key('host-unread-dot'),
              isLabelVisible: _c.hasUnreadHostMessage,
              smallSize: 8,
              child: const Icon(Icons.support_agent),
            ),
            label: l10n.tabHost,
          ),
        ],
      ),
    );
  }
}

/// EN | ES, always in the header; 48px targets; remembered on the device.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key, required this.controller});
  final PortalController controller;

  @override
  Widget build(BuildContext context) {
    Widget option(Lang lang, String label) {
      final selected = controller.lang == lang;
      return Semantics(
        selected: selected,
        button: true,
        label: label,
        excludeSemantics: true,
        child: TextButton(
          key: Key('lang-${lang.name}'),
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            foregroundColor: selected
                ? KachavaColors.primary
                : KachavaColors.onSurfaceVariant,
            textStyle: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500),
          ),
          onPressed: () => controller.setLang(lang),
          child: Text(label),
        ),
      );
    }

    return Semantics(
      label: controller.l10n.languageToggle,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        option(Lang.en, 'EN'),
        const Text('|',
            style:
                TextStyle(fontSize: 15, color: KachavaColors.onSurfaceVariant)),
        option(Lang.es, 'ES'),
      ]),
    );
  }
}

/// First load: skeletons in the final layout, never a lone spinner.
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key, required this.controller});
  final PortalController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = controller.l10n;
    return Scaffold(
      key: const Key('portal-loading'),
      backgroundColor: KachavaColors.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: KachavaColors.surface,
        title: const SkeletonBox(width: 160, height: 20),
        actions: [
          LanguageToggle(controller: controller),
          const SizedBox(width: 8)
        ],
      ),
      body: Semantics(
        label: l10n.loading,
        liveRegion: true,
        child: PageWidth(
          maxWidth: 720,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (controller.isReconnecting)
                ReconnectingIndicator(label: l10n.reconnecting),
              const SkeletonBox(width: 220, height: 18),
              const SizedBox(height: 16),
              for (var i = 0; i < 3; i++) ...[
                const SkeletonBox(height: 52, radius: 16),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
