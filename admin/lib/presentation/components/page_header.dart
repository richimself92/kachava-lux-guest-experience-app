import 'package:flutter/material.dart';

import 'info_tooltip.dart';

/// Page title (headlineSmall) with an optional ⓘ and trailing actions.
/// Replaces eyebrow + subtitle banners.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.info,
    this.actions = const [],
  });

  final String title;
  final String? info;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child:
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
            ),
            if (info != null) InfoTooltip(info!),
          ],
        ),
        if (actions.isNotEmpty)
          Wrap(spacing: 8, runSpacing: 8, children: actions),
      ],
    );
  }
}
