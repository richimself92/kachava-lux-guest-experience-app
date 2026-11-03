import '../entities/concierge_folio_entities.dart';
import '../entities/experience_entities.dart';
import '../entities/stay_entities.dart';

import 'sanctuary_results.dart';

export 'sanctuary_results.dart';

/// Aggregate snapshot of the guest's residency state.
class SanctuarySnapshot {
  const SanctuarySnapshot({
    required this.stay,
    required this.transport,
    required this.preferences,
    required this.checklist,
    required this.larderItems,
    required this.experiences,
    required this.yachtPackages,
    required this.yachtCharter,
    required this.diningMenus,
    required this.diningReservation,
    required this.conciergeRequests,
    required this.chatMessages,
    required this.folioItems,
    this.latestMidStayCheckIn,
  });

  final StaySummary stay;
  final FlightTransport transport;
  final PersonalizationPreferences preferences;
  final List<ChecklistTask> checklist;
  final List<LarderItem> larderItems;
  final List<ExperienceItem> experiences;
  final List<YachtPackageOption> yachtPackages;
  final YachtCharterConfig yachtCharter;
  final List<DiningMenuOption> diningMenus;
  final DiningReservation diningReservation;
  final List<ConciergeRequest> conciergeRequests;
  final List<ChatMessage> chatMessages;
  final List<FolioLineItem> folioItems;
  final MidStayCheckIn? latestMidStayCheckIn;
}

/// Clean Architecture repository port for guest portal operations.
abstract interface class SanctuaryRepository {
  Future<SanctuaryFetchResult> fetchLiveSanctuary(String guestUuid);

  Future<MutationResult> syncFlightTransport(
    String guestUuid,
    FlightTransport transport, {
    String? stepUpSession,
  });

  Future<MutationResult> savePersonalization(
    String guestUuid,
    PersonalizationPreferences preferences, {
    String? stepUpSession,
  });

  Future<MutationResult> saveLarderOrder(
    String guestUuid,
    List<LarderItem> items, {
    String? stepUpSession,
  });

  Future<MutationResult> saveYachtCharter(
    String guestUuid,
    YachtCharterConfig charter, {
    String? stepUpSession,
  });

  Future<MutationResult> saveDiningReservation(
    String guestUuid,
    DiningReservation reservation, {
    String? stepUpSession,
  });

  Future<MutationResult> saveExperienceBooking(
    String guestUuid,
    ExperienceItem experience,
    String slot, {
    int partySize = 2,
    String? stepUpSession,
  });

  Future<MutationResult> submitConciergeRequest(
    String guestUuid,
    ConciergeRequest request, {
    String? stepUpSession,
  });

  /// Sends the guest's answer (villa number or last name) to the server.
  /// Returns the server-issued step-up token, or `null` when not verified.
  Future<String?> verifyStepUpChallenge(String guestUuid, String answer);

  Future<MutationResult> appendConciergeMessage(
    String guestUuid,
    String requestId,
    String text, {
    String? senderName,
    String? stepUpSession,
  });

  Future<MutationResult> submitMidStayCheckIn(
    String guestUuid,
    MidStayCheckIn checkIn, {
    String? stepUpSession,
  });

  Future<MutationResult> completeCheckout(
    String guestUuid, {
    required String stepUpToken,
  });

  void dispose();
}
