import 'package:flutter/material.dart';

import '../../core/theme/kachava_tokens.dart';

/// Paints the MUJI focus outline (1.5px ink, 2px outside [child]) while a
/// descendant has focus via the keyboard.
///
/// The ring is hidden for pointer/touch interaction (highlight mode touch).
class FocusRing extends StatefulWidget {
  const FocusRing({
    super.key,
    required this.child,
    this.borderRadius = KachavaTokens.radius,
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
    const width = 1.5;
    const offset = 2 + width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = KachavaTokens.ink;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            (Offset.zero & size).inflate(offset), Radius.circular(radius)),
        paint);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => oldDelegate.radius != radius;
}
