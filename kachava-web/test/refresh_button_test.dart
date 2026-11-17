import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_guest_api.dart';

const _button = Key('guest-refresh-button');

void main() {
  testWidgets('refresh button is in the app bar on all four tabs',
      (tester) async {
    await pumpPortal(tester);
    for (final tab in ['Home', 'Services', 'Requests', 'Host']) {
      await tester.tap(find.descendant(
          of: find.byKey(const Key('portal-tabs')), matching: find.text(tab)));
      await tester.pumpAndSettle();
      expect(
          find.descendant(
              of: find.byType(AppBar), matching: find.byKey(_button)),
          findsOneWidget,
          reason: tab);
    }
    await unmount(tester);
  });

  testWidgets('tapping refreshes with brief progress; tooltip is localized',
      (tester) async {
    final api = await pumpPortal(tester);
    expect(find.byTooltip('Refresh'), findsOneWidget);
    final before = api.stayFetches;
    api.stayGate = Completer<void>();
    await tester.tap(find.byKey(_button));
    await tester.pump();
    expect(
        find.descendant(
            of: find.byKey(_button),
            matching: find.byType(CircularProgressIndicator)),
        findsOneWidget);
    api.stayGate!.complete();
    api.stayGate = null;
    await tester.pumpAndSettle();
    expect(api.stayFetches, before + 1);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
    await tester.tap(find.byKey(const Key('lang-es')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Actualizar'), findsOneWidget);
    await unmount(tester);
  });
}
