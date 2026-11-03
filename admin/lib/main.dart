import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'application/admin_live_sync.dart';
import 'application/admin_shell_controller.dart';
import 'application/notification_bell_controller.dart';
import 'application/resort_settings_controller.dart';
import 'application/service_catalog_deps.dart';
import 'core/admin_theme.dart';
import 'core/alert_chime_port.dart';
import 'core/app_config.dart';
import 'core/guest_portal_link.dart';
import 'core/image_file_picker.dart';
import 'core/resort_time.dart';
import 'core/time_zone_catalog.dart';
import 'data/admin_api_client.dart';
import 'data/http_catalog_repositories.dart';
import 'data/http_operations_repositories.dart';
import 'data/http_service_catalog_repository.dart';
import 'data/http_stay_repositories.dart';
import 'data/http_trip_repository.dart';
import 'data/http_uploads.dart';
import 'domain/admin_catalog_repositories.dart';
import 'domain/staff_member.dart';
import 'presentation/admin_command_shell.dart';
import 'presentation/operations/operations_scope.dart';
import 'presentation/services/service_catalog_scope.dart';
import 'presentation/workspaces/transportation/trip_scope.dart';

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
    child: TripScope(
      deps: TripDeps(
        trips: HttpTripRepository(api),
        stays: HttpStayListRepository(api),
      ),
      child: KachavaAdminApp(
        resort: AdminResortRepositories(
          settings: HttpSettingsRepository(api),
          villas: HttpVillaRepository(api),
        ),
        operations: OperationsDeps(
          dashboard: HttpDashboardRepository(api),
          reservations: HttpReservationRepository(api),
          guests: HttpGuestRepository(api),
          tasks: HttpTaskRepository(api),
          notifications: HttpNotificationRepository(api),
          conversations: HttpConversationRepository(api),
        ),
        staff: HttpStaffDirectoryRepository(api),
        timeZones: createTimeZoneCatalog(),
        enableLivePolling: true,
      ),
    ),
  ));
}

/// Root of the Kachava Lux staff Command Center.
///
/// There is no sign-in: the API client authenticates silently, so the shell
/// is always shown. The only background traffic is the bell poll (unread
/// notification counts every 15 s); each screen reads its own pages.
class KachavaAdminApp extends StatefulWidget {
  const KachavaAdminApp({
    super.key,
    required this.resort,
    required this.timeZones,
    this.operations,
    this.staff,
    this.chime,
    this.zoneResolver,
    this.enableLivePolling = false,
  });

  /// Settings and Villas (`/admin/settings`, `/admin/villas`).
  final AdminResortRepositories resort;
  final TimeZoneCatalog timeZones;

  /// Dashboard, Reservations, Guests, Tasks, Notifications, Messages;
  /// without them those screens show one error line.
  final OperationsDeps? operations;
  final StaffDirectoryRepository? staff;
  final AlertChimePort? chime;
  final ZoneOffsetResolver? zoneResolver;
  final bool enableLivePolling;

  @override
  State<KachavaAdminApp> createState() => _KachavaAdminAppState();
}

class _KachavaAdminAppState extends State<KachavaAdminApp> {
  late final AdminShellController _shell =
      AdminShellController(staff: widget.staff);
  late final NotificationBellController _bell = NotificationBellController(
      repository: widget.operations?.notifications, chime: widget.chime);
  late final ResortSettingsController _resortSettings =
      ResortSettingsController(widget.resort.settings);
  late final AdminLiveSync _poll =
      AdminLiveSync(initialLoad: _bell.refresh, refresh: _bell.refresh);

  @override
  void initState() {
    super.initState();
    _resortSettings.load();
    _shell.loadStaff();
    _poll.tick();
    if (widget.enableLivePolling) _poll.startPolling();
  }

  @override
  void dispose() {
    _poll.dispose();
    _bell.dispose();
    _resortSettings.dispose();
    _shell.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shell = AdminCommandShell(
      controller: _shell,
      bell: _bell,
      resortSettings: _resortSettings,
      villas: widget.resort.villas,
      timeZones: widget.timeZones,
      syncStatus: _poll.status,
      zoneResolver: widget.zoneResolver,
    );
    final operations = widget.operations;
    return MaterialApp(
      title: 'Kachava Lux · Command Center',
      debugShowCheckedModeBanner: false,
      theme: KachavaAdminTheme.build(),
      home: operations == null
          ? shell
          : OperationsScope(deps: operations, child: shell),
    );
  }
}
