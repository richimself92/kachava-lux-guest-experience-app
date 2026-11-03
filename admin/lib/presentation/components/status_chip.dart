import 'package:flutter/material.dart';

import '../../core/admin_i18n.dart';
import '../../core/admin_theme.dart' show statusToneFor;
import '../../core/theme/kachava_tokens.dart';

/// Pill-shaped status label: light tone background + dark tone text (AA).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.tone});

  /// Builds a chip from a raw operational status (e.g. `ACTIVE_STAY`,
  /// `In progress`, `URGENT`). [label] overrides the localized status text.
  factory StatusChip.fromStatus(String rawStatus, {Key? key, String? label}) =>
      StatusChip(
        key: key,
        label: label ?? AdminI18n.statusLabel(rawStatus),
        tone: statusToneFor(rawStatus),
      );

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(KachavaTokens.radiusPill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: tone.foreground,
            ),
      ),
    );
  }
}
