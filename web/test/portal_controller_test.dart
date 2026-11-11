import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_guest_portal/application/portal_controller.dart';
import 'package:kachava_guest_portal/core/i18n/l10n.dart';
import 'package:kachava_guest_portal/core/storage/device_prefs.dart';
import 'package:kachava_guest_portal/data/guest_api.dart';

import 'support/fake_guest_api.dart';
import 'support/fixtures.dart';

PortalController _c(FakeGuestApi api,
        {DevicePrefs? prefs, void Function()? onRejected}) =>
    PortalController(
      api: api,
      prefs: prefs ?? MemoryDevicePrefs(),
      initialUri: portalUri(),
      clock: clockAt(DateTime.utc(2026, 11, 1, 10)),
      onLinkRejected: onRejected,
    );

void main() {
  test('5xx after a good load keeps last data and flags Reconnecting',
      () async {
    final api = FakeGuestApi(catalog: fullCatalog());
    final c = _c(api);
    await c.refresh();
    expect(c.phase, PortalPhase.ready);
    api
      ..stayFailure = FailureKind.unreachable
      ..catalogFailure = FailureKind.unreachable;
    await c.refresh();
    expect(c.phase, PortalPhase.ready);
    expect(c.stay!.villaName, 'Casa Ceiba');
    expect(c.catalog, hasLength(5), reason: 'last published catalog kept');
    expect(c.isReconnecting, isTrue);
    c.dispose();
  });

  test('a link rejected while polling expires the session once', () async {
    var rejected = 0;
    final api = FakeGuestApi();
    final c = _c(api, onRejected: () => rejected++);
    await c.refresh();
    api.stayFailure = FailureKind.linkRejected;
    await c.refresh();
    await c.refresh();
    expect(c.phase, PortalPhase.linkExpired);
    expect(c.stay, isNull);
    expect(rejected, 1);
    c.dispose();
  });

  test('refreshes never overlap', () async {
    final api = FakeGuestApi()..stayGate = Completer<void>();
    final c = _c(api);
    final first = c.refresh();
    await c.refresh();
    api.stayGate!.complete();
    await first;
    expect(api.stayFetches, 1);
    c.dispose();
  });

  test('a write made while a poll is in flight is read back by a fresh refresh',
      () async {
    final api = FakeGuestApi()..stayGate = Completer<void>();
    final c = _c(api);
    final poll = c.refresh(); // reads the server before the write lands
    final write = c.savePreferences('None', const []);
    await pumpEventQueue();
    api.stayGate!.complete();
    await poll;
    await write;
    expect(api.stayFetches, 2);
    c.dispose();
  });

  test('language: stored choice wins over the browser', () {
    expect(
        _c(FakeGuestApi(), prefs: MemoryDevicePrefs(browserLanguage: 'es-MX'))
            .lang,
        Lang.es);
    expect(
        _c(FakeGuestApi(), prefs: MemoryDevicePrefs(browserLanguage: 'fr-FR'))
            .lang,
        Lang.en);
    final stored = MemoryDevicePrefs(
        browserLanguage: 'es-MX', seed: {'kachava_lang': 'en'});
    expect(_c(FakeGuestApi(), prefs: stored).lang, Lang.en);
  });

  test('a successful write refreshes from the server; a failed one does not',
      () async {
    final api = FakeGuestApi(catalog: fullCatalog());
    final c = _c(api);
    await c.refresh();
    final before = api.stayFetches;
    await c.sendRating(5, '');
    expect(api.stayFetches, before + 1);
    api.writeFailure = FailureKind.invalid;
    expect(await c.sendRating(5, ''), isA<ApiFailed<void>>());
    expect(api.stayFetches, before + 1);
    c.dispose();
  });
}
