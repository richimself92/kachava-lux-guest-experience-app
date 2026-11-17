import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_guest_portal/presentation/common/kit.dart';

void main() {
  testWidgets('SegmentTab hugs its label so filters sit in one row',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Wrap(children: [
          SegmentTab('All', true, () {}, key: const Key('a')),
          SegmentTab('Dining', false, () {}, key: const Key('b')),
        ]),
      ),
    ));
    final a = tester.getRect(find.byKey(const Key('a')));
    final b = tester.getRect(find.byKey(const Key('b')));
    expect(a.width, lessThan(150));
    expect(b.top, a.top);
    expect(a.height, greaterThanOrEqualTo(44));
  });
}
