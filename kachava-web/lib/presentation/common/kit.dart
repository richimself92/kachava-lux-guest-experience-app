import 'package:flutter/material.dart';

import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';

/// Small uppercase tracked label (eyebrows, form labels, metadata).
class KlLabel extends StatelessWidget {
  const KlLabel(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: color == null
          ? KachavaTheme.klLabel
          : KachavaTheme.klLabel.copyWith(color: color));
}

/// Callout: a 2px left rule in the status colour, never a tinted box.
class Callout extends StatelessWidget {
  const Callout({super.key, required this.child, required this.rule});
  final Widget child;
  final Color rule;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.only(left: 16),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: rule, width: 2)),
        ),
        child: child,
      );
}

/// Text-only segmented tab: selected = ink text over a 1px ink rule.
class SegmentTab extends StatelessWidget {
  const SegmentTab(this.label, this.selected, this.onTap, {super.key});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: KachavaTheme.minTarget),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: selected ? KachavaColors.ink : Colors.transparent),
            ),
          ),
          child: Align(
            widthFactor: 1,
            child: Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                    color: selected ? KachavaColors.ink : KachavaColors.muted)),
          ),
        ),
      ),
    );
  }
}
