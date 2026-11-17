import 'package:flutter/material.dart';

import '../../core/admin_i18n.dart';
import '../../core/admin_theme.dart' show statusToneFor;
import '../../core/status_vocabulary.dart';
import '../../core/theme/kachava_tokens.dart';

/// Square status label: tone wash, tone text (AA) and a 1px tone line.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.tone});

  /// Builds a chip from a wire status (e.g. `ACTIVE_STAY`, `In progress`,
  /// `URGENT`) through the single [StatusVocabulary]; raw enums are never
  /// shown. [label] overrides the localized text.
  factory StatusChip.fromStatus(String rawStatus,
          {Key? key, String? label, bool? isEs}) =>
      StatusChip(
        key: key,
        label: label ?? AdminI18n.statusLabel(rawStatus, isEs),
        tone: StatusVocabulary.tone(rawStatus) ?? statusToneFor(rawStatus),
      );

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone.wash,
        border: Border.all(color: tone.line),
        borderRadius: BorderRadius.circular(KachavaTokens.radius),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: tone.foreground),
      ),
    );
  }
}
