import 'package:kachava_admin_dashboard/data/admin_write_gateway.dart';
import 'package:kachava_admin_dashboard/data/admin_write_through_cache.dart';
import 'package:kachava_admin_dashboard/domain/admin_stay_entities.dart';
import 'package:kachava_admin_dashboard/domain/admin_sync_snapshot.dart';

import 'admin_seed_fixtures.dart';
import 'admin_seed_operations.dart';

/// Test-only offline repository: the production [AdminWriteThroughCache]
/// pre-filled with seed fixtures and wired to an [OfflineEchoGateway].
/// Lives under `test/` so it can never be reached from `lib/main.dart`.
class SeededAdminRepository extends AdminWriteThroughCache {
  SeededAdminRepository({AdminSyncSnapshot? initialData})
      : super(
            gateway: OfflineEchoGateway(),
            initialData: initialData ?? seedSnapshot()) {
    if (initialData == null) syncStaff(AdminSeedFixtures.buildStaffDirectory());
  }

  static AdminSyncSnapshot seedSnapshot() => AdminSyncSnapshot(
      stays: AdminSeedFixtures.buildStays(),
      alerts: AdminSeedOperations.buildAlerts(),
      bookings: AdminSeedOperations.buildBookings(),
      larderOrders: AdminSeedOperations.buildLarderOrders(),
      conciergeTickets: AdminSeedOperations.buildConciergeTickets(),
      midStayPulses: AdminSeedOperations.buildMidStayPulses(),
      folioItems: AdminSeedOperations.buildFolioItems());

  List<StaffMember> _roster = const [];
  int _stayCounter = 100;

  @override
  void syncStaff(List<StaffMember> staff) {
    _roster = List.of(staff);
    super.syncStaff(staff);
  }

  @override
  void clearCache() {
    _roster = const [];
    super.clearCache();
  }

  /// Offline: the first seeded staff member acts as the session.
  @override
  StaffMember? get sessionStaff => _roster.isEmpty ? null : _roster.first;

  /// Offline: the seeded resort villas.
  @override
  List<AdminVillaInfo> villasFor(List<AdminStayRecord> stays) =>
      AdminSeedFixtures.buildVillas();

  /// Offline: a stay built from the create payload (no server to confirm).
  @override
  Future<AdminStayRecord> createStay({
    required String villaName,
    required String guestNames,
    required String checkInDate,
    required String checkOutDate,
    required String occasion,
    String? wifiSsid,
    String? wifiPasscode,
  }) async {
    final counter = ++_stayCounter;
    final stay = AdminSeedFixtures.buildCreatedStay(
        counter: counter,
        uuid: '550e8400-e29b-41d4-a716-446655440$counter',
        villaName: villaName,
        guestNames: guestNames,
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
        occasion: occasion,
        wifiSsid: wifiSsid,
        wifiPasscode: wifiPasscode);
    upsertStay(stay);
    return stay;
  }
}

/// Answers writes the way the server would confirm them, without a network.
class OfflineEchoGateway implements AdminWriteGateway {
  int _counter = 100;

  @override
  Future<Map<String, dynamic>> postJson(
      String path, Map<String, dynamic> body) async {
    if (path.endsWith('/regenerate-token')) {
      return {
        'guestTokenUuid': 'a8098c1a-f86e-41da-bd1a-00112444b${++_counter}'
      };
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> patchJson(
          String path, Map<String, dynamic> body) async =>
      {};

  @override
  Future<Map<String, dynamic>> deleteJson(String path) async => {};

  @override
  void dispose() {}
}
