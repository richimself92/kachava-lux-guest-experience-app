import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:kachava_admin_dashboard/application/admin_dashboard_controller.dart';
import 'package:kachava_admin_dashboard/application/server_confirmed_action.dart';
import 'package:kachava_admin_dashboard/data/admin_cached_records.dart';
import 'package:kachava_admin_dashboard/data/admin_wire_mapper.dart';
import 'package:kachava_admin_dashboard/data/api_admin_operations_repository.dart';
import 'package:kachava_admin_dashboard/data/seeded_admin_repository.dart';
import 'package:kachava_admin_dashboard/domain/admin_entities.dart';

import 'support/admin_sync_envelope.dart';
import 'support/signed_in_api_client.dart';

/// Offline fake whose acknowledge fails with an [Error], not an [Exception].
class _ErroringAckRepository extends SeededAdminRepository {
  @override
  Future<OperationalAlert> acknowledgeAlert(
          {required String alertId, required String staffId}) async =>
      throw StateError('corrupt cache');
}

void main() {
  group('runServerConfirmed', () {
    for (final error in <Object>[RangeError.index(-1, []), TypeError()]) {
      test('test_guard_${error.runtimeType}_reportsFailureWithoutEscaping',
          () async {
        final reports = <String>[];

        await runServerConfirmed(() async => throw error,
            report: reports.add, failureMessage: 'Not saved');

        expect(reports, ['Not saved']);
      });
    }

    test('test_guard_ownerDisposed_stopsSilently', () async {
      final reports = <String>[];

      await runServerConfirmed(() async => throw const OwnerDisposedException(),
          report: reports.add, failureMessage: 'Not saved');

      expect(reports, isEmpty);
    });
  });

  group('Per-collection parsing never leaks TypeErrors', () {
    test('test_parseMidStayPulses_nonNumericRating_throwsFormatException', () {
      expect(
          () => AdminWireMapper.parseMidStayPulses([
                {'checkInId': 'p1', 'rating': 'five'}
              ], const []),
          throwsA(isA<FormatException>()));
    });

    test('test_parseStays_nonNumericNights_throwsFormatException', () {
      expect(
          () => AdminWireMapper.parseStays([
                {...liveStayWire(), 'nights': 'three'}
              ]),
          throwsA(isA<FormatException>()));
    });
  });

  group('Mutations on records that are not loaded', () {
    test('test_regenerate_unknownStay_reportsFailureAndSendsNothing', () async {
      final requests = <String>[];
      final controller = AdminDashboardController(repository:
          ApiAdminOperationsRepository(
              apiClient: signedInApiClient(MockClient((request) async {
        requests.add('${request.method} ${request.url.path}');
        return jsonResponse(adminSyncEnvelope(stays: [liveStayWire()]));
      }))));
      await controller.initialize();

      await controller.regenerateMagicLink('stay_missing');

      expect(controller.lastToastMessage, startsWith('Link not rotated'));
      expect(requests.where((r) => r.startsWith('POST')), isEmpty);
    });

    test('test_cachedRecords_find_missingId_throwsNotLoaded', () {
      expect(() => CachedRecords.find(<String>['a'], (s) => s, 'b'),
          throwsA(isA<AdminRecordNotLoadedException>()));
    });

    test('test_controller_mutationThrowsError_reportsNotSaved', () async {
      final controller =
          AdminDashboardController(repository: _ErroringAckRepository());
      await controller.initialize();

      await controller.acknowledgeAlert(controller.alerts.first.alertId);

      expect(controller.lastToastMessage, startsWith('Not saved'));
    });
  });
}
