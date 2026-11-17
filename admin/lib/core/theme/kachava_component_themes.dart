import 'package:flutter/material.dart';

import 'kachava_text_styles.dart';
import 'kachava_tokens.dart';

/// MUJI component themes: elevation 0, radius 2, hairlines, no tint, no
/// shadows. [t] is the resolved text theme of the admin.
abstract final class KachavaComponentThemes {
  static const RoundedRectangleBorder square = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(KachavaTokens.radius)));

  /// 40px square icon buttons (also the filled Send button).
  static const IconButtonThemeData iconButton = IconButtonThemeData(
    style: ButtonStyle(
      shape: WidgetStatePropertyAll(square),
      minimumSize: WidgetStatePropertyAll(Size(40, 40)),
    ),
  );

  static RoundedRectangleBorder squareWith(Color line) =>
      RoundedRectangleBorder(
        borderRadius:
            const BorderRadius.all(Radius.circular(KachavaTokens.radius)),
        side: BorderSide(color: line),
      );

  static WidgetStateProperty<Color?> _hover(Color idle, Color hover) =>
      WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return KachavaTokens.wash;
        final active = states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.focused);
        return active ? hover : idle;
      });

  static ButtonStyle _base(TextTheme t) => ButtonStyle(
        elevation: const WidgetStatePropertyAll(0),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: const WidgetStatePropertyAll(square),
        minimumSize: const WidgetStatePropertyAll(Size(64, 40)),
        padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: KachavaTokens.space4)),
        textStyle: WidgetStatePropertyAll(t.labelLarge),
        animationDuration: KachavaTokens.motion,
      );

  static ButtonStyle primary(TextTheme t) => _base(t).copyWith(
        backgroundColor: _hover(KachavaTokens.brand, KachavaTokens.brandDeep),
        foregroundColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.disabled)
                ? KachavaTokens.faint
                : KachavaTokens.onBrand),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      );

  static ButtonStyle outlined(TextTheme t) => _base(t).copyWith(
        backgroundColor: _hover(KachavaTokens.surface, KachavaTokens.wash),
        foregroundColor: const WidgetStatePropertyAll(KachavaTokens.ink),
        side: const WidgetStatePropertyAll(
            BorderSide(color: KachavaTokens.lineStrong)),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      );

  static ButtonStyle quiet(TextTheme t) => _base(t).copyWith(
        foregroundColor: const WidgetStatePropertyAll(KachavaTokens.ink),
        overlayColor: const WidgetStatePropertyAll(KachavaTokens.wash),
        padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: KachavaTokens.space2)),
      );

  static OutlineInputBorder _outline(Color color, double width) =>
      OutlineInputBorder(
        borderRadius:
            const BorderRadius.all(Radius.circular(KachavaTokens.radius)),
        borderSide: BorderSide(color: color, width: width),
      );

  static InputDecorationThemeData inputs(double inputSize) =>
      InputDecorationThemeData(
        filled: true,
        fillColor: KachavaTokens.surface,
        hoverColor: Colors.transparent,
        border: _outline(KachavaTokens.lineStrong, 1),
        enabledBorder: _outline(KachavaTokens.lineStrong, 1),
        disabledBorder: _outline(KachavaTokens.line, 1),
        focusedBorder: _outline(KachavaTokens.ink, 1.5),
        errorBorder: _outline(KachavaTokens.danger, 1),
        focusedErrorBorder: _outline(KachavaTokens.danger, 1.5),
        labelStyle: TextStyle(color: KachavaTokens.muted, fontSize: inputSize),
        floatingLabelStyle: KachavaTextStyles.klLabel,
        hintStyle: TextStyle(color: KachavaTokens.faint, fontSize: inputSize),
        errorStyle: const TextStyle(color: KachavaTokens.danger),
      );

  static const DataTableThemeData dataTable = DataTableThemeData(
    dataRowColor: WidgetStatePropertyAll(KachavaTokens.surface),
    headingRowColor: WidgetStatePropertyAll(KachavaTokens.surface),
    headingTextStyle: KachavaTextStyles.klLabel,
    dataTextStyle: TextStyle(
        fontFamily: KachavaTokens.fontSans,
        fontSize: 14,
        color: KachavaTokens.ink,
        fontFeatures: KachavaTextStyles.tabular),
    dividerThickness: 1,
    horizontalMargin: 16,
    columnSpacing: 24,
    decoration: BoxDecoration(color: KachavaTokens.surface),
  );

  static ChipThemeData chip(TextTheme t) => ChipThemeData(
        backgroundColor: KachavaTokens.surface,
        selectedColor: KachavaTokens.wash,
        disabledColor: KachavaTokens.wash,
        side: const BorderSide(color: KachavaTokens.line),
        shape: squareWith(KachavaTokens.line),
        elevation: 0,
        pressElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        checkmarkColor: KachavaTokens.ink,
        labelStyle: t.labelLarge?.copyWith(color: KachavaTokens.ink),
      );

  static DialogThemeData dialog(TextTheme t) => DialogThemeData(
        backgroundColor: KachavaTokens.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: squareWith(KachavaTokens.line),
        barrierColor: KachavaTokens.ink.withValues(alpha: 0.4),
        titleTextStyle: t.titleLarge?.copyWith(color: KachavaTokens.ink),
        contentTextStyle: t.bodyMedium?.copyWith(color: KachavaTokens.ink),
      );

  static const CardThemeData card = CardThemeData(
    color: KachavaTokens.surface,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(KachavaTokens.radius)),
      side: BorderSide(color: KachavaTokens.line),
    ),
  );

  static TooltipThemeData tooltip(TextTheme t) => TooltipThemeData(
        decoration: const BoxDecoration(
          color: KachavaTokens.ink,
          borderRadius: BorderRadius.all(Radius.circular(KachavaTokens.radius)),
        ),
        textStyle: t.bodySmall?.copyWith(color: KachavaTokens.onBrand),
        waitDuration: const Duration(milliseconds: 300),
      );

  static SnackBarThemeData snackBar(TextTheme t) => SnackBarThemeData(
        backgroundColor: KachavaTokens.ink,
        contentTextStyle: t.bodyMedium?.copyWith(color: KachavaTokens.onBrand),
        actionTextColor: KachavaTokens.onBrand,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        shape: square,
      );

  static PopupMenuThemeData popupMenu(TextTheme t) => PopupMenuThemeData(
        color: KachavaTokens.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: squareWith(KachavaTokens.line),
        textStyle: t.bodyMedium?.copyWith(color: KachavaTokens.ink),
      );

  static final MenuStyle menuStyle = MenuStyle(
    backgroundColor: const WidgetStatePropertyAll(KachavaTokens.surface),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    shadowColor: const WidgetStatePropertyAll(Colors.transparent),
    elevation: const WidgetStatePropertyAll(0),
    shape: WidgetStatePropertyAll(squareWith(KachavaTokens.line)),
  );

  static final BottomSheetThemeData bottomSheet = BottomSheetThemeData(
    backgroundColor: KachavaTokens.surface,
    modalBackgroundColor: KachavaTokens.surface,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
    modalElevation: 0,
    shape: squareWith(KachavaTokens.line),
    showDragHandle: false,
  );

  static ListTileThemeData listTile(TextTheme t) => ListTileThemeData(
        shape: square,
        iconColor: KachavaTokens.muted,
        textColor: KachavaTokens.ink,
        selectedColor: KachavaTokens.ink,
        selectedTileColor: KachavaTokens.wash,
        titleTextStyle: t.bodyMedium?.copyWith(color: KachavaTokens.ink),
        subtitleTextStyle: t.bodySmall?.copyWith(color: KachavaTokens.muted),
      );

  static const BadgeThemeData badge = BadgeThemeData(
    backgroundColor: Colors.transparent,
    textColor: KachavaTokens.pending,
    textStyle: TextStyle(
        fontFamily: KachavaTokens.fontSans,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        fontFeatures: KachavaTextStyles.tabular),
  );

  static SegmentedButtonThemeData segmented(TextTheme t) =>
      SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(square),
          elevation: const WidgetStatePropertyAll(0),
          side: const WidgetStatePropertyAll(
              BorderSide(color: KachavaTokens.lineStrong)),
          backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? KachavaTokens.wash
                  : KachavaTokens.surface),
          foregroundColor: const WidgetStatePropertyAll(KachavaTokens.ink),
          textStyle: WidgetStatePropertyAll(t.labelLarge),
        ),
      );

  /// Text-only tabs: selected = ink text over a 1px ink rule; others muted.
  static TabBarThemeData tabBar(TextTheme t) => TabBarThemeData(
        labelColor: KachavaTokens.ink,
        unselectedLabelColor: KachavaTokens.muted,
        labelStyle: t.labelLarge,
        unselectedLabelStyle:
            t.labelLarge?.copyWith(fontWeight: FontWeight.w400),
        indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(color: KachavaTokens.ink, width: 1)),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: KachavaTokens.line,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      );
}
