import '../entities/concierge_folio_entities.dart';
import '../entities/experience_entities.dart';
import '../entities/stay_entities.dart';

/// Aggregate snapshot of the guest's residency state in Villa 102.
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
  Future<SanctuarySnapshot> loadSanctuary(String guestUuid);

  Future<SanctuarySnapshot?> fetchLiveSanctuary(String guestUuid);

  Future<void> syncFlightTransport(
    String guestUuid,
    FlightTransport transport, {
    String? stepUpSession,
  });

  Future<void> savePersonalization(
    String guestUuid,
    PersonalizationPreferences preferences, {
    String? stepUpSession,
  });

  Future<void> saveLarderOrder(
    String guestUuid,
    List<LarderItem> items, {
    String? stepUpSession,
  });

  Future<void> saveYachtCharter(
    String guestUuid,
    YachtCharterConfig charter, {
    String? stepUpSession,
  });

  Future<void> saveDiningReservation(
    String guestUuid,
    DiningReservation reservation, {
    String? stepUpSession,
  });

  Future<void> saveExperienceBooking(
    String guestUuid,
    ExperienceItem experience,
    String slot, {
    int partySize = 2,
    String? stepUpSession,
  });

  Future<void> submitConciergeRequest(
    String guestUuid,
    ConciergeRequest request, {
    String? stepUpSession,
  });

  Future<String?> verifyStepUpChallenge(
    String guestUuid, {
    String? villaNumber,
    String? lastName,
  });

  Future<void> appendConciergeMessage(
    String guestUuid,
    String requestId,
    String text, {
    String? senderName,
    String? stepUpSession,
  });

  Future<void> submitMidStayCheckIn(
    String guestUuid,
    MidStayCheckIn checkIn, {
    String? stepUpSession,
  });

  Future<void> completeCheckout(
    String guestUuid, {
    required String stepUpToken,
  });

  void dispose();
}
