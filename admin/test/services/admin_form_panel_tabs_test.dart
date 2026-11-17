import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/core/admin_theme.dart';
import 'package:kachava_admin_dashboard/presentation/components/components.dart';

void main() {
  late List<String> saved;
  late List<String> calls;

  Widget app({Object? failWith, bool closeOnSave = false}) => MaterialApp(
        theme: KachavaAdminTheme.build(),
        home: Scaffold(
          body: SizedBox(
            width: 560,
            child: AdminFormPanel(
              title: 'Edit',
              closeOnSave: closeOnSave,
              onClose: () => calls.add('close'),
              onSave: () async {
                calls.add('save');
                if (failWith != null) throw failWith;
              },
              failureMessage: (e) => e is StateError ? 'Cover required' : null,
              actions: const [Text('chip')],
              footerActions: [
                AdminFormAction(
                  key: const Key('form-activate'),
                  label: 'Activate',
                  confirmTitle: 'Activate this service?',
                  run: () async => calls.add('activate'),
                ),
              ],
              tabs: [
                AdminFormTab(label: 'General', children: [
                  AdminTextFormField(
                      label: 'Name',
                      isRequired: true,
                      onSaved: (v) => saved.add('name=$v')),
                ]),
                AdminFormTab(label: 'Price', children: [
                  AdminTextFormField(
                      label: 'Amount',
                      initialValue: '5',
                      validator: (v) => v == 'x' ? 'Invalid amount' : null,
                      onSaved: (v) => saved.add('amount=$v')),
                ]),
                const AdminFormTab(label: 'Items', child: Text('raw items')),
              ],
            ),
          ),
        ),
      );

  setUp(() {
    saved = [];
    calls = [];
  });

  testWidgets('every tab stays mounted and is saved together', (tester) async {
    await tester.pumpWidget(app());
    expect(find.text('chip'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Lux bar');
    await tester.tap(find.byKey(const Key('form-save')));
    await tester.pumpAndSettle();
    expect(saved, ['name=Lux bar', 'amount=5']);
    expect(calls, ['save']);
  });

  testWidgets('an invalid field jumps to its tab', (tester) async {
    await tester.pumpWidget(app());
    await tester.enterText(find.byType(TextFormField).first, 'Lux bar');
    await tester.tap(find.text('Price'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, 'x');
    await tester.tap(find.text('General'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('form-save')));
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
    expect(find.text('Invalid amount'), findsOneWidget);
    expect(
        tester
            .widget<IndexedStack>(find.byKey(const Key('form-panel-tabs')))
            .index,
        1);
  });

  testWidgets('footer action confirms, saves fields, then runs',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.enterText(find.byType(TextFormField).first, 'Spa');
    await tester.tap(find.byKey(const Key('form-activate')));
    await tester.pumpAndSettle();
    expect(find.text('Activate this service?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
    await tester.pumpAndSettle();
    expect(calls, ['activate']);
    expect(saved, ['name=Spa', 'amount=5']);
  });

  testWidgets('failures show the mapped one-line message', (tester) async {
    await tester.pumpWidget(app(failWith: StateError('422')));
    await tester.enterText(find.byType(TextFormField).first, 'Spa');
    await tester.tap(find.byKey(const Key('form-save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('form-save-error')), findsOneWidget);
    expect(find.text('Cover required'), findsOneWidget);
    expect(calls, ['save']);
  });

  testWidgets('unmapped failures keep "Couldn\'t save"', (tester) async {
    await tester.pumpWidget(app(failWith: Exception('boom')));
    await tester.enterText(find.byType(TextFormField).first, 'Spa');
    await tester.tap(find.byKey(const Key('form-save')));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't save"), findsOneWidget);
  });
}
