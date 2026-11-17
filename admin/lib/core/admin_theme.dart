import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';

import 'theme/kachava_component_themes.dart';
import 'theme/kachava_fade_transitions.dart';
import 'theme/kachava_text_styles.dart';
import 'theme/kachava_tokens.dart';

export 'theme/kachava_fade_transitions.dart';
export 'theme/kachava_text_styles.dart';
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

/// Material 3 theme for the Kachava Lux admin (MUJI restyle, root
/// `DESIGN.md` v2.0): paper canvas, one brown accent, square hairlined
/// components, quiet type and fades.
class KachavaAdminTheme {
  const KachavaAdminTheme._();

  /// Small uppercase display label (widgets apply the uppercase).
  static const TextStyle klLabel = KachavaTextStyles.klLabel;

  static const ColorScheme colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: KachavaTokens.brand,
    onPrimary: KachavaTokens.onBrand,
    primaryContainer: KachavaTokens.wash,
    onPrimaryContainer: KachavaTokens.ink,
    secondary: KachavaTokens.muted,
    onSecondary: KachavaTokens.onBrand,
    secondaryContainer: KachavaTokens.wash,
    onSecondaryContainer: KachavaTokens.ink,
    tertiary: KachavaTokens.brand,
    onTertiary: KachavaTokens.onBrand,
    error: KachavaTokens.danger,
    onError: KachavaTokens.onBrand,
    errorContainer: KachavaTokens.dangerWash,
    onErrorContainer: KachavaTokens.danger,
    surface: KachavaTokens.surface,
    onSurface: KachavaTokens.ink,
    onSurfaceVariant: KachavaTokens.muted,
    surfaceContainerLowest: KachavaTokens.surface,
    surfaceContainerLow: KachavaTokens.surface,
    surfaceContainer: KachavaTokens.surface,
    surfaceContainerHigh: KachavaTokens.surface,
    surfaceContainerHighest: KachavaTokens.wash,
    outline: KachavaTokens.lineStrong,
    outlineVariant: KachavaTokens.line,
    shadow: Colors.transparent,
    scrim: KachavaTokens.ink,
    surfaceTint: Colors.transparent,
    inverseSurface: KachavaTokens.ink,
    onInverseSurface: KachavaTokens.onBrand,
    inversePrimary: KachavaTokens.wash,
  );

  /// Touch platforms get 16px input text so iOS never zooms into a field.
  static bool isTouch(TargetPlatform p) =>
      p == TargetPlatform.iOS || p == TargetPlatform.android;

  static ThemeData build({TargetPlatform? platform}) {
    final inputSize = isTouch(platform ?? defaultTargetPlatform) ? 16.0 : 14.0;
    final text = KachavaTextStyles.textTheme(inputSize: inputSize)
        .apply(bodyColor: KachavaTokens.ink, displayColor: KachavaTokens.ink);
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: text,
      scaffoldBackgroundColor: KachavaTokens.paper,
      canvasColor: KachavaTokens.paper,
      dividerColor: KachavaTokens.line,
      focusColor: KachavaTokens.wash,
      hoverColor: KachavaTokens.wash,
      highlightColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      shadowColor: Colors.transparent,
      pageTransitionsTheme: kachavaFadePageTransitions,
      iconTheme: const IconThemeData(color: KachavaTokens.muted),
    );
    return _surfaces(_controls(base, text, inputSize), text);
  }

  /// Buttons, inputs, tables, chips and tabs.
  static ThemeData _controls(ThemeData base, TextTheme t, double input) {
    final c = KachavaComponentThemes.primary(t);
    return base.copyWith(
      filledButtonTheme: FilledButtonThemeData(style: c),
      elevatedButtonTheme: ElevatedButtonThemeData(style: c),
      outlinedButtonTheme:
          OutlinedButtonThemeData(style: KachavaComponentThemes.outlined(t)),
      textButtonTheme:
          TextButtonThemeData(style: KachavaComponentThemes.quiet(t)),
      inputDecorationTheme: KachavaComponentThemes.inputs(input),
      dataTableTheme: KachavaComponentThemes.dataTable,
      chipTheme: KachavaComponentThemes.chip(t),
      dialogTheme: KachavaComponentThemes.dialog(t),
      dividerTheme: const DividerThemeData(
          color: KachavaTokens.line, thickness: 1, space: 1),
      cardTheme: KachavaComponentThemes.card,
      iconButtonTheme: KachavaComponentThemes.iconButton,
    );
  }

  /// Overlays, menus, lists and navigation surfaces.
  static ThemeData _surfaces(ThemeData base, TextTheme t) {
    return base.copyWith(
      tooltipTheme: KachavaComponentThemes.tooltip(t),
      snackBarTheme: KachavaComponentThemes.snackBar(t),
      popupMenuTheme: KachavaComponentThemes.popupMenu(t),
      menuTheme: MenuThemeData(style: KachavaComponentThemes.menuStyle),
      dropdownMenuTheme:
          DropdownMenuThemeData(menuStyle: KachavaComponentThemes.menuStyle),
      bottomSheetTheme: KachavaComponentThemes.bottomSheet,
      listTileTheme: KachavaComponentThemes.listTile(t),
      badgeTheme: KachavaComponentThemes.badge,
      segmentedButtonTheme: KachavaComponentThemes.segmented(t),
      tabBarTheme: KachavaComponentThemes.tabBar(t),
      appBarTheme: _appBar(t),
      navigationRailTheme: _rail,
      navigationDrawerTheme: _navDrawer,
      drawerTheme: _drawer,
    );
  }

  static AppBarTheme _appBar(TextTheme t) => AppBarTheme(
        backgroundColor: KachavaTokens.paper,
        foregroundColor: KachavaTokens.ink,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: t.titleLarge,
      );

  static const NavigationDrawerThemeData _navDrawer = NavigationDrawerThemeData(
    backgroundColor: KachavaTokens.paper,
    indicatorColor: KachavaTokens.wash,
    indicatorShape: KachavaComponentThemes.square,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
  );

  static const DrawerThemeData _drawer = DrawerThemeData(
    backgroundColor: KachavaTokens.paper,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(),
  );

  static const NavigationRailThemeData _rail = NavigationRailThemeData(
    backgroundColor: KachavaTokens.paper,
    elevation: 0,
    indicatorColor: KachavaTokens.wash,
    indicatorShape: KachavaComponentThemes.square,
    selectedIconTheme: IconThemeData(color: KachavaTokens.ink),
    unselectedIconTheme: IconThemeData(color: KachavaTokens.muted),
  );
}
