import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/application/list_query_store.dart';
import 'package:kachava_admin_dashboard/application/paged_list_controller.dart';
import 'package:kachava_admin_dashboard/domain/list_query.dart';
import 'package:kachava_admin_dashboard/domain/paged_result.dart';

import '../support/in_memory_paged_source.dart';

/// Records every query and answers from [source] (or a pending completer).
class _RecordingFetcher {
  _RecordingFetcher(this.source);

  final InMemoryPagedSource<String> source;
  final List<ListQuery> queries = [];
  final List<Completer<PagedResult<String>>> pending = [];
  bool manual = false;
  Object? failWith;

  Future<PagedResult<String>> call(ListQuery query) {
    queries.add(query);
    if (failWith != null) return Future.error(failWith!);
    if (!manual) return Future.value(source.page(query));
    final completer = Completer<PagedResult<String>>();
    pending.add(completer);
    return completer.future;
  }
}

InMemoryPagedSource<String> _names(int count) => InMemoryPagedSource<String>(
      items: [for (var i = 1; i <= count; i++) 'Item ${'$i'.padLeft(3, '0')}'],
      searchText: (s) => [s],
      sortValue: (s, field) => s,
    );

void main() {
  late _RecordingFetcher fetcher;
  late PagedListController<String> controller;

  setUp(() {
    fetcher = _RecordingFetcher(_names(132));
    controller = PagedListController<String>(fetch: fetcher.call);
  });

  tearDown(() => controller.dispose());

  testWidgets('loads page 1 of 25 and exposes data state', (tester) async {
    expect(controller.status, ListLoadStatus.loading);
    await controller.load();
    expect(controller.status, ListLoadStatus.data);
    expect(controller.items, hasLength(25));
    expect(controller.result!.total, 132);
  });

  testWidgets('search is debounced 300 ms and resets the page', (tester) async {
    await controller.load();
    await controller.goToPage(3);
    controller.search('Item 1');
    controller.search('Item 12');
    await tester.pump(const Duration(milliseconds: 299));
    expect(fetcher.queries.last.q, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(fetcher.queries.last.q, 'Item 12');
    expect(fetcher.queries.last.page, 1);
    expect(fetcher.queries.where((q) => q.q == 'Item 1'), isEmpty);
  });

  testWidgets('filter and sort changes reset the page', (tester) async {
    await controller.load();
    await controller.goToPage(4);
    await controller.toggleSort('name');
    expect(controller.query.page, 1);
    await controller.goToPage(2);
    await controller.setFilter('status', 'A');
    expect(controller.query.page, 1);
    await controller.setPageSize(50);
    expect(controller.query.pageSize, 50);
  });

  testWidgets('stale responses are dropped (sequence guard)', (tester) async {
    fetcher.manual = true;
    final first = controller.load();
    final second = controller.setFilter('status', 'B');
    fetcher.pending[1].complete(fetcher.source.page(fetcher.queries[1]));
    await second;
    fetcher.pending[0].complete(
        const PagedResult(items: ['STALE'], page: 1, pageSize: 25, total: 1));
    await first;
    expect(controller.items, isNot(contains('STALE')));
    expect(controller.query.filters, {'status': 'B'});
  });

  testWidgets('empty vs no-results vs error states', (tester) async {
    final empty =
        PagedListController<String>(fetch: _RecordingFetcher(_names(0)).call);
    addTearDown(empty.dispose);
    await empty.load();
    expect(empty.status, ListLoadStatus.empty);

    await controller.setFilter('status', 'none');
    controller.search('zzz');
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.status, ListLoadStatus.noResults);

    fetcher.failWith = StateError('down');
    await controller.retry();
    expect(controller.status, ListLoadStatus.error);
    fetcher.failWith = null;
    await controller.clearFilters();
    expect(controller.status, ListLoadStatus.data);
    expect(controller.searchText, isEmpty);
  });

  testWidgets('refresh keeps old rows while loading', (tester) async {
    await controller.load();
    fetcher.manual = true;
    final pending = controller.nextPage();
    expect(controller.isRefreshing, isTrue);
    expect(controller.items, hasLength(25));
    fetcher.pending.single.complete(fetcher.source.page(controller.query));
    await pending;
    expect(controller.isRefreshing, isFalse);
    expect(controller.result!.page, 2);
  });

  testWidgets('a page past the end clamps to the last page', (tester) async {
    await controller.goToPage(99);
    expect(controller.query.page, 6);
    expect(controller.items, hasLength(7));
  });

  testWidgets('query persists per screen in the store and resets on clear',
      (tester) async {
    final store = ListQueryStore();
    final villas = PagedListController<String>(
        fetch: fetcher.call, store: store, storeKey: 'villas');
    await villas.setFilter('status', 'A');
    villas.dispose();

    final again = PagedListController<String>(
        fetch: fetcher.call, store: store, storeKey: 'villas');
    addTearDown(again.dispose);
    expect(again.query.filters, {'status': 'A'});
    expect(store.read('services'), const ListQuery());

    store.clear();
    expect(store.read('villas'), const ListQuery());
  });
}
