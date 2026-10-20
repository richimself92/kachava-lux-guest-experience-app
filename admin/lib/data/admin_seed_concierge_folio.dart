import '../domain/admin_entities.dart';
import '../domain/admin_enums.dart';
import '../domain/admin_stay_entities.dart';

/// Seeded concierge tickets, mid-stay pulses, and folio line items with mutation helpers.
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

  static AdminConciergeTicket applyStageUpdate({
    required List<AdminConciergeTicket> tickets,
    required String requestId,
    required ConciergeStage stage,
    required StaffMember? staff,
    required String nowIso,
  }) {
    final index = tickets.indexWhere((t) => t.requestId == requestId);
    final updated = tickets[index].copyWith(
      stage: stage,
      assignedStaffId: staff?.staffId,
      assignedStaffName: staff?.shortName,
      department: staff?.department,
      notifiedAt: nowIso,
    );
    tickets[index] = updated;
    return updated;
  }

  static AdminConciergeTicket applyReply({
    required List<AdminConciergeTicket> tickets,
    required String requestId,
    required String senderName,
    required String senderRole,
    required String messageText,
  }) {
    final index = tickets.indexWhere((t) => t.requestId == requestId);
    final current = tickets[index];
    final newMsg = ConciergeChatMessage(
      messageId: 'msg_${current.messages.length + 1}',
      senderName: senderName,
      senderRole: senderRole,
      body: messageText,
      timestampLabel: 'Just now',
      isStaff: true,
    );
    final updated = current.copyWith(messages: [...current.messages, newMsg]);
    tickets[index] = updated;
    return updated;
  }

  static AdminMidStayPulse applyPulseUpdate({
    required List<AdminMidStayPulse> pulses,
    required String checkInId,
    required String followUpNote,
    required String staffName,
  }) {
    final index = pulses.indexWhere((p) => p.checkInId == checkInId);
    final updated = pulses[index].copyWith(
      status: 'ATTENDED',
      followUpNote: followUpNote,
      handledByStaffName: staffName,
    );
    pulses[index] = updated;
    return updated;
  }

  static List<FolioLineItem> applyAddedFolioItem({
    required List<FolioLineItem> items,
    required String title,
    required String categoryLabel,
    required double amountUsd,
  }) {
    items.add(
      FolioLineItem(
        itemId: 'fol_custom_${items.length + 1}',
        title: title,
        categoryLabel: categoryLabel,
        amountUsd: amountUsd,
        isIncludedPrivilege: amountUsd == 0,
      ),
    );
    return List.unmodifiable(items);
  }

  static List<AdminExperienceCatalogItem> buildExperienceCatalog() => const [
        AdminExperienceCatalogItem(
            id: 'exp_cenote',
            title: 'Cenote Dos Ojos Private Cavern Dive',
            category: 'Excursions',
            duration: '4 Hours',
            location: 'Tulum Biosphere',
            priceText: '\$380 USD',
            basePriceUSD: 380,
            description: 'Private cavern dive with underwater historian.'),
        AdminExperienceCatalogItem(
            id: 'exp_yacht',
            title: 'Galeon 470 Sky Coastal Charter',
            category: 'Yacht Charters',
            duration: '4–8 Hours',
            location: 'Private Marina',
            priceText: 'Included / +\$1,400 Full-Day',
            basePriceUSD: 0,
            isIncluded: true,
            description:
                'Private luxury yacht charter along the Riviera Maya.'),
        AdminExperienceCatalogItem(
            id: 'exp_copal',
            title: 'Holistic Mayan Copal Massage & Sound Ritual',
            category: 'Included Privileges',
            duration: '60 Mins',
            location: 'In-Villa Sanctuary',
            priceText: 'Included',
            basePriceUSD: 0,
            isIncluded: true,
            description:
                'Sacred copal smoke cleansing and quartz sound bowls.'),
      ];

  static List<AdminLarderCatalogItem> buildLarderCatalog() => const [
        AdminLarderCatalogItem(
            id: 'lrd_fruit',
            name: 'Endemic Tropical Fruit Harvest',
            origin: 'Yucatán Orchard',
            price: 38,
            category: 'Fresh Produce',
            storageType: 'CHILLED IN LARDER',
            description: 'Mamey, dragonfruit & mango.'),
        AdminLarderCatalogItem(
            id: 'lrd_elixirs',
            name: 'Chilled Cold-Pressed Elixirs (Set of 4)',
            origin: 'Sanctuary Apothecary',
            price: 45,
            category: 'Wellness Beverages',
            storageType: 'SUB-ZERO CHILLED',
            description: 'Turmeric, spirulina & citrus.'),
        AdminLarderCatalogItem(
            id: 'lrd_mezcal',
            name: 'Artisanal Mezcal Tobalá & Sea Salt Curation',
            origin: 'Oaxaca Sierra',
            price: 185,
            category: 'Artisanal Spirits',
            storageType: 'DRY BAR PRESENTATION',
            description: 'Small-batch wild agave mezcal.'),
      ];
}
