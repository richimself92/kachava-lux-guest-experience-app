import 'package:flutter/material.dart' show IconData, Icons;

import '../../core/admin_i18n.dart';
import '../../domain/admin_enums.dart';

/// One navigation destination. Items without a [workspace] are modules that
/// are not built yet: they stay in the model but are hidden, never disabled.
class AdminNavItem {
  const AdminNavItem({
    required this.id,
    required this.labelEn,
    required this.labelEs,
    this.workspace,
    this.icon,
  });

  final String id;
  final String labelEn;
  final String labelEs;
  final AdminWorkspaceTab? workspace;

  /// Shown on the dashboard row and the tablet rail.
  final IconData? icon;

  bool get visible => workspace != null;

  String label(bool isEs) => AdminI18n.tr(isEs, labelEn, labelEs);
}

/// A non-clickable, uppercase group label with its items.
class AdminNavSection {
  const AdminNavSection({
    required this.id,
    required this.labelEn,
    required this.labelEs,
    required this.items,
  });

  final String id;
  final String labelEn;
  final String labelEs;
  final List<AdminNavItem> items;

  String label(bool isEs) => AdminI18n.tr(isEs, labelEn, labelEs);
}

/// Admin information architecture (root `DESIGN.md` › Navigation).
abstract final class AdminNavModel {
  static const AdminNavItem dashboard = AdminNavItem(
    id: 'dashboard',
    labelEn: 'Dashboard',
    labelEs: 'Panel',
    workspace: AdminWorkspaceTab.adminOverview,
    icon: Icons.grid_view_outlined,
  );

  static const AdminNavItem reservations = AdminNavItem(
    id: 'reservations',
    labelEn: 'Reservations',
    labelEs: 'Reservas',
    workspace: AdminWorkspaceTab.adminStays,
    icon: Icons.event_note_outlined,
  );

  static const List<AdminNavSection> sections = [
    AdminNavSection(
      id: 'guest-operations',
      labelEn: 'GUEST OPERATIONS',
      labelEs: 'OPERACIONES DE HUÉSPEDES',
      items: [
        reservations,
        AdminNavItem(id: 'guests', labelEn: 'Guests', labelEs: 'Huéspedes'),
        AdminNavItem(
          id: 'villas',
          labelEn: 'Villas',
          labelEs: 'Villas',
          workspace: AdminWorkspaceTab.adminVillas,
          icon: Icons.villa_outlined,
        ),
      ],
    ),
    AdminNavSection(
      id: 'hospitality',
      labelEn: 'HOSPITALITY',
      labelEs: 'HOSPITALIDAD',
      items: [
        // Hidden until Phase 4: the legacy Services/Larder and Experiences
        // workspaces depended on the removed `/admin/catalog/*` endpoints.
        AdminNavItem(id: 'services', labelEn: 'Services', labelEs: 'Servicios'),
        AdminNavItem(
            id: 'experiences', labelEn: 'Experiences', labelEs: 'Experiencias'),
        AdminNavItem(id: 'dining', labelEn: 'Dining', labelEs: 'Gastronomía'),
        AdminNavItem(
            id: 'transportation',
            labelEn: 'Transportation',
            labelEs: 'Transporte'),
        AdminNavItem(id: 'wellness', labelEn: 'Wellness', labelEs: 'Bienestar'),
      ],
    ),
    AdminNavSection(
      id: 'operations',
      labelEn: 'OPERATIONS',
      labelEs: 'OPERACIONES',
      items: [
        AdminNavItem(
          id: 'tasks',
          labelEn: 'Tasks',
          labelEs: 'Tareas',
          workspace: AdminWorkspaceTab.adminConcierge,
          icon: Icons.task_alt,
        ),
        AdminNavItem(
            id: 'notifications',
            labelEn: 'Notifications',
            labelEs: 'Notificaciones'),
      ],
    ),
  ];

  /// Sections with only their visible items; empty sections are dropped.
  static List<AdminNavSection> visibleSections() => [
        for (final section in sections)
          if (section.items.any((i) => i.visible))
            AdminNavSection(
              id: section.id,
              labelEn: section.labelEn,
              labelEs: section.labelEs,
              items: section.items.where((i) => i.visible).toList(),
            ),
      ];

  /// The menu item highlighted for [tab]. The stay summary (folio) is not a
  /// menu item: it keeps Reservations selected.
  static AdminNavItem? itemForWorkspace(AdminWorkspaceTab tab) {
    if (tab == AdminWorkspaceTab.adminFolio) return reservations;
    if (tab == dashboard.workspace) return dashboard;
    for (final item in sections.expand((s) => s.items)) {
      if (item.workspace == tab) return item;
    }
    return null;
  }
}
