import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every `lib/` file reachable from `lib/main.dart` through imports/exports
/// (conditional imports included).
Set<String> _reachableFromMain() {
  final seen = <String>{};
  final pending = ['lib/main.dart'];
  // Whole `import`/`export` directives, including conditional targets.
  final directive =
      RegExp(r'^(?:import|export)\s[^;]*;', multiLine: true, dotAll: true);
  final quoted = RegExp(r'''['"]([^'"]+)['"]''');
  while (pending.isNotEmpty) {
    final path = pending.removeLast();
    if (!seen.add(path)) continue;
    final source = File(path).readAsStringSync();
    final targets = [
      for (final d in directive.allMatches(source))
        for (final q in quoted.allMatches(d.group(0)!)) q.group(1)!
    ];
    for (final target in targets) {
      if (target.startsWith('dart:')) continue;
      final String resolved;
      if (target.startsWith('package:kachava_admin_dashboard/')) {
        resolved =
            'lib/${target.substring('package:kachava_admin_dashboard/'.length)}';
      } else if (target.startsWith('package:')) {
        continue;
      } else {
        resolved = File(path).parent.uri.resolve(target).path;
      }
      pending.add(_normalize(resolved));
    }
  }
  return seen;
}

String _normalize(String path) {
  final cwd = '${Directory.current.path}/';
  return path.startsWith(cwd) ? path.substring(cwd.length) : path;
}

void main() {
  test('main.dart never reaches seeded/fixture repositories', () {
    final reachable = _reachableFromMain();
    expect(
        reachable, contains('lib/data/api_admin_operations_repository.dart'));
    expect(reachable, contains('lib/data/admin_write_through_cache.dart'));
    for (final path in reachable) {
      expect(
          path,
          isNot(
              matches(RegExp(r'seed|fixture|fake|mock', caseSensitive: false))),
          reason: 'runtime import graph must not include $path');
      final source = File(path).readAsStringSync();
      expect(
          source,
          isNot(matches(
              RegExp(r'AdminSeed\w*|SeededAdminRepository|buildStays\('))),
          reason: '$path references seed data');
    }
  });

  test('lib/ contains no seed or fixture files', () {
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => f.path)
        .where(
            (p) => RegExp(r'seed|fixture', caseSensitive: false).hasMatch(p));
    expect(offenders, isEmpty);
  });

  test('main.dart wires the HTTP repositories to one silent API client', () {
    final main = File('lib/main.dart').readAsStringSync();
    expect(main, contains('final api = AdminApiClient();'));
    expect(main, contains('ApiAdminOperationsRepository(apiClient: api)'));
    expect(main, contains('settings: HttpSettingsRepository(api)'));
    expect(main, contains('villas: HttpVillaRepository(api)'));
    expect(main, contains('timeZones: createTimeZoneCatalog()'));
    expect(main, contains('HttpServiceCatalogRepository(api)'));
    expect(main, contains('HttpUploadSigner(api)'));
  });
}
