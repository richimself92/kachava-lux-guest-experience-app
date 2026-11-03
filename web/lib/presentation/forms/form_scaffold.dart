import 'package:flutter/material.dart';

import '../../core/i18n/l10n.dart';
import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';
import '../common/widgets.dart';

/// Full-screen form/wizard frame: numbered title, "Step 2 of 4" + bar,
/// fields, sticky primary, optional "Save & exit", one-line error + Retry.
class FormScaffold extends StatelessWidget {
  const FormScaffold({
    super.key,
    required this.l10n,
    required this.title,
    required this.children,
    required this.primaryLabel,
    required this.onPrimary,
    this.page = 0,
    this.pages = 1,
    this.busy = false,
    this.error,
    this.onRetry,
    this.onBack,
    this.secondaryLabel,
    this.onSecondary,
    this.bottomTop,
    this.info,
  });

  final L10n l10n;
  final String title;
  final List<Widget> children;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final int page;
  final int pages;
  final bool busy;
  final String? error;
  final VoidCallback? onRetry;

  /// Previous page; null pops the route.
  final VoidCallback? onBack;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final Widget? bottomTop;
  final String? info;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KachavaColors.surface,
      appBar: AppBar(
        backgroundColor: KachavaColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: l10n.back,
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontFamily: KachavaTheme.serifFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: KachavaColors.primary)),
        actions: [if (info != null) InfoTip(info!)],
      ),
      body: Column(
        children: [
          if (pages > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Text(l10n.stepOf(page + 1, pages),
                      style: const TextStyle(
                          fontSize: 14, color: KachavaColors.onSurfaceVariant)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (page + 1) / pages,
                        minHeight: 6,
                        color: KachavaColors.primary,
                        backgroundColor: KachavaColors.surfaceContainerHighest,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: PageWidth(
              maxWidth: 640,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: children,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: StickyAction(
        top: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (bottomTop != null) bottomTop!,
            if (error != null)
              InlineError(
                  message: error!, onRetry: onRetry, retryLabel: l10n.retry),
          ],
        ),
        secondary: secondaryLabel == null
            ? null
            : TextButton(
                onPressed: busy ? null : onSecondary,
                child: Text(secondaryLabel!)),
        child: FilledButton(
          key: const Key('form-primary'),
          onPressed: busy ? null : onPrimary,
          child: Text(busy ? l10n.sending : primaryLabel),
        ),
      ),
    );
  }
}

/// Field label + control + inline issue (<= 5 words).
class LabeledField extends StatelessWidget {
  const LabeledField(
      {super.key,
      required this.label,
      required this.child,
      this.issue,
      this.info});
  final String label;
  final Widget child;
  final String? issue;
  final String? info;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: KachavaColors.onSurface)),
            if (info != null) InfoTip(info!),
          ]),
          const SizedBox(height: 6),
          child,
          if (issue != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(issue!,
                  style: const TextStyle(
                      fontSize: 14, color: KachavaColors.errorRed)),
            ),
        ],
      ),
    );
  }
}

/// Tappable date field (opens the date picker).
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.l10n,
    required this.value,
    required this.onChanged,
    required this.first,
    required this.last,
    this.fieldKey,
  });

  final L10n l10n;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateTime first;
  final DateTime last;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: fieldKey,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        minimumSize: const Size.fromHeight(52),
        foregroundColor: KachavaColors.onSurface,
      ),
      icon: const Icon(Icons.calendar_today_outlined, size: 18),
      label: Text(value == null ? l10n.pickDate : l10n.date(value!)),
      onPressed: () async {
        final initial = value ?? first;
        final picked = await showDatePicker(
          context: context,
          initialDate: initial.isBefore(first)
              ? first
              : (initial.isAfter(last) ? last : initial),
          firstDate: first,
          lastDate: last,
        );
        if (picked != null) {
          onChanged(DateTime.utc(picked.year, picked.month, picked.day));
        }
      },
    );
  }
}

/// Selectable card (radio / checkbox) with optional photo.
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.selected,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.multiple = false,
    this.enabled = true,
  });

  final bool selected;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback onTap;
  final bool multiple;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: !multiple,
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? onTap : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: KachavaColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? KachavaColors.primary
                    : KachavaColors.inputBorder,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  multiple
                      ? (selected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank)
                      : (selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off),
                  color: selected
                      ? KachavaColors.primary
                      : KachavaColors.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                if (leading != null) ...[
                  SizedBox(width: 72, child: leading),
                  const SizedBox(width: 10)
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Text(subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14,
                                color: KachavaColors.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
