import 'package:flutter/material.dart';

import '../../core/admin_theme.dart';
import 'info_tooltip.dart';

/// One metric cell of a [HairlineGrid]: an uppercase `klLabel` with an
/// optional ⓘ explanation over a large tabular display value. It has no
/// fill or radius of its own; the grid draws the cell and its rules.
class KpiTile extends StatelessWidget {
  const KpiTile({
    super.key,
    required this.value,
    required this.label,
    this.info,
  });

  final String value;
  final String label;

  /// Optional formula/explanation shown in an [InfoTooltip].
  final String? info;

  Widget _label() => Row(children: [
        Flexible(
          child: Text(label.toUpperCase(), style: KachavaAdminTheme.klLabel),
        ),
        if (info != null) InfoTooltip(info!) else const SizedBox(height: 48),
      ]);

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(context).textTheme.displaySmall?.copyWith(
        color: KachavaTokens.ink, fontFeatures: KachavaTextStyles.tabular);
    return Padding(
      padding: const EdgeInsets.fromLTRB(KachavaTokens.space4,
          KachavaTokens.space2, KachavaTokens.space2, KachavaTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [_label(), Text(value, style: valueStyle)],
      ),
    );
  }
}
