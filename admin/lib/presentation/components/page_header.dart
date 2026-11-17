import 'package:flutter/material.dart';

import '../../core/admin_theme.dart';
import 'info_tooltip.dart';

/// MUJI page header: optional `klLabel` eyebrow, title (26px on phones,
/// 32px from 600px wide) with an optional ⓘ, optional muted meta line and
/// trailing actions, closed by a bottom hairline with 24px below the text.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.titleKey,
    this.eyebrow,
    this.meta,
    this.info,
    this.actions = const [],
  });

  final String title;
  final Key? titleKey;
  final String? eyebrow;
  final String? meta;
  final String? info;
  final List<Widget> actions;

  /// Viewport width from which the title grows to 32px.
  static const double wideFrom = 600;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: KachavaTokens.space6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: KachavaTokens.line)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: KachavaTokens.space3,
        runSpacing: KachavaTokens.space2,
        children: [
          _heading(context),
          if (actions.isNotEmpty)
            Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ),
    );
  }

  Widget _heading(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final wide = MediaQuery.sizeOf(context).width >= wideFrom;
    final titleStyle = (wide ? text.headlineMedium : text.headlineSmall)
        ?.copyWith(color: KachavaTokens.ink);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null)
          Text(eyebrow!.toUpperCase(), style: KachavaAdminTheme.klLabel),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(child: Text(title, key: titleKey, style: titleStyle)),
          if (info != null) InfoTooltip(info!),
        ]),
        if (meta != null)
          Text(meta!,
              style: text.bodyMedium?.copyWith(color: KachavaTokens.muted)),
      ],
    );
  }
}
