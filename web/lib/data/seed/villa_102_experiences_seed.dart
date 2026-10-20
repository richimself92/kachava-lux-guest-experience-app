import '../../domain/entities/experience_entities.dart';

/// Seeded experiences, yacht packages, and chef tasting menus for Villa 102.
abstract final class Villa102ExperiencesSeed {
  static List<ExperienceItem> buildExperiences() {
    return const [
      ExperienceItem(
        id: 'exp-1',
        title: 'Kachava Caribe · Galeon 470 Sky Yacht Experience',
        subtitle: 'Cancún & Isla Mujeres Turquoise Waters · 47ft Galeon Sky',
        duration: '4 Hours',
        location: 'Bahía de Mujeres & Playa Norte',
        priceText: 'INCLUDED',
        priceUsd: 0,
        isIncluded: true,
        category: 'Yacht',
        description: 'Private cruise with 19ft Beach Mode balconies & ceviche.',
        amenities: ['Beach Mode Balconies', 'Chef Ceviche', 'Master Captain'],
        isScheduled: true,
        scheduledSlot: 'Fri Nov 14 · 09:30 AM',
        targetScreenWireId: 'yacht',
      ),
      ExperienceItem(
        id: 'exp-2',
        title: 'Cenote Dos Ojos Private Dive & Ritual',
        subtitle: 'Sacred Cavern · Max 4 Guests',
        duration: '3.5 Hours',
        location: 'Sacred Cavern',
        priceText: 'FROM \$380',
        priceUsd: 380,
        isIncluded: false,
        category: 'Adventure',
        description: 'Private dawn access with Mayan copal blessing & dive.',
        amenities: ['Private Escalade Transfer', 'Cave Master', 'Photography'],
        isScheduled: false,
      ),
      ExperienceItem(
        id: 'exp-3',
        title: 'Sunrise Cenote Yoga & Mayan Hydrotherapy Circuit',
        subtitle: 'Secluded Villa 102 Terrace · Signature Ritual',
        duration: '90 Min',
        location: 'Villa 102 Terrace & Cenote Deck',
        priceText: 'INCLUDED',
        priceUsd: 0,
        isIncluded: true,
        category: 'Wellness',
        description: 'Warmed Puebla obsidian stones, copal balm & sound bowls.',
        amenities: ['Botanical Copal Balms', 'Obsidian Stones', 'Sound Bowls'],
        isScheduled: false,
      ),
      ExperienceItem(
        id: 'exp-4',
        title: "Sian Ka'an Biosphere Expedition",
        subtitle: 'UNESCO Biosphere · Natural Current Float',
        duration: '5 Hours',
        location: 'Sian Ka\'an Reserve',
        priceText: 'FROM \$450',
        priceUsd: 450,
        isIncluded: false,
        category: 'Adventure',
        description: 'Drift ancient Mayan canals with a resident biologist.',
        amenities: ['Marine Biologist', 'Canal Float', 'Sunset Wine Tasting'],
        isScheduled: false,
      ),
      ExperienceItem(
        id: 'exp-5',
        title: 'El Camaleón & PGA Riviera Maya Championship Golf',
        subtitle: '18 Holes · Full Callaway Paradym Fit',
        duration: '18 Holes',
        location: 'Championship Course',
        priceText: 'INCLUDED',
        priceUsd: 0,
        isIncluded: true,
        category: 'Wellness',
        description: 'Priority sunrise tee times with GPS cart & club rental.',
        amenities: ['18 Holes', 'Callaway Paradym Clubs', 'GPS Buggy'],
        isScheduled: false,
      ),
      ExperienceItem(
        id: 'exp-6',
        title: 'Tulum & Coba Archaeological Dawn Tour',
        subtitle: 'Private Archaeologist · Dawn Access',
        duration: '3 Hours',
        location: 'Tulum Cliffside & Coba',
        priceText: 'FROM \$290',
        priceUsd: 290,
        isIncluded: false,
        category: 'Culture',
        description: 'Explore ancient Mayan temples prior to public opening.',
        amenities: ['Private Historian', 'Chilled Coconuts', 'SUV Transfer'],
        isScheduled: false,
      ),
    ];
  }

  static List<YachtPackageOption> buildYachtPackages() {
    return const [
      YachtPackageOption(
        id: 'half-day',
        title: 'Half-Day Guest Experience',
        tagline: 'The Day Explorer · 4 Hours',
        durationHours: 4,
        valuationUsd: 2000,
        netUpgradeUsd: 0,
        isIncludedWithStay: true,
        priceLabel: 'Included with 4N+ Stay · \$0 Due (\$2,000 USD Value)',
        description: '4-hour private cruise with champagne lunch & reef swim.',
        highlights: ['Marine Team', 'El Meco Reef Snorkel', 'Ceviche'],
        suggestedRoute: 'Cancun Lagoon & Bahía de Mujeres to Playa Norte',
      ),
      YachtPackageOption(
        id: 'extended',
        title: 'Extended Caribbean Experience',
        tagline: 'The Deep Voyage · 6 Hours',
        durationHours: 6,
        valuationUsd: 3000,
        netUpgradeUsd: 1000,
        isIncludedWithStay: false,
        priceLabel: '+\$1,000 USD Stay Upgrade (Valued at \$3,000 USD)',
        description: '6 hours exploring isolated sandbars & golden sunset.',
        highlights: [
          'Full Day-Cabin Access',
          'El Cielo Sandbar',
          'Sunset Toast'
        ],
        suggestedRoute: 'Puerto Aventuras to El Cielo Sandbar Sanctuary',
      ),
      YachtPackageOption(
        id: 'full-day',
        title: 'Private Full-Day Escape',
        tagline: 'The Yucatan Sanctuary · 8 Hours',
        durationHours: 8,
        valuationUsd: 4000,
        netUpgradeUsd: 2000,
        isIncludedWithStay: false,
        priceLabel: '+\$2,000 USD Stay Upgrade (Valued at \$4,000 USD)',
        description: '8-hour voyage to Isla Contoy or Cozumel Deep Wall.',
        highlights: [
          '8-Hour Freedom Itinerary',
          'Onboard Seafood Feast',
          'Seabob'
        ],
        suggestedRoute: 'Cancun to Isla Contoy Protected Biosphere',
      ),
    ];
  }

  static List<DiningMenuOption> buildDiningMenus() {
    return const [
      DiningMenuOption(
        id: 'fuego',
        title: 'Fuego y Mar Mayan Fire Tasting',
        subtitle: 'Recommended for Anniversary · 5-Course Coastal Fire',
        courses: [
          '1. Yellowtail Aguachile & Smoked Lime',
          '2. Wood-Fired Mayan Octopus & Recado Negro',
          '3. Coastal Omakase & Charred Avocado',
          '4. Grilled Catch of the Day with Saffron Emulsion',
          '5. Chiapas Dark Cacao & Melipona Honey Ganache',
        ],
        sommelierPairing: 'Sommelier Cellar Pairing · Valle de Guadalupe Wines',
      ),
      DiningMenuOption(
        id: 'tierra',
        title: 'Tierra Sagrada Heritage Menu',
        subtitle: 'Ancestral Underground Pib & Heirloom Masa',
        courses: [
          '1. Sikil Pak Pumpkin Seed Dip & Blue Tostadas',
          '2. Squash Blossom & Black Truffle Velouté',
          '3. Underground Pit-Roasted Heritage Entrée',
          '4. Charred Chayote & Wild Herb Salad',
          '5. Smoked Coconut & Corn Husk Custard',
        ],
        sommelierPairing: 'Ancestral Mezcal & Biodynamic Orange Wine Flight',
      ),
      DiningMenuOption(
        id: 'flora',
        title: 'Flora Silvestre Botanical Omakase',
        subtitle: '100% Plant-Forward Milpa & Cenote Harvest',
        courses: [
          '1. Smoked Coconut Ceviche & Finger Lime',
          '2. Charred Heirloom Carrot & Copal Oil',
          '3. Wild Mushroom Tamal in Banana Leaf',
          '4. Roasted Mamey Sapote & Cacao Nib Mole',
          '5. Passionfruit & Hibiscus Sorbet',
        ],
        sommelierPairing: 'Biodynamic Pet-Nat & Botanical Elixir Pairing',
      ),
    ];
  }
}
