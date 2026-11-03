import 'package:flutter/material.dart';
import '../../core/admin_theme.dart';
import '../components/status_chip.dart';

/// Operational status pill. Renders a `StatusChip` tone for [label].
class SemanticStatusBadge extends StatelessWidget {
  const SemanticStatusBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => StatusChip.fromStatus(label);
}

/// One-line empty state shown when a workspace collection has 0 records.
class AdminEmptyStateBox extends StatelessWidget {
  const AdminEmptyStateBox({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('admin-empty-state-box'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: KachavaTokens.surface,
        borderRadius: BorderRadius.circular(KachavaTokens.radiusLg),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              size: 22, color: KachavaTokens.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: KachavaTokens.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
