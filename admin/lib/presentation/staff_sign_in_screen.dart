import 'package:flutter/material.dart';
import '../core/admin_i18n.dart';
import '../core/admin_theme.dart';
import '../data/admin_api_client.dart';

/// Kachava Lux Staff Sign-In card shown until a staff session is open and
/// again whenever the session expires (HTTP 401 from `AdminAuthGuard`).
class StaffSignInScreen extends StatefulWidget {
  const StaffSignInScreen(
      {super.key, required this.onSignIn, this.isEs = false});

  /// Exchanges the staff email for a session; throws when sign-in fails.
  final Future<void> Function(String email) onSignIn;
  final bool isEs;

  @override
  State<StaffSignInScreen> createState() => _StaffSignInScreenState();
}

class _StaffSignInScreenState extends State<StaffSignInScreen> {
  final TextEditingController _email = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSignIn(_email.text);
    } catch (error) {
      // Any failure (including Errors) stays on this screen as one line.
      debugPrint('Staff sign-in failed: $error');
      if (mounted) setState(() => _error = _describe(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _tr(String en, String es) => AdminI18n.tr(widget.isEs, en, es);

  String _describe(Object error) => error is AdminUnauthorizedException
      ? _tr('Sign-in rejected. Check your staff email.',
          'Acceso rechazado. Revisa tu correo del personal.')
      : _tr('Sign-in failed. Check your connection and try again.',
          'No se pudo iniciar sesión. Revisa tu conexión e intenta de nuevo.');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('staff-sign-in-screen'),
      backgroundColor: KachavaAdminColors.canvasLow,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Card(
            color: KachavaAdminColors.surfacePaper,
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _buildForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
            _tr('KACHAVA LUX · Staff Sign-In',
                'KACHAVA LUX · Acceso del Personal'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        _buildEmailField(),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              key: const Key('staff-sign-in-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 16),
        _buildSubmitButton(),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextField(
      key: const Key('staff-sign-in-email'),
      controller: _email,
      keyboardType: TextInputType.emailAddress,
      decoration:
          InputDecoration(labelText: _tr('Staff email', 'Correo del personal')),
      onSubmitted: (_) => _busy ? null : _submit(),
    );
  }

  Widget _buildSubmitButton() {
    return FilledButton(
      key: const Key('staff-sign-in-submit'),
      style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: KachavaAdminColors.zapotePrimary),
      onPressed: _busy ? null : _submit,
      child: Text(_tr('Sign in', 'Iniciar sesión')),
    );
  }
}
