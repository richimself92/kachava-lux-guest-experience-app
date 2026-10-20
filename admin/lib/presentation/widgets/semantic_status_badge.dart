import 'package:flutter/material.dart';
import '../../core/admin_i18n.dart';
import '../../core/admin_theme.dart';

/// Semantic operational pill badge styled according to UI/UX Section 6.2.
class SemanticStatusBadge extends StatelessWidget {
  const SemanticStatusBadge({
    super.key,
    required this.label,
    this.customStyle,
  });

  final String label;
  final AdminBadgeStyle? customStyle;

  @override
  Widget build(BuildContext context) {
    final style = customStyle ?? KachavaAdminColors.forStatus(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.border),
      ),
      child: Text(
        AdminI18n.statusLabel(label),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: style.foreground,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Editorial workspace section header with Libre Baskerville title and eyebrow.
class AdminSectionHeader extends StatelessWidget {
  const AdminSectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            color: KachavaAdminColors.mutedBronze,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Libre Baskerville',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: KachavaAdminColors.zapotePrimary,
          ),
        ),
      ],
    );
    if (trailing == null) {
      return titleBlock;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 480) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 10),
              trailing!,
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 12),
            trailing!,
          ],
        );
      },
    );
  }
}

/// Clean empty-state card displayed when a workspace collection has 0 records.
class AdminEmptyStateBox extends StatelessWidget {
  const AdminEmptyStateBox({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('admin-empty-state-box'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: KachavaAdminColors.surfacePaper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KachavaAdminColors.borderLimestone),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_outlined,
            color: KachavaAdminColors.zapotePrimary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: KachavaAdminColors.obsidian,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
