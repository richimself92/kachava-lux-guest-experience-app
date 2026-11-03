import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/application/admin_dashboard_controller.dart';
import 'package:kachava_admin_dashboard/core/rating_label.dart';
import 'package:kachava_admin_dashboard/data/admin_wire_mapper.dart';
import 'support/seeded_admin_repository.dart';
import 'package:kachava_admin_dashboard/domain/admin_sync_snapshot.dart';
import 'package:kachava_admin_dashboard/presentation/workspaces/folio_workspace.dart';
import 'package:kachava_admin_dashboard/presentation/workspaces/stay_dialogs.dart';

import 'support/admin_sync_envelope.dart';

/// Controller over one stay whose mid-stay pulse has no rating (`0`).
Future<AdminDashboardController> _controllerWithUnratedPulse() async {
  final stays = AdminWireMapper.parseStays([liveStayWire()]);
  final pulses = AdminWireMapper.parseMidStayPulses([
    {
      'checkInId': 'pulse_unrated',
      'stayId': 'stay_live_101',
      'sentiment': 'Calm',
      'notes': 'Lovely villa'
    }
  ], stays);
  final controller = AdminDashboardController(
      repository: SeededAdminRepository(
          initialData: AdminSyncSnapshot(
              stays: stays,
              alerts: const [],
              bookings: const [],
              larderOrders: const [],
              conciergeTickets: const [],
              midStayPulses: pulses,
              experienceCatalog: const [],
              larderCatalog: const [],
              folioItems: const [])));
  await controller.initialize();
  return controller;
}

void main() {
  group('RatingLabel', () {
    test('test_ratingLabel_missingRating_rendersDash', () {
      expect(RatingLabel.stars(0), '—');
      expect(RatingLabel.stars(-2), '—');
      expect(RatingLabel.score(0), '—');
    });

    test('test_ratingLabel_presentRating_rendersStarsAndScore', () {
      expect(RatingLabel.stars(4), '★★★★☆ — 4/5');
      expect(RatingLabel.stars(9), '★★★★★ — 5/5');
      expect(RatingLabel.score(3), '3/5');
    });
  });

  group('Unrated pulse rendering', () {
    testWidgets('test_folioWorkspace_unratedPulse_showsDashNotOneStar',
        (tester) async {
      final controller = await _controllerWithUnratedPulse();
      expect(controller.midStayPulses.single.rating, 0);

      await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: FolioWorkspace(controller: controller))));

      expect(find.textContaining('1/5'), findsNothing);
      expect(find.textContaining('★'), findsNothing);
      expect(find.text('—'), findsWidgets);
    });

    testWidgets('test_checkoutDialog_unratedPulse_showsDashNotZeroOfFive',
        (tester) async {
      final controller = await _controllerWithUnratedPulse();
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: Builder(
                  builder: (context) => TextButton(
                      onPressed: () => showConfirmCheckoutDialog(
                          context, controller, controller.stays.single),
                      child: const Text('open'))))));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.textContaining('0/5'), findsNothing);
      expect(find.textContaining('⭐ — ·'), findsOneWidget);
    });
  });
}
