import 'package:kachava_admin_dashboard/domain/admin_entities.dart';
import 'package:kachava_admin_dashboard/domain/admin_enums.dart';

/// Test-only seeded concierge tickets, mid-stay pulses, folio items and
/// catalogs. Never reachable from `lib/main.dart`.
class AdminSeedConciergeFolio {
  const AdminSeedConciergeFolio._();

  static List<AdminConciergeTicket> buildConciergeTickets() => const [
        AdminConciergeTicket(
          requestId: 'req_102_hvac',
          stayId: 'stay_villa_102',
          villaName: 'Villa 102 — Ceiba Suite',
          guestNames: 'Alex & Sarah Miller',
          category: 'Air conditioning',
          department: StaffDepartment.engineering,
          priority: 'URGENT',
          title: 'Air conditioning — Ceiba Suite',
          details:
              'Master bedroom thermostat reads 73°F; please calibrate night curve to 66°F before turndown.',
          stage: ConciergeStage.requested,
          assignedStaffId: 'staff_mateo_eng',
          assignedStaffName: 'HOST ADMIN',
          photoStoragePath:
              '/private/stays/stay_villa_102/concierge/req_102_hvac/thermostat.jpg',
          signedPhotoGetUrl:
              'https://storage.googleapis.com/kachava-lux-prod/private/stays/stay_villa_102/concierge/req_102_hvac/thermostat.jpg?X-Goog-Algorithm=GOOG4-RSA-SHA256&X-Goog-Expires=900',
          messages: [
            ConciergeChatMessage(
              messageId: 'msg_01',
              senderName: 'Sarah Miller',
              senderRole: 'Guest · Villa 102',
              body:
                  'Hi Host, the bedroom feels slightly warm after sunset. Attached a photo of the wall dial.',
              timestampLabel: '6:42 PM',
              isStaff: false,
            ),
          ],
        ),
        AdminConciergeTicket(
          requestId: 'req_102_turndown',
          stayId: 'stay_villa_102',
          villaName: 'Villa 102 — Ceiba Suite',
          guestNames: 'Alex & Sarah Miller',
          category: 'Housekeeping',
          department: StaffDepartment.housekeeping,
          priority: 'NORMAL',
          title: 'Extra Sacred Copal & Plush Goose Down Pillow',
          details:
              'Requesting 2 additional Plush Goose Down pillows and evening Copal resin burner lit at 7:15 PM.',
          stage: ConciergeStage.inProgress,
          assignedStaffId: 'staff_sofia',
          assignedStaffName: 'HOST ADMIN',
          messages: [
            ConciergeChatMessage(
              messageId: 'msg_02',
              senderName: 'HOST ADMIN',
              senderRole: 'HOST ADMIN',
              body:
                  'Villa Butlery is preparing your Goose Down pillows and Sacred Copal censer now.',
              timestampLabel: '6:15 PM',
              isStaff: true,
            ),
          ],
        ),
      ];

  static List<AdminMidStayPulse> buildMidStayPulses() => const [
        AdminMidStayPulse(
          checkInId: 'pulse_102_01',
          stayId: 'stay_villa_102',
          villaName: 'Villa 102 — Ceiba Suite',
          guestNames: 'Alex & Sarah Miller',
          sentiment: 'A Detail Could Be Tuned',
          focusChips: ['Pool Terrace Plunge Heat', 'Twilight Copal Timing'],
          guestNote:
              'Warm plunge pool by 2 degrees for evening swim (target 86°F) and light copal 30 mins prior to dinner.',
          slaLabel: '< 7 Min SLA · 04:12 remaining',
          isUnderSla: true,
          status: 'OPEN',
          followUpNote:
              'Thermal engineer dispatched to raise plunge heat to 86°F.',
          handledByStaffName: 'HOST ADMIN',
        ),
      ];

  static List<FolioLineItem> buildFolioItems() => const [
        FolioLineItem(
          itemId: 'fol_inc_1',
          title: 'Mayan Heritage Degustation Table (Fuego y Mar)',
          categoryLabel: 'INCLUDED SANCTUARY PRIVILEGE',
          amountUsd: 0.0,
          isIncludedPrivilege: true,
        ),
        FolioLineItem(
          itemId: 'fol_inc_2',
          title: 'Galeon 470 Sky · 4-Hour Coastal Charter Entitlement',
          categoryLabel: 'INCLUDED SANCTUARY PRIVILEGE',
          amountUsd: 0.0,
          isIncludedPrivilege: true,
        ),
        FolioLineItem(
          itemId: 'fol_inc_3',
          title: 'Daily Organic Artisanal Breakfast & Chilled Coconuts',
          categoryLabel: 'INCLUDED SANCTUARY PRIVILEGE',
          amountUsd: 0.0,
          isIncludedPrivilege: true,
        ),
        FolioLineItem(
          itemId: 'fol_bill_1',
          title: 'Cenote Dos Ojos Private Cavern Dive (2 Guests)',
          categoryLabel: 'CURATED EXCURSION',
          amountUsd: 760.0,
          isIncludedPrivilege: false,
        ),
        FolioLineItem(
          itemId: 'fol_bill_2',
          title: 'Stock My Villa — Curated Larder & Cold-Pressed Elixirs',
          categoryLabel: 'VILLA LARDER PROVISIONING',
          amountUsd: 128.0,
          isIncludedPrivilege: false,
        ),
        FolioLineItem(
          itemId: 'fol_bill_3',
          title: 'Organic Sun & Ocean Botanical Recovery Kit',
          categoryLabel: 'APOTHECARY & WELLNESS',
          amountUsd: 65.0,
          isIncludedPrivilege: false,
        ),
        FolioLineItem(
          itemId: 'fol_bill_4',
          title: 'Sian Ka\'an & Reef Biosphere Conservation Levy',
          categoryLabel: 'SANCTUARY STEWARDSHIP',
          amountUsd: 32.0,
          isIncludedPrivilege: false,
        ),
      ];
}
