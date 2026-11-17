import 'package:flutter/material.dart';

import 'kachava_tokens.dart';

/// MUJI type: Zen Kaku Gothic New (display, w500, 0.02em tracking) for titles
/// and labels; Noto Sans (w400 body, w500 emphasis) for text. No bold.
abstract final class KachavaTextStyles {
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  /// Sidebar row text size.
  static const double navSize = 15;

  /// "KACHAVA LUX" wordmark of the sidebar and drawer.
  static const TextStyle wordmark = TextStyle(
    fontFamily: KachavaTokens.fontDisplay,
    fontFamilyFallback: KachavaTokens.fontFamilyFallback,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 18 * 0.08,
    color: KachavaTokens.ink,
  );

  /// 12px helper text: origins, inline errors, status lines.
  static const TextStyle caption = TextStyle(
    fontFamily: KachavaTokens.fontSans,
    fontFamilyFallback: KachavaTokens.fontFamilyFallback,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
  );

  /// The signature small uppercase label; widgets apply the uppercase.
  static const TextStyle klLabel = TextStyle(
    fontFamily: KachavaTokens.fontDisplay,
    fontFamilyFallback: KachavaTokens.fontFamilyFallback,
    fontSize: 11,
    height: 1.4,
    fontWeight: FontWeight.w500,
    letterSpacing: 11 * 0.14,
    color: KachavaTokens.muted,
  );

  static TextStyle display(double size, double lineHeight) => TextStyle(
        fontFamily: KachavaTokens.fontDisplay,
        fontFamilyFallback: KachavaTokens.fontFamilyFallback,
        fontSize: size,
        height: lineHeight / size,
        fontWeight: FontWeight.w500,
        letterSpacing: size * 0.02,
      );

  static TextStyle sans(double size, double lineHeight,
          {FontWeight weight = FontWeight.w400}) =>
      TextStyle(
        fontFamily: KachavaTokens.fontSans,
        fontFamilyFallback: KachavaTokens.fontFamilyFallback,
        fontSize: size,
        height: lineHeight / size,
        fontWeight: weight,
      );

  /// Full text theme. [inputSize] is the body text size that inputs use
  /// (16 on touch platforms to avoid iOS zoom, 14 elsewhere).
  static TextTheme textTheme({required double inputSize}) => TextTheme(
        displayLarge: display(48, 56),
        displayMedium: display(40, 48),
        displaySmall: display(36, 44),
        headlineLarge: display(32, 40),
        headlineMedium: display(32, 40),
        headlineSmall: display(26, 34),
        titleLarge: display(18, 26),
        titleMedium: display(14, 20),
        titleSmall: display(14, 20),
        bodyLarge: sans(inputSize, inputSize + 8),
        bodyMedium: sans(14, 20),
        bodySmall: sans(12, 16),
        labelLarge: sans(14, 20, weight: FontWeight.w500),
        labelMedium: sans(12, 16, weight: FontWeight.w500),
        labelSmall: sans(11, 16, weight: FontWeight.w500),
      );
}
