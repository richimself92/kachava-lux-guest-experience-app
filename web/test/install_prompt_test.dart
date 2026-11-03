import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_guest_portal/core/i18n/guest_i18n.dart';
import 'package:kachava_guest_portal/core/pwa/install_prompt_port.dart';
import 'package:kachava_guest_portal/core/storage/guest_id_store.dart';
import 'package:kachava_guest_portal/main.dart';
import 'package:kachava_guest_portal/presentation/shell/install_app_banner.dart';

import 'support/fake_sanctuary_repository.dart';

class FakeInstallPromptPort extends ChangeNotifier
    implements InstallPromptPort {
  FakeInstallPromptPort({
    this.isStandalone = false,
    this.isIos = false,
    this.canPromptNative = false,
    this.isDismissed = false,
  });

  @override
  bool isStandalone, isIos, canPromptNative, isDismissed;
  int promptCalls = 0;

  @override
  void dismiss() {
    isDismissed = true;
    notifyListeners();
  }

  @override
  Future<bool> promptNative() async {
    promptCalls++;
    canPromptNative = false;
    notifyListeners();
    return true;
  }
}

Future<void> _pump(WidgetTester tester, InstallPromptPort port,
    {GuestLocale locale = GuestLocale.en}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: InstallAppBanner(port: port, i18n: GuestI18n(locale)),
    ),
  ));
}

void main() {
  group('InstallBannerMode.of', () {
    test('test_standalone_hidesEverything', () {
      final port = FakeInstallPromptPort(
          isStandalone: true, canPromptNative: true, isIos: true);
      expect(InstallBannerMode.of(port), InstallBannerMode.hidden);
    });

    test('test_dismissed_hidesEverything', () {
      final port = FakeInstallPromptPort(isDismissed: true, isIos: true);
      expect(InstallBannerMode.of(port), InstallBannerMode.hidden);
    });

    test('test_chromiumWithDeferredPrompt_showsNativeButton', () {
      final port = FakeInstallPromptPort(canPromptNative: true);
      expect(InstallBannerMode.of(port), InstallBannerMode.nativePrompt);
    });

    test('test_iosSafari_showsShareGuide', () {
      final port = FakeInstallPromptPort(isIos: true);
      expect(InstallBannerMode.of(port), InstallBannerMode.iosGuide);
    });

    test('test_browserWithoutPrompt_hidden', () {
      expect(InstallBannerMode.of(FakeInstallPromptPort()),
          InstallBannerMode.hidden);
    });
  });

  group('InstallAppBanner', () {
    testWidgets('test_nativePrompt_tapInstallCallsPromptAndHides',
        (tester) async {
      final port = FakeInstallPromptPort(canPromptNative: true);
      await _pump(tester, port, locale: GuestLocale.es);
      expect(find.text('Instalar app'), findsOneWidget);

      await tester.tap(find.byKey(const Key('install-app-btn')));
      await tester.pumpAndSettle();
      expect(port.promptCalls, 1);
      expect(find.byKey(const Key('install-app-banner')), findsNothing);
    });

    testWidgets('test_iosGuide_showsShareInstruction', (tester) async {
      await _pump(tester, FakeInstallPromptPort(isIos: true),
          locale: GuestLocale.es);
      expect(find.text('Toca Compartir → Agregar a pantalla de inicio'),
          findsOneWidget);
      expect(find.byKey(const Key('install-app-btn')), findsNothing);
    });

    testWidgets('test_dismiss_hidesAndRemembers', (tester) async {
      final port = FakeInstallPromptPort(isIos: true);
      await _pump(tester, port);
      await tester.tap(find.byKey(const Key('install-app-dismiss')));
      await tester.pumpAndSettle();
      expect(port.isDismissed, isTrue);
      expect(find.byKey(const Key('install-app-banner')), findsNothing);
    });

    testWidgets('test_standalone_rendersNothing', (tester) async {
      await _pump(tester,
          FakeInstallPromptPort(isStandalone: true, canPromptNative: true));
      expect(find.byKey(const Key('install-app-banner')), findsNothing);
    });

    testWidgets('test_dismissButton_meets48dpTarget', (tester) async {
      await _pump(tester, FakeInstallPromptPort(canPromptNative: true));
      final size = tester.getSize(find.byKey(const Key('install-app-dismiss')));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });

  testWidgets('test_homeScreen_showsInstallBannerFromAppPort', (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(KachavaGuestPortalApp(
      repository: FakeSanctuaryRepository.villa102(),
      guestIdStore: MemoryGuestIdStore('3f2b8c1e-4d5a-4b6c-8d7e-9f0a1b2c3d4e'),
      installPrompt: FakeInstallPromptPort(canPromptNative: true),
      initialUri: Uri.parse('https://guest.kachavalux.com/'),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen-home')), findsOneWidget);
    expect(find.byKey(const Key('install-app-banner')), findsOneWidget);
    expect(find.text('Install app'), findsOneWidget);
  });
}
