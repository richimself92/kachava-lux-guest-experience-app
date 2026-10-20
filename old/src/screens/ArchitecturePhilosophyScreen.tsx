import React from 'react';
import { ScreenId } from '../types';
import { IMAGES } from '../data/sanctuaryData';

interface ArchitecturePhilosophyScreenProps {
  onNavigate: (screen: ScreenId) => void;
  isSoundscapeActive?: boolean;
  onToggleSoundscape?: () => void;
}

export const ArchitecturePhilosophyScreen: React.FC<ArchitecturePhilosophyScreenProps> = ({
  onNavigate,
  isSoundscapeActive = false,
  onToggleSoundscape,
}) => {
  return (
    <div className="flex flex-col w-full pb-32 pt-2">
      
      {/* Sanctuary Soundscape Bar */}
      <div className="px-5 pt-2">
        <div
          onClick={onToggleSoundscape}
          className="p-3 rounded-2xl bg-[#ece8df] border border-[#d1c5b8]/50 flex items-center justify-between cursor-pointer hover:bg-[#e6e2d9] transition-colors shadow-xs"
        >
          <div className="flex items-center gap-3">
            <button
              className={`w-9 h-9 rounded-full flex items-center justify-center transition-all ${
                isSoundscapeActive ? 'bg-[#a67d52] text-white shadow-xs' : 'bg-[#754d24] text-white'
              }`}
            >
              <span className="material-symbols-outlined text-[20px]">
                {isSoundscapeActive ? 'pause' : 'play_arrow'}
              </span>
            </button>
            <div>
              <span className="font-label-sm text-[8px] uppercase tracking-widest text-[#a67d52] font-bold block">
                Sanctuary Soundscape · 432Hz
              </span>
              <h4 className="text-[12px] font-semibold text-[#754d24]">
                Sacred Cenote &amp; Wild Ceiba Breeze
              </h4>
            </div>
          </div>

          <div className="flex items-center gap-1">
            <span className={`w-1 h-3 bg-[#a67d52] rounded-full ${isSoundscapeActive ? 'animate-pulse' : 'opacity-40'}`}></span>
            <span className={`w-1 h-5 bg-[#a67d52] rounded-full ${isSoundscapeActive ? 'animate-pulse delay-75' : 'opacity-40'}`}></span>
            <span className={`w-1 h-2 bg-[#a67d52] rounded-full ${isSoundscapeActive ? 'animate-pulse delay-150' : 'opacity-40'}`}></span>
          </div>
        </div>
      </div>

      {/* Main Philosophy Introduction */}
      <div className="px-5 pt-6 space-y-2">
        <span className="font-label-sm text-[10px] uppercase tracking-widest text-[#a67d52] font-bold block">
          Sanctuary Essence &amp; Philosophy · Est. 2019
        </span>

        <h1 className="font-headline-lg text-[#754d24] tracking-tight leading-tight">
          The Architecture of Stillness
        </h1>

        <p className="font-body-md text-[14px] text-[#4e453c] leading-relaxed">
          Born from the limestone bedrock, cenote waters, and sacred Mayan resin of Quintana Roo, Kachava Lux was conceived not merely as a residence, but as a living temple to unhurried time.
        </p>

        <div className="flex items-center gap-2 pt-1 text-[11px] text-[#7f756a]">
          <span className="material-symbols-outlined text-[15px] text-[#a67d52]">auto_stories</span>
          <span>WORDS BY ELENA VALDÉS, SANCTUARY DIRECTOR · 6 MIN READ</span>
        </div>
      </div>

      {/* Hero Architectural Photo */}
      <div className="px-5 pt-5">
        <div className="relative rounded-2xl overflow-hidden shadow-sm border border-[#e6e2d9]">
          <img
            src={IMAGES.chukumCourtyard}
            alt="Sacred Courtyard & Pool"
            className="w-full h-64 object-cover"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-transparent"></div>
          
          <div className="absolute bottom-3 left-4 right-4 flex items-end justify-between text-white">
            <div>
              <span className="font-label-sm text-[8px] uppercase tracking-wider text-[#f7e8d0] block">
                Sanctuary Pavilion
              </span>
              <h3 className="font-headline-sm text-[18px] text-white">
                Sacred Courtyard &amp; Pool
              </h3>
            </div>
            <span className="font-mono text-[10px] text-white/80">20° 12' N</span>
          </div>
        </div>
      </div>

      {/* Architectural Quote */}
      <div className="px-5 pt-6">
        <div className="p-5 rounded-2xl bg-[#f7f3ea] border border-[#e6e2d9] space-y-2">
          <span className="text-[32px] text-[#a67d52] font-serif leading-none block">“</span>
          <p className="font-headline-sm text-[17px] text-[#754d24] italic leading-relaxed -mt-4">
            We did not clear the jungle to build villas. We listened to the ancient sapote trees and carved our sanctuaries within their breath.
          </p>
          <div className="pt-2 border-t border-[#e6e2d9] text-[11px] text-[#7f756a]">
            — ARQ. JAVIER MUÑOZ · LEAD ARCHITECT &amp; CHUKUM MASTER
          </div>
        </div>
      </div>

      {/* Chapter 1: Chukum */}
      <div className="px-5 pt-8 space-y-3">
        <span className="font-label-sm text-[9px] uppercase tracking-widest text-[#a67d52] font-bold block">
          Chapter 01 · Ancestral Materiality
        </span>

        <h2 className="font-headline-sm text-[21px] text-[#754d24] leading-tight">
          Chukum: The Tree That Cools the Stone
        </h2>

        <p className="text-[13px] text-[#4e453c] leading-relaxed">
          Centuries before modern waterproofing, the ancient Maya boiled the bark of the endemic Chukum tree (<em>Havardia albicans</em>), blending the extracted resin with softened limestone. This sacred alchemy bestows Kachava's walls with their signature velvety, cool-to-touch skin—a living, breathable barrier that naturally resists jungle heat and captures the warmth of fading sunsets.
        </p>

        <div className="rounded-2xl overflow-hidden border border-[#e6e2d9] my-3">
          <img src={IMAGES.chukumWall} alt="Chukum Texture" className="w-full h-44 object-cover" />
        </div>

        <div className="space-y-2 pt-1">
          <div className="p-3 rounded-xl bg-white border border-[#e6e2d9] flex items-start gap-3">
            <span className="material-symbols-outlined text-[#a67d52] text-[18px] shrink-0 mt-0.5">spa</span>
            <div>
              <span className="font-label-sm text-[9px] uppercase text-[#a67d52] font-bold block">Endemic Resin</span>
              <p className="text-[11px] text-[#4e453c] mt-0.5">
                100% natural organic harvest extracted solely from aged bark, replenishing local jungle soil.
              </p>
            </div>
          </div>

          <div className="p-3 rounded-xl bg-white border border-[#e6e2d9] flex items-start gap-3">
            <span className="material-symbols-outlined text-[#a67d52] text-[18px] shrink-0 mt-0.5">ac_unit</span>
            <div>
              <span className="font-label-sm text-[9px] uppercase text-[#a67d52] font-bold block">Sub-Zero Thermal Mass</span>
              <p className="text-[11px] text-[#4e453c] mt-0.5">
                Maintains interior ambient temperatures at 71°F naturally, eliminating harsh artificial cooling.
              </p>
            </div>
          </div>

          <div className="p-3 rounded-xl bg-white border border-[#e6e2d9] flex items-start gap-3">
            <span className="material-symbols-outlined text-[#a67d52] text-[18px] shrink-0 mt-0.5">palette</span>
            <div>
              <span className="font-label-sm text-[9px] uppercase text-[#a67d52] font-bold block">Living Patina</span>
              <p className="text-[11px] text-[#4e453c] mt-0.5">
                Gradually deepens into a warm rose-ochre tint with sea breezes, humidity, and tropical rains.
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Chapter 2: Cenotes & 1% Biosphere */}
      <div className="px-5 pt-8 space-y-3">
        <span className="font-label-sm text-[9px] uppercase tracking-widest text-[#a67d52] font-bold block">
          Chapter 02 · Hydrological Guardianship
        </span>

        <h2 className="font-headline-sm text-[21px] text-[#754d24] leading-tight">
          Cenotes: The Mirror of the Underworld
        </h2>

        <p className="text-[13px] text-[#4e453c] leading-relaxed">
          Directly beneath Kachava Lux weaves the sacred Sac Actun subterranean river system—revered by Maya ancestors as the threshold to <em>Xibalba</em>. Our sanctuary honors these fragile waters through a zero-chemical, closed-loop treatment sanctuary powered by endemic macro-algae wetlands. Every plunge pool is pure, mineralized limestone rainwater.
        </p>

        {/* 1% Biosphere Covenant */}
        <div className="p-5 rounded-2xl bg-[#754d24] text-white space-y-3 shadow-md">
          <div className="flex items-center justify-between">
            <span className="font-label-sm text-[9px] uppercase tracking-widest text-[#f7e8d0] font-bold">
              The Sian Ka'an Covenant
            </span>
            <span className="material-symbols-outlined text-[#f7e8d0] text-[18px]">water_drop</span>
          </div>

          <h3 className="font-headline-sm text-[24px] text-white leading-none">
            1% Biosphere
          </h3>

          <p className="text-[12px] text-white/90 leading-relaxed">
            Every reserved evening in Villa 102 finances the conservation of 45 hectares of the Sian Ka'an marine biosphere and nurtures indigenous Melipona stingless bee sanctuaries.
          </p>

          <div className="grid grid-cols-2 gap-2 pt-2 border-t border-white/20">
            <div>
              <span className="font-headline-sm text-[20px] text-[#f7e8d0] block leading-none">1,820 ha</span>
              <span className="font-label-sm text-[8px] uppercase tracking-wider text-white/80">Preserved Forest</span>
            </div>
            <div>
              <span className="font-headline-sm text-[20px] text-[#f7e8d0] block leading-none">34 Hives</span>
              <span className="font-label-sm text-[8px] uppercase tracking-wider text-white/80">Melipona Colonies</span>
            </div>
          </div>
        </div>
      </div>

      {/* Chapter 3: Flavors Born of Fire and Earth */}
      <div className="px-5 pt-8 space-y-3">
        <span className="font-label-sm text-[9px] uppercase tracking-widest text-[#a67d52] font-bold block">
          Chapter 03 · Kitchen As Altar
        </span>

        <h2 className="font-headline-sm text-[21px] text-[#754d24] leading-tight">
          Flavors Born of Fire and Earth
        </h2>

        <p className="text-[13px] text-[#4e453c] leading-relaxed">
          Executive Chef Mateo looks not to imported delicacies, but to the rich traditions of the 40-mile radius. Working intimately with Maya milpa cooperatives in Punta Allen and Valladolid, each course is an unhurried communion prepared over scented copal smoke and glowing underground <em>pib</em> pits.
        </p>

        <div className="grid grid-cols-2 gap-2 my-2">
          <img src={IMAGES.fireCooking} alt="Pib cooking" className="w-full h-32 object-cover rounded-xl" />
          <img src={IMAGES.tortillas} alt="Heirloom masa" className="w-full h-32 object-cover rounded-xl" />
        </div>

        <div className="p-3 rounded-xl bg-[#f7f3ea] border border-[#e6e2d9] flex items-center justify-between text-xs text-[#754d24]">
          <div>
            <span className="font-label-sm text-[8px] uppercase text-[#a67d52] font-bold block">Sacred Milpa Harvest</span>
            <span className="font-semibold">Zero processed imports · Heirloom seeds only</span>
          </div>
          <span className="material-symbols-outlined text-[#a67d52] text-[20px]">eco</span>
        </div>
      </div>

      {/* Living Sanctuary Rituals / Immersions */}
      <div className="px-5 pt-8 space-y-3">
        <span className="font-label-sm text-[9px] uppercase tracking-widest text-[#a67d52] font-bold block">
          Living Sanctuary Rituals
        </span>

        <h2 className="font-headline-sm text-[21px] text-[#754d24] leading-tight">
          Immersions for Villa 102
        </h2>

        <div className="space-y-3 pt-1">
          {/* Ritual 1 */}
          <div className="p-4 rounded-2xl bg-white border border-[#e6e2d9] space-y-2">
            <div className="flex items-center justify-between">
              <span className="px-2 py-0.5 rounded bg-[#ffdead] text-[#a67d52] font-label-sm text-[8px] uppercase font-bold">
                Included for Villa 102
              </span>
              <span className="text-[11px] text-[#7f756a]">Daily · 5:30 PM</span>
            </div>

            <h4 className="font-headline-sm text-[16px] text-[#754d24]">
              Architectural &amp; Botanical Twilight Tour
            </h4>

            <p className="text-[12px] text-[#4e453c] leading-relaxed">
              Led by our resident historian and master botanist. Uncover the hidden pre-Hispanic limestone formations and 150-year-old sacred ceiba trees tucked within the preserve.
            </p>

            <button
              onClick={() => onNavigate('concierge')}
              className="w-full py-2.5 rounded-lg bg-[#754d24] hover:bg-[#8b6339] text-white font-label-md text-[10px] uppercase font-bold tracking-wider flex items-center justify-center gap-1.5 shadow-xs"
            >
              <span className="material-symbols-outlined text-[16px]">calendar_month</span>
              <span>Reserve Tour with Concierge</span>
            </button>
          </div>

          {/* Ritual 2 */}
          <div className="p-4 rounded-2xl bg-white border border-[#e6e2d9] space-y-2">
            <div className="flex items-center justify-between">
              <span className="px-2 py-0.5 rounded bg-[#ece8df] text-[#754d24] font-label-sm text-[8px] uppercase font-bold">
                Sanctuary Ceremony
              </span>
              <span className="text-[11px] text-[#7f756a]">90 Min</span>
            </div>

            <h4 className="font-headline-sm text-[16px] text-[#754d24]">
              Mayan Copal &amp; Sound Harmonization
            </h4>

            <p className="text-[12px] text-[#4e453c] leading-relaxed">
              Sunset acoustic alignment inside the open-air Chukum Rotunda. Deep resonant obsidian singing vessels paired with purified raw copal resin smoke.
            </p>

            <button
              onClick={() => onNavigate('concierge')}
              className="w-full py-2.5 rounded-lg bg-[#ece8df] hover:bg-[#e6e2d9] text-[#754d24] font-label-md text-[10px] uppercase font-bold tracking-wider flex items-center justify-center gap-1.5"
            >
              <span className="material-symbols-outlined text-[16px] text-[#a67d52]">spa</span>
              <span>Curate Private Session</span>
            </button>
          </div>
        </div>
      </div>

      {/* Elena Valdés Signoff Note */}
      <div className="px-5 pt-8">
        <div className="p-6 rounded-2xl bg-[#f7f3ea] border border-[#e6e2d9] text-center flex flex-col items-center gap-3">
          <img
            src={IMAGES.elenaPortrait}
            alt="Elena Valdés"
            className="w-14 h-14 rounded-full object-cover shadow-sm ring-2 ring-white"
          />

          <p className="font-headline-sm text-[17px] text-[#754d24] italic leading-snug">
            “With reverence to the land and unhurried hospitality.”
          </p>

          <div className="text-[11px] text-[#7f756a]">
            <span className="font-bold text-[#754d24] block">ELENA VALDÉS</span>
            <span>&amp; the 42 Maya Artisan Families of Quintana Roo</span>
          </div>

          <div className="flex items-center gap-1.5 pt-1 text-[#a67d52]">
            <span>•</span>
            <span>•</span>
            <span>•</span>
          </div>
        </div>
      </div>

    </div>
  );
};
