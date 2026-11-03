import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/admin_list_strings.dart';
import '../../../core/theme/kachava_tokens.dart';
import '../info_tooltip.dart';

/// Field label above the input; required fields get a small asterisk (no
/// legend text). An optional [info] adds an ⓘ tooltip.
///
/// [readByInput]: the input below already announces [label] as its
/// accessible name, so the visible text is not read twice.
class AdminFieldLabel extends StatelessWidget {
  const AdminFieldLabel(this.label,
      {super.key,
      this.isRequired = false,
      this.info,
      this.readByInput = false});

  final String label;
  final bool isRequired;
  final String? info;
  final bool readByInput;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    final text = ExcludeSemantics(
      excluding: readByInput,
      // Labels are 1-3 words: one line keeps neighbouring inputs aligned.
      child: Text.rich(
        TextSpan(text: label, style: style, children: [
          if (isRequired)
            const TextSpan(
                text: ' *',
                style: TextStyle(fontSize: 12, color: KachavaTokens.error)),
        ]),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
    // One label height (24) with or without ⓘ, so inputs side by side align.
    if (info == null) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 24),
        child: Align(alignment: Alignment.centerLeft, child: text),
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Flexible(child: text),
      // 48x24 hit area (WCAG 2.2 target size) keeps the label row 24px tall.
      SizedBox(
          width: 48,
          height: 24,
          child: OverflowBox(
              maxWidth: 48, maxHeight: 48, child: InfoTooltip(info!))),
    ]);
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
///
/// The visible label sits above the input and is also the input's
/// accessible name. [hintText] shows inside an empty field (e.g. "Not set").
class AdminTextFormField extends StatelessWidget {
  const AdminTextFormField({
    super.key,
    required this.label,
    this.isRequired = false,
    this.initialValue,
    this.controller,
    this.validator,
    this.onSaved,
    this.onChanged,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.hintText,
    this.info,
    this.suffixIcon,
    this.obscureText = false,
    this.fieldKey,
    this.isEs = false,
  });

  final String label;
  final bool isRequired;
  final String? initialValue;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final String? hintText;

  /// ⓘ tooltip next to the label.
  final String? info;
  final Widget? suffixIcon;
  final bool obscureText;

  /// Key of the inner [TextFormField] (tests and e2e).
  final Key? fieldKey;
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KachavaTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminFieldLabel(label,
              isRequired: isRequired, info: info, readByInput: true),
          const SizedBox(height: KachavaTokens.space1),
          Semantics(
            label: label,
            child: TextFormField(
              key: fieldKey,
              controller: controller,
              initialValue: controller == null ? initialValue : null,
              maxLines: obscureText ? 1 : maxLines,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              textCapitalization: textCapitalization,
              obscureText: obscureText,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                  isDense: true,
                  errorMaxLines: 1,
                  hintText: hintText,
                  suffixIcon: suffixIcon),
              validator: AdminValidators.all([
                if (isRequired) AdminValidators.required(isEs),
                if (validator != null) validator!,
              ]),
              onSaved: onSaved,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Masked text field with a show/hide toggle (e.g. a Wi-Fi password).
class AdminPasswordFormField extends StatefulWidget {
  const AdminPasswordFormField({
    super.key,
    required this.label,
    required this.showLabel,
    required this.hideLabel,
    this.initialValue,
    this.onChanged,
    this.fieldKey,
    this.toggleKey,
    this.isEs = false,
  });

  final String label;

  /// Tooltips of the eye button ("Show password" / "Hide password").
  final String showLabel;
  final String hideLabel;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final Key? fieldKey;
  final Key? toggleKey;
  final bool isEs;

  @override
  State<AdminPasswordFormField> createState() => _AdminPasswordFormFieldState();
}

class _AdminPasswordFormFieldState extends State<AdminPasswordFormField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return AdminTextFormField(
      label: widget.label,
      initialValue: widget.initialValue,
      onChanged: widget.onChanged,
      obscureText: !_visible,
      fieldKey: widget.fieldKey,
      isEs: widget.isEs,
      suffixIcon: IconButton(
        key: widget.toggleKey,
        tooltip: _visible ? widget.hideLabel : widget.showLabel,
        icon: Icon(_visible
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined),
        onPressed: () => setState(() => _visible = !_visible),
      ),
    );
  }
}

/// One choice of an [AdminDropdownFormField].
class AdminChoice<T> {
  const AdminChoice(this.value, this.label);

  final T value;
  final String label;
}

/// Labelled dropdown (label above, like the text fields).
class AdminDropdownFormField<T> extends StatelessWidget {
  const AdminDropdownFormField({
    super.key,
    required this.label,
    required this.choices,
    this.initialValue,
    this.onChanged,
    this.isRequired = false,
    this.info,
    this.fieldKey,
    this.isEs = false,
  });

  final String label;
  final List<AdminChoice<T>> choices;
  final T? initialValue;
  final ValueChanged<T?>? onChanged;
  final bool isRequired;
  final String? info;
  final Key? fieldKey;
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KachavaTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminFieldLabel(label,
              isRequired: isRequired, info: info, readByInput: true),
          const SizedBox(height: KachavaTokens.space1),
          Semantics(
            label: label,
            child: DropdownButtonFormField<T>(
              key: fieldKey,
              initialValue: initialValue,
              isExpanded: true,
              decoration:
                  const InputDecoration(isDense: true, errorMaxLines: 1),
              validator: (value) => isRequired && value == null
                  ? AdminListStrings(isEs).required
                  : null,
              items: [
                for (final c in choices)
                  DropdownMenuItem<T>(value: c.value, child: Text(c.label)),
              ],
              onChanged: onChanged,
            ),
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
/// "Retry", or [actionLabel]). Call only after the awaited write succeeded.
void showAdminToast(
  BuildContext context,
  String message, {
  bool isError = false,
  VoidCallback? onRetry,
  String? actionLabel,
  bool isEs = false,
}) =>
    showAdminToastOn(ScaffoldMessenger.maybeOf(context), message,
        isError: isError,
        onRetry: onRetry,
        actionLabel: actionLabel,
        isEs: isEs);

/// [showAdminToast] on a messenger captured before an `await` (the calling
/// widget may be gone when the write completes).
void showAdminToastOn(
  ScaffoldMessengerState? messenger,
  String message, {
  bool isError = false,
  VoidCallback? onRetry,
  String? actionLabel,
  bool isEs = false,
}) {
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      key: const Key('admin-toast'),
      behavior: SnackBarBehavior.floating,
      width: 360,
      duration: Duration(seconds: isError ? 8 : 4),
      content: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
      action: isError && onRetry != null
          ? SnackBarAction(
              label: actionLabel ?? AdminListStrings(isEs).retry,
              onPressed: onRetry)
          : null,
    ));
}
