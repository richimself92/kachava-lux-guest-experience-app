import 'package:flutter/material.dart';

import '../../core/theme/kachava_theme.dart';

/// Fades [child] in (220ms) whenever [index] changes. The subtree is kept,
/// so tab state survives; no slide or scale. Skipped with reduced motion.
class TabFade extends StatefulWidget {
  const TabFade({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<TabFade> createState() => _TabFadeState();
}

class _TabFadeState extends State<TabFade> with SingleTickerProviderStateMixin {
  late final AnimationController _fade =
      AnimationController(vsync: this, duration: KachavaTheme.motion, value: 1);
  late final Animation<double> _opacity =
      CurvedAnimation(parent: _fade, curve: KachavaTheme.ease);

  @override
  void didUpdateWidget(covariant TabFade old) {
    super.didUpdateWidget(old);
    if (old.index == widget.index) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
    _fade.forward(from: 0);
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacity, child: widget.child);
}
