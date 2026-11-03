import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/application/paged_list_controller.dart';
import 'package:kachava_admin_dashboard/domain/list_query.dart';

import '../support/list_example.dart';

Future<void> _setSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  late ExampleFetcher fetcher;
  late PagedListController<ExampleRow> controller;

  setUp(() {
    fetcher = ExampleFetcher(exampleSource(132));
    controller = PagedListController<ExampleRow>(fetch: fetcher.call);
  });
  tearDown(() => controller.dispose());

  Future<void> pumpList(WidgetTester tester,
      {Size size = const Size(1440, 900)}) async {
    await _setSize(tester, size);
    await tester.pumpWidget(exampleListApp(controller));
    await tester.pumpAndSettle();
  }

  group('desktop (1440)', () {
    testWidgets('header: the one primary action sits at the right edge',
        (tester) async {
      await pumpList(tester);
      final right = tester.getTopRight(find.byKey(const Key('primary-items')));
      expect(right.dx, greaterThan(1440 - 16 - 1));
    });

    testWidgets('pagination footer: range, next/prev, rows per page',
        (tester) async {
      await pumpList(tester);
      expect(find.text('1–25 of 132'), findsOneWidget);
      expect(find.byKey(const Key('row-items-r1')), findsOneWidget);

      await tester.tap(find.byKey(const Key('pager-items-next')));
      await tester.pumpAndSettle();
      expect(find.text('26–50 of 132'), findsOneWidget);
      expect(find.byKey(const Key('row-items-r26')), findsOneWidget);

      await tester.tap(find.byKey(const Key('pager-items-size')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('10').last);
      await tester.pumpAndSettle();
      expect(find.text('1–10 of 132'), findsOneWidget);
      expect(controller.query.page, 1);

      final prev =
          tester.widget<IconButton>(find.byKey(const Key('pager-items-prev')));
      expect(prev.onPressed, isNull);
    });

    testWidgets('sortable header cycles asc, desc, none', (tester) async {
      await pumpList(tester);
      await tester.tap(find.byKey(const Key('sort-items-name')));
      await tester.pumpAndSettle();
      expect(controller.query.sort, const ListSort('name'));
      await tester.tap(find.byKey(const Key('sort-items-name')));
      await tester.pumpAndSettle();
      expect(controller.query.sort, const ListSort('name', SortDirection.desc));
      expect(find.byKey(const Key('row-items-r132')), findsOneWidget);
      expect(find.bySemanticsLabel('Name, sorted descending'), findsOneWidget);
      await tester.tap(find.byKey(const Key('sort-items-name')));
      await tester.pumpAndSettle();
      expect(controller.query.sort, isNull);
    });

    testWidgets('empty: one line + primary action that opens create panel',
        (tester) async {
      fetcher.source = exampleSource(0);
      await pumpList(tester);
      expect(find.byKey(const Key('list-items-empty')), findsOneWidget);
      expect(find.text('No items yet'), findsOneWidget);
      expect(find.byKey(const Key('pager-items')), findsNothing);
      await tester.tap(find.widgetWithText(OutlinedButton, 'New item'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('detail-panel')), findsOneWidget);
      expect(find.byKey(const Key('detail-panel-title')), findsOneWidget);
    });

    testWidgets('no results: "No results" + Clear filters', (tester) async {
      await pumpList(tester);
      await tester.enterText(find.byKey(const Key('search-items')), 'zzz');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('list-items-no-results')), findsOneWidget);
      expect(find.byKey(const Key('active-filter-items-q')), findsOneWidget);
      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      expect(find.text('1–25 of 132'), findsOneWidget);
      expect(
          tester
              .widget<TextField>(find.byKey(const Key('search-items')))
              .controller!
              .text,
          isEmpty);
    });

    testWidgets('error: "Couldn\'t load" + Retry', (tester) async {
      fetcher.failWith = StateError('offline');
      await pumpList(tester);
      expect(find.byKey(const Key('list-items-error')), findsOneWidget);
      fetcher.failWith = null;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('1–25 of 132'), findsOneWidget);
    });

    testWidgets('loading shows skeleton rows', (tester) async {
      await _setSize(tester, const Size(1440, 900));
      await tester.pumpWidget(exampleListApp(controller));
      expect(find.byKey(const Key('list-skeleton')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('list-skeleton')), findsNothing);
    });

    testWidgets('inline filter chip shows its value and can be cleared',
        (tester) async {
      await pumpList(tester);
      expect(find.text('Status'), findsWidgets);
      await tester.tap(find.byKey(const Key('filter-items-status')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Active').last);
      await tester.pumpAndSettle();
      expect(find.text('Status: Active'), findsNWidgets(2)); // chip + summary
      expect(find.text('1–25 of 66'), findsOneWidget);
      await tester.tap(find.byKey(const Key('clear-filters-items')));
      await tester.pumpAndSettle();
      expect(find.text('1–25 of 132'), findsOneWidget);
    });

    testWidgets('row opens side panel with tabs; Esc closes', (tester) async {
      await pumpList(tester);
      await tester.tap(find.byKey(const Key('row-items-r3')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('detail-panel')), findsOneWidget);
      expect(find.byKey(const Key('table-items')), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('id r3'), findsOneWidget);
      await tester.tap(find.text('Notes'));
      await tester.pumpAndSettle();
      expect(find.text('notes'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('detail-panel')), findsNothing);
    });

    testWidgets('"/" focuses search; PageDown pages', (tester) async {
      await pumpList(tester);
      await tester.tap(find.byKey(const Key('row-items-r1')));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();
      expect(controller.query.page, 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.slash);
      await tester.pump();
      final field =
          tester.widget<TextField>(find.byKey(const Key('search-items')));
      expect(field.focusNode!.hasFocus, isTrue);
    });

    testWidgets('minimal text: only title, toolbar, table and pager text',
        (tester) async {
      await pumpList(tester);
      final rows = controller.items;
      final allowed = <String>{
        'Items', 'New item', // header
        'Search', 'Status', // toolbar
        'Name', // column headers ("Status" above)
        for (final r in rows) r.name,
        'Active', 'Disabled', // status chips
        'Rows per page', '25', '1–25 of 132', // pager
      };
      final texts = tester
          .widgetList<Text>(find.descendant(
              of: find.byKey(const Key('list-items')),
              matching: find.byType(Text)))
          .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
          .where((t) => t.isNotEmpty)
          .toSet();
      expect(texts.difference(allowed), isEmpty,
          reason: 'No subtitles, helper paragraphs or banners');
      for (final t in texts) {
        expect(t.split(' ').length, lessThanOrEqualTo(4), reason: t);
      }
    });
  });

  group('mobile (375)', () {
    testWidgets('compact rows, filters sheet, full-screen detail',
        (tester) async {
      await pumpList(tester, size: const Size(375, 812));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('compact-items')), findsOneWidget);
      expect(find.byKey(const Key('table-items')), findsNothing);
      expect(find.byKey(const Key('pager-items-size')), findsNothing);
      expect(find.text('1–25 of 132'), findsOneWidget);

      await tester.tap(find.byKey(const Key('filters-items')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('filter-sheet-items')), findsOneWidget);
      await tester.tap(find.byKey(const Key('filter-sheet-status')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Disabled').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('filter-sheet-sort')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Name').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('filter-sheet-apply')));
      await tester.pumpAndSettle();
      expect(controller.query.filters, {'status': 'DISABLED'});
      expect(controller.query.sort, const ListSort('name'));
      expect(
          find.byKey(const Key('active-filter-items-status')), findsOneWidget);

      await tester.tap(find.byKey(const Key('row-items-r1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('detail-panel')), findsOneWidget);
      expect(find.byKey(const Key('compact-items')), findsNothing);
      await tester.tap(find.byKey(const Key('detail-panel-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('compact-items')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('search icon expands into the search field', (tester) async {
      await pumpList(tester, size: const Size(375, 812));
      expect(find.byKey(const Key('search-items')), findsNothing);
      await tester.tap(find.byKey(const Key('search-items-open')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('search-items')), findsOneWidget);
    });
  });
}
