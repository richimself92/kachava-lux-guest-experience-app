import 'package:flutter/material.dart';

/// Kachava Lux guest-portal brand tokens (the guest portal keeps its own
/// look; root `DESIGN.md` governs the admin only).
///
/// Text on cream must use [onSurface], [onSurfaceVariant] (8.5:1) or
/// [tertiary] (5.4:1). [secondary] (3.5:1) is decorative only.
abstract final class KachavaColors {
  // Primary Palette (Mayan Zapote Timber & Espresso)
  static const Color primary = Color(0xFF754D24);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF8B6339);
  static const Color onPrimaryContainer = Color(0xFFF7E8D0);
  static const Color primaryDeep = Color(0xFF603917);
  static const Color inversePrimary = Color(0xFFC6B198);

  // Secondary & Tertiary Palette (Copal Resin & Caribbean Sand)
  static const Color secondary = Color(0xFFA67D52);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFC49A6C);
  static const Color onSecondaryContainer = Color(0xFF603917);
  static const Color tertiary = Color(0xFF736458);
  static const Color tertiaryContainer = Color(0xFFC6B198);

  // Surface & Background Palette (Warm Chukum Cream)
  static const Color surface = Color(0xFFFDF9F0);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF7F3EA);
  static const Color surfaceContainer = Color(0xFFF1EDE5);
  static const Color surfaceContainerHigh = Color(0xFFECE8DF);
  static const Color surfaceContainerHighest = Color(0xFFE6E2D9);
  static const Color surfaceDim = Color(0xFFE8E2D6);

  // Typography, Outline & Semantic Status Colors
  static const Color onSurface = Color(0xFF1C1C16);
  static const Color onSurfaceVariant = Color(0xFF544741);

  /// Metadata text; same value as [tertiary] so it passes WCAG AA on cream.
  static const Color mutedMetadata = Color(0xFF736458);
  static const Color outline = Color(0xFFC6B198);
  static const Color outlineStrong = Color(0xFF988575);
  static const Color inputBorder = Color(0xFFD1C5B8);

  // Semantic Status Tokens
  static const Color confirmedGreen = Color(0xFF3B6D41);
  static const Color confirmedGreenBg = Color(0xFFEEF5ED);
  static const Color errorRed = Color(0xFFBA1A1A);
  static const Color errorRedContainer = Color(0xFFFFDAD6);
  static const Color highlightGold = Color(0xFFFFDEAD);
}
