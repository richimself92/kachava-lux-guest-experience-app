import 'package:flutter/material.dart';

import 'theme/kachava_tokens.dart';

export 'theme/kachava_tokens.dart';

/// Maps a raw operational status string to its [StatusTone].
///
/// Keys match whole words only ('ISLAND' is not 'SLA'); a multi-word key such
/// as 'CHECKED_OUT' matches those words in sequence.
StatusTone statusToneFor(String rawStatus) {
  final words = rawStatus
      .toUpperCase()
      .split(RegExp(r'[^A-Z]+'))
      .where((w) => w.isNotEmpty)
      .join('_');
  final s = '_${words}_';
  bool has(List<String> keys) => keys.any((k) => s.contains('_${k}_'));
  if (has(
      ['URGENT', 'ALLERGY', 'SLA', 'OVERDUE', 'OVERSTAY', 'ERROR', 'DIRECT'])) {
    return StatusTone.error;
  }
  if (has(['CHECKED_OUT', 'DEPARTURE', 'EXPIRED', 'NEUTRAL'])) {
    return StatusTone.neutral;
  }
  if (has(['IN_HOUSE', 'ACTIVE_STAY', 'COMPLETED', 'CONFIRMED', 'STOCKED'])) {
    return StatusTone.success;
  }
  if (has(['ARRIVAL', 'ASSIGNED', 'PROGRESS', 'INFO'])) {
    return StatusTone.info;
  }
  return StatusTone.neutral;
}

/// Material 3 theme for the Kachava Lux admin (root `DESIGN.md`).
class KachavaAdminTheme {
  const KachavaAdminTheme._();

  static const ColorScheme colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: KachavaTokens.primary,
    onPrimary: KachavaTokens.onPrimary,
    primaryContainer: KachavaTokens.surface,
    onPrimaryContainer: KachavaTokens.text,
    secondary: KachavaTokens.textSecondary,
    onSecondary: KachavaTokens.onPrimary,
    secondaryContainer: KachavaTokens.surface,
    onSecondaryContainer: KachavaTokens.text,
    tertiary: KachavaTokens.accent,
    onTertiary: KachavaTokens.text,
    error: KachavaTokens.error,
    onError: KachavaTokens.onPrimary,
    errorContainer: KachavaTokens.errorBackground,
    onErrorContainer: KachavaTokens.errorForeground,
    surface: KachavaTokens.background,
    onSurface: KachavaTokens.text,
    onSurfaceVariant: KachavaTokens.textSecondary,
    surfaceContainerLowest: KachavaTokens.background,
    surfaceContainerLow: KachavaTokens.surface,
    surfaceContainer: KachavaTokens.surface,
    surfaceContainerHigh: KachavaTokens.surface,
    surfaceContainerHighest: KachavaTokens.surface,
    outline: KachavaTokens.inputBorder,
    outlineVariant: KachavaTokens.border,
    surfaceTint: Colors.transparent,
    inverseSurface: KachavaTokens.text,
    onInverseSurface: KachavaTokens.background,
  );

  static const TextTheme textTheme = TextTheme(
    headlineSmall:
        TextStyle(fontSize: 24, height: 32 / 24, fontWeight: FontWeight.w500),
    titleLarge:
        TextStyle(fontSize: 18, height: 26 / 18, fontWeight: FontWeight.w500),
    titleMedium:
        TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w500),
    titleSmall:
        TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w500),
    bodyLarge:
        TextStyle(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w400),
    bodyMedium:
        TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w400),
    bodySmall:
        TextStyle(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w400),
    labelLarge:
        TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w500),
    labelMedium:
        TextStyle(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w500),
    labelSmall:
        TextStyle(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w500),
  );

  static ThemeData build() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: KachavaTokens.fontFamily,
      fontFamilyFallback: KachavaTokens.fontFamilyFallback,
      textTheme: textTheme,
    );
    return base.copyWith(
      scaffoldBackgroundColor: KachavaTokens.background,
      canvasColor: KachavaTokens.background,
      dividerColor: KachavaTokens.border,
      focusColor: KachavaTokens.focus.withValues(alpha: 0.12),
      hoverColor: KachavaTokens.text.withValues(alpha: 0.04),
      splashColor: KachavaTokens.text.withValues(alpha: 0.06),
      textTheme: base.textTheme.apply(
        bodyColor: KachavaTokens.text,
        displayColor: KachavaTokens.text,
      ),
      filledButtonTheme: FilledButtonThemeData(style: _primaryButton),
      elevatedButtonTheme: ElevatedButtonThemeData(style: _primaryButton),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KachavaTokens.text,
          side: const BorderSide(color: KachavaTokens.inputBorder),
          shape: _radius(KachavaTokens.radiusMd),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KachavaTokens.text,
          shape: _radius(KachavaTokens.radiusMd),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconTheme: const IconThemeData(color: KachavaTokens.textSecondary),
      inputDecorationTheme: _inputs,
      dataTableTheme: _dataTable,
      chipTheme: ChipThemeData(
        backgroundColor: KachavaTokens.surface,
        selectedColor: KachavaTokens.surfaceHover,
        side: BorderSide.none,
        shape: _radius(KachavaTokens.radiusMd),
        labelStyle: textTheme.labelLarge?.copyWith(color: KachavaTokens.text),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: KachavaTokens.background,
        surfaceTintColor: Colors.transparent,
        shape: _radius(KachavaTokens.radiusLg),
        titleTextStyle:
            textTheme.titleLarge?.copyWith(color: KachavaTokens.text),
      ),
      dividerTheme: const DividerThemeData(
          color: KachavaTokens.border, thickness: 1, space: 1),
      cardTheme: CardThemeData(
        color: KachavaTokens.background,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KachavaTokens.radiusLg),
          side: const BorderSide(color: KachavaTokens.border),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: KachavaTokens.tooltip,
          borderRadius: BorderRadius.circular(KachavaTokens.radiusSm),
        ),
        textStyle: const TextStyle(
            fontSize: 12, height: 16 / 12, color: KachavaTokens.onPrimary),
        waitDuration: const Duration(milliseconds: 300),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: KachavaTokens.background,
        foregroundColor: KachavaTokens.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: KachavaTokens.background,
        indicatorColor: KachavaTokens.surface,
        selectedIconTheme: IconThemeData(color: KachavaTokens.text),
        unselectedIconTheme: IconThemeData(color: KachavaTokens.textSecondary),
      ),
      navigationDrawerTheme: const NavigationDrawerThemeData(
        backgroundColor: KachavaTokens.background,
        indicatorColor: KachavaTokens.surface,
        surfaceTintColor: Colors.transparent,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: KachavaTokens.background,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static RoundedRectangleBorder _radius(double r) =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));

  static final ButtonStyle _primaryButton = ElevatedButton.styleFrom(
    backgroundColor: KachavaTokens.primary,
    foregroundColor: KachavaTokens.onPrimary,
    elevation: 0,
    shape: _radius(KachavaTokens.radiusMd),
    textStyle: textTheme.labelLarge,
  );

  static OutlineInputBorder _outline(Color color, double width) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(KachavaTokens.radiusMd),
        borderSide: BorderSide(color: color, width: width),
      );

  static final InputDecorationThemeData _inputs = InputDecorationThemeData(
    border: _outline(KachavaTokens.inputBorder, 1),
    enabledBorder: _outline(KachavaTokens.inputBorder, 1),
    focusedBorder: _outline(KachavaTokens.focus, 2),
    errorBorder: _outline(KachavaTokens.error, 1),
    focusedErrorBorder: _outline(KachavaTokens.error, 2),
    labelStyle: const TextStyle(color: KachavaTokens.textSecondary),
    hintStyle: const TextStyle(color: KachavaTokens.textSecondary),
  );

  static const DataTableThemeData _dataTable = DataTableThemeData(
    dataRowColor: WidgetStatePropertyAll(KachavaTokens.background),
    headingRowColor: WidgetStatePropertyAll(KachavaTokens.background),
    headingTextStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: KachavaTokens.textSecondary),
    dataTextStyle: TextStyle(fontSize: 14, color: KachavaTokens.text),
    dividerThickness: 1,
    horizontalMargin: 16,
    columnSpacing: 24,
  );
}
