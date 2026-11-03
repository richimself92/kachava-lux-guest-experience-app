import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_guest_portal/application/sanctuary_controller.dart';
import 'package:kachava_guest_portal/core/audio/soundscape_port.dart';
import 'package:kachava_guest_portal/core/constants/screen_id.dart';
import 'package:kachava_guest_portal/data/repositories/sanctuary_wire_mapper.dart';
import 'package:kachava_guest_portal/domain/repositories/sanctuary_repository.dart';
import 'package:kachava_guest_portal/main.dart';

import 'support/fake_sanctuary_repository.dart';

const _uuid = '3f2b8c1e-4d5a-4b6c-8d7e-9f0a1b2c3d4e';

/// Stay as a freshly created server record: name and villa only.
Future<SanctuaryController> _sparseStayController() async {
  final snapshot = SanctuaryWireMapper.mapSnapshot(_uuid, {
    'status': 'PRE_ARRIVAL',
    'villaName': 'Villa 110',
    'guestProfile': {'name': 'Elena Rostova'},
  });
  final controller = SanctuaryController(
    repository: FakeSanctuaryRepository(
        onFetch: (_) async => SanctuaryFetched(snapshot)),
    soundscape: SanctuarySoundscapeSynthesizer(),
    requireExplicitGuestId: true,
    initialUri: Uri.parse('https://kachavalux.com/?guestId=$_uuid'),
  );
  await controller.initialize();
  return controller;
}

void main() {
  testWidgets('test_sparseStay_homeShowsNoDanglingMissingFields',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    final controller = await _sparseStayController();

    await tester.pumpWidget(KachavaGuestPortalApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Elena Rostova'), findsWidgets);
    expect(find.textContaining('Elena Rostova —'), findsNothing);
    expect(find.textContaining('Wi-Fi: '), findsNothing);
    expect(find.textContaining('Miller'), findsNothing);
    controller.dispose();
  });

  testWidgets('test_sparseStay_profileHidesWifiCardWithoutServerWifi',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    final controller = await _sparseStayController();
    controller.navigateTo(ScreenId.profile);

    await tester.pumpWidget(KachavaGuestPortalApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile-copy-wifi-btn')), findsNothing);
    expect(find.textContaining('Passphrase'), findsNothing);
    controller.dispose();
  });

  testWidgets('test_sparseStay_conciergeShowsOneLineEmptyRequests',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    final controller = await _sparseStayController();
    controller.navigateTo(ScreenId.concierge);

    await tester.pumpWidget(KachavaGuestPortalApp(controller: controller));
    await tester.pumpAndSettle();
    expect(find.text('No requests yet.'), findsOneWidget);

    controller.toggleLocale();
    await tester.pumpAndSettle();
    expect(find.text('Aún no tienes solicitudes.'), findsOneWidget);
    controller.dispose();
  });
}
