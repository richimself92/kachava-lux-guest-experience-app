import 'package:flutter/material.dart';

import '../../core/i18n/l10n.dart';
import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';
import '../../data/guest_api.dart';
import '../../domain/catalog.dart';
import '../../domain/requests.dart';
import 'kit.dart';

export 'kit.dart';

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
        child: Icon(Icons.info_outline, size: 20, color: KachavaColors.muted),
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
          if (icon != null) Icon(icon, size: 32, color: KachavaColors.muted),
          if (icon != null) const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: KachavaColors.ink)),
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
      child: Callout(
        rule: KachavaColors.dangerText,
        child: Row(
          children: [
            const Icon(Icons.error_outline,
                size: 18, color: KachavaColors.dangerText),
            const SizedBox(width: 6),
            Expanded(
              child: Text(message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, color: KachavaColors.dangerText)),
            ),
            if (onRetry != null && retryLabel != null)
              TextButton(onPressed: onRetry, child: Text(retryLabel!)),
          ],
        ),
      ),
    );
  }
}

/// Status label: word + icon on its status wash, square; never a pill and
/// never colour alone.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, required this.l10n});
  final RequestStatus status;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final (icon, tone) = switch (status) {
      RequestStatus.received => (Icons.inbox_outlined, KachavaColors.pending),
      RequestStatus.arranging => (Icons.support_agent, KachavaColors.info),
      RequestStatus.confirmed => (Icons.check_circle_outline, KachavaColors.ok),
      RequestStatus.preparing => (Icons.timelapse, KachavaColors.info),
      RequestStatus.onTheWay => (
          Icons.directions_car_outlined,
          KachavaColors.info
        ),
      RequestStatus.done => (Icons.task_alt, KachavaColors.ok),
      RequestStatus.cancelled => (Icons.cancel_outlined, KachavaColors.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone.wash,
        borderRadius: KachavaTheme.borderRadius,
        border: Border.all(color: tone.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tone.text),
          const SizedBox(width: 4),
          Flexible(
            child: Text(l10n.status(status),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: tone.text)),
          ),
        ],
      ),
    );
  }
}

/// 4-dot progress track (Received → Confirmed → In progress/On the way → Done).
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
                border: Border.all(color: KachavaColors.lineStrong),
              ),
            ),
        ],
      ),
    );
  }
}

/// Grey box with the final layout size (no layout shift).
class SkeletonBox extends StatelessWidget {
  const SkeletonBox(
      {super.key,
      this.width,
      this.height = 16,
      this.radius = KachavaTheme.radius});
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: KachavaColors.wash,
          borderRadius: BorderRadius.all(Radius.circular(radius)),
        ),
      );
}

/// 16:9 photo with its box reserved before it loads; alt text in [l10n].
///
/// Decoded at the size it is shown ([decodeWidth]), never larger: decoding
/// full-size covers for small cards kept the page busy right when the guest
/// opened Services and started typing in the search.
class ServicePhoto extends StatelessWidget {
  const ServicePhoto(
      {super.key,
      required this.image,
      required this.l10n,
      this.radius = KachavaTheme.radius});
  final CatalogImage? image;
  final L10n l10n;
  final double radius;

  /// Largest decode width (physical pixels) of any photo.
  static const int maxDecodeWidth = 960;

  /// Physical pixels needed to show [logicalWidth] at [pixelRatio].
  static int decodeWidth(double logicalWidth, double pixelRatio) {
    if (!logicalWidth.isFinite || logicalWidth <= 0) return maxDecodeWidth;
    return (logicalWidth * pixelRatio).ceil().clamp(1, maxDecodeWidth);
  }

  @override
  Widget build(BuildContext context) {
    final img = image;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(radius)),
        child: Container(
          color: KachavaColors.wash,
          child: img == null
              ? const Icon(Icons.image_outlined, color: KachavaColors.muted)
              : LayoutBuilder(
                  builder: (context, box) => Semantics(
                    image: true,
                    label: l10n.text(img.alt),
                    child: Image.network(
                      img.url,
                      fit: BoxFit.cover,
                      cacheWidth: decodeWidth(box.maxWidth, pixelRatio),
                      excludeFromSemantics: true,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_not_supported_outlined,
                          color: KachavaColors.muted),
                    ),
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
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFeatures: KachavaTheme.tabular)),
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
      backgroundColor: error ? KachavaColors.dangerText : KachavaColors.ink,
      shape: KachavaTheme.shape,
      elevation: 0,
      duration: Duration(seconds: error ? 8 : 4),
      action: onRetry == null
          ? null
          : SnackBarAction(
              label: retryLabel ?? 'Retry',
              textColor: KachavaColors.onBrand,
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
      shape: const Border(top: BorderSide(color: KachavaColors.line)),
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

/// Category filter: text-only segmented tab (see [SegmentTab]).
class SelectChip extends StatelessWidget {
  const SelectChip(this.label, this.selected, this.onTap, {super.key});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SegmentTab(label, selected, onTap);
}
