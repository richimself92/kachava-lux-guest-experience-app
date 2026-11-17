import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/application/resort_settings_controller.dart';
import 'package:kachava_admin_dashboard/domain/admin_settings.dart';

import '../support/fake_resort_repositories.dart';

void main() {
  test('starts loading, then holds the unconfigured settings', () async {
    final repo = FakeSettingsRepository();
    final controller = ResortSettingsController(repo);
    addTearDown(controller.dispose);
    expect(controller.status, ResortSettingsStatus.loading);
    await controller.load();
    expect(controller.status, ResortSettingsStatus.ready);
    expect(controller.settings?.timeZone, isNull);
    expect(controller.isMissing(ResortSetting.timeZone), isTrue);
    expect(controller.isMissing(ResortSetting.checkInTime), isTrue);
    expect(controller.isMissing(ResortSetting.airports), isTrue);
  });

  test('a failed load is an error, never invented defaults', () async {
    final repo = FakeSettingsRepository()..failFetch = Exception('down');
    final controller = ResortSettingsController(repo);
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.status, ResortSettingsStatus.error);
    expect(controller.settings, isNull);
    // Unknown is not "missing": no setup link while the load failed.
    expect(controller.isMissing(ResortSetting.timeZone), isFalse);

    repo.failFetch = null;
    await controller.load();
    expect(controller.status, ResortSettingsStatus.ready);
  });

  test('save stores only the server-confirmed settings', () async {
    final repo = FakeSettingsRepository();
    final controller = ResortSettingsController(repo);
    addTearDown(controller.dispose);
    await controller.load();
    var notified = 0;
    controller.addListener(() => notified++);

    await controller.save(const AdminSettings(
        timeZone: 'America/Cancun',
        airports: [
          AirportSetting(code: 'CUN', name: 'Cancun', departureBufferHours: 3)
        ]));
    expect(repo.updates, hasLength(1));
    expect(controller.settings?.timeZone, 'America/Cancun');
    expect(controller.isMissing(ResortSetting.timeZone), isFalse);
    expect(controller.isMissing(ResortSetting.airports), isFalse);
    expect(notified, greaterThan(0));

    repo.failUpdate = Exception('409');
    await expectLater(
        controller.save(const AdminSettings()), throwsA(isA<Exception>()));
    expect(controller.settings?.timeZone, 'America/Cancun');
  });
}
