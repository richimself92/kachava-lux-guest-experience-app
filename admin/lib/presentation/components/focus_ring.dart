import 'package:flutter/material.dart';

import '../../core/theme/kachava_tokens.dart';

/// Paints a double focus ring (2px focus blue outside + 2px white inside)
/// around [child] while a descendant has focus via the keyboard.
///
/// The ring is hidden for pointer/touch interaction (highlight mode touch).
class FocusRing extends StatefulWidget {
  const FocusRing({
    super.key,
    required this.child,
    this.borderRadius = KachavaTokens.radiusMd,
  });

  final Widget child;
  final double borderRadius;

  @override
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing> {
  bool _focused = false;
  bool _keyboard =
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_onHighlightMode);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
    super.dispose();
  }

  void _onHighlightMode(FocusHighlightMode mode) {
    final keyboard = mode == FocusHighlightMode.traditional;
    if (keyboard != _keyboard && mounted) setState(() => _keyboard = keyboard);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (value) => setState(() => _focused = value),
      child: CustomPaint(
        foregroundPainter:
            _focused && _keyboard ? _RingPainter(widget.borderRadius) : null,
        child: widget.child,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.radius);

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    Paint stroke(Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = c;
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(1), Radius.circular(radius)),
        stroke(Colors.white));
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(1), Radius.circular(radius + 2)),
        stroke(KachavaTokens.focus));
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => oldDelegate.radius != radius;
}
