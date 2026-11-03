import 'package:kachava_guest_portal/domain/entities/concierge_folio_entities.dart';
import 'package:kachava_guest_portal/domain/entities/experience_entities.dart';
import 'package:kachava_guest_portal/domain/entities/stay_entities.dart';
import 'package:kachava_guest_portal/domain/repositories/sanctuary_repository.dart';

import 'villa_102_seed_data.dart';

/// In-memory test double for [SanctuaryRepository].
///
/// [onFetch] decides every fetch outcome; [mutationResult] is returned by every
/// mutation. Both are mutable so a test can switch server behaviour mid-flight.
class FakeSanctuaryRepository implements SanctuaryRepository {
  FakeSanctuaryRepository({
    required this.onFetch,
    this.mutationResult = const MutationConfirmed(),
  });

  /// Repository that always serves the fictitious Villa 102 fixture.
  factory FakeSanctuaryRepository.villa102({
    MutationResult mutationResult = const MutationConfirmed(),
  }) =>
      FakeSanctuaryRepository(
        onFetch: (uuid) async =>
            SanctuaryFetched(Villa102SeedData.buildDefaultSnapshot(uuid)),
        mutationResult: mutationResult,
      );

  Future<SanctuaryFetchResult> Function(String guestUuid) onFetch;
  MutationResult mutationResult;
  int fetchCount = 0;
  final List<String> mutationCalls = [];

  /// Server answer to a step-up challenge: a token, or `null` when rejected.
  Future<String?> Function(String answer) onStepUp =
      (_) async => 'fake-step-up-token';
  final List<String> stepUpAnswers = [];
  final List<ConciergeRequest> conciergeRequests = [];
  String? lastCheckoutToken;

  @override
  Future<SanctuaryFetchResult> fetchLiveSanctuary(String guestUuid) {
    fetchCount++;
    return onFetch(guestUuid);
  }

  Future<MutationResult> _record(String name) async {
    mutationCalls.add(name);
    return mutationResult;
  }

  @override
  Future<String?> verifyStepUpChallenge(String guestUuid, String answer) {
    stepUpAnswers.add(answer);
    return onStepUp(answer);
  }

  @override
  Future<MutationResult> syncFlightTransport(
          String guestUuid, FlightTransport transport,
          {String? stepUpSession}) =>
      _record('flight');

  @override
  Future<MutationResult> savePersonalization(
          String guestUuid, PersonalizationPreferences preferences,
          {String? stepUpSession}) =>
      _record('personalization');

  @override
  Future<MutationResult> saveLarderOrder(
          String guestUuid, List<LarderItem> items,
          {String? stepUpSession}) =>
      _record('larder');

  @override
  Future<MutationResult> saveYachtCharter(
          String guestUuid, YachtCharterConfig charter,
          {String? stepUpSession}) =>
      _record('yacht');

  @override
  Future<MutationResult> saveDiningReservation(
          String guestUuid, DiningReservation reservation,
          {String? stepUpSession}) =>
      _record('dining');

  @override
  Future<MutationResult> saveExperienceBooking(
          String guestUuid, ExperienceItem experience, String slot,
          {int partySize = 2, String? stepUpSession}) =>
      _record('experience');

  @override
  Future<MutationResult> submitConciergeRequest(
      String guestUuid, ConciergeRequest request,
      {String? stepUpSession}) {
    conciergeRequests.add(request);
    return _record('concierge');
  }

  @override
  Future<MutationResult> appendConciergeMessage(
          String guestUuid, String requestId, String text,
          {String? senderName, String? stepUpSession}) =>
      _record('message');

  @override
  Future<MutationResult> submitMidStayCheckIn(
          String guestUuid, MidStayCheckIn checkIn,
          {String? stepUpSession}) =>
      _record('midstay');

  @override
  Future<MutationResult> completeCheckout(String guestUuid,
      {required String stepUpToken}) {
    lastCheckoutToken = stepUpToken;
    return _record('checkout');
  }

  @override
  void dispose() {}
}
