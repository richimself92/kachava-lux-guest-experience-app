import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The backend removed `/admin/catalog/*` and `/admin/reset`; the admin must
/// never call them (directly or through a hidden legacy workspace).
void main() {
  test('lib/ never references a removed admin endpoint', () {
    // Also endpoints the backend never had (legacy Folio: midstay-checkins,
    // folios/:id/items) and the old full sync and queues, replaced by each
    // screen's paged reads and the 15 s unread-count poll.
    final removed = RegExp(r'''['"]/(catalog/|reset['"]|sync['"]|'''
        r'''midstay-checkins|folios/|alerts['"/]|bookings|larder-orders|'''
        r'''concierge-requests|midstay-feedback)''');
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      if (removed.hasMatch(source)) offenders.add(file.path);
    }
    expect(offenders, isEmpty);
  });
}
