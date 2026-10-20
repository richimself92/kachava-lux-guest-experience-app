/**
 * sanctuaryData.ts
 * ============================================================================
 * BRAND ASSET SWAP POINT — GUEST & DEMO DATA
 * ============================================================================
 * This file is the single source of truth for all prototype / demo content.
 * When real guest data or brand content is available, update the exports below.
 *
 * Sections:
 *   GUEST_INFO        — guest name, villa, dates, preferences
 *   IMAGES            — all image URLs (CDN / Unsplash placeholders)
 *   INITIAL_FLIGHT    — arrival flight details
 *   SERVICE_REQUESTS  — pre-seeded concierge service requests
 *   INITIAL_LARDER_ITEMS — villa larder / stock items
 *   ALL_EXPERIENCES   — curated experience cards
 * ============================================================================
 */
import {
  ExperienceItem,
  FlightDetails,
  LarderItem,
  ServiceRequest,
  YachtVesselSpecs,
  YachtCharterPackage,
  NavigableDestination,
} from '../types';

// ============ BRAND SWAP: Guest profile =====================================
export const GUEST_INFO = {
  name: 'Sarah Miller',
  partner: 'Mark',
  villa: 'Villa 102',
  suiteName: 'Ceiba Suite',
  sqft: '3,400 sq ft',
  stayDates: 'Nov 12–16, 2026',
  nights: 4,
  guests: 2,
  celebration: '4th Wedding Anniversary',
  folioCard: 'Visa ending in 8412',
  dietaryProfile: 'Pescatarian & Gluten-Sensitive',
  allergies: 'Shellfish (Mild) - Chef Alerted',
  inVillaBar: 'Mezcal & Fresh Lime, Sparkling Mineral',
  communicationPref: 'WhatsApp',
  phone: '+1 (415) 890-4412',
  email: 'sarah.miller@voyage.co',
};

// ============ BRAND SWAP: Image registry ====================================
// Replace URL values below with real Kachava property photos.
// Keys are referenced by every screen — change values here, not in components.
export const IMAGES = {
  facade: '/villa-facade-hdr.jpg',
  facadeFallback: '/villa-facade-hdr.jpg',
  avatar: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCSh1BJVQcVyzAX0RXPw0B2PwwD3mQ_C7e_b_N-Fpn_0w1eHg-Mvr_AKRY8BJ-PGPmcL6PEl1ppHrsrmGc26RHkH7TUHYlIM8UW55k1rgrNcczRmFzxbaXiQY-iHkhqVVVmDQ6aE6pzu1b5WgWnpkU7ZiT11huyB0Dc2ZiMG_DFJXTh2zi3NVhS51xHGI03BvoN1MjjTmqu4LPXGmyU3V6EyLf9e4crb9JwfkWy5aqaiSnMfY5R55ZP-xe2WyazNIhVC9dnLUFhaK3vkA',
  yacht: '/yacht/galleon-sky-hero-puerto-cancun.png',
  cenote: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCSrJ2KEjtl_LMT4yXlv6wUya5B7bMlbZ7vCjHYWfqwSpo57w8KcxNZpBk1ktiqVpqMBLLUgQUzBK_abqREFZRHcaLi7d1sMLSZEgnQh0twyQW1fpxTV_kwKg2yhyuyi-BmkSngfn-NHOrSluJ1zsFYusN7pueQtj2xdyluwrvZ-6jRDSrCsDVUePoOQUs2HH-dYygszg7DthtQaVId64rTmwyXJEP2gFygZKscuFiQwFOm-NGeRDNZ',
  spa: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBfi9HrgRoV1JC_4XML8WQcjWE5LnkFY0jeSB-v0jKlcg2ETPjeIEiUwauUlWBOtAOcZRFX8Xw1s65G5KaJ7buX1Q4E4t2dOwkrJOeUh7fKYcvQQ2df300P_o9QFzgfYY-b5h6bJLshHZcE2HOO391_HDB1yVboOSMWt1UZc4Bzn8SKHKZB0hoUeenv5diaY0mkpKws7dvXSsCcfkgywc1AtvAlpOMrRUTBYgiIpo7Gob-YP5fZxkf6',
  sianKaan: 'https://lh3.googleusercontent.com/aida-public/AB6AXuB5tFE9v41nfK5PfoSSkdosMXIhS1uT0zpmQ4Az8IOaB49v1dkTtVOE5ZzXM2pD0OsvERf8xZcjfJOC38R03jFuKV1Ixa3mAQOfQuWxQmrkOPkrFSSfKLcYb12v2kH4CNKW2Vvu8SRsIuu_3vbRuKz7loAE1JOFgJroNiSXueGNV7vYjxS7cwumgwxcqkEpTxyLGtJWaVyuYKZHEosRGcczrDi9L0HmqFIX1ryoWP_iAy-cxPVLEpd-',
  golf: 'https://lh3.googleusercontent.com/aida-public/AB6AXuA4jeC6KbKVcjPCKD-cXHuFm9-1KJ5S8i9HpA8ffCfjFr5OgCOtPIvgDHPL8Bus0Yl_ocfu33HEx99N8JgnnYP9XTKVffl1nWwGl_F1oYedEhwuyX4704RSMcu7zEh55J0phdRf4btPfF5cHaxDgk4BKrO2to8ikvrCkxURyzlA7FMqhEYUS5p3h-dZ7pynDcRGo26sLAwYBmqRg9RBKsm7ZESgAp0NS9XSvJ1DTU9meg31CmgjqEmD',
  chefFire: 'https://lh3.googleusercontent.com/aida-public/AB6AXuC7cUeZG27KVuATwTwXc-uznnGJjt8xSt_Uc8SVhYmYoyohTki64FL0slnFf1ongY0VEtOmnt25MtKym_Jbr2dg7FrzjWQAOXWcbDtCF70Qn7_ERuuztM7mOq2KxmRIwP8iK3tlMivd3qOPjw5ntZbRa_RZg70swivxURqCmzelb67eZgjgRa37MfuZy1xTHnRyOrNcBYNRNOAlS5Qg5vnafqyjFttfv3v7SLxS4jNgPczd2a6gYpXQ',
  mateoPortrait: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAv3QBJbAWHFcbZdS5qBwP-IublWik-X3S1vzSNMVtIr9o0haf0TP-dcQ6VSThH8syDON4N_6xCsPOsPAvbxw7ZGLhDQT1KAUY2oYMiVoilkr1dEzFyrZjXt-OUA6njZRA0BcelPfA2mU99pZPiJmAehn7Iv0DD3ema8WEX5VEjE2ri8wpBjIEJTxUDqoVQa2S2H6fNebxcGlpRNCLXh2gnHEOOTVUl05-2vrzNQlqUWlTsbI7_kN_a',
  sofiaPortrait: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDnag0pSUFWr136e6kLv-h0P5Y1TXPpKee_znH7C4bd_sc8o6PHk_4Ok_z676A4zbCKuw5eHWw11r2pQXnsPoteYjCq9oD7-Waw4ZitOVBZQM2NzLB_xXfFMhzwdcSZaCb1oL2L0eoOZu1hmzkvhhM-L_icuCr30E4lLx8Zzk43dOwLDlHTgHo7bFG74uO-rFQcIvZO3OxCjjNdJRAKmRjBWcgsY3A1Nhvh5fTc5oK6xLccKI1qAnAa',
  terracePlunge: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAG8b7txYiyVQ65LYCYyQjwlTdy1HY2ZJs57lp8gNDCJ_Gdt3BFN4-N_vjF6c-750nZTcGgHQAg3kqL_7ANo3gfBJ9yzQiFLhEFG933dQuTYxmi6X3j79uVvlvCwDaLpOVDGzCUHMVL4MDatfio5B231xCCoHbohPlaFqUWh2DAdOOxs30nqPLYtNrj3nd-Z5SmAisIGKqA4fsJo8NIV35SWsagZgAHwhVohXKplEUs8HjPsVR5QlEO',
  mateoClose: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAZnlbHRSqyiMVP6DMoArTLCZD7p5BMXqAVVNJ9lDovSPrQrDAuraMgvTIwSibHpP-uEYsI7AO8gI439EXF73KVCd9whOtH9w-OOtEcsEOybkZFIpE0GV0IcWHctzDHMOP3ZNbEu7cLrFBi_C8H9mn-IFdLT59I0Pct_8zTTqczfD0OyX-fi6RTDaNZhQjjszbeCOG_lI7EhOX0p_0uKsMJ3EE-xJuK1z9C-Ggmde-qtS54xpjum1jb',
  chauffeurTransfer: 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&w=1200&q=80',
  ceibaBedroom: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=1200&q=80',
  breakfast: 'https://images.unsplash.com/photo-1533089860892-a7c6f0a88666?auto=format&fit=crop&w=1200&q=80',
  dinnerChef: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=1200&q=80',
  coconuts: 'https://images.unsplash.com/photo-1525385133512-2f3bdd039054?auto=format&fit=crop&w=800&q=80',
  chukumCourtyard: 'https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?auto=format&fit=crop&w=1200&q=80',
  chukumWall: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
  fireCooking: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1200&q=80',
  tortillas: 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=800&q=80',
  elenaPortrait: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=600&q=80',
  fruitsBasket: 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?auto=format&fit=crop&w=800&q=80',
  juices: 'https://images.unsplash.com/photo-1622597467836-f3285f2131b8?auto=format&fit=crop&w=800&q=80',
  mezcalTequila: 'https://images.unsplash.com/photo-1569919659476-f0852f6834b7?auto=format&fit=crop&w=800&q=80',
  sourdough: 'https://images.unsplash.com/photo-1589367920969-ab8e050bbb04?auto=format&fit=crop&w=800&q=80',
  guacamoleBoard: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=800&q=80',
  wineBottle: 'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?auto=format&fit=crop&w=800&q=80',
  spaRecoveryKit: 'https://images.unsplash.com/photo-1608248597359-548450700021?auto=format&fit=crop&w=800&q=80',
  lobsterDish: 'https://images.unsplash.com/photo-1551248429-40975aa4de74?auto=format&fit=crop&w=800&q=80',
  cochinitaDish: 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=800&q=80',
  veggieDish: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80',
  carlosChauffeur: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=600&q=80',
};

// ============ KACHAVA CARIBE: Authentic Yacht Assets & Metadata =============
export const YACHT_VESSEL_SPECS: YachtVesselSpecs = {
  model: 'Galeon 470 Sky',
  tagline: 'Engineering Meets Luxury · Custom Commissioned for Kachava Lux',
  overallLength: '47 ft 3 in (14.4 m)',
  beam: '14 ft 4 in (4.37 m)',
  beachModeBeam: '19 ft 0 in (5.80 m)',
  capacity: 'Up to 12 Guests + 2 Crew',
  accommodations: '3 Private Cabins & 2 Ensuite Heads',
  engines: 'Twin Volvo Penta D8 Turbocharged',
  refinement: 'Kachava Custom Commissioned',
  marinaHome: 'Puerto Cancún Marina / Riviera Maya',
};

export const CAPTAIN_INFO = {
  name: 'Eduardo Velasco Tadeo',
  role: 'Master Yacht Captain',
  experience: '19 Years at Sea (10 yrs Master Captain / 9 yrs Diving & Marine)',
  origin: 'Quintana Roo, Mexico · Caribbean Native',
  image: '/yacht/captain.jpg',
  quote:
    'When our guests step on board, their only concern should be what drink to order. My crew and I handle everything else.',
  bio:
    'From a multi-generational Quintana Roo maritime family. Commanded vessels across Mexico, South Florida (Tampa to Cape Canaveral), Honduras, and the Bahamas.',
};

export const YACHT_PACKAGES: YachtCharterPackage[] = [
  {
    id: 'half-day',
    title: 'Half-Day Guest Experience',
    tagline: 'The Day Explorer · 4 Hours',
    durationHours: 4,
    durationLabel: '4 Hours (09:30 AM – 1:30 PM or 2:30 PM – 6:30 PM)',
    valuationUSD: 2000,
    isIncludedWithStay: true,
    priceLabel: 'Included with 4N+ Stay · $0 Due ($2,000 USD Value)',
    description:
      'Dip into coastal luxury with a 4-hour private cruise. Perfect for a champagne lunch, shallow turquoise swim, and afternoon sunbathing along Bahia de Mujeres.',
    highlights: [
      'Dedicated Master Captain & Hospitality Host',
      'El Meco Coral Reef & Sea Turtle Snorkeling',
      'Freshly prepared Yellowtail Ceviche & Guacamole',
      'Open Bar with Premium Spirits & Mexican Wines',
      'Dual Stand-Up Paddleboards & Cressi Snorkel Gear',
      'Door-to-Dock Mercedes-Benz Chauffeur',
    ],
    suggestedPaths: 'Cancun Lagoon & Bahía de Mujeres to Playa Norte Haven',
    idealFor: 'Anniversaries, scenic coastal swims, and golden hour dining',
  },
  {
    id: 'extended',
    title: 'Extended Caribbean Experience',
    tagline: 'The Deep Voyage · 6 Hours',
    durationHours: 6,
    durationLabel: '6 Hours (10:00 AM – 4:00 PM or 1:00 PM – 7:00 PM)',
    valuationUSD: 3000,
    isIncludedWithStay: false,
    priceLabel: '+$1,000 USD Stay Upgrade (Valued at $3,000 USD)',
    description:
      'Embrace the complete rhythm of the Caribbean. 6 hours to explore isolated sandbars, dive remote reefs, and take in a stunning golden sunset.',
    highlights: [
      'Full Day-Cabin Access with Sub-Zero Climate Control',
      'Extended Cruising Horizons to Secluded Anchorages',
      'Multiple Snorkeling & Mooring Drop Points',
      'Expanded Artisanal Tapas & Coastal Degustation',
      'Sunset Champagne Toast & Cocktail Hour',
    ],
    suggestedPaths: 'Puerto Aventuras to El Cielo Sandbar Sanctuary',
    idealFor: 'Full reef immersion, extended family cruises, and photography',
  },
  {
    id: 'full-day',
    title: 'Private Full-Day Escape',
    tagline: 'The Yucatan Sanctuary · 8 Hours',
    durationHours: 8,
    durationLabel: '8 Hours (09:00 AM – 5:00 PM)',
    valuationUSD: 4000,
    isIncludedWithStay: false,
    priceLabel: '+$2,000 USD Stay Upgrade (Valued at $4,000 USD)',
    description:
      'Navigate the legendary turquoise paths of the Mexican Caribbean. Absolute finest coral snorkeling, private sandbanks, and all-day private maritime service.',
    highlights: [
      'Complete 8-Hour Freedom Itinerary',
      'Full Master & VIP Suite Access for Rest & Rejuvenation',
      'Full-Course Fresh Seafood Lunch Prepared Onboard',
      'Reserve Cellar Agave & French Champagne Bar',
      'Seabob F5-S Underwater Scooter Deployment',
    ],
    suggestedPaths: 'Cancun to Isla Contoy Protected Biosphere or Cozumel Deep Wall',
    idealFor: 'The ultimate aquatic luxury experience with complete privacy',
  },
  {
    id: 'custom',
    title: 'Custom Yucatan Peninsula & Caribbean Routes',
    tagline: 'Ultimate Horizons · Bespoke Itinerary',
    durationHours: 10,
    durationLabel: 'Custom Duration & Itinerary',
    valuationUSD: 5000,
    isIncludedWithStay: false,
    priceLabel: 'Custom Proposal by Yacht Concierge',
    description:
      'Chart an uncompromised path tailored exactly to your vision in coordination with Captain Eduardo Velasco.',
    highlights: [
      'Unrestricted Maritime Corridor Routing',
      'Private Chef Custom Provisioning',
      'Helicopter or Private Ground Transfer Links',
      'Multi-day or Sunset-to-Twilight Night Cruises',
    ],
    suggestedPaths: 'Holbox Secluded Sands, Tulum Coast Anchorages, or Isla Contoy Borders',
    idealFor: 'Bespoke milestones, private gatherings, and personalized expeditions',
  },
];

export const NAVIGABLE_DESTINATIONS: NavigableDestination[] = [
  {
    id: 'isla-mujeres',
    title: 'Cancún & Isla Mujeres',
    region: 'Mexican Caribbean',
    badge: 'Signature Inclusion',
    image: '/yacht/playa-en-isla-mujeres.jpg',
    subtitle: 'The Turquoise Passage & Playa Norte Haven',
    description:
      'Cruise across Bahía de Mujeres to world-celebrated Playa Norte turquoise shallows. Snorkel El Meco coral reef, indulge in onboard chef ceviche, and paddleboard in calm crystal waters.',
    highlights: [
      'Playa Norte shallow crystal sandbar anchorage',
      'El Meco reef & sea turtle snorkeling',
      'Freshly prepared fish ceviche & open bar',
    ],
    duration: '4 Hours (Half-Day) or 8 Hours',
  },
  {
    id: 'isla-contoy',
    title: 'Isla Contoy Sanctuary',
    region: 'Protected National Park',
    badge: 'Eco-Sanctuary Expedition',
    image: '/yacht/galleon-sky-aerialview-ai.png',
    subtitle: 'Untouched Marine Biosphere & Bird Haven',
    description:
      'An exclusive voyage to an uninhabited paradise strictly limited to 200 daily visitors. Pristine Ixlaché coral reef snorkeling, rare tropical bird nesting sanctuaries, and virgin beach dining.',
    highlights: [
      'Strictly regulated national marine biosphere reserve',
      'Mesoamerican Barrier Ixlaché reef snorkel',
      'Secluded virgin beach dining & certified eco-guide',
    ],
    duration: 'Bespoke Full-Day (7–8 Hours)',
  },
  {
    id: 'miami',
    title: 'Miami & Biscayne Bay',
    region: 'South Florida, USA',
    badge: 'Sister Fleet US Route',
    image: '/yacht/miami-kachavacaribe.jpeg',
    subtitle: 'Miami Skylines & Biscayne Sandbar Horizons',
    description:
      'Signature Kachava hospitality under South Florida skies. Scenic cruise past Downtown Miami skyline, Key Biscayne, and sunset anchorages at the famous Nixon Beach sandbar.',
    highlights: [
      'Downtown Miami & Brickell skyline views',
      'Key Biscayne & Nixon Beach sandbar swim',
      'Dual-destination guest concierge integration',
    ],
    duration: '4 Hours or Full-Day',
  },
];

export const YACHT_GALLERY = [
  {
    src: '/yacht/galleon-sky-hero-puerto-cancun.png',
    caption: 'Galeon 470 Sky · Cruising Puerto Cancún Waters',
    tag: 'Exterior Profile',
  },
  {
    src: '/yacht/galleon-sky-aerialview-ai.png',
    caption: 'Aerial View · Dual Deck Line & Hardtop Aero-Sport Profile',
    tag: 'Aerial',
  },
  {
    src: '/yacht/galeon-sky-cockpitbar-ai.jpg',
    caption: 'Cockpit Bar & Beach Mode Fold-Down Balconies',
    tag: 'Beach Mode Club',
  },
  {
    src: '/yacht/galleon-sky-loungeview-puerto-cancun.jpg',
    caption: 'Main Saloon & Panoramic Floor-to-Ceiling Windows',
    tag: 'Main Saloon',
  },
  {
    src: '/yacht/galleon-sky-breakfast.jpg',
    caption: 'Skydeck Lounge & Elevated Flybridge Social Sanctuary',
    tag: 'Skydeck',
  },
  {
    src: '/yacht/galleon-sky-panoramic-view-puerto-cancun.png',
    caption: 'Open Galley & Gourmet Oceanview Kitchen',
    tag: 'Galley',
  },
  {
    src: '/yacht/galleon-sky-bedroom3.jpg',
    caption: 'Full-Beam Master Suite with Midship Hull Windows',
    tag: 'Master Suite',
  },
  {
    src: '/yacht/galleon-sky-bedroom2.jpg',
    caption: 'VIP Guest Cabin with Double Berth & Custom Timber Trim',
    tag: 'VIP Stateroom',
  },
  {
    src: '/yacht/galleon-sky-bathroom.jpg',
    caption: 'Luxury Ensuite Bath with Designer Vanity & Walk-in Shower',
    tag: 'Ensuite Head',
  },
  {
    src: '/yacht/galleon-sky-sunset.jpg',
    caption: 'Golden Hour Sunset Deck & Sundown Champagne Horizon',
    tag: 'Sunset',
  },
];


// ============ BRAND SWAP: Arrival flight details ============================
export const INITIAL_FLIGHT: FlightDetails = {
  arrivalAirport: 'Cancun International (CUN) · Terminal 3',
  airline: 'American Airlines',
  flightNumber: 'AA 172',
  estimatedLanding: 'Nov 12, 2026 · 11:35 AM CST',
  partySize: 2,
  luggageChecked: 3,
  luggageCarryOn: 2,
  status: 'Confirmed',
  assignedDriver: 'Carlos M.',
};

// ============ BRAND SWAP: Pre-seeded service requests =======================
export const SERVICE_REQUESTS: ServiceRequest[] = [
  {
    id: 'req-towels',
    title: 'Extra Towels',
    category: 'Housekeeping',
    time: 'Requested today · 2:04 PM',
    status: 'In Progress',
    currentStep: 3,
    assignedTo: 'Eduardo',
    details: 'Fresh bath and pool towels requested for Villa 102 master suite.',
    notes: 'Eduardo is preparing fresh towels for delivery.',
    isCompleted: false,
  },
  {
    id: 'req-transfer',
    title: 'Airport Transportation',
    category: 'Transportation',
    time: 'Requested yesterday · 4:15 PM',
    status: 'Completed',
    currentStep: 4,
    assignedTo: 'Eduardo',
    details: 'Private transfer scheduled for Cancun International Airport (CUN) arrival.',
    notes: 'Confirmed for Nov 12 at 11:35 AM.',
    isCompleted: true,
  },
  {
    id: 'req-dining',
    title: 'Dietary Preferences Confirmation',
    category: 'Dining',
    time: 'Requested Oct 28 · 10:30 AM',
    status: 'Completed',
    currentStep: 4,
    assignedTo: 'Eduardo',
    details: 'Pescatarian and gluten-sensitive notes shared with executive chef.',
    notes: 'Menu tailored for Villa 102.',
    isCompleted: true,
  },
];

// ============ BRAND SWAP: Villa larder / stock items ========================
export const INITIAL_LARDER_ITEMS: LarderItem[] = [
  {
    id: 'larder-1',
    name: 'Endemic Tropical Fruit Harvest',
    origin: 'Finca Santa Maria, Mayan Riviera',
    description: 'Fresh dragonfruit, golden passionfruit, wild papaya, and mamey sapote. Chilled, sliced, and arranged.',
    price: 38,
    category: 'fruit',
    quantity: 1,
    image: IMAGES.fruitsBasket,
    tag: 'HARVESTED MORNING OF NOV 12',
    dietary: 'PESCATARIAN / GF',
    storageType: 'CHILLED IN LARDER',
  },
  {
    id: 'larder-2',
    name: 'Chilled Cold-Pressed Elixirs (Set of 4)',
    origin: 'Cold-pressed 6:00 AM daily by In-House Alchemist',
    description: 'Green jungle detox, Mayan golden turmeric root, spiced hibiscus ginger, and fresh cold-cracked coconut water.',
    price: 45,
    category: 'elixirs',
    quantity: 2,
    image: IMAGES.juices,
    tag: 'REQUESTED IN ONBOARDING',
    dietary: 'VEGAN & RAW',
    storageType: 'SUB-ZERO CHILLED',
  },
  {
    id: 'larder-3',
    name: 'Casa Dragones Joven & Smoked Salt Kit',
    origin: 'Tequila, Jalisco · 100% Blue Agave',
    description: 'Small-batch 100% Pure Blue Agave sipping tequila, copal-smoked sea salt rim, fresh organic lime wheels, and stone copitas.',
    price: 285,
    category: 'cellar',
    quantity: 0,
    image: IMAGES.mezcalTequila,
    tag: 'CELLAR SELECTION',
    storageType: 'DRY BAR PRESENTATION',
  },
  {
    id: 'larder-4',
    name: 'GF Sourdough & Melipona Honeycomb',
    origin: 'Panadería Maya & Sacred Bee Sanctuary',
    description: 'Ancient grain loaf baked by local Tulum artisans, raw stingless Melipona forest honey, and cultured grass-fed churned butter.',
    price: 28,
    category: 'bakery',
    quantity: 0,
    image: IMAGES.sourdough,
    tag: "SARAH'S PREFERENCE: GF",
    storageType: 'LARDER BREAD BOX',
  },
  {
    id: 'larder-5',
    name: 'Oaxacan Quesillo & Guacamole Board',
    origin: 'Prepared 1:30 PM on Nov 12',
    description: 'Hand-pulled Quesillo, house-made stone-ground guacamole, smoked chipotle garden salsa, and heirloom blue corn tostadas.',
    price: 42,
    category: 'snacks',
    quantity: 0,
    image: IMAGES.guacamoleBoard,
    tag: "SARAH'S PREFERENCE: PESCATARIAN / GF",
    storageType: 'FRESH SNACK SETUP',
  },
  {
    id: 'larder-6',
    name: 'Casa Madero Gran Reserva Red Blend',
    origin: 'Parras Valley, Mexico · 2019 Vintage',
    description: "Mexico's most historic estate. Intense blackberry, cassis, cedarwood, and toasted cacao. Stored in temperature cellar.",
    price: 120,
    category: 'cellar',
    quantity: 0,
    image: IMAGES.wineBottle,
    tag: 'SOMMELIER RESTED AT 16°C',
    storageType: 'DECANTER PREPARED',
  },
  {
    id: 'larder-7',
    name: 'Organic Sun & Ocean Recovery Kit',
    origin: 'Handcrafted in Kachava Apothecary Lab',
    description: 'Reef-safe non-nano zinc sunscreen SPF 50, cold-infused copal & aloe vera after-sun mist, and soothing herbal lip balm.',
    price: 65,
    category: 'recovery',
    quantity: 0,
    image: IMAGES.spaRecoveryKit,
    tag: 'SPA APOTHECARY',
    storageType: 'BATHROOM VANITY VANITY',
  },
];

// ============ BRAND SWAP: Experience cards ==================================
export const ALL_EXPERIENCES: ExperienceItem[] = [
  {
    id: 'exp-1',
    title: 'Kachava Caribe · Galeon 470 Sky Private Yacht Experience',
    subtitle: 'Cancún & Isla Mujeres Turquoise Waters · 47ft Galeon Sky',
    duration: '4 Hours (Half-Day) or 8 Hours (Full-Day)',
    location: 'Bahía de Mujeres & Playa Norte Haven',
    vehicleOrDetail: '47ft Galeon 470 Sky with Beach Mode',
    priceText: '$0 USD',
    isIncluded: true,
    inclusionLabel: 'Included With Villa 102 Stay ($2,000 USD Value)',
    image: IMAGES.yacht,
    category: 'Yacht Charters',
    description: 'Cruise the turquoise shallows of Bahía de Mujeres and Playa Norte aboard our custom Galeon 470 Sky with 19ft fold-down Beach Mode balconies, chef ceviche, and open bar.',
    amenities: ['Beach Mode Balconies', 'Chef Ceviche & Open Bar', 'Reef Snorkel & Paddleboards', 'Master Captain & Host'],
    actionLabel: 'View Details & Schedule',
    actionScreen: 'yacht',
  },
  {
    id: 'exp-2',
    title: 'Subterranean Cenote Dos Ojos Private Dive & Ritual',
    subtitle: 'Sacred Cavern · Max 4 Guests',
    duration: '3.5 Hours',
    location: 'Sacred Cavern',
    vehicleOrDetail: 'Max 4 Guests',
    priceText: 'From $380 / Guest',
    isIncluded: false,
    image: IMAGES.cenote,
    category: 'Cenotes & Caverns',
    description: 'Private morning access before sanctuary gates open. Includes an ancestral Mayan copal water blessing, certified Cave Master immersion, custom thermal drysuits, and underwater high-res portraiture.',
    amenities: ['Private Escalade Transfer Included', 'Cave Master Certification', 'High-Res Photography'],
    actionLabel: 'Reserve Dive',
  },
  {
    id: 'exp-3',
    title: 'In-Villa Sacred Chukum & Obsidian Massage',
    subtitle: 'Secluded Villa 102 Terrace · Signature Ritual',
    duration: '60 or 90 Min',
    location: 'Secluded Villa 102 Terrace',
    vehicleOrDetail: '2 Therapists',
    priceText: 'Complimentary',
    isIncluded: true,
    inclusionLabel: 'Included (Signature Ritual)',
    image: IMAGES.spa,
    category: 'Wellness & Spa',
    description: 'Warmed obsidian mineral stones sourced from Puebla carved to release tension, paired with botanical copal tree balms, sound bowl therapy, and an herbal wild honey foot cleanse on your private deck.',
    amenities: ['Botanical Copal Balms', 'Obsidian Stone Therapy', 'Private Terrace Setup'],
    actionLabel: 'Select Time',
  },
  {
    id: 'exp-4',
    title: "Sian Ka'an Biosphere Sunset Eco-Safari",
    subtitle: 'UNESCO Biosphere · Natural Current Float',
    duration: '5 Hours',
    location: 'UNESCO Biosphere',
    vehicleOrDetail: 'Private Wooden Skiff',
    priceText: 'From $450 / Pair',
    isIncluded: false,
    image: IMAGES.sianKaan,
    category: 'Mayan Ruins',
    description: 'Led by a resident marine biologist. Drift weightlessly down ancient freshwater Mayan trading canals, track wild manatees and coastal birds, finishing with an open sandbank sunset tasting of organic Mexican wines.',
    amenities: ['Resident Marine Biologist', 'Canal Float Experience', 'Sunset Wine Tasting'],
    actionLabel: 'Explore Route',
  },
  {
    id: 'exp-5',
    title: 'PGA Riviera Maya Championship Golf',
    subtitle: 'Robert Trent Jones II · Full Callaway Fit',
    duration: '18 Holes',
    location: 'Robert Trent Jones II Course',
    vehicleOrDetail: 'Dedicated GPS Buggy',
    priceText: '$0 Green Fees',
    isIncluded: true,
    inclusionLabel: 'Included (Switchable Benefit)',
    image: IMAGES.golf,
    category: 'Golf',
    description: 'Priority sunrise tee times with dedicated GPS buggy, 2024 Callaway Paradym club rental set, and personalized clubhouse locker privileges. Switchable with the signature spa benefit.',
    amenities: ['18 Holes Championship', 'Callaway Paradym Rental', 'GPS Electric Cart'],
    actionLabel: 'Book Tee Time',
  },
  {
    id: 'exp-6',
    title: "Chef Mateo's Fire & Copal Table",
    subtitle: 'In-Villa Open Kitchen · 7-Course Journey',
    duration: '7-Course Journey',
    location: 'Villa 102 Terrace Open Kitchen',
    vehicleOrDetail: 'Executive Chef Mateo & Sommelier Elena',
    priceText: '1 Dinner Credit',
    isIncluded: true,
    inclusionLabel: 'Included (1 Evening With Villa)',
    image: IMAGES.chefFire,
    category: 'Private Dining',
    description: 'Ancestral underground pit-cooking and smoke-infused gastronomy prepared live on Villa 102’s terrace. Paired with biodynamic Valle de Guadalupe wines. Additional evenings available from $220 / guest.',
    amenities: ['7-Course Tasting', 'Sommelier Wine Pairing', 'Underground Pit Roasting'],
    actionLabel: 'Reserve Table',
    actionScreen: 'dining',
  },
];
