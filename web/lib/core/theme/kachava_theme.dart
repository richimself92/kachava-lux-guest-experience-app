import 'package:flutter/material.dart';
import 'kachava_colors.dart';

/// Builds the editorial biophilic luxury Material 3 ThemeData for Kachava Lux.
abstract final class KachavaTheme {
  static const String serifFamily = 'Libre Baskerville';
  static const String sansFamily = 'Libre Franklin';

  static ThemeData buildTheme() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: KachavaColors.primary,
      onPrimary: KachavaColors.onPrimary,
      primaryContainer: KachavaColors.primaryContainer,
      onPrimaryContainer: KachavaColors.onPrimaryContainer,
      secondary: KachavaColors.secondary,
      onSecondary: KachavaColors.onSecondary,
      secondaryContainer: KachavaColors.secondaryContainer,
      onSecondaryContainer: KachavaColors.onSecondaryContainer,
      tertiary: KachavaColors.tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: KachavaColors.tertiaryContainer,
      onTertiaryContainer: KachavaColors.onSurface,
      error: KachavaColors.errorRed,
      onError: Colors.white,
      errorContainer: KachavaColors.errorRedContainer,
      onErrorContainer: KachavaColors.errorRed,
      surface: KachavaColors.surface,
      onSurface: KachavaColors.onSurface,
      onSurfaceVariant: KachavaColors.onSurfaceVariant,
      outline: KachavaColors.outlineStrong,
      outlineVariant: KachavaColors.outline,
      inversePrimary: KachavaColors.inversePrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: KachavaColors.surfaceContainerLow,
      fontFamily: sansFamily,
      textTheme: _buildTextTheme(),
      dividerColor: KachavaColors.surfaceContainerHighest,
      cardTheme: CardThemeData(
        color: KachavaColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: KachavaColors.surfaceContainerHighest),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return const TextTheme(
      displaySmall: TextStyle(
        fontFamily: serifFamily,
        fontSize: 32,
        height: 1.23,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.34,
        color: KachavaColors.primary,
      ),
      headlineMedium: TextStyle(
        fontFamily: serifFamily,
        fontSize: 25,
        height: 1.30,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.26,
        color: KachavaColors.primary,
      ),
      titleLarge: TextStyle(
        fontFamily: serifFamily,
        fontSize: 20,
        height: 1.33,
        fontWeight: FontWeight.w700,
        color: KachavaColors.primary,
      ),
      bodyLarge: TextStyle(
        fontFamily: sansFamily,
        fontSize: 16,
        height: 1.60,
        fontWeight: FontWeight.w300,
        color: KachavaColors.onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: sansFamily,
        fontSize: 14,
        height: 1.55,
        fontWeight: FontWeight.w400,
        color: KachavaColors.onSurfaceVariant,
      ),
      bodySmall: TextStyle(
        fontFamily: sansFamily,
        fontSize: 12,
        height: 1.50,
        fontWeight: FontWeight.w400,
        color: KachavaColors.mutedMetadata,
      ),
      labelMedium: TextStyle(
        fontFamily: sansFamily,
        fontSize: 11,
        height: 1.45,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.32,
        color: KachavaColors.secondary,
      ),
      labelSmall: TextStyle(
        fontFamily: sansFamily,
        fontSize: 10,
        height: 1.40,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.40,
        color: KachavaColors.secondary,
      ),
    );
  }
}
