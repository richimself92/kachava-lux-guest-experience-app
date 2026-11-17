import 'package:flutter/material.dart';

import 'kachava_tokens.dart';

/// Route transition of the MUJI theme: a quiet fade, never a slide or zoom.
class KachavaFadeTransitionsBuilder extends PageTransitionsBuilder {
  const KachavaFadeTransitionsBuilder();

  @override
  Duration get transitionDuration => KachavaTokens.motion;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity:
          CurvedAnimation(parent: animation, curve: KachavaTokens.easeQuiet),
      child: child,
    );
  }
}

/// Every platform fades.
const PageTransitionsTheme kachavaFadePageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: KachavaFadeTransitionsBuilder(),
    TargetPlatform.iOS: KachavaFadeTransitionsBuilder(),
    TargetPlatform.macOS: KachavaFadeTransitionsBuilder(),
    TargetPlatform.windows: KachavaFadeTransitionsBuilder(),
    TargetPlatform.linux: KachavaFadeTransitionsBuilder(),
    TargetPlatform.fuchsia: KachavaFadeTransitionsBuilder(),
  },
);
