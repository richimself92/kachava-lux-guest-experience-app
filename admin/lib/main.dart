import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'application/admin_dashboard_controller.dart';
import 'application/admin_live_sync.dart';
import 'application/resort_settings_controller.dart';
import 'application/service_catalog_deps.dart';
import 'core/admin_theme.dart';
import 'core/app_config.dart';
import 'core/guest_portal_link.dart';
import 'core/image_file_picker.dart';
import 'core/time_zone_catalog.dart';
import 'data/admin_api_client.dart';
import 'data/api_admin_operations_repository.dart';
import 'data/http_catalog_repositories.dart';
import 'data/http_service_catalog_repository.dart';
import 'data/http_uploads.dart';
import 'domain/admin_catalog_repositories.dart';
import 'domain/admin_repository.dart';
import 'presentation/admin_command_shell.dart';
import 'presentation/services/service_catalog_scope.dart';

void main() {
  GuestPortalLink.configure(AdminAppConfig.guestPortalUrl);
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();
  // One API client: one silent staff session for every repository.
  final api = AdminApiClient();
  runApp(ServiceCatalogScope(
    deps: ServiceCatalogDeps(
      services: HttpServiceCatalogRepository(api),
      providers: HttpTransportProviderRepository(api),
      signer: HttpUploadSigner(api),
      transport: HttpSignedUploadTransport(),
      picker: createImageFilePicker(),
    ),
    child: KachavaAdminApp(
      repository: ApiAdminOperationsRepository(apiClient: api),
      resort: AdminResortRepositories(
        settings: HttpSettingsRepository(api),
        villas: HttpVillaRepository(api),
      ),
      timeZones: createTimeZoneCatalog(),
      enableLivePolling: true,
    ),
  ));
}

/// Root Flutter Web Application for Kachava Lux Administrative & Concierge Operations.
///
/// There is no sign-in: the API client authenticates silently, so the Command
/// Center shell is always shown. Sync health (reconnecting / no access) is a
/// single status line inside the shell.
class KachavaAdminApp extends StatefulWidget {
  const KachavaAdminApp({
    super.key,
    required this.repository,
    required this.resort,
    required this.timeZones,
    this.enableLivePolling = false,
  });

  final AdminOperationsRepository repository;

  /// Settings and Villas (`/admin/settings`, `/admin/villas`).
  final AdminResortRepositories resort;
  final TimeZoneCatalog timeZones;
  final bool enableLivePolling;

  @override
  State<KachavaAdminApp> createState() => _KachavaAdminAppState();
}

class _KachavaAdminAppState extends State<KachavaAdminApp> {
  late final AdminDashboardController _controller;
  late final AdminLiveSync _liveSync;

  /// Loaded once at start and after each save (settings are not polled).
  late final ResortSettingsController _resortSettings;

  @override
  void initState() {
    super.initState();
    _controller = AdminDashboardController(repository: widget.repository);
    _resortSettings = ResortSettingsController(widget.resort.settings)..load();
    _liveSync = AdminLiveSync(
      initialLoad: _controller.initialize,
      refresh: () => _controller.refreshFromBackend(silent: true),
    );
    _liveSync.tick();
    if (widget.enableLivePolling) _liveSync.startPolling();
  }

  @override
  void dispose() {
    _liveSync.dispose();
    _resortSettings.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kachava Lux · Command Center',
      debugShowCheckedModeBanner: false,
      theme: KachavaAdminTheme.build(),
      home: AdminCommandShell(
        controller: _controller,
        resortSettings: _resortSettings,
        villas: widget.resort.villas,
        timeZones: widget.timeZones,
        syncStatus: _liveSync.status,
      ),
    );
  }
}
