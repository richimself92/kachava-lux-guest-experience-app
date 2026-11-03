import 'package:flutter/material.dart';

import '../../core/theme/kachava_tokens.dart';
import 'info_tooltip.dart';

/// Light-gray dashboard tile: a large value, a short gray label and an
/// optional ⓘ explanation.
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(KachavaTokens.space6),
      decoration: BoxDecoration(
        color: KachavaTokens.surface,
        borderRadius: BorderRadius.circular(KachavaTokens.radiusTile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
                fontSize: 40,
                height: 48 / 40,
                fontWeight: FontWeight.w400,
                color: scheme.onSurface),
          ),
          const SizedBox(height: KachavaTokens.space1),
          Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      color: scheme.onSurfaceVariant),
                ),
              ),
              if (info != null) InfoTooltip(info!),
            ],
          ),
        ],
      ),
    );
  }
}
