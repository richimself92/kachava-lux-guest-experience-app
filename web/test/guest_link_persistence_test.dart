import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_guest_portal/application/sanctuary_controller.dart';
import 'package:kachava_guest_portal/core/audio/soundscape_port.dart';
import 'package:kachava_guest_portal/core/auth/guest_link_resolver.dart';
import 'package:kachava_guest_portal/core/i18n/guest_feedback_i18n.dart';
import 'package:kachava_guest_portal/core/i18n/guest_i18n.dart';
import 'package:kachava_guest_portal/core/storage/guest_id_store.dart';
import 'package:kachava_guest_portal/domain/repositories/sanctuary_repository.dart';
import 'package:kachava_guest_portal/main.dart';

import 'support/fake_sanctuary_repository.dart';

const _stored = '3f2b8c1e-4d5a-4b6c-8d7e-9f0a1b2c3d4e';
const _fresh = 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d';
const _expiredEn = 'Your link has expired. Ask your Resort Host for a new one.';
final _bare = Uri.parse('https://guest.kachavalux.com/');

Uri _withGuest(String id) =>
    Uri.parse('https://guest.kachavalux.com/?guestId=$id');

void main() {
  group('GuestLinkResolver', () {
    test('test_urlGuestId_isUsedAndSaved', () {
      final store = MemoryGuestIdStore();
      final uri = GuestLinkResolver.resolve(_withGuest(_fresh), store);
      expect(uri.queryParameters['guestId'], _fresh);
      expect(store.read(), _fresh);
    });

    test('test_urlGuestId_winsOverStoredAndReplacesIt', () {
      final store = MemoryGuestIdStore(_stored);
      final uri = GuestLinkResolver.resolve(_withGuest(_fresh), store);
      expect(uri.queryParameters['guestId'], _fresh);
      expect(store.read(), _fresh);
    });

    test('test_urlGuestId_isSavedLowercase', () {
      final store = MemoryGuestIdStore();
      GuestLinkResolver.resolve(_withGuest(_fresh.toUpperCase()), store);
      expect(store.read(), _fresh);
    });

    test('test_missingUrlGuestId_fallsBackToStored', () {
      final store = MemoryGuestIdStore(_stored);
      final uri = GuestLinkResolver.resolve(_bare, store);
      expect(uri.queryParameters['guestId'], _stored);
      expect(uri.host, 'guest.kachavalux.com');
    });

    test('test_invalidUrlGuestId_isNotSavedAndKeepsStored', () {
      final store = MemoryGuestIdStore(_stored);
      final uri = GuestLinkResolver.resolve(_withGuest('not-a-uuid'), store);
      expect(uri.queryParameters['guestId'], 'not-a-uuid');
      expect(store.read(), _stored);
    });

    test('test_invalidStoredGuestId_isIgnoredAndCleared', () {
      final store = MemoryGuestIdStore('garbage');
      final uri = GuestLinkResolver.resolve(_bare, store);
      expect(uri.queryParameters.containsKey('guestId'), isFalse);
      expect(store.read(), isNull);
    });

    test('test_noUrlAndNoStored_returnsUriUnchanged', () {
      final store = MemoryGuestIdStore();
      expect(GuestLinkResolver.resolve(_bare, store), _bare);
      expect(store.read(), isNull);
    });
  });

  group('Rejected link clears the stored guest', () {
    test('test_serverRejection_callsOnLinkRejectedOnce', () async {
      var calls = 0;
      final c = SanctuaryController(
        repository: FakeSanctuaryRepository(
            onFetch: (_) async => const SanctuaryLinkRejected()),
        soundscape: SanctuarySoundscapeSynthesizer(),
        requireExplicitGuestId: true,
        initialUri: _withGuest(_stored),
        onLinkRejected: () => calls++,
      );
      await c.initialize();
      await c.refreshFromBackend();
      expect(calls, 1);
      expect(c.isLinkExpired, isTrue);
      c.dispose();
    });

    test('test_expiredMessage_isOneLineBilingual', () {
      expect(const GuestI18n(GuestLocale.es).accessLinkExpired,
          'Tu enlace expiró, pide uno nuevo a tu Resort Host.');
      expect(const GuestI18n(GuestLocale.en).accessLinkExpired, _expiredEn);
    });

    testWidgets('test_app_usesStoredGuestWhenUrlHasNone', (tester) async {
      final seen = <String>[];
      final repo = FakeSanctuaryRepository.villa102();
      final serve = repo.onFetch;
      repo.onFetch = (uuid) {
        seen.add(uuid);
        return serve(uuid);
      };
      await tester.pumpWidget(KachavaGuestPortalApp(
          repository: repo,
          guestIdStore: MemoryGuestIdStore(_stored),
          initialUri: _bare));
      await tester.pumpAndSettle();
      expect(seen, contains(_stored));
      expect(find.textContaining('Access Restricted'), findsNothing);
    });

    testWidgets('test_app_rejectedLink_clearsStoreAndShowsExpired',
        (tester) async {
      final store = MemoryGuestIdStore(_stored);
      await tester.pumpWidget(KachavaGuestPortalApp(
          repository: FakeSanctuaryRepository(
              onFetch: (_) async => const SanctuaryLinkRejected()),
          guestIdStore: store,
          initialUri: _bare));
      await tester.pumpAndSettle();
      expect(store.read(), isNull);
      expect(find.text(_expiredEn), findsOneWidget);
    });
  });
}
