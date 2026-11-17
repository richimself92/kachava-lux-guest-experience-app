import 'package:flutter/material.dart';

import 'kachava_colors.dart';
import 'kachava_component_themes.dart';

export 'kachava_component_themes.dart' show QuietFadeTransitionsBuilder;

/// Guest-portal MUJI theme: Zen Kaku Gothic New titles and labels, Noto Sans
/// text, square 2px edges, hairlines instead of shadows, quiet fades.
/// Body text is >= 14px (inputs 16px) and uses an AA colour on paper.
abstract final class KachavaTheme {
  static const String displayFamily = 'Zen Kaku Gothic New';
  static const String sansFamily = 'Noto Sans';

  /// Minimum touch target on every interactive element.
  static const double minTarget = 48;

  /// The one corner radius of the portal (round only for dots and circles).
  static const double radius = 2;
  static const BorderRadius borderRadius =
      BorderRadius.all(Radius.circular(radius));
  static const RoundedRectangleBorder shape =
      RoundedRectangleBorder(borderRadius: borderRadius);

  /// Imperceptible motion: fades only.
  static const Duration motion = Duration(milliseconds: 220);
  static const Curve ease = Cubic(0.2, 0, 0, 1);

  /// Bottom-sheet enter/exit timing (the sheet itself stays a sheet).
  static const AnimationStyle sheetMotion = KachavaComponentThemes.sheetMotion;

  /// Columns of numbers (dates, times, prices, counts) stay aligned.
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  /// Small tracked label (eyebrows, form labels, metadata); the widget
  /// applies the uppercase.
  static const TextStyle klLabel = TextStyle(
    fontFamily: displayFamily,
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w500,
    letterSpacing: 12 * 0.14,
    color: KachavaColors.muted,
  );

  /// Display font at w500 with 0.02em tracking (titles, headings).
  static TextStyle display(double size, {Color color = KachavaColors.ink}) =>
      TextStyle(
        fontFamily: displayFamily,
        fontSize: size,
        height: 1.35,
        fontWeight: FontWeight.w500,
        letterSpacing: size * 0.02,
        color: color,
      );

  static ThemeData buildTheme() => _withComponents(_baseTheme());

  static ThemeData _baseTheme() => ThemeData(
        useMaterial3: true,
        colorScheme: _colorScheme,
        scaffoldBackgroundColor: KachavaColors.paper,
        canvasColor: KachavaColors.paper,
        fontFamily: sansFamily,
        textTheme: _buildTextTheme(),
        dividerColor: KachavaColors.line,
        materialTapTargetSize: MaterialTapTargetSize.padded,
        splashFactory: InkRipple.splashFactory,
        hoverColor: KachavaColors.wash,
        highlightColor: KachavaColors.wash,
        focusColor: KachavaColors.ink.withValues(alpha: 0.08),
        pageTransitionsTheme: KachavaComponentThemes.pageTransitions,
      );

  static ThemeData _withComponents(ThemeData base) => base.copyWith(
        appBarTheme: KachavaComponentThemes.appBar(display(18)),
        cardTheme: KachavaComponentThemes.card,
        filledButtonTheme: KachavaComponentThemes.filledButton(_button),
        outlinedButtonTheme: KachavaComponentThemes.outlinedButton(_button),
        textButtonTheme: KachavaComponentThemes.textButton(_button),
        chipTheme: KachavaComponentThemes.chip,
        inputDecorationTheme: KachavaComponentThemes.input,
        bottomSheetTheme: KachavaComponentThemes.bottomSheet,
        dialogTheme: KachavaComponentThemes.dialog,
        snackBarTheme: KachavaComponentThemes.snackBar,
        navigationBarTheme: KachavaComponentThemes.navigationBar,
        tooltipTheme: KachavaComponentThemes.tooltip,
        dividerTheme: KachavaComponentThemes.divider,
        popupMenuTheme: KachavaComponentThemes.popupMenu,
        progressIndicatorTheme: KachavaComponentThemes.progress,
        checkboxTheme: KachavaComponentThemes.checkbox,
        datePickerTheme: KachavaComponentThemes.datePicker,
      );

  static const TextStyle _button = TextStyle(
      fontFamily: sansFamily, fontSize: 15, fontWeight: FontWeight.w500);

  static const ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: KachavaColors.brand,
    onPrimary: KachavaColors.onBrand,
    primaryContainer: KachavaColors.wash,
    onPrimaryContainer: KachavaColors.ink,
    secondary: KachavaColors.muted,
    onSecondary: KachavaColors.onBrand,
    secondaryContainer: KachavaColors.wash,
    onSecondaryContainer: KachavaColors.ink,
    tertiary: KachavaColors.muted,
    onTertiary: KachavaColors.onBrand,
    error: KachavaColors.dangerText,
    onError: KachavaColors.onBrand,
    errorContainer: KachavaColors.dangerWash,
    onErrorContainer: KachavaColors.dangerText,
    surface: KachavaColors.surface,
    onSurface: KachavaColors.ink,
    onSurfaceVariant: KachavaColors.muted,
    surfaceContainerLowest: KachavaColors.surface,
    surfaceContainerLow: KachavaColors.surface,
    surfaceContainer: KachavaColors.surface,
    surfaceContainerHigh: KachavaColors.wash,
    surfaceContainerHighest: KachavaColors.wash,
    outline: KachavaColors.lineStrong,
    outlineVariant: KachavaColors.line,
    shadow: Colors.transparent,
    surfaceTint: Colors.transparent,
  );

  static TextTheme _buildTextTheme() {
    TextStyle body(double size, Color color,
            [FontWeight weight = FontWeight.w400]) =>
        TextStyle(
            fontFamily: sansFamily,
            fontSize: size,
            height: 1.5,
            fontWeight: weight,
            color: color);
    return TextTheme(
      headlineMedium: display(24),
      titleLarge: display(20),
      titleMedium: display(17),
      bodyLarge: body(16, KachavaColors.ink),
      bodyMedium: body(15, KachavaColors.ink),
      bodySmall: body(14, KachavaColors.muted),
      labelLarge: body(15, KachavaColors.ink, FontWeight.w500),
      labelMedium: body(14, KachavaColors.muted, FontWeight.w500),
      labelSmall: body(14, KachavaColors.muted),
    );
  }
}
