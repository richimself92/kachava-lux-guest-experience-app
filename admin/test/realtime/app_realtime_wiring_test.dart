import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/core/realtime_events_port.dart';
import 'package:kachava_admin_dashboard/core/resort_time.dart';
import 'package:kachava_admin_dashboard/main.dart';
import 'package:kachava_admin_dashboard/presentation/services/service_catalog_scope.dart';
import 'package:kachava_admin_dashboard/presentation/workspaces/transportation/trip_scope.dart';

import '../support/fake_operations.dart';
import '../support/fake_realtime_port.dart';
import '../support/fake_resort_repositories.dart';
import '../support/fake_service_catalog.dart';
import '../transport/fake_transport_repositories.dart';

void main() {
  testWidgets('the app listens to the channel; a signal refreshes the bell',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 960);
    tester.view.devicePixelRatio = 1;
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
    addTearDown(() {
      tester.view.reset();
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
    final port = FakeRealtimePort();
    addTearDown(port.dispose);
    final ops = FakeOperations();
    await tester.pumpWidget(ServiceCatalogScope(
      deps: fakeCatalogDeps(FakeServiceCatalogRepository()),
      child: TripScope(
        deps: TripDeps(trips: FakeTripRepository([]), stays: FakeStayList()),
        child: KachavaAdminApp(
          resort: fakeResortRepositories(),
          timeZones: testTimeZones,
          operations: ops.deps,
          staff: FakeStaffDirectory(const [testStaff]),
          chime: FakeChime(),
          zoneResolver: const FixedOffsetResolver(Duration(hours: -5)),
          realtimePort: port,
          realtimeChannel: ({bool renew = false}) async => 'admin-1',
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(port.connects, hasLength(1));
    port.setConnection(RealtimeConnection.open);
    final before = ops.notifications.countCalls;

    port.emit('notifications', scope: 'admin-only');
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(ops.notifications.countCalls, before + 1);
    await tester.pumpWidget(const SizedBox());
  });
}
