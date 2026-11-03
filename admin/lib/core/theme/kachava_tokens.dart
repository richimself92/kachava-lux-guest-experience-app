import 'dart:math' as math;
import 'dart:ui' show Color;

/// Kachava Lux admin design tokens (root `DESIGN.md`).
///
/// Prefer `Theme.of(context)` in widgets; use these constants only where the
/// theme has no matching role (status tones, tile radius, spacing).
abstract final class KachavaTokens {
  // Colors.
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF3F3F1);
  static const Color surfaceHover = Color(0xFFEBEBE8);
  static const Color primary = Color(0xFF6D4627);
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Restrained brown treatment for the selected navigation item: primary
  /// blended at 12% over white, paired with primary-colored bold text.
  static const Color primarySelected = Color(0xFFEEE9E5);

  /// Rare accent; never text and never the only carrier of status.
  static const Color accent = Color(0xFF989166);
  static const Color text = Color(0xFF202124);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color border = Color(0xFFDADCE0);
  static const Color inputBorder = Color(0xFF80868B);
  static const Color focus = Color(0xFF1A73E8);
  static const Color error = Color(0xFFB3261E);
  static const Color tooltip = Color(0xFF3C4043);

  // Status tone pairs (light background + dark foreground, AA contrast).
  static const Color successBackground = Color(0xFFE6F4EA);
  static const Color successForeground = Color(0xFF137333);
  static const Color infoBackground = Color(0xFFE8F0FE);
  static const Color infoForeground = Color(0xFF174EA6);
  static const Color neutralBackground = Color(0xFFF1F3F4);
  static const Color neutralForeground = Color(0xFF3C4043);
  static const Color warningBackground = Color(0xFFFEF7E0);
  static const Color warningForeground = Color(0xFF7A4A00);
  static const Color errorBackground = Color(0xFFFCE8E6);
  static const Color errorForeground = Color(0xFFA50E0E);

  // Radii.
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusTile = 12;
  static const double radiusPill = 999;

  // Spacing.
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space6 = 24;
  static const double space8 = 32;

  // Typography.
  static const String fontFamily = 'Roboto';
  static const List<String> fontFamilyFallback = ['Arial', 'sans-serif'];
}

/// Semantic status tones used by `StatusChip`.
enum StatusTone {
  success(KachavaTokens.successBackground, KachavaTokens.successForeground),
  info(KachavaTokens.infoBackground, KachavaTokens.infoForeground),
  neutral(KachavaTokens.neutralBackground, KachavaTokens.neutralForeground),
  warning(KachavaTokens.warningBackground, KachavaTokens.warningForeground),
  error(KachavaTokens.errorBackground, KachavaTokens.errorForeground);

  const StatusTone(this.background, this.foreground);

  final Color background;
  final Color foreground;
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
