import 'package:flutter/material.dart';

import 'kachava_colors.dart';

const double _r = 2;
const BorderRadius _radius = BorderRadius.all(Radius.circular(_r));
const RoundedRectangleBorder _square =
    RoundedRectangleBorder(borderRadius: _radius);
const BorderSide _hairline = BorderSide(color: KachavaColors.line);
const Duration _motion = Duration(milliseconds: 220);
const Curve _ease = Cubic(0.2, 0, 0, 1);
const TextStyle _onInk = TextStyle(fontSize: 14, color: KachavaColors.onBrand);

/// Page transitions: a 220ms opacity fade, no slide or scale.
class QuietFadeTransitionsBuilder extends PageTransitionsBuilder {
  const QuietFadeTransitionsBuilder();

  @override
  Duration get transitionDuration => _motion;

  @override
  Duration get reverseTransitionDuration => _motion;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      FadeTransition(
          opacity: animation.drive(CurveTween(curve: _ease)), child: child);
}

/// MUJI component themes: elevation 0, radius 2, hairlines, no tint.
abstract final class KachavaComponentThemes {
  static final PageTransitionsTheme pageTransitions =
      PageTransitionsTheme(builders: {
    for (final p in TargetPlatform.values)
      p: const QuietFadeTransitionsBuilder(),
  });

  static AppBarTheme appBar(TextStyle title) => AppBarTheme(
        backgroundColor: KachavaColors.paper,
        foregroundColor: KachavaColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: _hairline),
        titleTextStyle: title,
      );

  static const CardThemeData card = CardThemeData(
    color: KachavaColors.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: _radius, side: _hairline),
  );

  static FilledButtonThemeData filledButton(TextStyle text) =>
      FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          elevation: 0,
          textStyle: text,
          shape: _square,
          foregroundColor: KachavaColors.onBrand,
          disabledBackgroundColor: KachavaColors.wash,
          disabledForegroundColor: KachavaColors.muted,
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) return KachavaColors.wash;
            if (s.contains(WidgetState.hovered) ||
                s.contains(WidgetState.pressed)) {
              return KachavaColors.brandDeep;
            }
            return KachavaColors.brand;
          }),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      );

  static OutlinedButtonThemeData outlinedButton(TextStyle text) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          elevation: 0,
          textStyle: text,
          shape: _square,
          backgroundColor: KachavaColors.surface,
          foregroundColor: KachavaColors.ink,
          side: const BorderSide(color: KachavaColors.lineStrong),
        ),
      );

  /// Quiet text action: ink, underlined with a lineStrong rule.
  static TextButtonThemeData textButton(TextStyle text) => TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          elevation: 0,
          shape: _square,
          foregroundColor: KachavaColors.ink,
          textStyle: text.copyWith(
            decoration: TextDecoration.underline,
            decorationColor: KachavaColors.lineStrong,
          ),
        ),
      );

  static const ChipThemeData chip = ChipThemeData(
    backgroundColor: KachavaColors.surface,
    selectedColor: KachavaColors.wash,
    checkmarkColor: KachavaColors.ink,
    elevation: 0,
    pressElevation: 0,
    shape: RoundedRectangleBorder(borderRadius: _radius, side: _hairline),
    side: _hairline,
    labelStyle: TextStyle(fontSize: 14, color: KachavaColors.ink),
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
  );

  static const InputDecorationTheme input = InputDecorationTheme(
    filled: true,
    fillColor: KachavaColors.surface,
    hintStyle: TextStyle(fontSize: 16, color: KachavaColors.faint),
    labelStyle: TextStyle(fontSize: 15, color: KachavaColors.muted),
    border: OutlineInputBorder(borderRadius: _radius, borderSide: _hairline),
    enabledBorder:
        OutlineInputBorder(borderRadius: _radius, borderSide: _hairline),
    focusedBorder: OutlineInputBorder(
        borderRadius: _radius,
        borderSide: BorderSide(color: KachavaColors.ink, width: 1.5)),
    errorBorder: OutlineInputBorder(
        borderRadius: _radius,
        borderSide: BorderSide(color: KachavaColors.dangerText)),
  );

  static const BottomSheetThemeData bottomSheet = BottomSheetThemeData(
    backgroundColor: KachavaColors.surface,
    modalBackgroundColor: KachavaColors.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    modalElevation: 0,
    dragHandleColor: KachavaColors.lineStrong,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(_r))),
  );

  static const DialogThemeData dialog = DialogThemeData(
    backgroundColor: KachavaColors.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: _radius, side: _hairline),
  );

  static const SnackBarThemeData snackBar = SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: KachavaColors.ink,
    actionTextColor: KachavaColors.onBrand,
    elevation: 0,
    shape: _square,
    contentTextStyle: TextStyle(fontSize: 15, color: KachavaColors.onBrand),
  );

  /// Active tab = ink icon/label on a square wash, never a pill.
  static NavigationBarThemeData get navigationBar => NavigationBarThemeData(
        backgroundColor: KachavaColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: KachavaColors.wash,
        indicatorShape: _square,
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected)
                ? KachavaColors.ink
                : KachavaColors.muted)),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontSize: 13,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w500
                : FontWeight.w400,
            color: s.contains(WidgetState.selected)
                ? KachavaColors.ink
                : KachavaColors.muted)),
      );

  static const TooltipThemeData tooltip = TooltipThemeData(
    decoration: BoxDecoration(color: KachavaColors.ink, borderRadius: _radius),
    textStyle: _onInk,
  );

  static const DividerThemeData divider =
      DividerThemeData(color: KachavaColors.line, thickness: 1, space: 1);

  static const PopupMenuThemeData popupMenu = PopupMenuThemeData(
    color: KachavaColors.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: _radius, side: _hairline),
  );

  static const ProgressIndicatorThemeData progress = ProgressIndicatorThemeData(
    color: KachavaColors.brand,
    linearTrackColor: KachavaColors.line,
    borderRadius: BorderRadius.zero,
  );

  static CheckboxThemeData get checkbox => CheckboxThemeData(
        shape: _square,
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? KachavaColors.brand : null),
        checkColor: const WidgetStatePropertyAll(KachavaColors.onBrand),
      );

  static const DatePickerThemeData datePicker = DatePickerThemeData(
    backgroundColor: KachavaColors.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: _square,
  );

  /// Bottom-sheet motion (220ms); passed as `sheetAnimationStyle`.
  static const AnimationStyle sheetMotion =
      AnimationStyle(duration: _motion, reverseDuration: _motion);

  /// Curve shared by all fades.
  static const Curve ease = _ease;
}
