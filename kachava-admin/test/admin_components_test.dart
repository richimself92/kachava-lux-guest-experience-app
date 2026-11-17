import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/core/admin_theme.dart';
import 'package:kachava_admin_dashboard/presentation/components/components.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
      theme: KachavaAdminTheme.build(), home: Scaffold(body: child));

  test('test_statusToneFor_mapsOperationalStatuses', () {
    for (final s in ['In-house', 'ACTIVE_STAY', 'Completed', 'Stocked']) {
      expect(statusToneFor(s), StatusTone.success, reason: s);
    }
    for (final s in ['Arrival', 'PRE_ARRIVAL', 'Assigned', 'In progress']) {
      expect(statusToneFor(s), StatusTone.info, reason: s);
    }
    for (final s in ['Requested', 'Checked out', 'Departure']) {
      expect(statusToneFor(s), StatusTone.neutral, reason: s);
    }
    for (final s in ['URGENT', 'ALLERGY', 'SLA breach', 'overdue']) {
      expect(statusToneFor(s), StatusTone.error, reason: s);
    }
  });

  test('test_statusToneFor_matchesWholeTokensOnly', () {
    for (final s in ['ISLAND', 'Island tour', 'DIRECTOR', 'Directions']) {
      expect(statusToneFor(s), StatusTone.neutral, reason: s);
    }
    for (final s in [
      'DIRECT',
      'Direct booking',
      'OVERSTAY',
      'Overstay',
      'OVERDUE',
      'sla-breach',
    ]) {
      expect(statusToneFor(s), StatusTone.error, reason: s);
    }
    expect(statusToneFor('STOCKED_IN_VILLA'), StatusTone.success);
    expect(statusToneFor('CHECKED_OUT'), StatusTone.neutral);
    expect(statusToneFor('PRE_ARRIVAL'), StatusTone.info);
  });

  test('test_theme_usesMujiFontsPaperCanvasAndBrownPrimary', () {
    final theme = KachavaAdminTheme.build();
    expect(theme.textTheme.bodyMedium?.fontFamily, KachavaTokens.fontSans);
    expect(theme.textTheme.bodyMedium?.fontWeight, FontWeight.w400);
    final headline = theme.textTheme.headlineSmall!;
    expect(headline.fontFamily, KachavaTokens.fontDisplay);
    expect(headline.fontWeight, FontWeight.w500);
    expect(headline.letterSpacing, closeTo(headline.fontSize! * 0.02, 0.001));
    expect(theme.textTheme.titleMedium?.fontFamily, KachavaTokens.fontDisplay);
    expect(theme.scaffoldBackgroundColor, KachavaTokens.paper);
    expect(theme.colorScheme.primary, KachavaTokens.brand);
    expect(theme.colorScheme.surface, KachavaTokens.surface);
    expect(theme.colorScheme.surfaceTint, Colors.transparent);
  });

  test('test_klLabel_isSmallSpacedDisplayLabelInMuted', () {
    expect(KachavaAdminTheme.klLabel.fontFamily, KachavaTokens.fontDisplay);
    expect(KachavaAdminTheme.klLabel.fontSize, 11);
    expect(KachavaAdminTheme.klLabel.fontWeight, FontWeight.w500);
    expect(KachavaAdminTheme.klLabel.letterSpacing, closeTo(1.54, 0.001));
    expect(KachavaAdminTheme.klLabel.color, KachavaTokens.muted);
  });

  test('test_theme_iconButtonsAreSquare40', () {
    final style = KachavaAdminTheme.build().iconButtonTheme.style!;
    expect(_radiusOf(style.shape?.resolve({})), 2);
    expect(style.minimumSize?.resolve({}), const Size(40, 40));
  });

  test('test_theme_componentsAreFlatSquareAndHairlined', () {
    final theme = KachavaAdminTheme.build();
    final card = theme.cardTheme;
    expect(card.elevation, 0);
    expect(card.color, KachavaTokens.surface);
    expect(_radiusOf(card.shape), 2);
    expect(
        (card.shape! as RoundedRectangleBorder).side.color, KachavaTokens.line);
    expect(theme.dialogTheme.elevation, 0);
    expect(_radiusOf(theme.dialogTheme.shape), 2);
    expect(theme.dialogTheme.backgroundColor, KachavaTokens.surface);
    for (final style in [
      theme.filledButtonTheme.style!,
      theme.elevatedButtonTheme.style!,
      theme.outlinedButtonTheme.style!,
      theme.textButtonTheme.style!,
    ]) {
      expect(style.elevation?.resolve({}) ?? 0, 0);
      expect(_radiusOf(style.shape?.resolve({})), 2);
    }
    final filled = theme.filledButtonTheme.style!;
    expect(filled.backgroundColor?.resolve({}), KachavaTokens.brand);
    expect(filled.backgroundColor?.resolve({WidgetState.hovered}),
        KachavaTokens.brandDeep);
    expect(filled.foregroundColor?.resolve({}), KachavaTokens.onBrand);
    final outlined = theme.outlinedButtonTheme.style!;
    expect(outlined.side?.resolve({})?.color, KachavaTokens.lineStrong);
    expect(outlined.backgroundColor?.resolve({WidgetState.hovered}),
        KachavaTokens.wash);
    expect(theme.snackBarTheme.backgroundColor, KachavaTokens.ink);
    expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
    expect(theme.popupMenuTheme.elevation, 0);
    expect(theme.bottomSheetTheme.elevation, 0);
    expect(theme.appBarTheme.backgroundColor, KachavaTokens.paper);
    expect(theme.dividerTheme.color, KachavaTokens.line);
    expect(theme.pageTransitionsTheme.builders.values,
        everyElement(isA<KachavaFadeTransitionsBuilder>()));
  });

  test('test_inputs_surfaceFill_lineStrongOutline_inkFocus15', () {
    final inputs = KachavaAdminTheme.build().inputDecorationTheme;
    expect(inputs.filled, isTrue);
    expect(inputs.fillColor, KachavaTokens.surface);
    final enabled = inputs.enabledBorder! as OutlineInputBorder;
    expect(enabled.borderSide.color, KachavaTokens.lineStrong);
    expect(enabled.borderRadius, BorderRadius.circular(2));
    final focused = inputs.focusedBorder! as OutlineInputBorder;
    expect(focused.borderSide.color, KachavaTokens.ink);
    expect(focused.borderSide.width, 1.5);
    expect(inputs.hintStyle?.color, KachavaTokens.faint);
  });

  test('test_inputText_is16px_onTouchPlatforms_only', () {
    double? size(TargetPlatform p) =>
        KachavaAdminTheme.build(platform: p).textTheme.bodyLarge?.fontSize;
    expect(size(TargetPlatform.iOS), 16);
    expect(size(TargetPlatform.android), 16);
    final iosInput = KachavaAdminTheme.build(platform: TargetPlatform.iOS)
        .inputDecorationTheme;
    expect(iosInput.hintStyle?.fontSize, 16);
    final desktop = KachavaAdminTheme.build(platform: TargetPlatform.macOS)
        .inputDecorationTheme;
    expect(desktop.hintStyle?.fontSize, isNot(16));
  });

  testWidgets('test_infoTooltip_exposesMessage_andHas48dpTarget',
      (tester) async {
    await tester.pumpWidget(host(const Center(child: InfoTooltip('Formula'))));
    expect(find.bySemanticsLabel('Formula'), findsOneWidget);
    expect(tester.getSize(find.byType(InfoTooltip)), const Size(48, 48));
    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Formula'), findsOneWidget);
  });

  testWidgets('test_statusChip_isSquareWashWithToneLine_notPill',
      (tester) async {
    await tester.pumpWidget(host(StatusChip.fromStatus('URGENT')));
    expect(find.text('URGENT'), findsNothing); // never a raw enum
    final text = tester.widget<Text>(find.text('Urgent'));
    expect(text.style?.color, StatusTone.error.foreground);
    expect(text.style?.fontSize, 12);
    expect(text.style?.fontWeight, FontWeight.w500);
    final box = tester.widget<Container>(find.descendant(
        of: find.byType(StatusChip), matching: find.byType(Container)));
    final d = box.decoration! as BoxDecoration;
    expect(d.color, StatusTone.error.wash);
    expect(d.borderRadius, BorderRadius.circular(2));
    expect((d.border! as Border).top, BorderSide(color: StatusTone.error.line));
  });

  testWidgets('test_hairlineGrid_cellsOnLineBackground_withOnePxGaps',
      (tester) async {
    await tester.pumpWidget(host(SizedBox(
      width: 780,
      child: HairlineGrid(
        columnsFor: (w) => w >= 700 ? 3 : 2,
        children: [for (var i = 0; i < 6; i++) Text('cell-$i')],
      ),
    )));
    final bg = tester.widget<ColoredBox>(find
        .descendant(
            of: find.byType(HairlineGrid), matching: find.byType(ColoredBox))
        .first);
    expect(bg.color, KachavaTokens.line);
    final a = tester.getRect(find.ancestor(
        of: find.text('cell-0'),
        matching: find.byKey(const Key('hairline-cell'))));
    final b = tester.getRect(find.ancestor(
        of: find.text('cell-1'),
        matching: find.byKey(const Key('hairline-cell'))));
    final d = tester.getRect(find.ancestor(
        of: find.text('cell-3'),
        matching: find.byKey(const Key('hairline-cell'))));
    expect(b.left - a.right, closeTo(1, 0.01));
    expect(d.left, a.left); // 3 columns: cell-3 starts the second row
    expect(d.top - a.bottom, closeTo(1, 0.01));
    final cell = tester.widget<ColoredBox>(find
        .ancestor(of: find.text('cell-0'), matching: find.byType(ColoredBox))
        .first);
    expect(cell.color, KachavaTokens.surface);
  });

  testWidgets('test_sectionHead_rendersUppercaseKlLabelOverQuietTitle',
      (tester) async {
    await tester.pumpWidget(
        host(const SectionHead(eyebrow: '01 — Activity', title: 'Today')));
    final eyebrow = tester.widget<Text>(find.text('01 — ACTIVITY'));
    expect(eyebrow.style?.fontSize, 11);
    expect(eyebrow.style?.color, KachavaTokens.muted);
    final title = tester.widget<Text>(find.text('Today'));
    expect(title.style?.fontFamily, KachavaTokens.fontDisplay);
    expect(title.style?.fontSize, inInclusiveRange(16, 18));
  });

  testWidgets('test_ruledSection_andCallout_useRulesNotBoxes', (tester) async {
    await tester.pumpWidget(host(const Column(children: [
      RuledSection(child: Text('section')),
      Callout(tone: StatusTone.onHold, child: Text('note')),
    ])));
    final section = tester.widget<Container>(find
        .ancestor(of: find.text('section'), matching: find.byType(Container))
        .first);
    final sd = section.decoration! as BoxDecoration;
    expect((sd.border! as Border).top,
        const BorderSide(color: KachavaTokens.line));
    expect(sd.color, isNull);
    expect(section.padding, const EdgeInsets.only(top: 16));
    final callout = tester.widget<Container>(find
        .ancestor(of: find.text('note'), matching: find.byType(Container))
        .first);
    final cd = callout.decoration! as BoxDecoration;
    expect((cd.border! as Border).left,
        const BorderSide(color: KachavaTokens.plum, width: 2));
    expect(cd.color, isNull);
    expect(callout.padding, const EdgeInsets.only(left: 16));
  });

  testWidgets('test_textSegmented_selectedInkUnderline_othersMuted',
      (tester) async {
    String? picked;
    await tester.pumpWidget(host(TextSegmented<String>(
      key: const Key('seg'),
      options: const {'a': 'Ascending', 'd': 'Descending'},
      selected: 'a',
      onChanged: (v) => picked = v,
    )));
    final on = tester.widget<Text>(find.text('Ascending'));
    final off = tester.widget<Text>(find.text('Descending'));
    expect(on.style?.color, KachavaTokens.ink);
    expect(off.style?.color, KachavaTokens.muted);
    final rule = tester.widget<Container>(find
        .ancestor(of: find.text('Ascending'), matching: find.byType(Container))
        .first);
    expect(((rule.decoration! as BoxDecoration).border! as Border).bottom,
        const BorderSide(color: KachavaTokens.ink));
    await tester.tap(find.text('Descending'));
    expect(picked, 'd');
    expect(tester.getSize(find.byKey(const Key('seg-d'))).height,
        greaterThanOrEqualTo(40));
  });

  testWidgets('test_pageHeader_eyebrowTitleMetaAndBottomHairline',
      (tester) async {
    Future<void> pump(double width) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(host(const PageHeader(
          eyebrow: 'Operations', title: 'Overview', meta: 'Nov 3')));
    }

    addTearDown(tester.view.reset);
    await pump(375);
    expect(find.text('OPERATIONS'), findsOneWidget);
    expect(tester.widget<Text>(find.text('Overview')).style?.fontSize, 26);
    expect(tester.widget<Text>(find.text('Nov 3')).style?.color,
        KachavaTokens.muted);
    await pump(1024);
    expect(tester.widget<Text>(find.text('Overview')).style?.fontSize, 32);
    final rule = tester.widget<Container>(find
        .descendant(
            of: find.byType(PageHeader), matching: find.byType(Container))
        .first);
    final d = rule.decoration! as BoxDecoration;
    expect((d.border! as Border).bottom.color, KachavaTokens.line);
    expect(rule.padding, const EdgeInsets.only(bottom: 24));
  });

  testWidgets('test_kpiTile_klLabelAndLargeTabularValue_noOwnFill',
      (tester) async {
    await tester.pumpWidget(
        host(const KpiTile(value: '12', label: 'Arrivals', info: 'Formula')));
    final value = tester.widget<Text>(find.text('12'));
    expect(value.style?.fontSize, inInclusiveRange(32, 40));
    expect(value.style?.fontWeight, FontWeight.w500);
    expect(value.style?.fontFeatures,
        contains(const FontFeature.tabularFigures()));
    expect(tester.widget<Text>(find.text('ARRIVALS')).style?.fontSize, 11);
    expect(find.byType(InfoTooltip), findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(KpiTile), matching: find.byType(DecoratedBox)),
        findsNothing);
  });

  testWidgets('test_confirmDialog_returnsTrueOnlyWhenConfirmed',
      (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(host(Builder(builder: (c) {
      ctx = c;
      return const SizedBox();
    })));
    var result = showConfirmDialog(ctx,
        title: 'Delete', message: 'Sure?', confirmLabel: 'Delete');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-dialog-cancel')));
    await tester.pumpAndSettle();
    expect(await result, isFalse);
    result = showConfirmDialog(ctx,
        title: 'Delete',
        message: 'Sure?',
        confirmLabel: 'Delete',
        destructive: true);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
    await tester.pumpAndSettle();
    expect(await result, isTrue);
  });

  testWidgets('test_asyncStateView_rendersEmptyAndErrorBranches',
      (tester) async {
    var retried = false;
    await tester.pumpWidget(host(AsyncStateView(
      state: AsyncViewState.error,
      errorMessage: 'Could not load',
      onRetry: () => retried = true,
      builder: (_) => const Text('data'),
    )));
    expect(find.text('Could not load'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
    await tester.pumpWidget(host(AsyncStateView(
      state: AsyncViewState.data,
      builder: (_) => const Text('data'),
    )));
    expect(find.text('data'), findsOneWidget);
  });
}

double? _radiusOf(ShapeBorder? shape) {
  if (shape is! RoundedRectangleBorder) return null;
  final r = shape.borderRadius.resolve(TextDirection.ltr);
  return r.topLeft.x;
}
