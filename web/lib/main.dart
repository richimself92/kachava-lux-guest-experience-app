import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'application/portal_controller.dart';
import 'core/auth/guest_link_resolver.dart';
import 'core/platform/page_visibility.dart';
import 'core/platform/photo_picker.dart';
import 'core/pwa/install_prompt_port.dart';
import 'core/realtime/realtime_events_port.dart';
import 'core/storage/device_prefs.dart';
import 'core/storage/guest_id_store.dart';
import 'core/theme/kachava_theme.dart';
import 'data/guest_api.dart';
import 'data/http_guest_api.dart';
import 'domain/resort_clock.dart';
import 'presentation/shell/portal_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();
  runApp(const KachavaGuestPortalApp());
}

/// Kachava Lux guest portal (Flutter Web PWA).
class KachavaGuestPortalApp extends StatefulWidget {
  const KachavaGuestPortalApp({
    super.key,
    this.api,
    this.guestIdStore,
    this.prefs,
    this.installPrompt,
    this.photoPicker,
    this.realtime,
    this.clock = const ResortClock(),
    this.initialUri,
  });

  final GuestApi? api;

  /// Remembered guest link; defaults to browser storage on the web.
  final GuestIdStore? guestIdStore;
  final DevicePrefs? prefs;
  final InstallPromptPort? installPrompt;
  final PhotoPicker? photoPicker;

  /// Firestore signal listeners (ADR-012); defaults to the platform port.
  final RealtimeEventsPort? realtime;
  final ResortClock clock;

  /// Page URL; defaults to [Uri.base].
  final Uri? initialUri;

  @override
  State<KachavaGuestPortalApp> createState() => _KachavaGuestPortalAppState();
}

class _KachavaGuestPortalAppState extends State<KachavaGuestPortalApp> {
  late final GuestApi _api = widget.api ?? HttpGuestApi();
  late final InstallPromptPort _installPrompt =
      widget.installPrompt ?? createInstallPromptPort();
  late final PhotoPicker _photoPicker =
      widget.photoPicker ?? createPhotoPicker();
  late final PortalController _controller;

  @override
  void initState() {
    super.initState();
    final store = widget.guestIdStore ?? createGuestIdStore();
    _controller = PortalController(
      api: _api,
      prefs: widget.prefs ?? createDevicePrefs(),
      clock: widget.clock,
      realtime: widget.realtime ?? createRealtimeEventsPort(),
      onPageVisible: pageVisibleAgain(),
      initialUri:
          GuestLinkResolver.resolve(widget.initialUri ?? Uri.base, store),
      onLinkRejected: store.clear,
    );
    unawaited(_controller.start());
  }

  @override
  void dispose() {
    _controller.dispose();
    if (widget.api == null) _api.dispose();
    if (widget.installPrompt == null) _installPrompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) => MaterialApp(
        title: 'Kachava Lux',
        debugShowCheckedModeBanner: false,
        theme: KachavaTheme.buildTheme(),
        locale: Locale(_controller.lang.name),
        supportedLocales: const [Locale('en'), Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: child,
      ),
      child: PortalRoot(
        controller: _controller,
        installPrompt: _installPrompt,
        photoPicker: _photoPicker,
      ),
    );
  }
}
