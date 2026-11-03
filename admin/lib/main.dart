import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'application/admin_dashboard_controller.dart';
import 'application/admin_live_sync.dart';
import 'core/admin_theme.dart';
import 'core/app_config.dart';
import 'core/guest_portal_link.dart';
import 'data/admin_api_client.dart';
import 'data/api_admin_operations_repository.dart';
import 'domain/admin_repository.dart';
import 'presentation/admin_command_shell.dart';

void main() {
  GuestPortalLink.configure(AdminAppConfig.guestPortalUrl);
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();
  runApp(KachavaAdminApp(
    repository: ApiAdminOperationsRepository(apiClient: AdminApiClient()),
    enableLivePolling: true,
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
    this.enableLivePolling = false,
  });

  final AdminOperationsRepository repository;
  final bool enableLivePolling;

  @override
  State<KachavaAdminApp> createState() => _KachavaAdminAppState();
}

class _KachavaAdminAppState extends State<KachavaAdminApp> {
  late final AdminDashboardController _controller;
  late final AdminLiveSync _liveSync;

  @override
  void initState() {
    super.initState();
    _controller = AdminDashboardController(repository: widget.repository);
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
          controller: _controller, syncStatus: _liveSync.status),
    );
  }
}
