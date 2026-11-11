import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/core/admin_theme.dart';
import 'package:kachava_admin_dashboard/domain/uploads.dart';
import 'package:kachava_admin_dashboard/presentation/components/components.dart';

import '../support/fake_uploads.dart';

/// Hosts a form panel that can be closed (records the close).
class _FormHost extends StatefulWidget {
  const _FormHost({required this.onSave, required this.fields});

  final Future<void> Function() onSave;
  final List<Widget> fields;

  @override
  State<_FormHost> createState() => _FormHostState();
}

class _FormHostState extends State<_FormHost> {
  bool open = true;

  @override
  Widget build(BuildContext context) => open
      ? AdminFormPanel(
          title: 'New item',
          onSave: widget.onSave,
          onClose: () => setState(() => open = false),
          children: widget.fields,
        )
      : const Text('closed');
}

void main() {
  Future<void> pumpForm(WidgetTester tester,
      {required Future<void> Function() onSave,
      List<Widget>? fields,
      String? Function(String?)? captureName}) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: KachavaAdminTheme.build(),
      home: Scaffold(
        body: SizedBox(
          width: 420,
          child: _FormHost(
            onSave: onSave,
            fields: fields ??
                const [
                  AdminTextFormField(label: 'Name', isRequired: true),
                  AdminAdvancedSection(title: 'More', children: [
                    AdminTextFormField(label: 'Internal note'),
                  ]),
                ],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.descendant(
      of: find
          .ancestor(of: find.text(label), matching: find.byType(Column))
          .first,
      matching: find.byType(TextFormField));

  group('AdminFormPanel', () {
    testWidgets('required field: asterisk, "Required", no save',
        (tester) async {
      var saves = 0;
      await pumpForm(tester, onSave: () async => saves++);
      expect(find.text(' *', findRichText: true), findsNothing); // in a span
      expect(find.textContaining('Name *', findRichText: true), findsOneWidget);
      expect(find.text('Internal note'), findsNothing); // collapsed
      await tester.tap(find.byKey(const Key('form-save')));
      await tester.pumpAndSettle();
      expect(find.text('Required'), findsOneWidget);
      expect(saves, 0);
    });

    testWidgets('valid save awaits onSave then closes', (tester) async {
      var saves = 0;
      await pumpForm(tester, onSave: () async => saves++);
      await tester.enterText(field('Name *'), 'Ceiba');
      await tester.tap(find.byKey(const Key('form-save')));
      await tester.pumpAndSettle();
      expect(saves, 1);
      expect(find.text('closed'), findsOneWidget);
    });

    testWidgets('save failure keeps the form open with "Couldn\'t save"',
        (tester) async {
      await pumpForm(tester, onSave: () async => throw StateError('500'));
      await tester.enterText(field('Name *'), 'Ceiba');
      await tester.tap(find.byKey(const Key('form-save')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('form-save-error')), findsOneWidget);
      expect(find.text('closed'), findsNothing);
    });

    testWidgets('unsaved changes: Cancel asks; Keep editing stays',
        (tester) async {
      await pumpForm(tester, onSave: () async {});
      await tester.enterText(field('Name *'), 'Ceiba');
      await tester.tap(find.byKey(const Key('form-cancel')));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.text('closed'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('closed'), findsOneWidget);
    });

    testWidgets('a pristine form closes without asking', (tester) async {
      await pumpForm(tester, onSave: () async {});
      await tester.tap(find.byKey(const Key('detail-panel-close')));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('closed'), findsOneWidget);
    });
  });

  group('AdminImageUploadField', () {
    late FakeUploadSigner signer;
    late FakeSignedUploadTransport transport;
    late FakeImageFilePicker picker;
    UploadedImage? changed;

    setUp(() {
      signer = FakeUploadSigner();
      transport = FakeSignedUploadTransport();
      picker = FakeImageFilePicker(pickedImage());
      changed = null;
    });

    Future<void> pumpUpload(WidgetTester tester,
        {bool required = false, UploadSigner? customSigner}) async {
      await pumpForm(tester, onSave: () async {}, fields: [
        AdminImageUploadField(
          id: 'cover',
          label: 'Cover',
          folder: 'services',
          isRequired: required,
          signer: customSigner ?? signer,
          transport: transport,
          picker: picker,
          onChanged: (v) => changed = v,
        ),
      ]);
    }

    testWidgets('pick -> sign -> PUT -> preview', (tester) async {
      await pumpUpload(tester);
      await tester.tap(find.byKey(const Key('upload-cover-pick')));
      await tester.pumpAndSettle();
      expect(signer.calls.single, {
        'fileName': 'cover.png',
        'contentType': 'image/png',
        'sizeBytes': 1024,
        'folder': 'services',
      });
      expect(transport.puts.single.$1.toString(),
          'https://storage.test/put/services/cover.png');
      expect(changed?.publicUrl, 'https://cdn.test/services/cover.png');
      expect(find.text('Replace'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('over 5 MB is refused before signing', (tester) async {
      picker.file = pickedImage(size: ImageUploadPolicy.maxBytes + 1);
      await pumpUpload(tester);
      await tester.tap(find.byKey(const Key('upload-cover-pick')));
      await tester.pumpAndSettle();
      expect(find.text('Max 5 MB'), findsOneWidget);
      expect(signer.calls, isEmpty);
    });

    testWidgets('unsupported type is refused', (tester) async {
      picker.file = pickedImage(name: 'a.gif', contentType: 'image/gif');
      await pumpUpload(tester);
      await tester.tap(find.byKey(const Key('upload-cover-pick')));
      await tester.pumpAndSettle();
      expect(find.text('JPG, PNG or WebP'), findsOneWidget);
      expect(transport.puts, isEmpty);
    });

    testWidgets('signer failure shows "Upload failed", value unchanged',
        (tester) async {
      await pumpUpload(tester,
          customSigner: FakeUploadSigner(failWith: StateError('403')));
      await tester.tap(find.byKey(const Key('upload-cover-pick')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('upload-cover-error')), findsOneWidget);
      expect(find.text('Upload failed'), findsOneWidget);
      expect(changed, isNull);
    });

    testWidgets('required and empty fails form validation', (tester) async {
      await pumpUpload(tester, required: true);
      await tester.tap(find.byKey(const Key('form-save')));
      await tester.pumpAndSettle();
      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('an upload marks the form dirty (close asks)', (tester) async {
      await pumpUpload(tester);
      await tester.tap(find.byKey(const Key('upload-cover-pick')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('detail-panel-close')));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
    });
  });

  test('ImageUploadPolicy accepts jpeg/png/webp up to 5 MB', () {
    expect(ImageUploadPolicy.check(pickedImage(contentType: 'image/jpeg')),
        isNull);
    expect(ImageUploadPolicy.check(pickedImage(contentType: 'image/webp')),
        isNull);
    expect(ImageUploadPolicy.check(pickedImage(contentType: 'image/svg+xml')),
        ImageRejection.unsupportedType);
    expect(
        ImageUploadPolicy.check(pickedImage(size: ImageUploadPolicy.maxBytes)),
        isNull);
    expect(
        ImageUploadPolicy.check(
            pickedImage(size: ImageUploadPolicy.maxBytes + 1)),
        ImageRejection.tooLarge);
  });
}
