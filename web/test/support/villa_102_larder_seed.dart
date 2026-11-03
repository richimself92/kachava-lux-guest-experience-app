import 'package:kachava_guest_portal/domain/entities/experience_entities.dart';

/// Test-only fixture: larder catalog of the fictitious Villa 102 stay.
abstract final class Villa102LarderSeed {
  static List<LarderItem> buildLarderItems() => const [
        LarderItem(
          id: 'larder-1',
          name: 'Endemic Tropical Fruit Harvest',
          origin: 'Finca Santa Maria, Mayan Riviera',
          description: 'Dragonfruit, golden passionfruit, wild papaya & mamey.',
          priceUsd: 38,
          category: 'Fresh Fruit & Botanicals',
          quantity: 0,
          tag: 'HARVESTED EACH MORNING',
          storageType: 'CHILLED IN LARDER',
          dietaryBadge: 'PESCATARIAN / GF',
        ),
        LarderItem(
          id: 'larder-2',
          name: 'Chilled Cold-Pressed Elixirs (Set of 4)',
          origin: 'Cold-pressed 6:00 AM daily by In-House Alchemist',
          description:
              'Green jungle detox, golden turmeric, hibiscus & coconut.',
          priceUsd: 45,
          category: 'Chilled Elixirs',
          quantity: 0,
          tag: 'REQUESTED IN ONBOARDING',
          storageType: 'SUB-ZERO CHILLED',
          dietaryBadge: 'VEGAN & RAW',
        ),
        LarderItem(
          id: 'larder-3',
          name: 'Casa Dragones Joven & Smoked Salt Kit',
          origin: 'Tequila, Jalisco · 100% Blue Agave',
          description:
              'Small-batch sipping tequila, copal salt & stone copitas.',
          priceUsd: 285,
          category: 'Cellar Selection',
          quantity: 0,
          tag: 'CELLAR SELECTION',
          storageType: 'DRY BAR PRESENTATION',
        ),
        LarderItem(
          id: 'larder-4',
          name: 'GF Sourdough & Melipona Honeycomb',
          origin: 'Panadería Maya & Sacred Bee Sanctuary',
          description: 'Ancient grain loaf with raw stingless Melipona honey.',
          priceUsd: 28,
          category: 'GF Bakery',
          quantity: 0,
          tag: 'GLUTEN-FREE',
          storageType: 'LARDER BREAD BOX',
        ),
        LarderItem(
          id: 'larder-5',
          name: 'Oaxacan Quesillo & Guacamole Board',
          origin: 'Prepared fresh on request',
          description:
              'Stone-ground guacamole, chipotle salsa & blue tostadas.',
          priceUsd: 42,
          category: 'Snacks',
          quantity: 0,
          tag: 'PESCATARIAN / GF',
          storageType: 'FRESH SNACK SETUP',
        ),
        LarderItem(
          id: 'larder-6',
          name: 'Casa Madero Gran Reserva Red Blend',
          origin: 'Parras Valley, Mexico · 2019 Vintage',
          description: 'Blackberry, cassis, cedarwood & toasted cacao.',
          priceUsd: 120,
          category: 'Cellar Selection',
          quantity: 0,
          tag: 'SOMMELIER RESTED AT 16°C',
          storageType: 'DECANTER PREPARED',
        ),
        LarderItem(
          id: 'larder-7',
          name: 'Organic Sun & Ocean Recovery Kit',
          origin: 'Handcrafted in Kachava Apothecary Lab',
          description: 'Reef-safe SPF 50 zinc, copal & aloe after-sun mist.',
          priceUsd: 65,
          category: 'Recovery',
          quantity: 0,
          tag: 'SPA APOTHECARY',
          storageType: 'BATHROOM VANITY',
        ),
      ];
}
