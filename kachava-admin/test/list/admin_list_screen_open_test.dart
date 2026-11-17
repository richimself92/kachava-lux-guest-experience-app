import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/application/paged_list_controller.dart';
import 'package:kachava_admin_dashboard/core/admin_theme.dart';
import 'package:kachava_admin_dashboard/presentation/components/components.dart';

import '../support/list_example.dart';

/// A create panel that, like the service editor, keeps itself open after
/// saving and switches to the saved record.
class _SavingEditor extends StatefulWidget {
  const _SavingEditor({required this.onClose});

  final VoidCallback onClose;

  @override
  State<_SavingEditor> createState() => _SavingEditorState();
}

class _SavingEditorState extends State<_SavingEditor> {
  String? _savedName;

  @override
  Widget build(BuildContext context) => AdminDetailPanel(
        title: _savedName ?? 'New item',
        onClose: widget.onClose,
        body: TextButton(
          key: const Key('fake-save'),
          onPressed: () => setState(() => _savedName = 'Saved item'),
          child: const Text('Save'),
        ),
      );
}

void main() {
  late PagedListController<ExampleRow> controller;

  setUp(() {
    controller = PagedListController<ExampleRow>(
        fetch: ExampleFetcher(exampleSource(3)).call);
  });
  tearDown(() => controller.dispose());

  Future<void> size(WidgetTester tester, Size value) async {
    tester.view.physicalSize = value;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  String panelTitle(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('detail-panel-title'))).data!;

  testWidgets(
      'a second "New" after saving opens a fresh, empty editor on the first tap',
      (tester) async {
    await size(tester, const Size(1440, 900));
    await tester.pumpWidget(exampleListApp(controller,
        detailBuilder: (context, item, close) => item == null
            ? _SavingEditor(onClose: close)
            : AdminDetailPanel(
                title: item.name, onClose: close, body: const SizedBox())));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('primary-items')));
    await tester.pumpAndSettle();
    expect(panelTitle(tester), 'New item');
    await tester.tap(find.byKey(const Key('fake-save')));
    await tester.pumpAndSettle();
    expect(panelTitle(tester), 'Saved item');

    await tester.tap(find.byKey(const Key('primary-items')));
    await tester.pumpAndSettle();
    expect(panelTitle(tester), 'New item');
  });

  testWidgets(
      'list narrower than the window (sidebar): "New" opens the sheet on the '
      'first tap', (tester) async {
    // Window >= 840 but the list itself < 840: the side panel cannot fit.
    await size(tester, const Size(1000, 800));
    await tester.pumpWidget(MaterialApp(
      theme: KachavaAdminTheme.build(),
      home: Scaffold(
        body: Row(children: [
          const SizedBox(width: 256),
          Expanded(
            child: AdminListScreen<ExampleRow>(
              entity: 'items',
              title: 'Items',
              controller: controller,
              columns: exampleColumns,
              rowId: (r) => r.id,
              compactTitle: (r) => r.name,
              emptyMessage: 'No items yet',
              primaryActionLabel: 'New item',
              detailBuilder: (context, item, close) => AdminDetailPanel(
                  title: item?.name ?? 'New item',
                  onClose: close,
                  body: const SizedBox()),
            ),
          ),
        ]),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('primary-items')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('detail-panel')), findsOneWidget);
    expect(panelTitle(tester), 'New item');
  });

  testWidgets('initialDetail opens that record after the first frame',
      (tester) async {
    await size(tester, const Size(1440, 900));
    await tester.pumpWidget(MaterialApp(
      theme: KachavaAdminTheme.build(),
      home: Scaffold(
        body: AdminListScreen<ExampleRow>(
          entity: 'items',
          title: 'Items',
          controller: controller,
          columns: exampleColumns,
          rowId: (r) => r.id,
          compactTitle: (r) => r.name,
          emptyMessage: 'No items yet',
          initialDetail: const ExampleRow('x9', 'Deep link', 'ACTIVE'),
          detailBuilder: (context, item, close) => AdminDetailPanel(
              title: item?.name ?? 'New item',
              onClose: close,
              body: const SizedBox()),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(panelTitle(tester), 'Deep link');
  });
}
