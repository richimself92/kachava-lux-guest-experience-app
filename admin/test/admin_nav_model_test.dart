import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/domain/admin_enums.dart';
import 'package:kachava_admin_dashboard/presentation/navigation/admin_nav_model.dart';

void main() {
  group('AdminNavModel', () {
    test('test_visibleSections_orderAndLabels_matchMockup', () {
      final sections = AdminNavModel.visibleSections();
      expect(sections.map((s) => s.label(false)).toList(),
          ['GUEST OPERATIONS', 'HOSPITALITY', 'OPERATIONS']);
      expect(sections.map((s) => s.label(true)).toList(),
          ['OPERACIONES DE HUÉSPEDES', 'HOSPITALIDAD', 'OPERACIONES']);
      expect(sections.map((s) => s.items.map((i) => i.labelEn).toList()), [
        ['Reservations'],
        ['Services', 'Experiences'],
        ['Tasks'],
      ]);
      expect(AdminNavModel.dashboard.label(false), 'Dashboard');
      expect(AdminNavModel.dashboard.label(true), 'Panel');
    });

    test('test_hiddenItems_areNotVisible', () {
      final visible = AdminNavModel.visibleSections()
          .expand((s) => s.items)
          .map((i) => i.labelEn)
          .toSet();
      for (final hidden in [
        'Guests',
        'Villas',
        'Dining',
        'Transportation',
        'Wellness',
        'Notifications',
      ]) {
        expect(visible.contains(hidden), isFalse, reason: hidden);
        final item = AdminNavModel.sections
            .expand((s) => s.items)
            .firstWhere((i) => i.labelEn == hidden);
        expect(item.visible, isFalse, reason: hidden);
      }
    });

    test('test_labels_haveNoNumericPrefix_noFolioNoTeam', () {
      final labels = <String>[
        AdminNavModel.dashboard.labelEn,
        AdminNavModel.dashboard.labelEs,
        for (final s in AdminNavModel.sections) ...[
          s.labelEn,
          s.labelEs,
          for (final i in s.items) ...[i.labelEn, i.labelEs],
        ],
      ];
      for (final label in labels) {
        expect(RegExp(r'^\d').hasMatch(label), isFalse, reason: label);
        expect(label.toUpperCase().contains('FOLIO'), isFalse, reason: label);
        expect(label.toUpperCase(), isNot('TEAM'));
      }
      final mapped = AdminNavModel.sections
          .expand((s) => s.items)
          .map((i) => i.workspace)
          .toList();
      expect(mapped.contains(AdminWorkspaceTab.adminFolio), isFalse);
    });

    test('test_itemForWorkspace_mapsTabs_andFolioResolvesToReservations', () {
      expect(AdminNavModel.itemForWorkspace(AdminWorkspaceTab.adminOverview),
          AdminNavModel.dashboard);
      expect(
          AdminNavModel.itemForWorkspace(AdminWorkspaceTab.adminStays)?.labelEn,
          'Reservations');
      expect(
          AdminNavModel.itemForWorkspace(AdminWorkspaceTab.adminLarder)
              ?.labelEn,
          'Services');
      expect(
          AdminNavModel.itemForWorkspace(AdminWorkspaceTab.adminExperiences)
              ?.labelEn,
          'Experiences');
      expect(
          AdminNavModel.itemForWorkspace(AdminWorkspaceTab.adminConcierge)
              ?.labelEn,
          'Tasks');
      expect(
          AdminNavModel.itemForWorkspace(AdminWorkspaceTab.adminFolio)?.labelEn,
          'Reservations');
    });

    test('test_workspaceTabLabels_haveNoNumbers', () {
      for (final tab in AdminWorkspaceTab.values) {
        expect(RegExp(r'^\d').hasMatch(tab.label), isFalse);
        expect(RegExp(r'^\d').hasMatch(tab.shortLabel), isFalse);
      }
      expect(AdminWorkspaceTab.adminOverview.label, 'Dashboard');
      expect(AdminWorkspaceTab.adminFolio.label, 'Stay summary');
    });
  });
}
