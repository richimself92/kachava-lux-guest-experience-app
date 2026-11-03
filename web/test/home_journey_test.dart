import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_guest_portal/core/storage/device_prefs.dart';
import 'package:kachava_guest_portal/data/guest_api.dart';

import 'support/fake_guest_api.dart';
import 'support/fixtures.dart';

FakeGuestApi _api() => FakeGuestApi(
      stay: stayJson(checkIn: '2026-11-03', checkOut: '2026-11-08'),
      catalog: fullCatalog(),
    );

void main() {
  testWidgets('step 1 open before arrival with numbered rows and progress',
      (tester) async {
    await pumpPortal(tester, api: _api());
    expect(find.text('1 Before arrival'), findsOneWidget);
    expect(find.text('1.1 Flight & transfer'), findsOneWidget);
    expect(find.text('1.2 Preferences'), findsOneWidget);
    expect(find.text('1.3 Villa stocking'), findsOneWidget);
    expect(find.text('1.4 Massage'), findsOneWidget);
    expect(find.byKey(const Key('progress-1')), findsOneWidget);
    expect(find.text('0 of 4'), findsOneWidget);
    // Future steps are buttons that read "Opens Nov 3", never dead text.
    expect(find.text('Opens Nov 3'), findsOneWidget);
    expect(find.text('Opens Nov 7'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'Step 1 of 3, 0 of 4 done, expanded')),
        findsOneWidget);
    expect(find.text('Next: 1.1 Flight & transfer'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a future step expands to a read-only preview', (tester) async {
    await pumpPortal(tester, api: _api());
    await tester.tap(find.byKey(const Key('step-2')));
    await tester.pumpAndSettle();
    expect(find.text('2.1 Pool bar'), findsOneWidget);
    final row = tester.widget<InkWell>(find.byKey(const Key('task-2.1')));
    expect(row.onTap, isNull);
    await unmount(tester);
  });

  testWidgets('Not now skips the task on the stay, which leaves the count',
      (tester) async {
    final prefs = MemoryDevicePrefs();
    final api = await pumpPortal(tester, api: _api(), prefs: prefs);
    await tester.tap(find.byKey(const Key('journey-not-now')));
    await tester.pumpAndSettle();
    expect(api.writes.single.$1, 'journey');
    expect(api.writes.single.$2, {
      'skippedTaskIds': ['1:core:flight']
    });
    expect(find.text('0 of 3'), findsOneWidget);
    expect(find.text('Skipped'), findsOneWidget);
    expect(find.text('Next: 1.2 Preferences'), findsOneWidget);
    expect(prefs.read('kachava_skips_$guestUuid'), isNull,
        reason: 'skips live on the stay, not on the device');
    await unmount(tester);
  });

  testWidgets('skips stored on the stay show on any device', (tester) async {
    await pumpPortal(tester,
        api: FakeGuestApi(
          stay: stayJson(
              checkIn: '2026-11-03',
              checkOut: '2026-11-08',
              skipped: ['1:core:flight']),
          catalog: fullCatalog(),
        ));
    expect(find.text('Skipped'), findsOneWidget);
    expect(find.text('Next: 1.2 Preferences'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a failed skip keeps the task pending and says so',
      (tester) async {
    final api = _api()..writeFailure = FailureKind.unreachable;
    await pumpPortal(tester, api: api);
    await tester.tap(find.byKey(const Key('journey-not-now')));
    await tester.pumpAndSettle();
    expect(find.text('Skipped'), findsNothing);
    expect(find.text('Next: 1.1 Flight & transfer'), findsOneWidget);
    expect(find.text("Couldn't send"), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('done task shows a one-line summary; Next moves on',
      (tester) async {
    final api = _api()..tripsJson = [tripJson('t1')];
    await pumpPortal(tester, api: api);
    expect(find.text('AA 1482 · Nov 3'), findsOneWidget);
    expect(find.text('1 of 4'), findsOneWidget);
    expect(find.text('Next: 1.2 Preferences'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('section row opens Services filtered and titled; Back returns',
      (tester) async {
    await pumpPortal(tester, api: _api());
    await tester.tap(find.byKey(const Key('task-1.3')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen-services')), findsOneWidget);
    expect(find.text('1.3 Villa stocking'), findsOneWidget);
    expect(find.text('1 services'), findsNothing);
    expect(find.byKey(const Key('service-card-stock')), findsOneWidget);
    expect(find.byKey(const Key('service-card-spa')), findsNothing);
    await tester.tap(find.byKey(const Key('services-back')));
    await tester.pumpAndSettle();
    expect(find.text('1 Before arrival'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('Next opens the core task wizard with the same number',
      (tester) async {
    await pumpPortal(tester, api: _api());
    await tester.tap(find.byKey(const Key('journey-next')));
    await tester.pumpAndSettle();
    expect(find.text('1.1 Flight & transfer'), findsOneWidget);
    expect(find.text('Step 1 of 4'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('Wi-Fi tap reveals and really copies the password',
      (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map)['text'] as String);
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await pumpPortal(tester, api: _api());
    await tester.tap(find.byKey(const Key('wifi-button')));
    await tester.pumpAndSettle();
    expect(copied, ['sea-breeze-77']);
    expect(find.text('Casa-Ceiba · sea-breeze-77'), findsOneWidget);
    expect(find.text('Wi-Fi password copied'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('during stay opens step 2 and its rows are live', (tester) async {
    await pumpPortal(tester, api: _api(), now: DateTime.utc(2026, 11, 4, 9));
    expect(find.text('Next: 2.1 Pool bar'), findsOneWidget);
    final row = tester.widget<InkWell>(find.byKey(const Key('task-2.1')));
    expect(row.onTap, isNotNull);
    await unmount(tester);
  });

  testWidgets('everything done shows All set and hides Next', (tester) async {
    final api = FakeGuestApi(
      stay: stayJson(status: 'ACTIVE_STAY', dietary: 'None', feedback: const [
        {'feedbackId': 'f1'}
      ]),
      catalog: const [],
    );
    await pumpPortal(tester, api: api);
    expect(find.text('All set ✓'), findsOneWidget);
    expect(find.byKey(const Key('journey-next')), findsNothing);
    await unmount(tester);
  });
}
