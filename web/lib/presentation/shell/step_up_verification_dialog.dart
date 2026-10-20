import 'package:flutter/material.dart';
import '../../application/sanctuary_controller.dart';
import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';

/// Zero-Password Step-Up Verification Modal confirming Villa Number (`102`)
/// or Primary Guest Last Name (`Miller`) prior to sensitive actions.
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

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final stay = widget.controller.stay;
    final verified = widget.controller.verifyStepUp(_inputController.text);
    if (!verified) {
      setState(() {
        _errorText =
            'Please enter Villa Number (${stay.villaNumber}) or Last Name (${stay.lastName}).';
      });
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    await widget.onVerified();
  }

  @override
  Widget build(BuildContext context) {
    final stay = widget.controller.stay;
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
      content: _buildDialogContent(stay.villaNumber, stay.lastName),
      actions: [
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
          onPressed: _handleVerify,
          child: Text(i18n.t('Confirm & Proceed', 'Confirmar y Continuar')),
        ),
      ],
    );
  }

  Widget _buildDialogContent(String villaNum, String lastName) {
    final i18n = widget.controller.i18n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          i18n.t(
            'To protect your Villa $villaNum folio, please confirm your Villa Number ($villaNum) or Last Name ($lastName):',
            'Para proteger tu cuenta de Villa $villaNum, confirma tu Número de Villa ($villaNum) o Apellido ($lastName):',
          ),
          style: const TextStyle(
              fontSize: 13, color: KachavaColors.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('step-up-input-field'),
          controller: _inputController,
          decoration: InputDecoration(
            hintText: 'Enter $villaNum or $lastName',
            errorText: _errorText,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: KachavaColors.inputBorder),
            ),
          ),
        ),
      ],
    );
  }
}
