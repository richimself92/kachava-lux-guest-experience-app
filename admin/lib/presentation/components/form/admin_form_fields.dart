import 'package:flutter/material.dart';

import '../../../core/admin_list_strings.dart';
import '../../../core/theme/kachava_tokens.dart';

/// Field label above the input; required fields get a small asterisk (no
/// legend text).
class AdminFieldLabel extends StatelessWidget {
  const AdminFieldLabel(this.label, {super.key, this.isRequired = false});

  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    return Text.rich(
      TextSpan(text: label, style: style, children: [
        if (isRequired)
          const TextSpan(
              text: ' *',
              style: TextStyle(fontSize: 12, color: KachavaTokens.error)),
      ]),
    );
  }
}

/// Short inline validators (<= 5 words).
abstract final class AdminValidators {
  static FormFieldValidator<String> required(bool isEs) => (value) =>
      (value ?? '').trim().isEmpty ? AdminListStrings(isEs).required : null;

  static FormFieldValidator<String> maxLength(int max, bool isEs) =>
      (value) => (value ?? '').length > max
          ? (isEs ? 'Máx. $max caracteres' : 'Max $max characters')
          : null;

  /// Runs [validators] in order and returns the first message.
  static FormFieldValidator<String> all(
          List<FormFieldValidator<String>> validators) =>
      (value) {
        for (final v in validators) {
          final message = v(value);
          if (message != null) return message;
        }
        return null;
      };
}

/// Labelled text field with short inline validation text (never color only).
class AdminTextFormField extends StatelessWidget {
  const AdminTextFormField({
    super.key,
    required this.label,
    this.isRequired = false,
    this.initialValue,
    this.validator,
    this.onSaved,
    this.maxLines = 1,
    this.keyboardType,
    this.isEs = false,
  });

  final String label;
  final bool isRequired;
  final String? initialValue;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KachavaTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminFieldLabel(label, isRequired: isRequired),
          const SizedBox(height: KachavaTokens.space1),
          TextFormField(
            initialValue: initialValue,
            maxLines: maxLines,
            keyboardType: keyboardType,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: const InputDecoration(isDense: true, errorMaxLines: 1),
            validator: AdminValidators.all([
              if (isRequired) AdminValidators.required(isEs),
              if (validator != null) validator!,
            ]),
            onSaved: onSaved,
          ),
        ],
      ),
    );
  }
}

/// Optional/advanced fields, collapsed by default (progressive disclosure).
class AdminAdvancedSection extends StatelessWidget {
  const AdminAdvancedSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: key,
        initiallyExpanded: false,
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        children: children,
      ),
    );
  }
}

/// One-line toast, bottom-start, auto-dismiss after 4 s (errors 8 s with
/// "Retry"). Call only after the awaited write succeeded.
void showAdminToast(
  BuildContext context,
  String message, {
  bool isError = false,
  VoidCallback? onRetry,
  bool isEs = false,
}) {
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      key: const Key('admin-toast'),
      behavior: SnackBarBehavior.floating,
      width: 360,
      duration: Duration(seconds: isError ? 8 : 4),
      content: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
      action: isError && onRetry != null
          ? SnackBarAction(
              label: AdminListStrings(isEs).retry, onPressed: onRetry)
          : null,
    ));
}
