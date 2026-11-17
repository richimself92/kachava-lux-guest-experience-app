import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_guest_portal/core/auth/guest_link_resolver.dart';
import 'package:kachava_guest_portal/core/storage/device_prefs.dart';
import 'package:kachava_guest_portal/core/storage/guest_id_store.dart';
import 'package:kachava_guest_portal/data/guest_api.dart';

import 'support/fake_guest_api.dart';
import 'support/fixtures.dart';

const _fresh = 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d';
final _bare = Uri.parse('https://guest.kachavalux.com/');

void main() {
  group('GuestLinkResolver (phase A)', () {
    test('URL guestId is used and saved lowercase', () {
      final store = MemoryGuestIdStore();
      GuestLinkResolver.resolve(portalUri(_fresh.toUpperCase()), store);
      expect(store.read(), _fresh);
    });

    test('URL guestId wins over the stored one', () {
      final store = MemoryGuestIdStore(guestUuid);
      final uri = GuestLinkResolver.resolve(portalUri(_fresh), store);
      expect(uri.queryParameters['guestId'], _fresh);
      expect(store.read(), _fresh);
    });

    test('no URL guestId falls back to the stored one', () {
      final uri =
          GuestLinkResolver.resolve(_bare, MemoryGuestIdStore(guestUuid));
      expect(uri.queryParameters['guestId'], guestUuid);
    });

    test('invalid URL id is not saved; invalid stored id is cleared', () {
      final store = MemoryGuestIdStore(guestUuid);
      GuestLinkResolver.resolve(portalUri('nope'), store);
      expect(store.read(), guestUuid);
      final bad = MemoryGuestIdStore('garbage');
      GuestLinkResolver.resolve(_bare, bad);
      expect(bad.read(), isNull);
    });
  });

  group('access states', () {
    testWidgets('loading shows skeletons, never guest data', (tester) async {
      final api = FakeGuestApi()..stayGate = Completer<void>();
      await pumpPortal(tester, api: api);
      expect(find.byKey(const Key('portal-loading')), findsOneWidget);
      expect(find.text('Casa Ceiba'), findsNothing);
      api.stayGate!.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('screen-home')), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('missing link asks for the Resort Host link', (tester) async {
      await pumpPortal(tester, uri: _bare);
      expect(find.text('Open the link from your Resort Host.'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('malformed link is invalid', (tester) async {
      await pumpPortal(tester, uri: portalUri('not-a-uuid'));
      expect(find.text('This link is not valid. Ask your Resort Host.'),
          findsOneWidget);
      await unmount(tester);
    });

    testWidgets('rejected link clears the stored guest and says expired (ES)',
        (tester) async {
      final store = MemoryGuestIdStore(guestUuid);
      await pumpPortal(tester,
          api: FakeGuestApi()..stayFailure = FailureKind.linkRejected,
          store: store,
          uri: _bare,
          prefs: MemoryDevicePrefs(browserLanguage: 'es-MX'));
      expect(store.read(), isNull);
      expect(find.text('Tu enlace expiró, pide uno nuevo a tu Resort Host.'),
          findsOneWidget);
      await unmount(tester);
    });

    testWidgets('installed app reopens as the stored guest', (tester) async {
      final api = await pumpPortal(tester,
          store: MemoryGuestIdStore(guestUuid), uri: _bare);
      expect(api.stayFetches, greaterThan(0));
      expect(find.byKey(const Key('screen-home')), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('server down on first load keeps skeleton + Reconnecting',
        (tester) async {
      await pumpPortal(tester,
          api: FakeGuestApi()..stayFailure = FailureKind.unreachable);
      expect(find.byKey(const Key('portal-loading')), findsOneWidget);
      expect(find.text('Reconnecting…'), findsOneWidget);
      await unmount(tester);
    });
  });

  group('shell', () {
    testWidgets('4 tabs, no all-screens drawer, Resort Host wording',
        (tester) async {
      await pumpPortal(tester, api: FakeGuestApi(catalog: fullCatalog()));
      for (final label in ['Home', 'Services', 'Requests', 'Host']) {
        expect(
            find.descendant(
                of: find.byKey(const Key('portal-tabs')),
                matching: find.text(label)),
            findsOneWidget);
      }
      expect(find.byType(Drawer), findsNothing);
      await tester.tap(find.text('Host'));
      await tester.pumpAndSettle();
      expect(find.text('Resort Host'), findsOneWidget);
      expect(find.textContaining('Concierge'), findsNothing);
      await unmount(tester);
    });

    testWidgets('language: browser es → ES; toggle is remembered',
        (tester) async {
      final prefs = MemoryDevicePrefs(browserLanguage: 'es-ES');
      await pumpPortal(tester,
          prefs: prefs, api: FakeGuestApi(catalog: fullCatalog()));
      expect(find.text('Inicio'), findsOneWidget);
      await tester.tap(find.byKey(const Key('lang-en')));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(prefs.read('kachava_lang'), 'en');
      await unmount(tester);
    });

    testWidgets('unread dot only for a real new Host message', (tester) async {
      final stay = stayJson(threads: const [
        {
          'requestId': 'c1',
          'type': 'ask',
          'category': 'Resort Host chat',
          'status': 'Requested',
          'createdAt': '2026-11-01T10:00:00Z',
          'messages': [
            {
              'sender': 'GUEST',
              'senderName': 'Ana',
              'text': 'Hi',
              'sentAt': '2026-11-01T10:00:00Z'
            },
            {
              'sender': 'CONCIERGE',
              'senderName': 'Lucia',
              'text': 'Welcome',
              'sentAt': '2026-11-01T10:05:00Z'
            },
          ],
        },
      ]);
      await pumpPortal(tester, api: FakeGuestApi(stay: stay));
      Badge badge() =>
          tester.widget<Badge>(find.byKey(const Key('host-unread-dot')));
      expect(badge().isLabelVisible, isTrue);
      await tester.tap(find.text('Host'));
      await tester.pumpAndSettle();
      expect(badge().isLabelVisible, isFalse);
      expect(find.text('Welcome'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('install banner (phase B) on Home', (tester) async {
      final install = FakeInstallPrompt(canPromptNative: true);
      await pumpPortal(tester, install: install);
      expect(find.byKey(const Key('install-app-banner')), findsOneWidget);
      await tester.tap(find.byKey(const Key('install-app-btn')));
      await tester.pumpAndSettle();
      expect(install.promptCalls, 1);
      expect(find.byKey(const Key('install-app-banner')), findsNothing);
      await unmount(tester);
    });

    testWidgets('iOS shows the Share guide', (tester) async {
      await pumpPortal(tester,
          install: FakeInstallPrompt(isIos: true),
          prefs: MemoryDevicePrefs(browserLanguage: 'es'));
      expect(find.text('Toca Compartir → Agregar a pantalla de inicio'),
          findsOneWidget);
      await unmount(tester);
    });
  });
}
