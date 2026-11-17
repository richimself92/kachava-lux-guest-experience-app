import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/application/admin_realtime.dart';
import 'package:kachava_admin_dashboard/application/list_query_store.dart';
import 'package:kachava_admin_dashboard/application/paged_list_controller.dart';
import 'package:kachava_admin_dashboard/core/admin_theme.dart';
import 'package:kachava_admin_dashboard/core/resort_time.dart';
import 'package:kachava_admin_dashboard/domain/conversation.dart';
import 'package:kachava_admin_dashboard/domain/guest_profile.dart';
import 'package:kachava_admin_dashboard/presentation/components/components.dart';
import 'package:kachava_admin_dashboard/presentation/operations/guests/guests_screen.dart';

import '../operations/recorded_operations_contract.dart';
import '../support/fake_operations.dart';
import '../support/fake_realtime_port.dart';
import '../support/list_example.dart';

const _window = Duration(milliseconds: 250);

void main() {
  late FakeRealtimePort port;
  late AdminRealtime realtime;

  setUp(() {
    port = FakeRealtimePort();
    realtime = AdminRealtime(
        port: port, channel: ({bool renew = false}) async => 'admin-1');
  });
  tearDown(() {
    realtime.dispose();
    port.dispose();
  });

  Widget scoped(Widget home) => AdminRealtimeScope(
        invalidations: realtime.invalidations,
        child: MaterialApp(
            theme: KachavaAdminTheme.build(), home: Scaffold(body: home)),
      );

  Future<void> desktop(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await realtime.start();
  }

  group('lists', () {
    late ExampleFetcher fetcher;
    late PagedListController<ExampleRow> list;

    setUp(() {
      fetcher = ExampleFetcher(exampleSource(60));
      list = PagedListController<ExampleRow>(fetch: fetcher.call);
    });
    tearDown(() => list.dispose());

    Widget trips() => AdminListScreen<ExampleRow>(
          entity: 'trips',
          title: 'Trips',
          controller: list,
          columns: exampleColumns,
          rowId: (r) => r.id,
          compactTitle: (r) => r.name,
          emptyMessage: 'No trips yet',
          detailBuilder: (context, item, close) => AdminDetailPanel(
              title: item?.name ?? 'New', onClose: close, body: const Text('')),
        );

    testWidgets('a trips event reloads the visible list on the same page',
        (tester) async {
      await desktop(tester);
      await tester.pumpWidget(scoped(trips()));
      await tester.pumpAndSettle();
      await list.goToPage(2);
      await tester.pumpAndSettle();
      final before = fetcher.calls;
      fetcher.source.items[25] = const ExampleRow('r26', 'Renamed', 'ACTIVE');

      port.emit('trips', stayId: 's1');
      await tester.pump(_window);
      await tester.pumpAndSettle();

      expect(fetcher.calls, before + 1);
      expect(list.query.page, 2);
      expect(find.text('Renamed'), findsOneWidget);
    });

    testWidgets('an unrelated topic does not reload the list', (tester) async {
      await desktop(tester);
      await tester.pumpWidget(scoped(trips()));
      await tester.pumpAndSettle();
      final before = fetcher.calls;

      port.emit('catalog', scope: 'global');
      await tester.pump(_window);
      await tester.pumpAndSettle();

      expect(fetcher.calls, before);
    });

    testWidgets('Refresh (everything) reloads the list too', (tester) async {
      await desktop(tester);
      await tester.pumpWidget(scoped(trips()));
      await tester.pumpAndSettle();
      final before = fetcher.calls;

      await realtime.refreshAll();
      await tester.pumpAndSettle();

      expect(fetcher.calls, before + 1);
    });

    testWidgets('the open detail panel shows the reloaded row', (tester) async {
      await desktop(tester);
      await tester.pumpWidget(scoped(trips()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('row-trips-r1')));
      await tester.pumpAndSettle();
      fetcher.source.items[0] = const ExampleRow('r1', 'Updated', 'ACTIVE');

      port.emit('trips');
      await tester.pump(_window);
      await tester.pumpAndSettle();

      expect(
          tester.widget<Text>(find.byKey(const Key('detail-panel-title'))).data,
          'Updated');
    });
  });

  group('conversation thread', () {
    late FakeConversationRepository conversations;

    setUp(() {
      conversations = FakeConversationRepository()
        ..rows.add(ConversationRow.fromJson(
            {...recordedConversationRow, 'stayId': 'stay_a'}))
        ..threads['stay_a'] = [ConversationMessage.fromJson(recordedMessage)];
    });

    Widget messages() => GuestsScreen(
          guests: FakeGuestRepository()
            ..profiles['stay_a'] = GuestProfile.fromJson(recordedGuestProfile),
          conversations: conversations,
          queries: ListQueryStore(),
          resortTime: const ResortTime(
              timeZone: 'America/Cancun',
              resolver: FixedOffsetResolver(Duration(hours: -5))),
          isEs: false,
          section: GuestsScreen.messagesSection,
          openId: 'stay_a',
        );

    ConversationMessage guestMessage(String id, String text) =>
        ConversationMessage.fromJson({
          ...recordedMessage,
          'id': id,
          'text': text,
          'photoUrl': null,
        });

    testWidgets('a messages event refreshes the open thread', (tester) async {
      await desktop(tester);
      await tester.pumpWidget(scoped(messages()));
      await tester.pumpAndSettle();
      expect(conversations.readMarks, ['stay_a']);

      conversations.threads['stay_a']!.add(guestMessage('m2', 'Also ice'));
      port.emit('messages', stayId: 'stay_a');
      await tester.pump(_window);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('message-m2')), findsOneWidget);
      expect(conversations.readMarks, ['stay_a', 'stay_a']);
    });

    testWidgets('no new message: no read mark (no event loop)', (tester) async {
      await desktop(tester);
      await tester.pumpWidget(scoped(messages()));
      await tester.pumpAndSettle();

      port.emit('messages', stayId: 'stay_a');
      await tester.pump(_window);
      await tester.pumpAndSettle();
      port.emit('messages', stayId: 'other_stay');
      await tester.pump(_window);
      await tester.pumpAndSettle();

      expect(conversations.readMarks, ['stay_a']);
    });
  });
}
