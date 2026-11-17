import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/core/admin_theme.dart';
import 'package:kachava_admin_dashboard/core/resort_time.dart';
import 'package:kachava_admin_dashboard/domain/conversation.dart';
import 'package:kachava_admin_dashboard/domain/realtime_change.dart';
import 'package:kachava_admin_dashboard/presentation/components/realtime_scope.dart';
import 'package:kachava_admin_dashboard/presentation/operations/messages/chat_list.dart';
import 'package:kachava_admin_dashboard/presentation/operations/messages/messages_workspace.dart';

import '../support/fake_operations.dart';
import '../transport/fake_transport_repositories.dart';

ConversationRow _row(String id, String guest,
        {int unread = 0, bool awaiting = false, DateTime? at}) =>
    ConversationRow(
      stayId: id,
      guestName: guest,
      villaName: 'Villa $id',
      lastText: 'Hello from $guest',
      lastAt: at ?? testNow,
      lastFromGuest: awaiting,
      lastHasPhoto: false,
      unreadCount: unread,
      awaitingReply: awaiting,
    );

ConversationMessage _msg(String id, bool guest, DateTime at, String text) =>
    ConversationMessage(
        id: id,
        fromGuest: guest,
        senderName: guest ? 'Valeria' : 'Host',
        text: text,
        at: at);

void main() {
  late FakeConversationRepository repo;
  late StreamController<RealtimeInvalidation> signals;

  setUp(() {
    repo = FakeConversationRepository()
      ..rows.addAll([
        _row('s1', 'Valeria Gómez',
            unread: 2,
            awaiting: true,
            at: testNow.subtract(const Duration(minutes: 8))),
        _row('s2', 'Ana Ruiz', at: testNow),
        _row('s3', 'Luis Paz',
            awaiting: true, at: testNow.subtract(const Duration(minutes: 30))),
      ])
      ..threads['s1'] = [
        _msg('m1', true, testNow.subtract(const Duration(days: 1)), 'Hi'),
        _msg('m2', false, testNow.subtract(const Duration(hours: 20)), 'Hello'),
        _msg('m3', true, testNow.subtract(const Duration(minutes: 8)),
            'Can you have a cake ready?'),
      ];
    signals = StreamController<RealtimeInvalidation>.broadcast();
  });

  tearDown(() => signals.close());

  Future<void> pump(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AdminRealtimeScope(
      invalidations: signals.stream,
      child: MaterialApp(
        theme: KachavaAdminTheme.build(),
        home: Scaffold(
          body: MessagesWorkspace(
            repository: repo,
            resortTime: const ResortTime(
                timeZone: 'America/Cancun', resolver: testZoneResolver),
            isEs: false,
            now: () => testNow,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  test('test_chatOrder_awaitingFirst_oldestWaitingFirst', () {
    expect(chatOrder(repo.rows).map((r) => r.stayId), ['s3', 's1', 's2']);
    expect(initialsOf('Valeria Gómez'), 'VG');
  });

  testWidgets('test_1440_twoPanes_bubblesAlign_unreadClearsOnOpen',
      (tester) async {
    await pump(tester, const Size(1440, 900));
    expect(find.byKey(const Key('chat-list')), findsOneWidget);
    expect(find.byKey(const Key('chat-empty')), findsOneWidget);
    expect(find.byKey(const Key('chat-unread-s1')), findsOneWidget);
    expect(find.text('8 min ago'), findsOneWidget);

    await tester.tap(find.byKey(const Key('chat-row-s1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-list')), findsOneWidget);
    expect(find.byKey(const Key('chat-thread-s1')), findsOneWidget);
    expect(find.byKey(const Key('chat-unread-s1')), findsNothing);
    expect(repo.readMarks, contains('s1'));
    final guest = tester.getCenter(find.byKey(const Key('message-m3'))).dx;
    final staff = tester.getCenter(find.byKey(const Key('message-m2'))).dx;
    expect(guest < staff, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('test_375_singlePane_backArrowReturnsToTheList', (tester) async {
    await pump(tester, const Size(375, 812));
    await tester.tap(find.byKey(const Key('chat-row-s1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-list')), findsNothing);
    expect(find.byKey(const Key('chat-thread-s1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-list')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('test_draftSurvivesARealtimeRefresh_andEnterSends',
      (tester) async {
    await pump(tester, const Size(1440, 900));
    await tester.tap(find.byKey(const Key('chat-row-s1')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('conversation-reply')), 'Of course');

    repo.threads['s1']!.add(_msg('m4', true, testNow, 'Chocolate please'));
    signals.add(RealtimeInvalidation(const [
      RealtimeChange(scope: 'admin-only', topic: 'messages', stayId: 's1')
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Chocolate please'), findsOneWidget);
    expect(find.text('Of course'), findsOneWidget);
    await tester.showKeyboard(find.byKey(const Key('conversation-reply')));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(repo.replies.single, ('s1', 'Of course'));
  });
}
