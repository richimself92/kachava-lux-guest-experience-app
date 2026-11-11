import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/domain/admin_enums.dart';
import 'package:kachava_admin_dashboard/presentation/navigation/admin_nav_model.dart';

void main() {
  group('AdminNavModel (plan v2 menu)', () {
    test('every plan item is visible, in order, with EN/ES labels', () {
      final sections = AdminNavModel.visibleSections();
      expect(sections.map((s) => s.label(false)).toList(),
          ['GUEST OPERATIONS', 'HOSPITALITY', 'OPERATIONS']);
      expect(sections.map((s) => s.label(true)).toList(),
          ['OPERACIONES DE HUÉSPEDES', 'HOSPITALIDAD', 'OPERACIONES']);
      expect(sections.map((s) => s.items.map((i) => i.labelEn).toList()), [
        ['Reservations', 'Guests', 'Villas'],
        ['Services', 'Experiences', 'Dining', 'Transportation', 'Wellness'],
        ['Tasks', 'Notifications'],
      ]);
      expect(AdminNavModel.dashboard.label(false), 'Dashboard');
      expect(AdminNavModel.dashboard.label(true), 'Panel');
      expect(
          AdminNavModel.sections.expand((s) => s.items).every((i) => i.visible),
          isTrue);
    });

    test('Requests and Messages sit right under Dashboard', () {
      expect(AdminNavModel.topItems.map((i) => i.labelEn),
          ['Dashboard', 'Requests', 'Messages']);
      expect(AdminNavModel.topItems.map((i) => i.labelEs),
          ['Panel', 'Solicitudes', 'Mensajes']);
      expect(AdminNavModel.itemForWorkspace(AdminWorkspaceTab.adminRequests),
          AdminNavModel.requests);
      expect(AdminNavModel.itemForWorkspace(AdminWorkspaceTab.adminMessages),
          AdminNavModel.messages);
      expect(AdminWorkspaceTab.adminRequests.id, 'admin-requests');
      expect(AdminWorkspaceTab.adminMessages.id, 'admin-messages');
    });

    test('labels have no numeric prefix, no Folio and no TEAM', () {
      final labels = <String>[
        AdminNavModel.dashboard.labelEn,
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
    });

    test('itemForWorkspace maps every menu workspace; Settings has none', () {
      for (final (tab, label) in [
        (AdminWorkspaceTab.adminOverview, 'Dashboard'),
        (AdminWorkspaceTab.adminStays, 'Reservations'),
        (AdminWorkspaceTab.adminGuests, 'Guests'),
        (AdminWorkspaceTab.adminVillas, 'Villas'),
        (AdminWorkspaceTab.adminServices, 'Services'),
        (AdminWorkspaceTab.adminTransportation, 'Transportation'),
        (AdminWorkspaceTab.adminTasks, 'Tasks'),
        (AdminWorkspaceTab.adminNotifications, 'Notifications'),
      ]) {
        expect(AdminNavModel.itemForWorkspace(tab)?.labelEn, label);
      }
      expect(AdminNavModel.itemForWorkspace(AdminWorkspaceTab.adminSettings),
          isNull);
    });

    test('workspace labels have no numbers and are translated', () {
      for (final tab in AdminWorkspaceTab.values) {
        expect(RegExp(r'^\d').hasMatch(tab.label), isFalse);
        expect(tab.labelEs, isNotEmpty);
      }
      expect(AdminWorkspaceTab.adminTasks.labelEs, 'Tareas');
    });
  });
}
