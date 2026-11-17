import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter/animation.dart' show Cubic;

/// Kachava Lux admin design tokens (MUJI restyle, root `DESIGN.md` v2.0 and
/// `MUJI Design Implementation Guide.md`). This is the only file with color
/// values; widgets read these tokens or `Theme.of(context)`.
abstract final class KachavaTokens {
  // Neutrals (warm, tinted toward the brand).
  static const Color paper = Color(0xFFF4F2EC); // scaffold
  static const Color surface = Color(0xFFFAF9F5); // tables, dialogs, inputs
  static const Color wash = Color(0xFFECE9E1); // hover, quiet fills, selected
  static const Color ink = Color(0xFF2A2A28); // text, focus outline
  static const Color muted = Color(0xFF6B6A65); // secondary text, labels
  static const Color faint = Color(0xFFA3A097); // placeholder, disabled
  static const Color line = Color(0xFFD9D6CD); // hairlines
  static const Color lineStrong = Color(0xFFC2BEB2); // button/input outlines

  // The single accent.
  static const Color brand = Color(0xFF6D4627);
  static const Color brandDeep = Color(0xFF55361D); // primary hover
  static const Color onBrand = Color(0xFFFAF9F5);

  // Status colors: text / wash / line (text on wash >= 4.5:1).
  static const Color pending = Color(0xFF8F611A); // ochre
  static const Color pendingWash = Color(0xFFF3EBD9);
  static const Color pendingLine = Color(0xFFE2D2AE);
  static const Color info = Color(0xFF3F5A7A); // ink blue
  static const Color infoWash = Color(0xFFE6EBF1);
  static const Color infoLine = Color(0xFFC9D3DF);
  static const Color ok = Color(0xFF4F6B3A); // moss
  static const Color okWash = Color(0xFFE8EDE1);
  static const Color okLine = Color(0xFFCDD8C1);
  static const Color danger = Color(0xFFA8322D); // brick
  static const Color dangerWash = Color(0xFFF5E3E1);
  static const Color dangerLine = Color(0xFFE6C3BF);
  static const Color plum = Color(0xFF6E4E6B); // on hold
  static const Color plumWash = Color(0xFFEFE7EE);
  static const Color plumLine = Color(0xFFD9C8D6);

  // Edges: square 2px everywhere; round only for dots and avatars.
  static const double radius = 2;
  static const double radiusRound = 999;

  // Motion: imperceptible fades only.
  static const Duration motion = Duration(milliseconds: 220);
  static const Duration motionFast = Duration(milliseconds: 150);
  static const Cubic easeQuiet = Cubic(0.2, 0, 0, 1);

  // Spacing.
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space6 = 24;
  static const double space8 = 32;

  // Typography.
  static const String fontSans = 'Noto Sans';
  static const String fontDisplay = 'Zen Kaku Gothic New';
  static const List<String> fontFamilyFallback = [
    'Noto Sans',
    'Helvetica Neue',
    'Arial',
    'sans-serif',
  ];
}

/// Semantic status tones used by `StatusChip`: text, wash and line colors.
enum StatusTone {
  success(KachavaTokens.ok, KachavaTokens.okWash, KachavaTokens.okLine),
  info(KachavaTokens.info, KachavaTokens.infoWash, KachavaTokens.infoLine),
  // Muted on wash is 4.47:1, so neutral labels sit on surface (5.14:1).
  neutral(KachavaTokens.muted, KachavaTokens.surface, KachavaTokens.line),
  warning(KachavaTokens.pending, KachavaTokens.pendingWash,
      KachavaTokens.pendingLine),
  error(
      KachavaTokens.danger, KachavaTokens.dangerWash, KachavaTokens.dangerLine),
  onHold(KachavaTokens.plum, KachavaTokens.plumWash, KachavaTokens.plumLine);

  const StatusTone(this.foreground, this.wash, this.line);

  /// Status text color.
  final Color foreground;

  /// Quiet background of a status label.
  final Color wash;

  /// 1px border of a status label.
  final Color line;
}

/// WCAG 2.x contrast ratio between two opaque colors (1.0 to 21.0).
double contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

double _relativeLuminance(Color c) =>
    0.2126 * _linear(c.r) + 0.7152 * _linear(c.g) + 0.0722 * _linear(c.b);

double _linear(double channel) => channel <= 0.04045
    ? channel / 12.92
    : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
