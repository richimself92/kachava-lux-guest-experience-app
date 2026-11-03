import 'package:flutter/material.dart';

import '../../core/i18n/l10n.dart';
import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';
import '../../data/guest_api.dart';
import '../../domain/catalog.dart';
import '../../domain/requests.dart';

/// ⓘ: explanations live here, never as paragraphs on screen.
class InfoTip extends StatelessWidget {
  const InfoTip(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 4),
      child: const SizedBox(
        width: KachavaTheme.minTarget,
        height: KachavaTheme.minTarget,
        child: Icon(Icons.info_outline,
            size: 20, color: KachavaColors.onSurfaceVariant),
      ),
    );
  }
}

/// Empty / error state: one line + one action.
class OneLineState extends StatelessWidget {
  const OneLineState({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 32, color: KachavaColors.onSurfaceVariant),
          if (icon != null) const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16, color: KachavaColors.onSurface)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Inline error line kept above the action; form data is never lost.
class InlineError extends StatelessWidget {
  const InlineError(
      {super.key, required this.message, this.onRetry, this.retryLabel});
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              size: 18, color: KachavaColors.errorRed),
          const SizedBox(width: 6),
          Expanded(
            child: Text(message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14, color: KachavaColors.errorRed)),
          ),
          if (onRetry != null && retryLabel != null)
            TextButton(onPressed: onRetry, child: Text(retryLabel!)),
        ],
      ),
    );
  }
}

/// Status chip: word + icon, never colour alone.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, required this.l10n});
  final RequestStatus status;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final (icon, fg, bg) = switch (status) {
      RequestStatus.received => (
          Icons.inbox_outlined,
          KachavaColors.onSurfaceVariant,
          KachavaColors.surfaceContainerHigh
        ),
      RequestStatus.confirmed => (
          Icons.check_circle_outline,
          KachavaColors.confirmedGreen,
          KachavaColors.confirmedGreenBg
        ),
      RequestStatus.preparing => (
          Icons.timelapse,
          KachavaColors.primary,
          KachavaColors.surfaceContainerHigh
        ),
      RequestStatus.onTheWay => (
          Icons.directions_car_outlined,
          KachavaColors.primary,
          KachavaColors.surfaceContainerHigh
        ),
      RequestStatus.done => (
          Icons.task_alt,
          KachavaColors.confirmedGreen,
          KachavaColors.confirmedGreenBg
        ),
      RequestStatus.cancelled => (
          Icons.cancel_outlined,
          KachavaColors.errorRed,
          KachavaColors.errorRedContainer
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(l10n.status(status),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
          ),
        ],
      ),
    );
  }
}

/// 4-dot progress track (Received → Confirmed → Preparing/On the way → Done).
class StatusTrack extends StatelessWidget {
  const StatusTrack({super.key, required this.status});
  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final at = status.trackIndex;
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 4; i++)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= at ? KachavaColors.primary : Colors.transparent,
                border: Border.all(color: KachavaColors.outlineStrong),
              ),
            ),
        ],
      ),
    );
  }
}

/// Grey box with the final layout size (no layout shift).
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height = 16, this.radius = 8});
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: KachavaColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

/// 16:9 photo with its box reserved before it loads; alt text in [l10n].
class ServicePhoto extends StatelessWidget {
  const ServicePhoto(
      {super.key, required this.image, required this.l10n, this.radius = 12});
  final CatalogImage? image;
  final L10n l10n;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final img = image;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          color: KachavaColors.surfaceContainerHighest,
          child: img == null
              ? const Icon(Icons.image_outlined,
                  color: KachavaColors.onSurfaceVariant)
              : Semantics(
                  image: true,
                  label: l10n.text(img.alt),
                  child: Image.network(
                    img.url,
                    fit: BoxFit.cover,
                    cacheWidth: 960,
                    excludeFromSemantics: true,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_not_supported_outlined,
                        color: KachavaColors.onSurfaceVariant),
                  ),
                ),
        ),
      ),
    );
  }
}

/// 48px − n + stepper.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.min = 0,
    this.max = 20,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final String label;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      value: '$value',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: '− $label',
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 28,
            child: Text('$value',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          IconButton(
            tooltip: '+ $label',
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}

/// One-line toast above the tab bar: 4 s, errors 8 s with Retry.
void showPortalToast(BuildContext context, String message,
    {bool error = false, VoidCallback? onRetry, String? retryLabel}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Semantics(
        liveRegion: true,
        child: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      backgroundColor: error ? KachavaColors.errorRed : KachavaColors.onSurface,
      duration: Duration(seconds: error ? 8 : 4),
      action: onRetry == null
          ? null
          : SnackBarAction(
              label: retryLabel ?? 'Retry',
              textColor: Colors.white,
              onPressed: onRetry),
    ));
}

/// One-line message for a failed write.
String failureMessage(L10n l10n, ApiResult<Object?> result) => switch (result) {
      ApiFailed(kind: FailureKind.linkRejected) => l10n.linkExpired,
      ApiFailed(kind: FailureKind.notConfigured) => l10n.notConfigured,
      ApiFailed(kind: FailureKind.invalid) => l10n.checkDetails,
      _ => l10n.sendFailed,
    };

/// Primary action pinned in the thumb zone.
class StickyAction extends StatelessWidget {
  const StickyAction(
      {super.key, required this.child, this.secondary, this.top});
  final Widget child;
  final Widget? secondary;
  final Widget? top;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KachavaColors.surface,
      elevation: 6,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (top != null) top!,
              child,
              if (secondary != null) secondary!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Page container with the 960px max width used across the portal.
class PageWidth extends StatelessWidget {
  const PageWidth({super.key, required this.child, this.maxWidth = 960});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      );
}

/// Filter chip with a 48px target; selected = filled + check.
class SelectChip extends StatelessWidget {
  const SelectChip(this.label, this.selected, this.onTap, {super.key});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: FilterChip(
          label: Text(label),
          selected: selected,
          showCheckmark: true,
          selectedColor: KachavaColors.surfaceContainerHighest,
          materialTapTargetSize: MaterialTapTargetSize.padded,
          onSelected: (_) => onTap(),
        ),
      );
}
