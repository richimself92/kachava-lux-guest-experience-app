import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'application/admin_dashboard_controller.dart';
import 'application/admin_live_sync.dart';
import 'core/admin_theme.dart';
import 'core/app_config.dart';
import 'core/guest_portal_link.dart';
import 'data/admin_api_client.dart';
import 'data/admin_session.dart';
import 'data/api_admin_operations_repository.dart';
import 'domain/admin_repository.dart';
import 'presentation/admin_command_shell.dart';
import 'presentation/admin_no_access_screen.dart';
import 'presentation/staff_sign_in_screen.dart';

void main() {
  GuestPortalLink.configure(AdminAppConfig.guestPortalUrl);
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();
  final apiClient = AdminApiClient();
  runApp(KachavaAdminApp(
    repository: ApiAdminOperationsRepository(apiClient: apiClient),
    authClient: apiClient,
    enableLivePolling: true,
  ));
}

/// Root Flutter Web Application for Kachava Lux Administrative & Concierge Operations.
class KachavaAdminApp extends StatefulWidget {
  const KachavaAdminApp({
    super.key,
    required this.repository,
    this.authClient,
    this.enableLivePolling = false,
  });

  final AdminOperationsRepository repository;

  /// Staff authentication. When set, the dashboard is shown only while its
  /// session is open; offline fakes (tests) omit it.
  final AdminApiClient? authClient;
  final bool enableLivePolling;

  @override
  State<KachavaAdminApp> createState() => _KachavaAdminAppState();
}

class _KachavaAdminAppState extends State<KachavaAdminApp> {
  late final AdminDashboardController _controller;
  late final AdminLiveSync _liveSync;

  /// Staff member whose data is loaded; a different one starts from empty.
  String? _staffId;

  AdminSession? get _session => widget.authClient?.session;
  bool get _signedIn => _session?.isAuthenticated ?? true;

  @override
  void initState() {
    super.initState();
    _controller = AdminDashboardController(repository: widget.repository);
    _liveSync = AdminLiveSync(
      initialLoad: _controller.initialize,
      refresh: () => _controller.refreshFromBackend(silent: true),
    );
    _staffId = _session?.staff?.staffId;
    _session?.addListener(_onSessionChanged);
    if (_signedIn) _startSync();
  }

  void _startSync() {
    _liveSync.tick();
    if (widget.enableLivePolling) _liveSync.startPolling();
  }

  /// On expiry (401) or a different staff member, nothing of the previous
  /// session may stay in memory: data, caches and sync state are reset.
  void _onSessionChanged() {
    final staffId = _session?.staff?.staffId;
    if (!_signedIn || staffId != _staffId) _resetSessionData();
    _staffId = staffId;
    if (_signedIn) _startSync();
    setState(() {});
  }

  void _resetSessionData() {
    _liveSync
      ..stopPolling()
      ..reset();
    _controller.clearSessionData();
  }

  @override
  void dispose() {
    _session?.removeListener(_onSessionChanged);
    _liveSync.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kachava Lux · Sanctuary Operations Command Center',
      debugShowCheckedModeBanner: false,
      theme: KachavaAdminTheme.build(),
      home: _signedIn ? _buildSignedInHome() : _buildSignIn(),
    );
  }

  Widget _buildSignIn() => StaffSignInScreen(
      onSignIn: widget.authClient!.signIn, isEs: _controller.isEs);

  /// A 403 on the sync feed shows a dedicated screen, never the shell.
  Widget _buildSignedInHome() {
    return ValueListenableBuilder<AdminSyncStatus>(
      valueListenable: _liveSync.status,
      builder: (context, status, _) => status == AdminSyncStatus.noAccess
          ? AdminNoAccessScreen(
              isEs: _controller.isEs, onSignOut: _session?.expire)
          : AdminCommandShell(
              controller: _controller, syncStatus: _liveSync.status),
    );
  }
}
