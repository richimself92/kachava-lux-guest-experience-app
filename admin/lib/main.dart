import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'application/admin_dashboard_controller.dart';
import 'core/admin_theme.dart';
import 'data/api_admin_operations_repository.dart';
import 'domain/admin_repository.dart';
import 'presentation/admin_command_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();
  runApp(const KachavaAdminApp(enableLivePolling: true));
}

/// Root Flutter Web Application for Kachava Lux Administrative & Concierge Operations.
class KachavaAdminApp extends StatefulWidget {
  const KachavaAdminApp({
    super.key,
    this.repository,
    this.enableLivePolling = false,
  });

  final AdminOperationsRepository? repository;
  final bool enableLivePolling;

  @override
  State<KachavaAdminApp> createState() => _KachavaAdminAppState();
}

class _KachavaAdminAppState extends State<KachavaAdminApp> {
  late final AdminDashboardController _controller;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _controller = AdminDashboardController(
      repository: widget.repository ?? ApiAdminOperationsRepository(),
    );
    _controller.initialize();
    if (widget.enableLivePolling) {
      _pollTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _controller.refreshFromBackend(silent: true),
      );
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kachava Lux · Sanctuary Operations Command Center',
      debugShowCheckedModeBanner: false,
      theme: KachavaAdminTheme.build(),
      home: AdminCommandShell(controller: _controller),
    );
  }
}
