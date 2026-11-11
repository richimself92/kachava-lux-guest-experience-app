import 'package:flutter/material.dart';
import 'package:kachava_admin_dashboard/application/paged_list_controller.dart';
import 'package:kachava_admin_dashboard/core/admin_theme.dart';
import 'package:kachava_admin_dashboard/domain/list_query.dart';
import 'package:kachava_admin_dashboard/domain/paged_result.dart';
import 'package:kachava_admin_dashboard/presentation/components/components.dart';

import 'in_memory_paged_source.dart';

/// Tiny demo-free test entity: generated rows (`Item 001`...), no business
/// data. Exercises the list infrastructure without any real workspace.
class ExampleRow {
  const ExampleRow(this.id, this.name, this.status);

  final String id;
  final String name;
  final String status;
}

List<ExampleRow> exampleRows(int count) => [
      for (var i = 1; i <= count; i++)
        ExampleRow('r$i', 'Item ${'$i'.padLeft(3, '0')}',
            i.isEven ? 'ACTIVE' : 'DISABLED'),
    ];

InMemoryPagedSource<ExampleRow> exampleSource(int count) =>
    InMemoryPagedSource<ExampleRow>(
      items: exampleRows(count),
      searchText: (r) => [r.name],
      sortValue: (r, field) => field == 'status' ? r.status : r.name,
      filterValue: (r, key) => key == 'status' ? r.status : null,
    );

/// A fetcher whose answers can be held back or made to fail.
class ExampleFetcher {
  ExampleFetcher(this.source);

  InMemoryPagedSource<ExampleRow> source;
  Object? failWith;
  int calls = 0;

  Future<PagedResult<ExampleRow>> call(ListQuery query) async {
    calls++;
    if (failWith != null) throw failWith!;
    return source.page(query);
  }
}

const exampleColumns = [
  AdminTableColumn<ExampleRow>(
      label: 'Name', text: _name, sortField: 'name', flex: 3),
  AdminTableColumn<ExampleRow>(
      label: 'Status', cell: _status, sortField: 'status'),
];

String _name(ExampleRow r) => r.name;
Widget _status(ExampleRow r) => StatusChip.fromStatus(r.status, isEs: false);

const exampleFilters = [
  AdminListFilter(key: 'status', label: 'Status', options: [
    AdminFilterOption('ACTIVE', 'Active'),
    AdminFilterOption('DISABLED', 'Disabled'),
  ]),
];

/// Hosts an [AdminListScreen] of [ExampleRow]s in the admin theme.
Widget exampleListApp(
  PagedListController<ExampleRow> controller, {
  AdminDetailBuilder<ExampleRow>? detailBuilder,
  String? primaryActionLabel = 'New item',
}) =>
    MaterialApp(
      theme: KachavaAdminTheme.build(),
      home: Scaffold(
        body: AdminListScreen<ExampleRow>(
          entity: 'items',
          title: 'Items',
          controller: controller,
          columns: exampleColumns,
          rowId: (r) => r.id,
          compactTitle: (r) => r.name,
          compactTrailing: (r) => StatusChip.fromStatus(r.status, isEs: false),
          filters: exampleFilters,
          emptyMessage: 'No items yet',
          primaryActionLabel: primaryActionLabel,
          detailBuilder: detailBuilder ??
              (context, item, close) => AdminDetailPanel(
                    title: item?.name ?? 'New item',
                    onClose: close,
                    tabs: [
                      AdminPanelTab(
                          label: 'Overview',
                          builder: (_) => Text('id ${item?.id}')),
                      AdminPanelTab(
                          label: 'Notes', builder: (_) => const Text('notes')),
                    ],
                  ),
        ),
      ),
    );
