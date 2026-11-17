import 'package:flutter/material.dart';

import '../../core/service_catalog_strings.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../domain/json_draft.dart';
import '../components/components.dart';

/// Labelled block: label (+ required mark, + ⓘ) above [child].
class DraftLabelled extends StatelessWidget {
  const DraftLabelled({
    super.key,
    required this.label,
    required this.child,
    this.tip,
    this.isRequired = false,
  });

  final String label;
  final String? tip;
  final bool isRequired;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: KachavaTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Flexible(child: AdminFieldLabel(label, isRequired: isRequired)),
              if (tip != null) InfoTooltip(tip!),
            ]),
            const SizedBox(height: KachavaTokens.space1),
            child,
          ],
        ),
      );
}

/// A text input bound to [path]; `svc-<path>` is its widget key and its
/// semantics identifier (stable e2e hook).
Widget draftInput(
  JsonDraft draft,
  String path, {
  FormFieldValidator<String>? validator,
  ValueChanged<String>? onChanged,
  String? hint,
  String? initial,
  int maxLines = 1,
  TextInputType? keyboardType,
}) =>
    Semantics(
      container: true,
      identifier: 'svc-$path',
      child: TextFormField(
        key: Key('svc-$path'),
        initialValue:
            initial ?? (draft.get(path) == null ? '' : draft.text(path)),
        maxLines: maxLines,
        keyboardType: keyboardType,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration:
            InputDecoration(isDense: true, hintText: hint, errorMaxLines: 1),
        validator: validator,
        onChanged: onChanged ?? (v) => draft.set(path, v),
      ),
    );

/// Plain text; [nullIfBlank] stores `null` for an empty value.
class DraftTextField extends StatelessWidget {
  const DraftTextField({
    super.key,
    required this.draft,
    required this.path,
    required this.label,
    this.tip,
    this.maxLines = 1,
    this.nullIfBlank = false,
  });

  final JsonDraft draft;
  final String path;
  final String label;
  final String? tip;
  final int maxLines;
  final bool nullIfBlank;

  @override
  Widget build(BuildContext context) => DraftLabelled(
        label: label,
        tip: tip,
        child: draftInput(draft, path,
            maxLines: maxLines,
            onChanged: (v) =>
                draft.set(path, nullIfBlank && v.trim().isEmpty ? null : v)),
      );
}

/// EN and ES side by side (`<path>.en`, `<path>.es`). [requireOne] needs at
/// least one language.
class DraftLocalizedField extends StatelessWidget {
  const DraftLocalizedField({
    super.key,
    required this.draft,
    required this.path,
    required this.label,
    required this.isEs,
    this.tip,
    this.maxLines = 1,
    this.requireOne = false,
  });

  final JsonDraft draft;
  final String path;
  final String label;
  final bool isEs;
  final String? tip;
  final int maxLines;
  final bool requireOne;

  String? _validate(String? _) {
    final blank = draft.text('$path.en').trim().isEmpty &&
        draft.text('$path.es').trim().isEmpty;
    return requireOne && blank
        ? ServiceCatalogStrings(isEs).nameRequired
        : null;
  }

  @override
  Widget build(BuildContext context) => DraftLabelled(
        label: label,
        tip: tip,
        isRequired: requireOne,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: draftInput(draft, '$path.en',
                hint: 'EN', maxLines: maxLines, validator: _validate),
          ),
          const SizedBox(width: KachavaTokens.space2),
          Expanded(
            child:
                draftInput(draft, '$path.es', hint: 'ES', maxLines: maxLines),
          ),
        ]),
      );
}

/// Whole number in [min]..[max]; blank stores `null`.
class DraftIntField extends StatelessWidget {
  const DraftIntField({
    super.key,
    required this.draft,
    required this.path,
    required this.label,
    required this.isEs,
    this.min = 0,
    this.max = 10000,
    this.tip,
  });

  final JsonDraft draft;
  final String path;
  final String label;
  final bool isEs;
  final int min;
  final int max;
  final String? tip;

  String? _validate(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) return null;
    final value = int.tryParse(text);
    final s = ServiceCatalogStrings(isEs);
    if (value == null) return s.wholeNumber;
    return value < min || value > max ? s.range(min, max) : null;
  }

  @override
  Widget build(BuildContext context) => DraftLabelled(
        label: label,
        tip: tip,
        child: draftInput(draft, path,
            keyboardType: TextInputType.number,
            validator: _validate,
            onChanged: (v) => draft.set(path, int.tryParse(v.trim()))),
      );
}

/// USD amount, 0..1,000,000 with at most 2 decimals; blank stores `null`.
class DraftAmountField extends StatelessWidget {
  const DraftAmountField({
    super.key,
    required this.draft,
    required this.path,
    required this.label,
    required this.isEs,
    this.tip,
  });

  final JsonDraft draft;
  final String path;
  final String label;
  final bool isEs;
  final String? tip;

  static final RegExp _amount = RegExp(r'^\d{1,7}(\.\d{1,2})?$');

  String? _validate(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) return null;
    final ok = _amount.hasMatch(text) && double.parse(text) <= 1000000;
    return ok ? null : ServiceCatalogStrings(isEs).invalidAmount;
  }

  @override
  Widget build(BuildContext context) {
    final value = draft.doubleOrNull(path);
    return DraftLabelled(
      label: label,
      tip: tip,
      child: draftInput(draft, path,
          initial: value == null ? '' : _plain(value),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: _validate,
          onChanged: (v) => draft.set(path, double.tryParse(v.trim()))),
    );
  }

  static String _plain(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}
