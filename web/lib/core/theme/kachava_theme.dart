import 'package:flutter/material.dart';
import 'kachava_colors.dart';

/// Guest-portal brand theme: Libre Baskerville titles, Libre Franklin text.
/// Every text style is >= 14px (body 16) and uses an AA colour on cream.
abstract final class KachavaTheme {
  static const String serifFamily = 'Libre Baskerville';
  static const String sansFamily = 'Libre Franklin';

  /// Minimum touch target on every interactive element.
  static const double minTarget = 48;

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

    const focusSide = BorderSide(color: KachavaColors.primary, width: 2);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: KachavaColors.surfaceContainerLow,
      fontFamily: sansFamily,
      textTheme: _buildTextTheme(),
      dividerColor: KachavaColors.surfaceContainerHighest,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      focusColor: KachavaColors.primary.withValues(alpha: 0.12),
      cardTheme: CardThemeData(
        color: KachavaColors.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: KachavaColors.surfaceContainerHighest),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(minTarget, 52),
          textStyle: const TextStyle(
              fontFamily: sansFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(minTarget, minTarget),
          textStyle: const TextStyle(
              fontFamily: sansFamily,
              fontSize: 15,
              fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(minTarget, minTarget),
          textStyle: const TextStyle(
              fontFamily: sansFamily,
              fontSize: 15,
              fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: const ChipThemeData(
        labelStyle: TextStyle(fontSize: 14, color: KachavaColors.onSurface),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: KachavaColors.surfaceContainerLowest,
        labelStyle:
            TextStyle(fontSize: 15, color: KachavaColors.onSurfaceVariant),
        border: OutlineInputBorder(
            borderSide: BorderSide(color: KachavaColors.inputBorder)),
        enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: KachavaColors.inputBorder)),
        focusedBorder: OutlineInputBorder(borderSide: focusSide),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: KachavaColors.surface,
        indicatorColor: KachavaColors.surfaceContainerHigh,
        labelTextStyle: WidgetStateProperty.all(const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: KachavaColors.onSurface)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        contentTextStyle: TextStyle(fontSize: 15, color: Colors.white),
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return const TextTheme(
      headlineMedium: TextStyle(
        fontFamily: serifFamily,
        fontSize: 24,
        height: 1.30,
        fontWeight: FontWeight.w400,
        color: KachavaColors.primary,
      ),
      titleLarge: TextStyle(
        fontFamily: serifFamily,
        fontSize: 20,
        height: 1.33,
        fontWeight: FontWeight.w700,
        color: KachavaColors.primary,
      ),
      titleMedium: TextStyle(
        fontFamily: serifFamily,
        fontSize: 17,
        height: 1.35,
        fontWeight: FontWeight.w700,
        color: KachavaColors.onSurface,
      ),
      bodyLarge: TextStyle(
        fontFamily: sansFamily,
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: KachavaColors.onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: sansFamily,
        fontSize: 15,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: KachavaColors.onSurfaceVariant,
      ),
      bodySmall: TextStyle(
        fontFamily: sansFamily,
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: KachavaColors.tertiary,
      ),
      labelLarge: TextStyle(
        fontFamily: sansFamily,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: KachavaColors.onSurface,
      ),
      labelMedium: TextStyle(
        fontFamily: sansFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: KachavaColors.onSurfaceVariant,
      ),
      labelSmall: TextStyle(
        fontFamily: sansFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: KachavaColors.tertiary,
      ),
    );
  }
}
