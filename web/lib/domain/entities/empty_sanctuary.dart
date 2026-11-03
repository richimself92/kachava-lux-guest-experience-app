import '../repositories/sanctuary_repository.dart';
import 'experience_entities.dart';
import 'stay_entities.dart';

/// Blank guest state: what the portal holds before (or without) server data.
///
/// Every guest-specific field is empty; nothing here describes a real or
/// fictitious guest.
abstract final class EmptySanctuary {
  /// Neutral comfort default until the guest chooses a temperature.
  static const int defaultAmbientTempCelsius = 23;

  static StaySummary stay(String guestUuid) => StaySummary(
        guestUuid: guestUuid,
        guestNames: '',
        primaryGuestName: '',
        partnerName: '',
        lastName: '',
        villaNumber: '',
        villaTitle: '',
        suiteName: '',
        celebrationTitle: '',
        stayDates: '',
        nights: 0,
        guestsCount: 0,
        villaClimateCelsius: 0,
        weatherSummary: '',
        privateHostName: '',
        privateHostRole: '',
        wifiSsid: '',
        wifiPassphrase: '',
        folioCardLabel: '',
        selectedSignaturePrivilege: '',
        isDigitalKeyEnabled: false,
        lifecycleStatus: StayLifecycleStatus.activeStay,
      );

  static const FlightTransport transport = FlightTransport(
    arrivalAirport: '',
    airline: '',
    flightNumber: '',
    estimatedLanding: '',
    terminalBay: '',
    partySize: 0,
    luggageChecked: 0,
    luggageCarryOn: 0,
    status: '',
    assignedDriver: '',
    vehicleModel: '',
  );

  static const PersonalizationPreferences preferences =
      PersonalizationPreferences(
    tripPurpose: '',
    occasionNote: '',
    interests: [],
    pillowType: '',
    ambientTempCelsius: defaultAmbientTempCelsius,
    scentProfile: '',
    circadianLighting: '',
    dietaryRegimen: '',
    allergyAlerts: '',
    communicationChannel: '',
  );

  static const YachtCharterConfig yachtCharter = YachtCharterConfig(
    vesselModel: '',
    selectedPackageId: '',
    selectedDestinationId: '',
    selectedDate: '',
    departureWindow: '',
    guestCount: 1,
    selectedAddOns: [],
    isConfirmed: false,
  );

  static const DiningReservation diningReservation = DiningReservation(
    selectedMenuId: '',
    selectedEvening: '',
    serviceTime: '',
    guestCount: 1,
    tableSetting: '',
    dietaryNotes: '',
    isConfirmed: false,
  );

  static SanctuarySnapshot snapshot(String guestUuid) => SanctuarySnapshot(
        stay: stay(guestUuid),
        transport: transport,
        preferences: preferences,
        checklist: const [],
        larderItems: const [],
        experiences: const [],
        yachtPackages: const [],
        yachtCharter: yachtCharter,
        diningMenus: const [],
        diningReservation: diningReservation,
        conciergeRequests: const [],
        chatMessages: const [],
        folioItems: const [],
      );
}
