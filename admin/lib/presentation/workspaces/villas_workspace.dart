import 'package:flutter/material.dart';

import '../../application/list_query_store.dart';
import '../../application/paged_list_controller.dart';
import '../../core/admin_i18n.dart';
import '../../core/resort_strings.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../domain/admin_catalog_repositories.dart';
import '../../domain/admin_villa.dart';
import '../../domain/list_query.dart';
import '../components/components.dart';
import 'villa_detail_panel.dart';

/// GUEST OPERATIONS › Villas: server-paged list (search, status / category /
/// active filters, sort, pages) with a create/edit side panel.
class VillasWorkspace extends StatefulWidget {
  const VillasWorkspace({
    super.key,
    required this.repository,
    required this.queries,
    required this.isEs,
  });

  /// [ListQueryStore] key of this screen.
  static const String storeKey = 'villas';

  /// Default order: name A-Z.
  static const ListQuery initialQuery = ListQuery(sort: ListSort('name'));

  /// Enough to read every category of a resort-sized inventory at once
  /// (backend maximum page size).
  static const ListQuery categoriesQuery =
      ListQuery(pageSize: 100, sort: ListSort('category'));

  final VillaRepository repository;
  final ListQueryStore queries;
  final bool isEs;

  @override
  State<VillasWorkspace> createState() => _VillasWorkspaceState();
}

class _VillasWorkspaceState extends State<VillasWorkspace> {
  late final PagedListController<AdminVilla> _list = PagedListController(
    fetch: widget.repository.list,
    initialQuery: VillasWorkspace.initialQuery,
    store: widget.queries,
    storeKey: VillasWorkspace.storeKey,
  );

  /// Category filter options, read from the villas themselves (staff type
  /// categories freely; nothing is predefined).
  List<String> _categories = const [];

  ResortStrings get _s => ResortStrings(widget.isEs);

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _list.dispose();
    super.dispose();
  }

  /// Best effort: without it the category filter just has no options.
  Future<void> _loadCategories() async {
    try {
      final page =
          await widget.repository.list(VillasWorkspace.categoriesQuery);
      final names = {
        for (final v in page.items)
          if (v.category.isNotEmpty) v.category
      }.toList()
        ..sort();
      if (mounted) setState(() => _categories = names);
    } catch (_) {
      // Keep the previous options.
    }
  }

  void _afterChange() {
    _list.load();
    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('workspace-admin-villas'),
      color: KachavaTokens.background,
      child: AdminListScreen<AdminVilla>(
        entity: 'villas',
        title: _s.villas,
        info: _s.villasInfo,
        controller: _list,
        columns: _columns(),
        rowId: (v) => v.id,
        compactTitle: (v) => v.name,
        compactSubtitle: (v) => [
          v.category,
          if (v.currentGuestName case final guest?) guest,
        ].join(' · '),
        compactTrailing: _statusChip,
        filters: _filters(),
        emptyMessage: _s.noVillas,
        primaryActionLabel: _s.newVilla,
        detailBuilder: (context, villa, close) => VillaDetailPanel(
          villa: villa,
          repository: widget.repository,
          onClose: close,
          onChanged: _afterChange,
          isEs: widget.isEs,
        ),
        isEs: widget.isEs,
      ),
    );
  }

  /// Inactive villas show "Inactive" instead of their operational status.
  Widget _statusChip(AdminVilla v) => v.isActive
      ? StatusChip.fromStatus(v.operationalStatus, isEs: widget.isEs)
      : StatusChip(label: _s.villaInactive, tone: StatusTone.neutral);

  List<AdminTableColumn<AdminVilla>> _columns() => [
        AdminTableColumn(
            label: _s.name, text: (v) => v.name, sortField: 'name', flex: 3),
        AdminTableColumn(
            label: _s.category, text: (v) => v.category, sortField: 'category'),
        AdminTableColumn(
            label: _s.capacity,
            text: (v) => v.capacity?.toString() ?? '—',
            sortField: 'capacity',
            numeric: true,
            flex: 1),
        AdminTableColumn(
            label: _s.status,
            cell: _statusChip,
            sortField: 'operationalStatus'),
        AdminTableColumn(
            label: _s.housekeeping,
            cell: (v) =>
                StatusChip.fromStatus(v.housekeepingStatus, isEs: widget.isEs)),
        AdminTableColumn(
            label: _s.currentGuest, text: (v) => v.currentGuestName ?? '—'),
      ];

  List<AdminListFilter> _filters() => [
        AdminListFilter(
          key: 'operationalStatus',
          label: _s.status,
          options: [
            for (final value in VillaStatusValues.operational)
              AdminFilterOption(
                  value, AdminI18n.statusLabel(value, widget.isEs)),
          ],
        ),
        AdminListFilter(
          key: 'category',
          label: _s.category,
          options: [for (final c in _categories) AdminFilterOption(c, c)],
        ),
        AdminListFilter(
          key: 'isActive',
          label: _s.villaActiveFilter,
          options: [
            AdminFilterOption('true', _s.yes),
            AdminFilterOption('false', _s.no),
          ],
        ),
      ];
}
