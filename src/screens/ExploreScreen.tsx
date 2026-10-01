import React, { useState } from 'react';
import { ScreenId } from '../types';
import { GUEST_INFO, IMAGES } from '../data/sanctuaryData';

interface ExploreScreenProps {
  onNavigate: (screen: ScreenId) => void;
}

export type ExploreCategory =
  | 'All'
  | 'Included'
  | 'Yacht'
  | 'Wellness'
  | 'Dining'
  | 'Adventure'
  | 'Culture';

export interface DetailedExperience {
  id: string;
  title: string;
  category: 'Yacht' | 'Wellness' | 'Dining' | 'Adventure' | 'Culture';
  duration: string;
  priceType: 'INCLUDED' | 'FROM_PRICE';
  priceDisplay: string;
  availability: string;
  oneLineDescription: string;
  fullDescription: string;
  heroImage: string;
  gallery: string[];
  whatsIncluded: string[];
  location: string;
  isUnusedBenefit?: boolean;
  timeSlots: string[];
  actionScreen?: ScreenId;
}

const EXPERIENCES_DATA: DetailedExperience[] = [
  // 1. Yacht - INCLUDED
  {
    id: 'exp-yacht',
    title: 'Kachava Private Yacht Voyage',
    category: 'Yacht',
    duration: '4 Hours',
    priceType: 'INCLUDED',
    priceDisplay: 'INCLUDED',
    availability: 'Nov 13–15 · Morning & Sunset',
    oneLineDescription: 'Private 44ft Leopard Catamaran cruise to Boca Paila reef with ceviche bar and wild mezcal.',
    fullDescription:
      'Sail along the secluded crystalline waterways of the Boca Paila Barrier Reef aboard our signature 44-foot Leopard catamaran. Your dedicated captain and onboard private cook prepare fresh ceviche and sashimi from the day’s local catch, complemented by artisanal wild agave mezcals and chilled organic elixirs. Anchor in calm turquoise coves for guided drift snorkeling among vibrant coral heads and sea turtles.',
    heroImage: IMAGES.yacht,
    gallery: [
      IMAGES.yacht,
      'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80',
    ],
    whatsIncluded: [
      'Private 44ft Leopard Catamaran & dedicated 3-person crew',
      'Onboard raw bar: freshly cured ceviche & Caribbean lobster sashimi',
      'Artisanal Mezcal & Valle de Guadalupe wine pairing',
      'Professional underwater snorkeling gear & SeaDoo sea scooters',
      'Roundtrip private Escalade transfer to Puerto Aventuras marina',
    ],
    location: 'Boca Paila Barrier Reef · Private Marina Berth',
    isUnusedBenefit: true,
    timeSlots: ['9:00 AM (Morning Reef Sail)', '1:30 PM (Midday Drift)', '4:15 PM (Golden Sunset Sail)'],
    actionScreen: 'yacht',
  },

  // 2. Wellness - INCLUDED
  {
    id: 'exp-massage',
    title: 'In-Villa Sacred Obsidian & Chukum Massage',
    category: 'Wellness',
    duration: '90 Min',
    priceType: 'INCLUDED',
    priceDisplay: 'INCLUDED',
    availability: 'Daily 8:00 AM – 7:00 PM',
    oneLineDescription: 'Warmed volcanic Puebla stones, botanical copal balms, and sound bowl therapy on Villa 102 terrace.',
    fullDescription:
      'A deeply restorative sanctuary ritual performed in complete privacy on your secluded Villa 102 pool terrace or air-conditioned master suite. Hand-carved obsidian stones from Puebla are gently heated to dissolve muscular tension, accompanied by wild copal tree balms, vibrational Tibetan singing bowls, and an herbal Melipona honey foot wash.',
    heroImage: IMAGES.spa,
    gallery: [
      IMAGES.spa,
      'https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=1200&q=80',
      IMAGES.terracePlunge,
    ],
    whatsIncluded: [
      'Two master sanctuary therapists dedicated to Villa 102',
      'Hand-carved heated Puebla obsidian mineral therapy',
      'Wild forest copal oil and sacred Melipona honey infusion',
      'Acoustic sound bowl realignment & lavender temple compresses',
      'Post-treatment botanical infusion & chilled coconut water',
    ],
    location: 'Villa 102 Private Terrace / Master Suite',
    isUnusedBenefit: true,
    timeSlots: ['9:00 AM', '11:30 AM', '3:00 PM', '5:30 PM'],
  },

  // 3. Dining - INCLUDED
  {
    id: 'exp-chef',
    title: "Chef's Fire & Copal In-Villa Table",
    category: 'Dining',
    duration: '7 Courses',
    priceType: 'INCLUDED',
    priceDisplay: 'INCLUDED',
    availability: 'Nov 13 or 14 Evening',
    oneLineDescription: 'Live embers pit-cooking and smoke-infused gastronomy paired with Valle de Guadalupe wines.',
    fullDescription:
      'Executive Chef leads an ancestral open-flame dining journey prepared exclusively inside Villa 102’s private terrace kitchen. Savor seven courses celebrating heritage Mayan ingredients—underground cochinita roasted beneath banana leaves, flame-seared Caribbean lobster, and smoked tropical cacao—guided by personal sommelier wine selections.',
    heroImage: IMAGES.chefFire,
    gallery: [
      IMAGES.chefFire,
      IMAGES.dinnerChef,
      IMAGES.lobsterDish,
      IMAGES.cochinitaDish,
    ],
    whatsIncluded: [
      'Private executive chef & personal sommelier for the evening',
      'Bespoke 7-course tasting menu tailored to Sarah’s pescatarian/GF preference',
      'Full biodynamic Valle de Guadalupe wine & artisanal mezcal pairing',
      'Handcrafted copal-scented candlelight & tropical floral tablescape',
      'Discreet complete kitchen cleanup & lingering digestif setup',
    ],
    location: 'Villa 102 Terrace Open Kitchen',
    isUnusedBenefit: true,
    timeSlots: ['7:00 PM (Sunset Seating)', '8:00 PM (Starlight Seating)'],
    actionScreen: 'dining',
  },

  // 4. Wellness / Sport - INCLUDED (Switchable)
  {
    id: 'exp-golf',
    title: 'PGA Riviera Maya Championship Golf',
    category: 'Wellness',
    duration: '18 Holes',
    priceType: 'INCLUDED',
    priceDisplay: 'INCLUDED',
    availability: 'Daily Sunrise & Morning',
    oneLineDescription: 'Robert Trent Jones II masterwork with private GPS buggy and 2024 Callaway Paradym clubs.',
    fullDescription:
      'Immerse in world-class golf carved gracefully through indigenous Mayan jungle and natural cenote hazards. As a Villa 102 resident, enjoy preferred sunrise tee times, a dedicated electric GPS buggy stocked with chilled refreshments, and complimentary premium Callaway Paradym rentals.',
    heroImage: IMAGES.golf,
    gallery: [
      IMAGES.golf,
      'https://images.unsplash.com/photo-1535131749006-b7f58c99034b?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1592919505780-303950717480?auto=format&fit=crop&w=1200&q=80',
    ],
    whatsIncluded: [
      '18-hole championship green fees waived for 2 guests',
      'Dedicated GPS electric golf cart with onboard cool box',
      '2024 Callaway Paradym fitted set rental (Men’s & Women’s)',
      'Clubhouse locker room, sauna & practice facility privileges',
      'Private luxury roundtrip chauffeur transfer from Villa 102',
    ],
    location: 'PGA Riviera Maya · Robert Trent Jones II Course',
    isUnusedBenefit: true,
    timeSlots: ['7:15 AM (Sunrise)', '8:30 AM', '10:00 AM'],
  },

  // 5. Adventure - Cenote Dive
  {
    id: 'exp-cenote',
    title: 'Subterranean Cenote Dos Ojos Private Dive',
    category: 'Adventure',
    duration: '3.5 Hours',
    priceType: 'FROM_PRICE',
    priceDisplay: 'FROM $380',
    availability: 'Daily 7:30 AM · Max 4 Guests',
    oneLineDescription: 'Private dawn cavern entry before sanctuary gates open with certified Cave Master and blessing.',
    fullDescription:
      'Experience the mystical underworld of the ancient Maya before public gates open. Descend into sacred crystal-clear caverns where stalactites pierce jade-colored waters. Accompanied by a dedicated Cave Master, undergo an ancestral copal water blessing before gliding through submerged geological cathedrals.',
    heroImage: IMAGES.cenote,
    gallery: [
      IMAGES.cenote,
      'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1518638150340-f706e86654de?auto=format&fit=crop&w=1200&q=80',
    ],
    whatsIncluded: [
      'Exclusive private gate access prior to public operating hours',
      'Private certified Cave Master and safety escort',
      'Ancestral Mayan copal water ceremony by local elder',
      'Custom thermal wetsuits, professional masks & underwater torches',
      'High-resolution underwater portrait photography package',
    ],
    location: 'Sacred Cavern Cenote System · Jaguar Corridor',
    timeSlots: ['7:30 AM (Dawn Solitude)', '10:30 AM'],
  },

  // 6. Adventure - Sian Ka'an Eco-Safari
  {
    id: 'exp-siankaan',
    title: "Sian Ka'an Biosphere Sunset Eco-Safari",
    category: 'Adventure',
    duration: '5 Hours',
    priceType: 'FROM_PRICE',
    priceDisplay: 'FROM $450',
    availability: 'Daily 1:00 PM · Private Skiff',
    oneLineDescription: 'Ancient freshwater Mayan canal float with resident marine biologist and dunes wine tasting.',
    fullDescription:
      'Venture into the UNESCO World Heritage biosphere of Sian Ka’an (“Origin of the Sky”). Aboard a private wooden skiff with a resident marine biologist, glide weightlessly down ancient mangrove canals cultivated by pre-Columbian Mayan merchants. Encounter wild manatees, sea eagles, and dolphins, concluding with an open sandbank sunset wine tasting.',
    heroImage: IMAGES.sianKaan,
    gallery: [
      IMAGES.sianKaan,
      'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?auto=format&fit=crop&w=1200&q=80',
    ],
    whatsIncluded: [
      'Private skiff with captain and resident marine biologist',
      'Gentle freshwater natural current canal float experience',
      'High-grade life jackets and water shoes',
      'Artisanal organic picnic and biodynamic wine tasting on dunes',
      'All biosphere reserve permits and private transfers',
    ],
    location: "Sian Ka'an UNESCO Biosphere Reserve",
    timeSlots: ['1:00 PM – 6:00 PM (Sunset Float)'],
  },

  // 7. Culture - Tulum Cliffside Ruins
  {
    id: 'exp-ruins',
    title: 'Tulum Cliffside Ruins Private Archaeologist Dawn Access',
    category: 'Culture',
    duration: '3 Hours',
    priceType: 'FROM_PRICE',
    priceDisplay: 'FROM $290',
    availability: 'Daily 6:30 AM · Dawn Only',
    oneLineDescription: 'Private gate access at dawn with a Mayan historian before opening hours, followed by cliffside tea.',
    fullDescription:
      'Gaze upon the iconic sea-facing temples of Tulum in peaceful solitude before the general public arrives. Accompanied by a credentialed Mesoamerican archaeologist, walk through the fortress walls as dawn paints the Caribbean waters below in liquid gold. Uncover ancient astronomical alignments and maritime trading secrets.',
    heroImage: 'https://images.unsplash.com/photo-1518638150340-f706e86654de?auto=format&fit=crop&w=1200&q=80',
    gallery: [
      'https://images.unsplash.com/photo-1518638150340-f706e86654de?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?auto=format&fit=crop&w=1200&q=80',
      IMAGES.coconuts,
    ],
    whatsIncluded: [
      'Special sunrise pre-opening access permit through VIP archaeological gate',
      'Private tour led by distinguished Mesoamerican historian',
      'Chilled ceremonial cacao elixirs & fresh pastries upon arrival',
      'Professional scenic photography session against Caribbean cliffs',
      'Private roundtrip chauffeur escort in Mercedes Suburban',
    ],
    location: 'Tulum Archaeological Zone · Cliffside Sanctuary',
    timeSlots: ['6:30 AM (Sunrise Dawn Access)'],
  },

  // 8. Culture - Temazcal Ceremony
  {
    id: 'exp-temazcal',
    title: 'Ancestral Copal & Clay Temazcal Ceremony',
    category: 'Culture',
    duration: '2.5 Hours',
    priceType: 'FROM_PRICE',
    priceDisplay: 'FROM $320',
    availability: 'Sunset Daily · Secluded Forest',
    oneLineDescription: 'Traditional Mayan stone sweat lodge led by an authentic shaman with medicinal herbs and sound bowls.',
    fullDescription:
      'Step into an ancestral steam lodge nestled in the deep jungle for a sacred rebirth ceremony. Led by a local Mayan Xaman (shaman), red-hot volcanic stones are drenched with medicinal herb infusions and fragrant copal resin. The gentle darkness, healing songs, and ancient chants purify body, mind, and spirit.',
    heroImage: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=1200&q=80',
    gallery: [
      'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=1200&q=80',
      IMAGES.spa,
      'https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=1200&q=80',
    ],
    whatsIncluded: [
      'Private consecrated lodge session with traditional Mayan shaman',
      'Organic copal smoke purification & herbal water immersion',
      'Mineral-rich volcanic clay application and cold spring rinse',
      'Traditional medicinal tea ceremony and local seasonal fruits',
      'Plush organic linen robes and footwear provided',
    ],
    location: 'Kachava Jungle Botanical Sanctuary',
    timeSlots: ['4:30 PM – 7:00 PM (Twilight Healing)'],
  },

  // 9. Yacht - Sunset Cruise
  {
    id: 'exp-sunset-yacht',
    title: 'Sunset Champagne & Bioluminescent Lagoon Cruise',
    category: 'Yacht',
    duration: '3.5 Hours',
    priceType: 'FROM_PRICE',
    priceDisplay: 'FROM $650',
    availability: 'Limited to 2 evenings per week',
    oneLineDescription: 'Twilight sail into glowing lagoon channels with sommelier champagne service and night swimming.',
    fullDescription:
      'Embark at golden hour for an enchanting journey into the quiet mangrove lagoons where microscopic organisms illuminate the dark waters with neon blue sparkles. Sip vintage Dom Pérignon poured by your sommelier while drifting under a canopy of Caribbean stars.',
    heroImage: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=1200&q=80',
    gallery: [
      'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=1200&q=80',
      IMAGES.yacht,
      'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?auto=format&fit=crop&w=1200&q=80',
    ],
    whatsIncluded: [
      'Private 44ft Catamaran sunset charter',
      'Bottle of chilled Dom Pérignon champagne & caviar canapés',
      'Guided bioluminescent night swim with safety divers',
      'Star constellation storytelling by local navigator',
      'Private roundtrip luxury vehicle transfer',
    ],
    location: 'Boca Paila South Lagoon & Barrier Reef',
    timeSlots: ['5:00 PM – 8:30 PM (Sunset & Starlight)'],
    actionScreen: 'yacht',
  },

  // 10. Dining - Wild Agave Tasting
  {
    id: 'exp-mezcal',
    title: 'Wild Agave & Oaxacan Mole Degustation',
    category: 'Dining',
    duration: '2 Hours',
    priceType: 'FROM_PRICE',
    priceDisplay: 'FROM $190',
    availability: 'Nightly 7:00 PM · Agave Garden',
    oneLineDescription: 'Rare ancestral mezcal flight paired with five regional single-origin moles in the agave courtyard.',
    fullDescription:
      'Explore Mexico’s liquid heritage through single-village, ancestral clay-distilled mezcals. Guided by Kachava’s master Mezcalier, each rare pour is paired with handcrafted artisanal moles made from heritage chilies, native herbs, and stone-ground Criollo cacao.',
    heroImage: IMAGES.mezcalTequila,
    gallery: [
      IMAGES.mezcalTequila,
      IMAGES.dinnerChef,
      IMAGES.guacamoleBoard,
    ],
    whatsIncluded: [
      'Flight of 5 rare, artisanal wild-harvested mezcals (Tobalá, Tepeztate, Arroqueño)',
      'Tasting of 5 regional Oaxacan moles crafted over 72 hours',
      'House-pressed heirloom blue corn tortillas and pairing bites',
      'Storytelling by certified Master Mezcalier',
      'Commemorative hand-blown copita glass to keep',
    ],
    location: 'Kachava Secret Agave Courtyard',
    timeSlots: ['7:00 PM', '9:00 PM'],
    actionScreen: 'dining',
  },
];

export const ExploreScreen: React.FC<ExploreScreenProps> = ({ onNavigate }) => {
  const [selectedCategory, setSelectedCategory] = useState<ExploreCategory>('All');
  const [activeExperience, setActiveExperience] = useState<DetailedExperience | null>(null);
  const [selectedGalleryImg, setSelectedGalleryImg] = useState<string | null>(null);
  const [selectedDate, setSelectedDate] = useState<string>('Nov 13');
  const [selectedTime, setSelectedTime] = useState<string>('');
  const [bookingToast, setBookingToast] = useState<string | null>(null);
  const [scheduledExperiences, setScheduledExperiences] = useState<string[]>([]);

  const filterCategories: ExploreCategory[] = [
    'All',
    'Included',
    'Yacht',
    'Wellness',
    'Dining',
    'Adventure',
    'Culture',
  ];

  // Sarah's unused benefits (all included items that haven't been scheduled yet)
  const unusedBenefits = EXPERIENCES_DATA.filter((exp) => exp.priceType === 'INCLUDED');

  // Filter experiences based on selected category
  const filteredExperiences = EXPERIENCES_DATA.filter((exp) => {
    if (selectedCategory === 'All') return true;
    if (selectedCategory === 'Included') return exp.priceType === 'INCLUDED';
    return exp.category === selectedCategory;
  }).sort((a, b) => {
    // Prioritize INCLUDED experiences for this guest
    if (a.priceType === 'INCLUDED' && b.priceType !== 'INCLUDED') return -1;
    if (a.priceType !== 'INCLUDED' && b.priceType === 'INCLUDED') return 1;
    return 0;
  });

  const handleOpenDetail = (exp: DetailedExperience) => {
    setActiveExperience(exp);
    setSelectedGalleryImg(exp.heroImage);
    setSelectedDate('Nov 13');
    setSelectedTime(exp.timeSlots[0] || '10:00 AM');
  };

  const handleCloseDetail = () => {
    setActiveExperience(null);
    setSelectedGalleryImg(null);
  };

  const handleConfirmBooking = () => {
    if (!activeExperience) return;
    const isAlready = scheduledExperiences.includes(activeExperience.id);
    if (!isAlready) {
      setScheduledExperiences((prev) => [...prev, activeExperience.id]);
    }
    const message = `${activeExperience.title} confirmed for ${selectedDate} at ${selectedTime}. Majordomo Eduardo notified.`;
    handleCloseDetail();
    showToast(message);
  };

  const showToast = (msg: string) => {
    setBookingToast(msg);
    setTimeout(() => setBookingToast(null), 3800);
  };

  return (
    <div className="flex flex-col w-full pb-28 pt-2">
      {/* Toast Notification */}
      {bookingToast && (
        <div className="fixed top-20 left-1/2 -translate-x-1/2 z-50 bg-[#564121] text-white px-4 py-2.5 rounded-full text-[12px] font-medium shadow-xl animate-in fade-in slide-in-from-top-2 duration-200 flex items-center gap-2 max-w-[90vw]">
          <span className="material-symbols-outlined text-[17px] text-[#febe4f] shrink-0">check_circle</span>
          <span className="truncate">{bookingToast}</span>
        </div>
      )}

      {/* TOP SECTION: INCLUDED WITH YOUR STAY (Sarah's Unused Benefits First) */}
      <section className="px-5 pt-3 pb-5 bg-gradient-to-b from-[#f7f3ea]/90 to-transparent">
        <div className="flex items-center justify-between mb-1">
          <span className="font-label-sm text-[9px] uppercase tracking-[0.2em] text-[#7f5700] font-bold">
            VILLA 102 PRIVILEGES
          </span>
          <span className="font-label-sm text-[9px] uppercase tracking-wider text-[#3b6d41] bg-[#eef5ed] px-2 py-0.5 rounded-full font-semibold">
            {unusedBenefits.length} Benefits Available
          </span>
        </div>

        <h2 className="font-serif text-[22px] text-[#564121] font-medium leading-tight mb-1">
          INCLUDED WITH YOUR STAY
        </h2>
        <p className="font-sans text-[12px] text-[#5e5449] leading-relaxed mb-3">
          Complimentary private experiences curated for Sarah Miller. Tap to schedule with your majordomo.
        </p>

        {/* Horizontal Carousel of Unused Benefits */}
        <div className="flex gap-3 overflow-x-auto no-scrollbar -mx-5 px-5 pb-2 pt-0.5">
          {unusedBenefits.map((benefit) => {
            const isScheduled = scheduledExperiences.includes(benefit.id);
            return (
              <div
                key={`benefit-${benefit.id}`}
                onClick={() => handleOpenDetail(benefit)}
                className="shrink-0 w-[240px] bg-white rounded-2xl border border-[#e6e2d9] overflow-hidden shadow-xs hover:shadow-md cursor-pointer transition-all active:scale-[0.98] flex flex-col"
              >
                <div className="relative h-28 w-full bg-[#ece8df]">
                  <img
                    src={benefit.heroImage}
                    alt={benefit.title}
                    className="w-full h-full object-cover"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent" />
                  <span className="absolute top-2.5 left-2.5 bg-[#564121] text-white text-[8px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-md shadow-xs">
                    {isScheduled ? 'SCHEDULED ✓' : 'UNUSED BENEFIT'}
                  </span>
                  <span className="absolute bottom-2 right-2 text-white/95 text-[10px] font-medium bg-black/40 backdrop-blur-xs px-2 py-0.5 rounded">
                    {benefit.duration}
                  </span>
                </div>

                <div className="p-3 flex-1 flex flex-col justify-between">
                  <div>
                    <h3 className="font-serif text-[15px] font-medium text-[#564121] leading-snug line-clamp-1">
                      {benefit.title}
                    </h3>
                    <p className="font-sans text-[11px] text-[#7f756a] mt-0.5 line-clamp-1">
                      {benefit.availability}
                    </p>
                  </div>

                  <div className="mt-2.5 pt-2 border-t border-[#f1ede5] flex items-center justify-between">
                    <span className="text-[10px] font-bold text-[#7f5700] uppercase tracking-wider">
                      $0 · INCLUDED
                    </span>
                    <span className="text-[10px] font-semibold text-[#564121] flex items-center gap-0.5 hover:underline">
                      <span>{isScheduled ? 'View Details' : 'Schedule'}</span>
                      <span className="material-symbols-outlined text-[13px]">chevron_right</span>
                    </span>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </section>

      {/* MAIN SECTION: EXPLORE YOUR KACHAVA */}
      <div className="px-5 pt-2 pb-1">
        <h1 className="font-serif text-[26px] text-[#564121] font-normal tracking-tight">
          EXPLORE YOUR KACHAVA
        </h1>
        <p className="font-sans text-[12px] text-[#5e5449] mt-0.5">
          Curated private encounters, sanctuary rituals, and unhurried expeditions.
        </p>
      </div>

      {/* HORIZONTAL CATEGORY FILTERS: All | Included | Yacht | Wellness | Dining | Adventure | Culture */}
      <div className="w-full overflow-x-auto no-scrollbar px-5 py-3 flex items-center gap-1.5">
        {filterCategories.map((category) => {
          const isActive = selectedCategory === category;
          return (
            <button
              key={category}
              onClick={() => setSelectedCategory(category)}
              className={`whitespace-nowrap px-3.5 py-1.5 rounded-full text-[11px] font-semibold tracking-wider transition-all uppercase ${
                isActive
                  ? 'bg-[#564121] text-white shadow-xs'
                  : 'bg-white text-[#564121] border border-[#e6e2d9] hover:bg-[#fcfaf5]'
              }`}
            >
              {category}
            </button>
          );
        })}
      </div>

      {/* FEED OF EXPERIENCE CARDS (STRICTLY: Photo, Name, Duration, INCLUDED or FROM $XXX, Availability, Short one-line desc) */}
      <div className="px-5 pt-1 space-y-4">
        {filteredExperiences.map((exp) => {
          const isIncluded = exp.priceType === 'INCLUDED';
          const isScheduled = scheduledExperiences.includes(exp.id);

          return (
            <article
              key={exp.id}
              onClick={() => handleOpenDetail(exp)}
              className="bg-white border border-[#e6e2d9] rounded-2xl overflow-hidden shadow-xs hover:shadow-md cursor-pointer transition-all active:scale-[0.99] flex flex-col group"
            >
              {/* Photo */}
              <div className="relative w-full aspect-[16/9] bg-[#ece8df] overflow-hidden">
                <img
                  src={exp.heroImage}
                  alt={exp.title}
                  className="w-full h-full object-cover group-hover:scale-[1.02] transition-transform duration-500"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-black/15" />

                {/* Top Badges: Price & Duration */}
                <div className="absolute top-3 left-3 right-3 flex items-center justify-between">
                  <span
                    className={`text-[9px] font-bold uppercase tracking-widest px-2.5 py-1 rounded-md shadow-xs ${
                      isIncluded
                        ? 'bg-[#564121] text-white'
                        : 'bg-white/95 backdrop-blur-xs text-[#564121] font-semibold'
                    }`}
                  >
                    {isScheduled ? 'SCHEDULED ✓' : exp.priceDisplay}
                  </span>

                  <span className="text-[10px] text-white/95 font-medium bg-black/40 backdrop-blur-xs px-2.5 py-1 rounded-md">
                    {exp.duration}
                  </span>
                </div>

                {/* Bottom Overlay: Availability Indicator */}
                <div className="absolute bottom-2.5 left-3 right-3 flex items-center justify-between text-white">
                  <div className="flex items-center gap-1.5 text-[11px] font-medium">
                    <span className="w-1.5 h-1.5 rounded-full bg-[#febe4f] animate-pulse" />
                    <span className="truncate">{exp.availability}</span>
                  </div>
                  <span className="text-[10px] uppercase tracking-wider text-[#ffddb2] font-semibold flex items-center gap-0.5">
                    Explore
                    <span className="material-symbols-outlined text-[13px]">arrow_forward</span>
                  </span>
                </div>
              </div>

              {/* Card Text Content (STRICTLY minimal: Name + One-line description) */}
              <div className="p-3.5">
                <div className="flex items-baseline justify-between gap-2">
                  <h3 className="font-serif text-[17px] font-medium text-[#564121] leading-snug">
                    {exp.title}
                  </h3>
                </div>

                <p className="font-sans text-[12px] text-[#5e5449] mt-1 line-clamp-1 leading-relaxed">
                  {exp.oneLineDescription}
                </p>
              </div>
            </article>
          );
        })}

        {filteredExperiences.length === 0 && (
          <div className="text-center py-12 px-4 bg-white rounded-2xl border border-[#e6e2d9]">
            <span className="material-symbols-outlined text-[32px] text-[#7f756a] mb-2">filter_alt_off</span>
            <p className="text-[14px] text-[#564121] font-serif font-medium">No experiences found in this category</p>
            <p className="text-[12px] text-[#7f756a] mt-1">Select “All” or choose another category filter.</p>
          </div>
        )}
      </div>

      {/* BESPOKE CONCIERGE BANNER */}
      <div className="px-5 pt-8">
        <div className="bg-[#f7f3ea] border border-[#e6e2d9] p-5 rounded-2xl flex flex-col items-center text-center gap-2">
          <span className="material-symbols-outlined text-[#7f5700] text-[24px]">explore</span>
          <h3 className="font-serif text-[18px] text-[#564121] font-medium">
            Custom Unlisted Encounters
          </h3>
          <p className="font-sans text-[12px] text-[#5e5449] max-w-xs leading-relaxed">
            Have a private wish beyond our curated collection? Majordomo Eduardo can tailor any bespoke Yucatan itinerary.
          </p>
          <button
            onClick={() => onNavigate('concierge')}
            className="mt-2 inline-flex items-center gap-1.5 bg-[#564121] text-white px-5 py-2.5 rounded-xl text-[10px] font-semibold uppercase tracking-wider hover:bg-[#6c532d] transition-colors"
          >
            <span className="material-symbols-outlined text-[15px]">chat</span>
            <span>Message Eduardo</span>
          </button>
        </div>
      </div>

      {/* COMPLETE EXPERIENCE DETAIL PAGE / MODAL */}
      {activeExperience && (
        <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4 bg-black/60 backdrop-blur-xs animate-in fade-in duration-200">
          <div className="w-full max-w-md bg-[#fdf9f0] rounded-t-3xl sm:rounded-2xl shadow-2xl border border-[#d1c5b8] max-h-[92vh] flex flex-col overflow-hidden animate-in slide-in-from-bottom-4 duration-300">
            {/* Modal Top Bar */}
            <div className="px-5 py-3.5 border-b border-[#e6e2d9] bg-white flex items-center justify-between shrink-0">
              <div className="flex items-center gap-2">
                <span className="text-[9px] uppercase font-bold tracking-widest text-[#7f5700] bg-[#fbf6ed] border border-[#f0e3cc] px-2 py-0.5 rounded-md">
                  {activeExperience.category}
                </span>
                <span
                  className={`text-[9px] uppercase font-bold tracking-widest px-2 py-0.5 rounded-md ${
                    activeExperience.priceType === 'INCLUDED'
                      ? 'bg-[#564121] text-white'
                      : 'bg-[#ece8df] text-[#564121]'
                  }`}
                >
                  {activeExperience.priceDisplay}
                </span>
              </div>

              <button
                onClick={handleCloseDetail}
                className="w-8 h-8 rounded-full bg-[#ece8df] hover:bg-[#dfd9cd] flex items-center justify-center text-[#564121] transition-colors"
                aria-label="Close details"
              >
                <span className="material-symbols-outlined text-[18px]">close</span>
              </button>
            </div>

            {/* Modal Scrollable Body */}
            <div className="overflow-y-auto px-5 py-4 space-y-4 flex-1">
              {/* Hero Image & Interactive Gallery */}
              <div className="space-y-2">
                <div className="w-full aspect-[16/9.5] rounded-2xl overflow-hidden border border-[#e6e2d9] bg-[#ece8df] shadow-xs">
                  <img
                    src={selectedGalleryImg || activeExperience.heroImage}
                    alt={activeExperience.title}
                    className="w-full h-full object-cover transition-all duration-300"
                  />
                </div>

                {/* Thumbnails */}
                {activeExperience.gallery.length > 1 && (
                  <div className="flex gap-2 overflow-x-auto no-scrollbar py-0.5">
                    {activeExperience.gallery.map((img, idx) => {
                      const isSelected = (selectedGalleryImg || activeExperience.heroImage) === img;
                      return (
                        <button
                          key={`thumb-${idx}`}
                          onClick={() => setSelectedGalleryImg(img)}
                          className={`w-16 h-12 rounded-lg overflow-hidden shrink-0 border-2 transition-all ${
                            isSelected ? 'border-[#7f5700] scale-105' : 'border-transparent opacity-70 hover:opacity-100'
                          }`}
                        >
                          <img src={img} alt="Thumbnail" className="w-full h-full object-cover" />
                        </button>
                      );
                    })}
                  </div>
                )}
              </div>

              {/* Title & Core Meta */}
              <div>
                <h2 className="font-serif text-[22px] font-medium text-[#564121] leading-tight">
                  {activeExperience.title}
                </h2>
                <div className="flex flex-wrap items-center gap-y-1 gap-x-3 text-[11px] text-[#7f756a] mt-1.5">
                  <span className="flex items-center gap-1 font-medium text-[#564121]">
                    <span className="material-symbols-outlined text-[15px] text-[#7f5700]">schedule</span>
                    {activeExperience.duration}
                  </span>
                  <span>•</span>
                  <span className="flex items-center gap-1">
                    <span className="material-symbols-outlined text-[15px] text-[#7f5700]">location_on</span>
                    {activeExperience.location}
                  </span>
                  <span>•</span>
                  <span className="flex items-center gap-1 text-[#3b6d41] font-medium">
                    <span className="material-symbols-outlined text-[15px]">event_available</span>
                    {activeExperience.availability}
                  </span>
                </div>
              </div>

              {/* Editorial Narrative Description */}
              <div className="bg-white p-4 rounded-xl border border-[#e6e2d9]">
                <h4 className="text-[10px] uppercase font-bold tracking-widest text-[#7f756a] mb-1.5">
                  The Experience
                </h4>
                <p className="font-sans text-[13px] text-[#4e453c] leading-relaxed">
                  {activeExperience.fullDescription}
                </p>
              </div>

              {/* What's Included */}
              <div className="bg-white p-4 rounded-xl border border-[#e6e2d9] space-y-2">
                <h4 className="text-[10px] uppercase font-bold tracking-widest text-[#7f756a]">
                  What's Included
                </h4>
                <ul className="space-y-2">
                  {activeExperience.whatsIncluded.map((item, idx) => (
                    <li key={`inc-${idx}`} className="flex items-start gap-2 text-[12px] text-[#4e453c]">
                      <span className="material-symbols-outlined text-[16px] text-[#7f5700] shrink-0 mt-0.5">
                        check
                      </span>
                      <span>{item}</span>
                    </li>
                  ))}
                </ul>
              </div>

              {/* DATE & TIME SELECTION */}
              <div className="bg-[#f7f3ea] p-4 rounded-xl border border-[#e6e2d9] space-y-3">
                <h4 className="text-[10px] uppercase font-bold tracking-widest text-[#564121]">
                  Select Date &amp; Time
                </h4>

                {/* Stay Dates: Nov 12 - Nov 16 */}
                <div>
                  <label className="text-[10px] uppercase font-semibold text-[#7f756a] block mb-1.5">
                    Residency Date (Sarah Miller · Villa 102)
                  </label>
                  <div className="grid grid-cols-5 gap-1.5 text-center">
                    {[
                      { day: 'Wed', date: 'Nov 12' },
                      { day: 'Thu', date: 'Nov 13' },
                      { day: 'Fri', date: 'Nov 14' },
                      { day: 'Sat', date: 'Nov 15' },
                      { day: 'Sun', date: 'Nov 16' },
                    ].map((d) => {
                      const isSelected = selectedDate === d.date;
                      return (
                        <button
                          key={d.date}
                          onClick={() => setSelectedDate(d.date)}
                          className={`py-2 rounded-lg text-center transition-all ${
                            isSelected
                              ? 'bg-[#564121] text-white font-semibold shadow-xs'
                              : 'bg-white text-[#564121] border border-[#e6e2d9] hover:bg-[#ece8df]'
                          }`}
                        >
                          <span className="text-[9px] block uppercase opacity-80">{d.day}</span>
                          <span className="text-[11px] block font-bold">{d.date.replace('Nov ', '')}</span>
                        </button>
                      );
                    })}
                  </div>
                </div>

                {/* Available Time Slots */}
                <div>
                  <label className="text-[10px] uppercase font-semibold text-[#7f756a] block mb-1.5">
                    Preferred Time Slot
                  </label>
                  <div className="space-y-1.5">
                    {activeExperience.timeSlots.map((slot) => {
                      const isSelected = selectedTime === slot;
                      return (
                        <button
                          key={slot}
                          onClick={() => setSelectedTime(slot)}
                          className={`w-full py-2.5 px-3 rounded-lg text-left text-[12px] flex items-center justify-between border transition-all ${
                            isSelected
                              ? 'bg-white border-[#7f5700] text-[#564121] font-semibold shadow-xs'
                              : 'bg-white/80 border-[#e6e2d9] text-[#564121] hover:bg-white'
                          }`}
                        >
                          <span>{slot}</span>
                          <span
                            className={`w-4 h-4 rounded-full border flex items-center justify-center ${
                              isSelected ? 'border-[#7f5700] bg-[#7f5700] text-white' : 'border-[#d1c5b8]'
                            }`}
                          >
                            {isSelected && <span className="material-symbols-outlined text-[12px]">check</span>}
                          </span>
                        </button>
                      );
                    })}
                  </div>
                </div>

                {/* Party Size */}
                <div className="pt-1 flex items-center justify-between text-[12px] text-[#564121]">
                  <span className="font-medium">Guests</span>
                  <span className="font-semibold bg-white border border-[#e6e2d9] px-3 py-1 rounded-md">
                    2 Guests (Villa 102)
                  </span>
                </div>
              </div>

              {/* Dedicated portal link if present */}
              {activeExperience.actionScreen && (
                <div className="text-center pt-1">
                  <button
                    onClick={() => {
                      const screen = activeExperience.actionScreen!;
                      handleCloseDetail();
                      onNavigate(screen);
                    }}
                    className="text-[11px] text-[#7f5700] underline font-medium"
                  >
                    Open dedicated {activeExperience.title} portal →
                  </button>
                </div>
              )}
            </div>

            {/* Modal Sticky Booking Footer */}
            <div className="p-4 bg-white border-t border-[#e6e2d9] flex items-center gap-3 shrink-0">
              <div className="shrink-0">
                <span className="text-[9px] uppercase font-bold text-[#7f756a] block tracking-wider">
                  Total Folio Charge
                </span>
                <span className="font-serif text-[17px] font-semibold text-[#564121]">
                  {activeExperience.priceType === 'INCLUDED' ? '$0 USD (Included)' : activeExperience.priceDisplay}
                </span>
              </div>

              <button
                onClick={handleConfirmBooking}
                className="flex-1 bg-[#564121] hover:bg-[#6c532d] text-white py-3.5 px-4 rounded-xl text-[11px] font-semibold uppercase tracking-[0.14em] flex items-center justify-center gap-2 transition-colors shadow-sm"
              >
                <span className="material-symbols-outlined text-[17px]">
                  {activeExperience.priceType === 'INCLUDED' ? 'task_alt' : 'calendar_month'}
                </span>
                <span>
                  {activeExperience.priceType === 'INCLUDED'
                    ? 'CONFIRM BENEFIT'
                    : 'RESERVE EXPERIENCE'}
                </span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
