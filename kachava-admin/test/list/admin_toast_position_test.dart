import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/presentation/components/components.dart';

void main() {
  for (final width in const [1440.0, 375.0]) {
    testWidgets('toast sits bottom-start (left) at ${width.toInt()}px',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAdminToast(context, 'Saved'),
              child: const Text('go'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      final rect = tester.getRect(find
          .descendant(
              of: find.byKey(const Key('admin-toast')),
              matching: find.byType(Material))
          .first);
      expect(rect.left, 16);
      expect(rect.width, lessThanOrEqualTo(360));
      expect(rect.bottom, closeTo(800 - 16, 1));
    });
  }
}
