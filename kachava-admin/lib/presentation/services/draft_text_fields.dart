import 'package:flutter/material.dart';

import '../../core/service_catalog_strings.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../domain/item_pricing_rules.dart';
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
    this.validator,
  });

  final JsonDraft draft;
  final String path;
  final String label;
  final String? tip;
  final int maxLines;
  final bool nullIfBlank;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) => DraftLabelled(
        label: label,
        tip: tip,
        child: draftInput(draft, path,
            maxLines: maxLines,
            validator: validator,
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
    this.maxLength,
  });

  final JsonDraft draft;
  final String path;
  final String label;
  final bool isEs;
  final String? tip;
  final int maxLines;
  final bool requireOne;

  /// Characters allowed per language; `null` = no admin-side limit.
  final int? maxLength;

  String? _validate(String? _) {
    final blank = draft.text('$path.en').trim().isEmpty &&
        draft.text('$path.es').trim().isEmpty;
    return requireOne && blank
        ? ServiceCatalogStrings(isEs).nameRequired
        : null;
  }

  String? _length(String? raw) {
    final max = maxLength;
    return max != null && (raw ?? '').length > max
        ? ServiceCatalogStrings(isEs).maxChars(max)
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
                hint: 'EN',
                maxLines: maxLines,
                validator: (v) => _validate(v) ?? _length(v)),
          ),
          const SizedBox(width: KachavaTokens.space2),
          Expanded(
            child: draftInput(draft, '$path.es',
                hint: 'ES', maxLines: maxLines, validator: _length),
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

/// Amount, 0..1,000,000 with at most [decimals] decimals; blank stores
/// `null` (an error when [isRequired]; then it must also be above 0).
class DraftAmountField extends StatelessWidget {
  const DraftAmountField({
    super.key,
    required this.draft,
    required this.path,
    required this.label,
    required this.isEs,
    this.tip,
    this.decimals = 2,
    this.isRequired = false,
  });

  final JsonDraft draft;
  final String path;
  final String label;
  final bool isEs;
  final String? tip;
  final int decimals;
  final bool isRequired;

  String? _validate(String? raw) {
    final text = (raw ?? '').trim();
    final s = ServiceCatalogStrings(isEs);
    if (text.isEmpty) return isRequired ? s.priceRequired : null;
    if (!ItemPricingRules.amountOk(text, decimals: decimals)) {
      return s.invalidAmount;
    }
    return isRequired && double.parse(text) <= 0 ? s.priceRequired : null;
  }

  @override
  Widget build(BuildContext context) {
    final value = draft.doubleOrNull(path);
    return DraftLabelled(
      label: label,
      tip: tip,
      isRequired: isRequired,
      child: draftInput(draft, path,
          initial: value == null ? '' : plainAmount(value),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: _validate,
          onChanged: (v) => draft.set(path, double.tryParse(v.trim()))),
    );
  }
}

/// `12`, `12.50` or `3.3114` (up to 4 decimals, at least 2 when fractional).
String plainAmount(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  var text = v.toStringAsFixed(4);
  while (text.endsWith('0') && text.indexOf('.') < text.length - 3) {
    text = text.substring(0, text.length - 1);
  }
  return text;
}
