import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'application/sanctuary_controller.dart';
import 'core/audio/soundscape_port.dart';
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
  });

  final SanctuaryController? controller;
  final SanctuaryRepository? repository;
  final bool enableLivePolling;

  @override
  State<KachavaGuestPortalApp> createState() => _KachavaGuestPortalAppState();
}

class _KachavaGuestPortalAppState extends State<KachavaGuestPortalApp> {
  late SanctuaryController _controller;
  late bool _ownsController;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _bindController();
  }

  void _bindController() {
    _pollingTimer?.cancel();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _ownsController = true;
      _controller = SanctuaryController(
        repository: widget.repository ?? ApiSanctuaryRepository(),
        soundscape: SanctuarySoundscapeSynthesizer(),
        requireExplicitGuestId: true,
      );
      _controller.initialize();
    }
    if (widget.enableLivePolling) {
      _pollingTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _controller.refreshFromBackend(),
      );
    }
  }

  @override
  void didUpdateWidget(covariant KachavaGuestPortalApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller ||
        widget.repository != oldWidget.repository ||
        widget.enableLivePolling != oldWidget.enableLivePolling) {
      if (_ownsController) {
        _controller.dispose();
      }
      _bindController();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kachava Lux · Guest Portal',
      debugShowCheckedModeBanner: false,
      theme: KachavaTheme.buildTheme(),
      home: SanctuaryShell(controller: _controller),
    );
  }
}
