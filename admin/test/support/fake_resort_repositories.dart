import 'package:kachava_admin_dashboard/core/time_zone_catalog.dart';
import 'package:kachava_admin_dashboard/domain/admin_catalog_repositories.dart';
import 'package:kachava_admin_dashboard/domain/admin_settings.dart';
import 'package:kachava_admin_dashboard/domain/admin_villa.dart';
import 'package:kachava_admin_dashboard/domain/list_query.dart';
import 'package:kachava_admin_dashboard/domain/paged_result.dart';

import 'in_memory_paged_source.dart';

/// In-memory `/admin/settings`: starts unconfigured, like an empty database.
class FakeSettingsRepository implements AdminSettingsRepository {
  FakeSettingsRepository([this.stored = const AdminSettings()]);

  AdminSettings stored;
  Object? failFetch;
  Object? failUpdate;
  int fetchCalls = 0;
  final List<AdminSettings> updates = [];

  @override
  Future<AdminSettings> fetch() async {
    fetchCalls++;
    if (failFetch != null) throw failFetch!;
    return stored;
  }

  /// Echoes the saved values back, the way the server confirms them.
  @override
  Future<AdminSettings> update(AdminSettings settings) async {
    if (failUpdate != null) throw failUpdate!;
    updates.add(settings);
    return stored = AdminSettings.fromJson(settings.toJson());
  }
}

/// In-memory `/admin/villas` that applies a [ListQuery] like the backend.
class FakeVillaRepository implements VillaRepository {
  FakeVillaRepository([List<AdminVilla> villas = const []])
      : villas = List.of(villas);

  final List<AdminVilla> villas;

  /// Ids the backend refuses to delete (they have stays: HTTP 409).
  final Set<String> withStays = {};
  Object? failWith;
  int _ids = 0;
  final List<ListQuery> queries = [];

  @override
  Future<PagedResult<AdminVilla>> list(ListQuery query) async {
    queries.add(query);
    _maybeFail();
    return InMemoryPagedSource<AdminVilla>(
      items: villas,
      searchText: (v) => [v.name, v.category],
      sortValue: (v, field) => switch (field) {
        'capacity' => v.capacity,
        'category' => v.category,
        'operationalStatus' => v.operationalStatus,
        _ => v.name,
      },
      filterValue: (v, key) => switch (key) {
        'isActive' => '${v.isActive}',
        'category' => v.category,
        'operationalStatus' => v.operationalStatus,
        _ => null,
      },
    ).page(query);
  }

  @override
  Future<AdminVilla> create(AdminVilla villa) async {
    _maybeFail();
    final saved = _withId(villa, 'villa-${++_ids}');
    villas.add(saved);
    return saved;
  }

  @override
  Future<AdminVilla> update(AdminVilla villa) async {
    _maybeFail();
    final index = villas.indexWhere((v) => v.id == villa.id);
    final current = villas[index];
    return villas[index] = AdminVilla.fromJson({
      ...villa.toWriteJson(),
      'id': villa.id,
      'currentGuestName': current.currentGuestName,
    });
  }

  @override
  Future<AdminVilla> setActive(String id, bool isActive) async {
    _maybeFail();
    final index = villas.indexWhere((v) => v.id == id);
    final current = villas[index];
    return villas[index] = AdminVilla.fromJson({
      ...current.toWriteJson(),
      'isActive': isActive,
      'id': id,
      'currentGuestName': current.currentGuestName,
    });
  }

  @override
  Future<void> delete(String id) async {
    _maybeFail();
    if (withStays.contains(id)) throw VillaHasStaysException(id);
    villas.removeWhere((v) => v.id == id);
  }

  void _maybeFail() {
    final error = failWith;
    if (error != null) throw error;
  }

  static AdminVilla _withId(AdminVilla villa, String id) =>
      AdminVilla.fromJson({...villa.toWriteJson(), 'id': id});
}

/// Generated test villas (`Villa 01`...), no business data.
List<AdminVilla> generatedVillas(int count) => [
      for (var i = 1; i <= count; i++)
        AdminVilla.fromJson({
          'id': 'v$i',
          'name': 'Villa ${'$i'.padLeft(2, '0')}',
          'category': i.isEven ? 'Garden' : 'Ocean',
          'capacity': 2 + i % 4,
          'wifi': {'ssid': 'net-$i', 'password': 'pw-$i'},
          'operationalStatus': i % 5 == 0 ? 'BLOCKED' : 'AVAILABLE',
          'housekeepingStatus': i.isEven ? 'DIRTY' : 'CLEAN',
          'maintenanceStatus': 'OK',
          'maintenanceNote': '',
          'isActive': i % 7 != 0,
          'currentGuestName': i == 3 ? 'Guest 3' : null,
        }),
    ];

/// Both resort repositories, empty (a fresh database).
AdminResortRepositories fakeResortRepositories({
  FakeSettingsRepository? settings,
  FakeVillaRepository? villas,
}) =>
    AdminResortRepositories(
      settings: settings ?? FakeSettingsRepository(),
      villas: villas ?? FakeVillaRepository(),
    );

/// A fixed IANA list standing in for the browser's `Intl` zones.
const TimeZoneCatalog testTimeZones = ListTimeZoneCatalog([
  'America/Cancun',
  'America/Mexico_City',
  'America/New_York',
  'Europe/Madrid',
  'UTC',
]);
