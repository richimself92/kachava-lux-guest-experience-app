import 'package:kachava_guest_portal/domain/entities/concierge_folio_entities.dart';
import 'package:kachava_guest_portal/domain/entities/experience_entities.dart';
import 'package:kachava_guest_portal/domain/entities/stay_entities.dart';
import 'package:kachava_guest_portal/domain/repositories/sanctuary_repository.dart';

import 'villa_102_experiences_seed.dart';
import 'villa_102_larder_seed.dart';

/// Test-only fixture: the fictitious Villa 102 stay (`Alex & Sarah Miller`).
abstract final class Villa102SeedData {
  static SanctuarySnapshot buildDefaultSnapshot(String guestUuid) {
    return SanctuarySnapshot(
      stay: StaySummary(
        guestUuid: guestUuid,
        guestNames: 'Alex & Sarah Miller',
        primaryGuestName: 'Sarah Miller',
        partnerName: 'Alex / Mark',
        lastName: 'Miller',
        villaNumber: '102',
        villaTitle: 'VILLA 102 — CEIBA SUITE',
        suiteName: 'Ceiba Suite · 3,400 sq ft',
        celebrationTitle: 'Anniversary Sanctuary · 4th Wedding Anniversary',
        stayDates: 'November 12–16, 2026',
        nights: 4,
        guestsCount: 2,
        villaClimateCelsius: 23,
        weatherSummary: '28°C · Riviera Maya Coastal Breeze',
        privateHostName: 'HOST ADMIN',
        privateHostRole: '24/7 Concierge & Villa Host · On-Grounds',
        wifiSsid: 'Kachava_Sanctuary_102',
        wifiPassphrase: 'Stillness432Hz',
        folioCardLabel: 'Visa ending in 8412',
        selectedSignaturePrivilege: 'massage',
        isDigitalKeyEnabled: true,
        lifecycleStatus: StayLifecycleStatus.activeStay,
      ),
      transport: const FlightTransport(
        arrivalAirport: 'Cancun International (CUN) · Terminal 3',
        airline: 'American Airlines',
        flightNumber: 'AA 1492 / AA 172',
        estimatedLanding: 'Nov 12, 2026 · 11:35 AM CST',
        terminalBay: 'Private FBO & Terminal 3 Valet Bay 4',
        partySize: 2,
        luggageChecked: 3,
        luggageCarryOn: 2,
        status: 'Confirmed',
        assignedDriver: 'HOST ADMIN',
        vehicleModel: 'Cadillac Escalade ESV / Mercedes-Benz EQS SUV',
      ),
      preferences: const PersonalizationPreferences(
        tripPurpose: 'Anniversary',
        occasionNote: '4th Wedding Anniversary Sanctuary',
        interests: ['Wellness & Spa', 'Private Yacht', 'Gastronomy', 'Cenotes'],
        pillowType: 'Goose Down',
        ambientTempCelsius: 23,
        scentProfile: 'Tierra Sagrada · Copal & Amber',
        circadianLighting: 'Warm Sunset Curve (2200K)',
        dietaryRegimen: 'Pescatarian & Gluten-Sensitive',
        allergyAlerts: 'Shellfish (Mild) — Chef Alerted',
        communicationChannel: 'WhatsApp',
      ),
      checklist: _buildChecklist(),
      larderItems: Villa102LarderSeed.buildLarderItems(),
      experiences: Villa102ExperiencesSeed.buildExperiences(),
      yachtPackages: Villa102ExperiencesSeed.buildYachtPackages(),
      yachtCharter: const YachtCharterConfig(
        vesselModel: 'Galeon 470 Sky / 500 FLY',
        selectedPackageId: 'half-day',
        selectedDestinationId: 'isla-mujeres',
        selectedDate: '',
        departureWindow: 'Morning Sail · 09:30 AM – 1:30 PM',
        guestCount: 2,
        selectedAddOns: ['Chef Ceviche & Open Bar'],
        isConfirmed: false,
        bookingStatus: '',
        cancellationReason: '',
      ),
      diningMenus: Villa102ExperiencesSeed.buildDiningMenus(),
      diningReservation: const DiningReservation(
        selectedMenuId: 'fuego',
        selectedEvening: '',
        serviceTime: 'Degustation 8:00 PM',
        guestCount: 2,
        tableSetting: 'Villa 102 Oceanfront Pool Terrace',
        dietaryNotes: '',
        isConfirmed: false,
        bookingStatus: '',
        cancellationReason: '',
      ),
      conciergeRequests: _buildConciergeRequests(),
      chatMessages: const [
        ChatMessage(
          id: 'msg-1',
          senderName: 'HOST ADMIN (Concierge)',
          isFromHost: true,
          text:
              'Welcome to Villa 102, Alex & Sarah. Ceiba Suite is chilled to 23°C.',
          timestampLabel: '1:45 PM',
        ),
      ],
      folioItems: _buildFolioItems(),
    );
  }

  static List<ChecklistTask> _buildChecklist() => const [
        ChecklistTask(
            id: 'chk-1',
            title: 'Complete preferences',
            subtitle: 'Room comfort, temperature & dietary alerts',
            targetScreenId: 'personalize',
            isCompleted: false),
        ChecklistTask(
            id: 'chk-2',
            title: 'Choose Spa or Golf',
            subtitle: 'Complimentary residency entitlement',
            targetScreenId: 'included',
            isCompleted: false),
        ChecklistTask(
            id: 'chk-3',
            title: 'Schedule Private Yacht',
            subtitle: 'Kachava Caribe · Galeon 470 Sky cruise',
            targetScreenId: 'yacht',
            isCompleted: false),
        ChecklistTask(
            id: 'chk-4',
            title: 'Reservation confirmed',
            subtitle: 'Villa 102 — Ceiba Suite locked',
            targetScreenId: 'home',
            isCompleted: true),
        ChecklistTask(
            id: 'chk-5',
            title: 'Airport transportation confirmed',
            subtitle: 'Chauffeur HOST ADMIN · AA 1492 / AA 172',
            targetScreenId: 'transport',
            isCompleted: true),
        ChecklistTask(
            id: 'chk-6',
            title: 'Guest profile started',
            subtitle: 'Alex & Sarah Miller · Anniversary',
            targetScreenId: 'profile',
            isCompleted: true),
      ];

  static List<ConciergeRequest> _buildConciergeRequests() => const [
        ConciergeRequest(
          id: 'req-towels',
          title: 'Extra Organic Pool & Bath Towels',
          category: 'Housekeeping',
          timestampLabel: 'Requested today · 2:04 PM',
          stage: ConciergeStage.inProgress,
          assignedTo: 'HOST ADMIN',
          details: 'Fresh bath & pool towels for Villa 102 master deck.',
        ),
        ConciergeRequest(
          id: 'req-transfer',
          title: 'Private Airport Transportation Sync',
          category: 'Transportation',
          timestampLabel: 'Requested yesterday · 4:15 PM',
          stage: ConciergeStage.completed,
          assignedTo: 'HOST ADMIN',
          details: 'Confirmed AA 1492 / AA 172 arrival with HOST ADMIN.',
        ),
      ];

  static List<FolioLineItem> _buildFolioItems() => const [
        FolioLineItem(
          id: 'fol-inc-1',
          title: 'In-Villa Degustation by Culinary Team',
          subtitle: 'Included Sanctuary Privilege · 5-Course Fuego y Mar',
          amountUsd: 0,
          isIncludedPrivilege: true,
          retailValuationUsd: 420,
        ),
        FolioLineItem(
          id: 'fol-inc-2',
          title: 'Kachava Caribe · Galeon 470 Sky Half-Day Cruise',
          subtitle: 'Included Sanctuary Privilege · 4 Hours Private',
          amountUsd: 0,
          isIncludedPrivilege: true,
          retailValuationUsd: 2000,
        ),
        FolioLineItem(
          id: 'fol-inc-3',
          title: 'Sunrise Cenote Yoga & Daily Artisanal Breakfast',
          subtitle: 'Included Sanctuary Privilege · Served 07:00–11:30 AM',
          amountUsd: 0,
          isIncludedPrivilege: true,
          retailValuationUsd: 360,
        ),
        FolioLineItem(
          id: 'fol-paid-1',
          title: 'Subterranean Cenote Dos Ojos Private Dive (2 Guests)',
          subtitle: 'Curated Excursion · Cave Master & Escalade Transfer',
          amountUsd: 760,
          isIncludedPrivilege: false,
        ),
        FolioLineItem(
          id: 'fol-paid-2',
          title: 'Stock My Villa Curated Larder',
          subtitle: 'Endemic Fruit Harvest & 2x Cold-Pressed Elixirs',
          amountUsd: 128,
          isIncludedPrivilege: false,
        ),
        FolioLineItem(
          id: 'fol-paid-3',
          title: 'Organic Sun & Ocean Recovery Kit',
          subtitle: 'Kachava Apothecary Lab · Reef-Safe SPF 50 & Aloe Mist',
          amountUsd: 65,
          isIncludedPrivilege: false,
        ),
        FolioLineItem(
          id: 'fol-paid-4',
          title: 'Sanctuary Ecological Biosphere Levy',
          subtitle: '1% Sian Ka\'an Forest & Melipona Bee Preservation',
          amountUsd: 32,
          isIncludedPrivilege: false,
        ),
      ];
}
