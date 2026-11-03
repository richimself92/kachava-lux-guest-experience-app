import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'application/sanctuary_controller.dart';
import 'core/audio/soundscape_port.dart';
import 'core/auth/guest_link_resolver.dart';
import 'core/pwa/install_prompt_port.dart';
import 'core/storage/guest_id_store.dart';
import 'core/theme/kachava_theme.dart';
import 'data/repositories/api_sanctuary_repository.dart';
import 'domain/repositories/sanctuary_repository.dart';
import 'presentation/shell/sanctuary_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();
  runApp(const KachavaGuestPortalApp(enableLivePolling: true));
}

/// Root Flutter Web application widget for the Kachava Lux Guest Portal.
class KachavaGuestPortalApp extends StatefulWidget {
  const KachavaGuestPortalApp({
    super.key,
    this.controller,
    this.repository,
    this.enableLivePolling = false,
    this.guestIdStore,
    this.installPrompt,
    this.initialUri,
  });

  final SanctuaryController? controller;
  final SanctuaryRepository? repository;
  final bool enableLivePolling;

  /// Remembered guest link; defaults to browser storage on the web.
  final GuestIdStore? guestIdStore;

  /// Install hint on Home; defaults to the browser implementation.
  final InstallPromptPort? installPrompt;

  /// Page URL; defaults to [Uri.base].
  final Uri? initialUri;

  @override
  State<KachavaGuestPortalApp> createState() => _KachavaGuestPortalAppState();
}

class _KachavaGuestPortalAppState extends State<KachavaGuestPortalApp> {
  late SanctuaryController _controller;
  late bool _ownsController;
  late final InstallPromptPort _installPrompt =
      widget.installPrompt ?? createInstallPromptPort();

  @override
  void initState() {
    super.initState();
    _bindController();
  }

  /// The first load and live polling share the controller's poller, so a
  /// refresh never overlaps another one.
  void _bindController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _ownsController = true;
      final store = widget.guestIdStore ?? createGuestIdStore();
      _controller = SanctuaryController(
        repository: widget.repository ?? ApiSanctuaryRepository(),
        soundscape: SanctuarySoundscapeSynthesizer(),
        requireExplicitGuestId: true,
        initialUri:
            GuestLinkResolver.resolve(widget.initialUri ?? Uri.base, store),
        onLinkRejected: store.clear,
      );
      unawaited(_controller.initialize());
    }
    if (widget.enableLivePolling) _controller.startLivePolling();
  }

  void _releaseController() {
    _controller.stopLivePolling();
    if (_ownsController) _controller.dispose();
  }

  @override
  void didUpdateWidget(covariant KachavaGuestPortalApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller ||
        widget.repository != oldWidget.repository ||
        widget.enableLivePolling != oldWidget.enableLivePolling) {
      _releaseController();
      _bindController();
    }
  }

  @override
  void dispose() {
    _releaseController();
    if (widget.installPrompt == null) _installPrompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kachava Lux · Guest Portal',
      debugShowCheckedModeBanner: false,
      theme: KachavaTheme.buildTheme(),
      home: SanctuaryShell(
        controller: _controller,
        installPrompt: _installPrompt,
      ),
    );
  }
}
