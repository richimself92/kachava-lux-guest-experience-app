import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/domain/realtime_change.dart';

void main() {
  late RealtimeSignalTracker tracker;
  setUp(() => tracker = RealtimeSignalTracker());

  test('the first snapshot is only the baseline', () {
    expect(tracker.read({'topic': 'messages', 'seq': 4}), isNull);
    expect(tracker.hasBaseline, isTrue);
  });

  test('a missing doc is a valid baseline', () {
    expect(tracker.read(null), isNull);
    expect(tracker.read({'topic': 'trips', 'seq': 1})?.topic, 'trips');
  });

  test('consecutive seq keeps the topic; same data is ignored', () {
    tracker.read({'topic': 'messages', 'seq': 4});
    expect(tracker.read({'topic': 'trips', 'seq': 5})?.topic, 'trips');
    expect(tracker.read({'topic': 'trips', 'seq': 5}), isNull);
  });

  test('a seq gap (coalesced writes) invalidates every topic', () {
    tracker.read({'topic': 'messages', 'seq': 4});
    final change = tracker.read({'topic': 'notifications', 'seq': 7})!;
    final batch = RealtimeInvalidation([change]);
    expect(batch.touches({'messages'}), isTrue);
    expect(batch.touchesStay('stay_a', {'trips'}), isTrue);
  });

  test('a signal without topic also invalidates everything', () {
    tracker.read({'seq': 1});
    final change = tracker.read({'seq': 2})!;
    expect(RealtimeInvalidation([change]).touches({'tasks'}), isTrue);
  });

  test('reset starts a new baseline', () {
    tracker.read({'topic': 'messages', 'seq': 4});
    tracker.reset();
    expect(tracker.read({'topic': 'trips', 'seq': 9}), isNull);
  });
}
