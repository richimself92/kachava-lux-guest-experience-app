import 'package:flutter/material.dart';

import 'focus_ring.dart';

/// An 18px ⓘ icon that explains a value without on-screen text.
///
/// Shows [message] on hover and keyboard focus (desktop) and on tap (touch);
/// screen readers get it through [Semantics]. Tap target is 48x48.
class InfoTooltip extends StatefulWidget {
  const InfoTooltip(this.message, {super.key});

  final String message;

  @override
  State<InfoTooltip> createState() => _InfoTooltipState();
}

class _InfoTooltipState extends State<InfoTooltip> {
  final GlobalKey<TooltipState> _tooltipKey = GlobalKey<TooltipState>();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Semantics(
      label: widget.message,
      child: ExcludeSemantics(
        child: Tooltip(
          key: _tooltipKey,
          message: widget.message,
          triggerMode: TooltipTriggerMode.tap,
          child: FocusRing(
            borderRadius: 24,
            child: Focus(
              onFocusChange: (focused) {
                if (focused) _tooltipKey.currentState?.ensureTooltipVisible();
              },
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Icon(Icons.info_outline, size: 18, color: color),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
