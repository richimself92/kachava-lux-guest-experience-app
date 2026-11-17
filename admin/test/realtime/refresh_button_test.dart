import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/core/admin_theme.dart';
import 'package:kachava_admin_dashboard/presentation/widgets/admin_refresh_button.dart';

void main() {
  Future<void> pump(WidgetTester tester, Future<void> Function() onRefresh,
          {bool isEs = false}) =>
      tester.pumpWidget(MaterialApp(
        theme: KachavaAdminTheme.build(),
        home: Scaffold(
            body: AdminRefreshButton(onRefresh: onRefresh, isEs: isEs)),
      ));

  testWidgets('shows progress while refreshing and ignores repeat taps',
      (tester) async {
    final pending = Completer<void>();
    var calls = 0;
    await pump(tester, () {
      calls++;
      return pending.future;
    });
    expect(find.byIcon(Icons.refresh), findsOneWidget);
    expect(find.byTooltip('Refresh'), findsOneWidget);

    await tester.tap(find.byKey(const Key('admin-refresh-button')));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byKey(const Key('admin-refresh-button')));
    expect(calls, 1);

    pending.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });

  testWidgets('a failed refresh still ends the progress state', (tester) async {
    await pump(tester, () async => throw StateError('offline'));
    await tester.tap(find.byKey(const Key('admin-refresh-button')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });

  testWidgets('Spanish tooltip', (tester) async {
    await pump(tester, () async {}, isEs: true);
    expect(find.byTooltip('Actualizar'), findsOneWidget);
  });
}
