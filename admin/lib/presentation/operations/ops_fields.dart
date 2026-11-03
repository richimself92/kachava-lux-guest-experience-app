import 'package:flutter/material.dart';

import '../../core/resort_time.dart';
import '../../core/theme/kachava_tokens.dart';
import '../components/components.dart';

/// Calendar day typed as `YYYY-MM-DD` or picked with the calendar button.
class IsoDateField extends StatelessWidget {
  const IsoDateField({
    super.key,
    required this.label,
    required this.controller,
    required this.fieldKey,
    required this.formatMessage,
    required this.pickLabel,
    required this.isEs,
    this.isRequired = false,
    this.validator,
  });

  static final RegExp _format = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  final String label;
  final TextEditingController controller;
  final Key fieldKey;
  final String formatMessage;
  final String pickLabel;
  final bool isEs;
  final bool isRequired;

  /// Extra check after the format (e.g. "after arrival").
  final FormFieldValidator<String>? validator;

  static bool isValid(String text) {
    if (!_format.hasMatch(text)) return false;
    final parsed = DateTime.tryParse('${text}T00:00:00Z');
    return parsed != null && ResortTime.isoDay(parsed) == text;
  }

  String? _validate(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return isRequired ? AdminValidators.required(isEs)(text) : null;
    }
    if (!isValid(text)) return formatMessage;
    return validator?.call(text);
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final current = DateTime.tryParse('${controller.text.trim()}T00:00:00');
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (date == null) return;
    controller.text = ResortTime.isoDay(date);
  }

  @override
  Widget build(BuildContext context) => AdminTextFormField(
        label: label,
        isRequired: isRequired,
        controller: controller,
        fieldKey: fieldKey,
        hintText: 'YYYY-MM-DD',
        validator: _validate,
        keyboardType: TextInputType.datetime,
        suffixIcon: Builder(
          builder: (context) => IconButton(
            tooltip: pickLabel,
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            onPressed: () => _pick(context),
          ),
        ),
        isEs: isEs,
      );
}

/// A label/value line of a detail panel; empty values show "—".
class FactRow extends StatelessWidget {
  const FactRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: KachavaTokens.space3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 140,
          child: Text(label,
              style: theme.bodyMedium
                  ?.copyWith(color: KachavaTokens.textSecondary)),
        ),
        Expanded(
          child:
              Text(value.trim().isEmpty ? '—' : value, style: theme.bodyMedium),
        ),
      ]),
    );
  }
}

/// A short section heading inside a panel.
class PanelHeading extends StatelessWidget {
  const PanelHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(
            top: KachavaTokens.space4, bottom: KachavaTokens.space2),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}

/// A one-field dialog ("Reason", "Note"); resolves the trimmed text or
/// `null` when dismissed. The field is required.
Future<String?> showTextInputDialog(
  BuildContext context, {
  required Key key,
  required String title,
  required String fieldLabel,
  required Key fieldKey,
  required String confirmLabel,
  required String cancelLabel,
  required bool isEs,
  bool destructive = false,
}) {
  final form = GlobalKey<FormState>();
  var text = '';
  final scheme = Theme.of(context).colorScheme;
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: key,
      title: Text(title),
      content: SizedBox(
        width: 360,
        child: Form(
          key: form,
          child: AdminTextFormField(
            label: fieldLabel,
            isRequired: true,
            fieldKey: fieldKey,
            maxLines: 3,
            validator: AdminValidators.all([
              AdminValidators.required(isEs),
              AdminValidators.maxLength(500, isEs),
            ]),
            onChanged: (v) => text = v,
            isEs: isEs,
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('input-dialog-cancel'),
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(cancelLabel),
        ),
        FilledButton(
          key: const Key('input-dialog-confirm'),
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError)
              : null,
          onPressed: () {
            if (!(form.currentState?.validate() ?? false)) return;
            Navigator.of(dialogContext).pop(text.trim());
          },
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}
