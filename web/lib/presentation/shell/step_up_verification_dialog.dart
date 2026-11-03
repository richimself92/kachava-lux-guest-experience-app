import 'package:flutter/material.dart';
import '../../application/sanctuary_controller.dart';
import '../../core/i18n/guest_feedback_i18n.dart';
import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';

/// Zero-password step-up modal: the server checks the guest's villa number or
/// last name and issues a step-up token before sensitive actions.
class StepUpVerificationDialog extends StatefulWidget {
  const StepUpVerificationDialog({
    super.key,
    required this.controller,
    required this.onVerified,
  });

  final SanctuaryController controller;
  final Future<void> Function() onVerified;

  static Future<void> show(
    BuildContext context, {
    required SanctuaryController controller,
    required Future<void> Function() onVerified,
  }) async {
    if (controller.isStepUpVerified) {
      await onVerified();
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => StepUpVerificationDialog(
        controller: controller,
        onVerified: onVerified,
      ),
    );
  }

  @override
  State<StepUpVerificationDialog> createState() =>
      _StepUpVerificationDialogState();
}

class _StepUpVerificationDialogState extends State<StepUpVerificationDialog> {
  final TextEditingController _inputController = TextEditingController();
  String? _errorText;
  bool _isVerifying = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    setState(() => _isVerifying = true);
    final verified = await _verifyOrFalse();
    if (!mounted) return;
    if (!verified) {
      setState(() => _errorText = widget.controller.i18n.stepUpFailed);
      return;
    }
    Navigator.of(context).pop();
    await widget.onVerified();
  }

  /// An error counts as a failed check; the button is always re-enabled.
  Future<bool> _verifyOrFalse() async {
    try {
      return await widget.controller.verifyStepUp(_inputController.text);
    } catch (_) {
      return false;
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = widget.controller.i18n;
    return AlertDialog(
      backgroundColor: KachavaColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        i18n.t('Identity Verification', 'Verificación de Identidad'),
        style: const TextStyle(
          fontFamily: KachavaTheme.serifFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: KachavaColors.primary,
        ),
      ),
      content: _buildDialogContent(),
      actions: _buildActions(),
    );
  }

  List<Widget> _buildActions() {
    final i18n = widget.controller.i18n;
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(i18n.t('Cancel', 'Cancelar')),
      ),
      ElevatedButton(
        key: const Key('step-up-confirm-btn'),
        style: ElevatedButton.styleFrom(
          backgroundColor: KachavaColors.primary,
          foregroundColor: Colors.white,
        ),
        onPressed: _isVerifying ? null : _handleVerify,
        child: Text(i18n.t('Confirm & Proceed', 'Confirmar y Continuar')),
      ),
    ];
  }

  Widget _buildDialogContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.controller.i18n.stepUpPrompt,
          style: const TextStyle(
              fontSize: 13, color: KachavaColors.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        _buildAnswerField(),
      ],
    );
  }

  Widget _buildAnswerField() {
    return TextField(
      key: const Key('step-up-input-field'),
      controller: _inputController,
      decoration: InputDecoration(
        hintText: widget.controller.i18n.stepUpHint,
        errorText: _errorText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: KachavaColors.inputBorder),
        ),
      ),
    );
  }
}
