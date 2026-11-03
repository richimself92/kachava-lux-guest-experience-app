import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/application/list_query_store.dart';
import 'package:kachava_admin_dashboard/core/admin_theme.dart';
import 'package:kachava_admin_dashboard/core/resort_time.dart';
import 'package:kachava_admin_dashboard/domain/conversation.dart';
import 'package:kachava_admin_dashboard/domain/guest_profile.dart';
import 'package:kachava_admin_dashboard/presentation/operations/guests/guests_screen.dart';

import '../support/fake_operations.dart';
import 'recorded_operations_contract.dart';

ConversationRow _row(String id, {int unread = 0, String guest = 'Guest'}) =>
    ConversationRow.fromJson({
      ...recordedConversationRow,
      'stayId': id,
      'guestName': guest,
      'unreadCount': unread,
      'awaitingReply': unread > 0,
    });

void main() {
  late FakeGuestRepository guests;
  late FakeConversationRepository conversations;
  late int readEvents;

  setUp(() {
    guests = FakeGuestRepository()
      ..rows.add(GuestRow.fromJson(recordedGuestProfile))
      ..profiles['stay_a'] = GuestProfile.fromJson(recordedGuestProfile);
    conversations = FakeConversationRepository()
      ..rows.addAll([
        _row('stay_read', guest: 'Read Guest'),
        _row('stay_a', unread: 2, guest: 'Ana Ruiz'),
      ])
      ..threads['stay_a'] = [ConversationMessage.fromJson(recordedMessage)];
    readEvents = 0;
  });

  Future<void> pump(WidgetTester tester,
      {String? section, String? openId}) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: KachavaAdminTheme.build(),
      home: Scaffold(
        body: GuestsScreen(
          guests: guests,
          conversations: conversations,
          queries: ListQueryStore(),
          resortTime: const ResortTime(
              timeZone: 'America/Cancun',
              resolver: FixedOffsetResolver(Duration(hours: -5))),
          isEs: false,
          section: section,
          openId: openId,
          onMessagesRead: () => readEvents++,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('Guests tab: allergy flag, open requests and the profile',
      (tester) async {
    await pump(tester);
    for (final h in ['Guest', 'Villa', 'Dates', 'Language', 'Allergies']) {
      expect(find.text(h), findsWidgets, reason: h);
    }
    expect(find.byKey(const Key('guest-allergy-stay_a')), findsOneWidget);
    expect(find.text('Spanish'), findsOneWidget);
    await tester.tap(find.byKey(const Key('row-guests-stay_a')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('guest-profile')), findsOneWidget);
    expect(find.text('Shellfish'), findsOneWidget);
    expect(find.text('ARRIVAL trip'), findsOneWidget);
    expect(find.text('VIP'), findsOneWidget);

    await tester.tap(find.byKey(const Key('guest-open-chat')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('conversation-panel')), findsOneWidget);
  });

  testWidgets('Messages: unread first; opening marks read; reply appends',
      (tester) async {
    await pump(tester, section: GuestsScreen.messagesSection);
    final first =
        tester.getTopLeft(find.byKey(const Key('row-conversations-stay_a')));
    final second =
        tester.getTopLeft(find.byKey(const Key('row-conversations-stay_read')));
    expect(first.dy, lessThan(second.dy), reason: 'unread first');
    expect(find.byKey(const Key('conversation-unread-stay_a')), findsOneWidget);
    expect(
        find.byKey(const Key('filter-conversations-unread')), findsOneWidget);
    expect(find.byKey(const Key('filter-conversations-awaitingReply')),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('row-conversations-stay_a')));
    await tester.pumpAndSettle();
    expect(conversations.readMarks, ['stay_a']);
    expect(readEvents, greaterThan(0));
    expect(find.byKey(const Key('message-photo-req_1:0')), findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('conversation-reply')), 'Sending them now');
    await tester.tap(find.byKey(const Key('conversation-send')));
    await tester.pumpAndSettle();
    expect(conversations.replies, [('stay_a', 'Sending them now')]);
    expect(find.text('Sending them now'), findsOneWidget);
  });

  testWidgets('a notification opens the conversation directly', (tester) async {
    await pump(tester, section: GuestsScreen.messagesSection, openId: 'stay_a');
    expect(find.byKey(const Key('conversation-panel')), findsOneWidget);
    expect(conversations.readMarks, ['stay_a']);
  });
}
