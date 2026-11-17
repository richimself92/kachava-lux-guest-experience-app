import 'package:flutter/material.dart';

import '../../core/admin_theme.dart';

/// Section heading inside a page: an uppercase `klLabel` eyebrow such as
/// "01 — Activity" over a quiet display title. Never used in the nav.
class SectionHead extends StatelessWidget {
  const SectionHead({
    super.key,
    required this.title,
    this.eyebrow,
    this.titleKey,
    this.trailing = const [],
  });

  final String title;
  final String? eyebrow;
  final Key? titleKey;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context)
        .textTheme
        .titleLarge
        ?.copyWith(color: KachavaTokens.ink);
    return Semantics(
      header: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null)
                  Text(eyebrow!.toUpperCase(),
                      style: KachavaAdminTheme.klLabel),
                Text(title, key: titleKey, style: style),
              ],
            ),
          ),
          ...trailing,
        ],
      ),
    );
  }
}

/// A section separated by a 1px `line` top rule and 16px above its content,
/// instead of a card or tinted box.
class RuledSection extends StatelessWidget {
  const RuledSection({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.only(top: KachavaTokens.space4),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: KachavaTokens.line)),
        ),
        child: child,
      );
}

/// A callout: a 2px left rule in the status color with 16px left padding,
/// instead of a tinted card.
class Callout extends StatelessWidget {
  const Callout({super.key, required this.tone, required this.child});

  final StatusTone tone;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.only(left: KachavaTokens.space4),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: tone.foreground, width: 2)),
        ),
        child: child,
      );
}
