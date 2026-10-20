import '../domain/admin_entities.dart';
import '../domain/admin_enums.dart';
import 'admin_seed_concierge_folio.dart';

/// Seeded operational alerts, bookings, larder orders, concierge tickets, and folio records.
class AdminSeedOperations {
  const AdminSeedOperations._();

  static List<OperationalAlert> buildAlerts() => const [
        OperationalAlert(
          alertId: 'alt_001',
          stayId: 'stay_villa_102',
          villaId: 'villa-102',
          villaName: 'Villa 102',
          guestNames: 'Alex & Sarah Miller',
          category: AlertCategory.concierge,
          severity: AlertSeverity.urgent,
          title: 'Villa 102 reported Air Conditioning issue (Photo attached)',
          summary:
              'Master suite chiller reading 73°F instead of 66°F night target. Guest uploaded V4 signed maintenance photo.',
          targetTab: AdminWorkspaceTab.adminConcierge,
          targetRecordId: 'req_102_hvac',
          assignedDepartment: StaffDepartment.engineering,
          createdAtLabel: '2 mins ago',
        ),
        OperationalAlert(
          alertId: 'alt_002',
          stayId: 'stay_villa_102',
          villaId: 'villa-102',
          villaName: 'Villa 102',
          guestNames: 'Alex & Sarah Miller',
          category: AlertCategory.dietary,
          severity: AlertSeverity.urgent,
          title: 'Allergy Caution: Shellfish · Chef & Yacht Crew Briefing',
          summary:
              'Severe shellfish allergy flagged for Fuego y Mar tasting menu and Galeon 470 Sky charter.',
          targetTab: AdminWorkspaceTab.adminExperiences,
          targetRecordId: 'bkg_102_yacht',
          assignedDepartment: StaffDepartment.culinary,
          createdAtLabel: '8 mins ago',
        ),
        OperationalAlert(
          alertId: 'alt_003',
          stayId: 'stay_villa_102',
          villaId: 'villa-102',
          villaName: 'Villa 102',
          guestNames: 'Alex & Sarah Miller',
          category: AlertCategory.midstay,
          severity: AlertSeverity.high,
          title:
              'Mid-Stay Pulse (< 7 Min SLA): Pool Terrace Plunge Heat · 86°F',
          summary:
              'Guest submitted "A Detail Could Be Tuned" requesting plunge pool warmed by 2°F for twilight swim.',
          targetTab: AdminWorkspaceTab.adminFolio,
          targetRecordId: 'pulse_102_01',
          assignedDepartment: StaffDepartment.engineering,
          createdAtLabel: '4 mins ago',
        ),
        OperationalAlert(
          alertId: 'alt_004',
          stayId: 'stay_villa_102',
          villaId: 'villa-102',
          villaName: 'Villa 102',
          guestNames: 'Alex & Sarah Miller',
          category: AlertCategory.larder,
          severity: AlertSeverity.normal,
          title: 'Villa 102 Curated Larder Provisioning (\$128.00 USD)',
          summary:
              '3 curated items across Chilled in Larder, Sub-Zero Chilled, and Dry Bar Presentation awaiting stocking.',
          targetTab: AdminWorkspaceTab.adminLarder,
          targetRecordId: 'larder_102',
          assignedDepartment: StaffDepartment.housekeeping,
          createdAtLabel: '19 mins ago',
        ),
        OperationalAlert(
          alertId: 'alt_005',
          stayId: 'stay_villa_102',
          villaId: 'villa-102',
          villaName: 'Villa 102',
          guestNames: 'Alex & Sarah Miller',
          category: AlertCategory.transfer,
          severity: AlertSeverity.high,
          title: 'Flight AA 1492 Arrival Dispatch · Terminal 3',
          summary:
              'Mercedes-Benz EQS SUV #04 staged at 71°F with chilled young coconuts for HOST ADMIN.',
          targetTab: AdminWorkspaceTab.adminStays,
          targetRecordId: 'stay_villa_102',
          assignedDepartment: StaffDepartment.transport,
          createdAtLabel: '25 mins ago',
        ),
      ];

  static List<AdminBookingRecord> buildBookings() => const [
        AdminBookingRecord(
          bookingId: 'bkg_102_yacht',
          stayId: 'stay_villa_102',
          villaName: 'Villa 102 — Ceiba Suite',
          guestNames: 'Alex & Sarah Miller',
          category: 'Yacht Charters',
          title: 'Galeon 470 Sky · 8-Hr Full-Day Sian Ka\'an & Sunset Return',
          subtitle: 'Afternoon & Sunset Window · Private Marina Slip #02',
          scheduledTime: 'Nov 14 · 1:00 PM – 9:00 PM',
          addOns: [
            'Private Onboard Chef (+\$380)',
            'Dom Pérignon Vintage (+\$490)',
            'Seabob F5S (+\$320)',
          ],
          allergyWarning: 'Shellfish Allergy · Zero Crustacean Cross-Contact',
          priceUsd: 2230.0,
          status: 'Requested',
          assignedStaffId: 'staff_velasco',
          assignedStaffName: 'HOST ADMIN',
          assignedDepartment: StaffDepartment.marine,
        ),
        AdminBookingRecord(
          bookingId: 'bkg_102_dining',
          stayId: 'stay_villa_102',
          villaName: 'Villa 102 — Ceiba Suite',
          guestNames: 'Alex & Sarah Miller',
          category: 'Private Dining',
          title: 'Fuego y Mar · Mayan Heritage Degustation Table',
          subtitle: 'In-Villa Ceiba Terrace · 2 Guests · Candlelight Setup',
          scheduledTime: 'Nov 13 · 7:30 PM',
          addOns: ['Ancestral Agave & Mezcal Flight (+\$145/guest)'],
          allergyWarning: 'Shellfish Allergy · Culinary Team Briefed',
          priceUsd: 290.0,
          status: 'Requested',
          assignedStaffId: 'staff_mateo',
          assignedStaffName: 'HOST ADMIN',
          assignedDepartment: StaffDepartment.culinary,
        ),
        AdminBookingRecord(
          bookingId: 'bkg_102_excursion',
          stayId: 'stay_villa_102',
          villaName: 'Villa 102 — Ceiba Suite',
          guestNames: 'Alex & Sarah Miller',
          category: 'Excursions',
          title: 'Cenote Dos Ojos Private Cavern Dive & Historian',
          subtitle: 'Private EQS SUV Transfer · Dive Master & Underwater Photo',
          scheduledTime: 'Nov 15 · 9:00 AM',
          addOns: ['Subsurface Thermal Wetsuits', 'Raw Cacao Picnic'],
          allergyWarning: null,
          priceUsd: 760.0,
          status: 'Confirmed',
          assignedStaffId: 'staff_eduardo',
          assignedStaffName: 'HOST ADMIN',
          assignedDepartment: StaffDepartment.concierge,
          notifiedAt: '2026-11-12T15:30:00Z',
        ),
        AdminBookingRecord(
          bookingId: 'bkg_102_privilege',
          stayId: 'stay_villa_102',
          villaName: 'Villa 102 — Ceiba Suite',
          guestNames: 'Alex & Sarah Miller',
          category: 'Included Privileges',
          title: '60-Min Holistic Mayan Copal Massage & Sound Harmonization',
          subtitle: 'Included Sanctuary Privilege (\$0.00 USD)',
          scheduledTime: 'Nov 13 · 4:30 PM',
          addOns: ['Sacred Copal Smoke Cleansing', '432Hz Quartz Bowls'],
          allergyWarning: null,
          priceUsd: 0.0,
          status: 'Confirmed',
          assignedStaffId: 'staff_spa',
          assignedStaffName: 'HOST ADMIN',
          assignedDepartment: StaffDepartment.wellness,
          notifiedAt: '2026-11-12T14:00:00Z',
        ),
      ];

  static List<AdminLarderOrder> buildLarderOrders() => const [
        AdminLarderOrder(
          orderId: 'larder_102',
          stayId: 'stay_villa_102',
          villaName: 'Villa 102 — Ceiba Suite',
          guestNames: 'Alex & Sarah Miller',
          targetDeadline: 'Pre-Arrival · Nov 12 by 2:00 PM',
          totalUsd: 128.0,
          status: 'Pending',
          assignedStaffId: 'staff_sofia',
          assignedStaffName: 'HOST ADMIN',
          items: [
            LarderOrderItem(
              itemId: 'larder-1',
              name: '1x Endemic Tropical Fruit Harvest',
              quantity: 1,
              priceUsd: 38.0,
              placementZone: 'CHILLED IN LARDER',
            ),
            LarderOrderItem(
              itemId: 'larder-2',
              name: '2x Chilled Cold-Pressed Elixirs (Set of 4)',
              quantity: 2,
              priceUsd: 90.0,
              placementZone: 'SUB-ZERO CHILLED',
            ),
            LarderOrderItem(
              itemId: 'larder-3',
              name: '1x Artisanal Mezcal Tobalá & Sea Salt Curation',
              quantity: 1,
              priceUsd: 0.0,
              placementZone: 'DRY BAR PRESENTATION',
            ),
          ],
          complimentaryStaples: [
            '2x Chilled Fresh Cracked Young Coconuts',
            'Still & Sparkling Limestone Mineral Water',
            'Oaxacan Single-Origin Espresso Pods',
            'Raw Melipona Bee Honey & Sea Salt',
          ],
        ),
      ];

  static List<AdminConciergeTicket> buildConciergeTickets() =>
      AdminSeedConciergeFolio.buildConciergeTickets();

  static List<AdminMidStayPulse> buildMidStayPulses() =>
      AdminSeedConciergeFolio.buildMidStayPulses();

  static List<FolioLineItem> buildFolioItems() =>
      AdminSeedConciergeFolio.buildFolioItems();
}
