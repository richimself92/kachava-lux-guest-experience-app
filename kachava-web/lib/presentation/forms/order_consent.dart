import 'package:flutter/material.dart';

import '../../core/i18n/l10n.dart';
import '../../core/theme/kachava_colors.dart';
import '../../domain/forms.dart';
import '../common/widgets.dart';

const _error = TextStyle(color: KachavaColors.dangerText, fontSize: 14);

/// Review-step consent: terms text, the substitution choice (when the
/// service asks) and the "I accept" checkbox (when it has terms).
class OrderConsent extends StatelessWidget {
  const OrderConsent({
    super.key,
    required this.l10n,
    required this.cart,
    required this.showIssues,
    required this.onSubstitutions,
    required this.onTerms,
  });

  final L10n l10n;
  final OrderCart cart;
  final bool showIssues;
  final ValueChanged<bool> onSubstitutions;
  final ValueChanged<bool> onTerms;

  bool _missing(FormIssue i) => showIssues && cart.issues.contains(i);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (cart.service.askSubstitutions) ..._substitutions(),
        if (cart.hasTerms) ..._terms(),
      ],
    );
  }

  List<Widget> _substitutions() => [
        const SizedBox(height: 16),
        KlLabel(l10n.substitutions),
        RadioGroup<bool>(
          groupValue: cart.substitutions,
          onChanged: (v) => v == null ? null : onSubstitutions(v),
          child: Column(children: [
            _option(true, l10n.substitutionsYes, 'subs-yes'),
            _option(false, l10n.substitutionsNo, 'subs-no'),
          ]),
        ),
        if (_missing(FormIssue.substitutionRequired))
          Text(l10n.issue(FormIssue.substitutionRequired), style: _error),
      ];

  Widget _option(bool value, String label, String key) => RadioListTile<bool>(
        key: Key(key),
        value: value,
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: const TextStyle(fontSize: 15)),
      );

  List<Widget> _terms() => [
        const SizedBox(height: 16),
        KlLabel(l10n.termsTitle),
        const SizedBox(height: 4),
        Text(l10n.text(cart.service.guestInfo.terms),
            key: const Key('order-terms'),
            style: const TextStyle(fontSize: 14, color: KachavaColors.muted)),
        CheckboxListTile(
          key: const Key('terms-check'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: cart.termsAccepted,
          onChanged: (v) => onTerms(v ?? false),
          title: Text(l10n.acceptTerms),
          subtitle: _missing(FormIssue.termsRequired)
              ? Text(l10n.issue(FormIssue.termsRequired), style: _error)
              : null,
        ),
      ];
}
