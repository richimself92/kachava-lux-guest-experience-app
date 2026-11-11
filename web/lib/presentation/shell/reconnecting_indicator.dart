import 'package:flutter/material.dart';
import '../../core/theme/kachava_colors.dart';

/// Small non-blocking status line shown while the server is unreachable.
class ReconnectingIndicator extends StatelessWidget {
  const ReconnectingIndicator({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Padding(
        key: const Key('reconnecting-indicator'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_sync_outlined,
                size: 16, color: KachavaColors.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 14, color: KachavaColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
