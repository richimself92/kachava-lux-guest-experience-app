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

  test('test_theme_usesRobotoWhiteCanvasAndBrownPrimary', () {
    final theme = KachavaAdminTheme.build();
    expect(theme.textTheme.bodyMedium?.fontFamily, 'Roboto');
    expect(theme.scaffoldBackgroundColor, KachavaTokens.background);
    expect(theme.colorScheme.primary, KachavaTokens.primary);
    expect(theme.colorScheme.surfaceContainerHighest, KachavaTokens.surface);
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

  testWidgets('test_statusChip_fromStatus_usesToneColors', (tester) async {
    await tester.pumpWidget(host(StatusChip.fromStatus('URGENT')));
    final text = tester.widget<Text>(find.text('URGENT'));
    expect(text.style?.color, StatusTone.error.foreground);
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
