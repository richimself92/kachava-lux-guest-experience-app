import React, { useState } from 'react';
import { ScreenId } from '../types';
import { IMAGES } from '../data/sanctuaryData';

interface IncludedPrivilegesProps {
  onNavigate: (screen: ScreenId) => void;
}

export const IncludedPrivilegesScreen: React.FC<IncludedPrivilegesProps> = ({ onNavigate }) => {
  const [selectedSignature, setSelectedSignature] = useState<'massage' | 'golf'>('massage');
  const [toast, setToast] = useState<string | null>(null);

  const handleSelectSignature = (choice: 'massage' | 'golf') => {
    setSelectedSignature(choice);
    const label = choice === 'massage' ? 'In-Villa Chukum Massages' : 'PGA Riviera Maya Golf';
    setToast(`Bespoke benefit updated to ${label}. Coordinated with Concierge.`);
    setTimeout(() => setToast(null), 3000);
  };

  return (
    <div className="flex flex-col w-full pb-28 pt-2">
      
      {/* Toast */}
      {toast && (
        <div className="fixed top-20 left-1/2 -translate-x-1/2 z-50 bg-[#564121] text-white px-4 py-2 rounded-full text-xs font-medium shadow-lg animate-in fade-in duration-200">
          {toast}
        </div>
      )}

      {/* Header */}
      <div className="px-5 pt-3 pb-2 flex flex-col gap-1.5">
        <span className="font-label-sm text-[10px] uppercase tracking-widest text-[#7f5700] flex items-center gap-1.5 font-bold">
          <span className="w-1.5 h-1.5 rounded-full bg-[#7f5700]"></span>
          Sanctuary Bespoke Privileges
        </span>

        <h1 className="font-headline-lg text-[#564121] tracking-tight leading-tight mt-1">
          Included in Your Stay
        </h1>

        <p className="font-body-sm text-[13px] text-[#4e453c]">
          Complimentary privileges curated for Villa 102 · Nov 12–16
        </p>
      </div>

      {/* All-Inclusive Tier Banner */}
      <div className="px-5 pt-3">
        <div className="bg-[#f7f3ea] border border-[#e6e2d9] rounded-2xl p-4 flex items-center justify-between shadow-xs">
          <div className="flex items-start gap-3">
            <div className="w-9 h-9 rounded-xl bg-[#564121] text-[#ffddb2] flex items-center justify-center shrink-0 mt-0.5">
              <span className="material-symbols-outlined text-[20px]">shield</span>
            </div>
            <div>
              <span className="font-label-sm text-[9px] uppercase tracking-wider text-[#7f5700] font-bold block">
                All-Inclusive Sanctuary Tier
              </span>
              <p className="text-[12px] text-[#4e453c] mt-0.5">
                Zero hidden fees · Fully prepaid privilegefolio
              </p>
            </div>
          </div>

          <div className="text-right shrink-0 pl-2">
            <span className="font-headline-sm text-[18px] text-[#564121] block leading-none">
              $0.00
            </span>
            <span className="font-label-sm text-[9px] text-[#7f5700] uppercase font-bold">
              Due
            </span>
          </div>
        </div>
      </div>

      {/* List of Included Items */}
      <div className="px-5 pt-5 space-y-5">
        
        {/* Item 1: Artisanal Breakfast */}
        <article className="bg-white border border-[#e6e2d9] rounded-2xl overflow-hidden shadow-xs flex flex-col">
          <div className="relative h-48 w-full">
            <img
              src={IMAGES.breakfast}
              alt="Artisanal Breakfast"
              className="w-full h-full object-cover"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent"></div>
            
            <div className="absolute top-3 left-3 bg-[#fdf9f0]/90 backdrop-blur-md px-2.5 py-0.5 rounded-full text-[#7f5700] font-label-sm text-[9px] uppercase tracking-widest font-bold">
              Included · Daily
            </div>

            <div className="absolute bottom-3 left-4 right-4 flex items-end justify-between text-white">
              <h3 className="font-headline-sm text-[19px] text-white">
                Artisanal Breakfast
              </h3>
              <span className="font-label-sm text-[10px] uppercase text-[#ffddb2]">
                Villa or Pavilion
              </span>
            </div>
          </div>

          <div className="p-4 flex flex-col gap-2.5">
            <p className="text-[12px] text-[#4e453c] leading-relaxed">
              In-villa oceanfront terrace or poolside pavilion setting. Cold-pressed endemic juices, organic pasture-raised eggs, wood-fired sourdough, and heirloom Mayan chocolate pastries.
            </p>
            <div className="flex items-center gap-2 pt-2 border-t border-[#f1ede5] text-[11px] text-[#7f756a] font-medium">
              <span className="material-symbols-outlined text-[15px] text-[#7f5700]">restaurant</span>
              <span>SERVED 07:00 – 11:30 · NO RESERVATION REQUIRED</span>
            </div>
          </div>
        </article>

        {/* Item 2: Private Airport Chauffeur */}
        <article className="bg-white border border-[#e6e2d9] rounded-2xl overflow-hidden shadow-xs flex flex-col">
          <div className="relative h-48 w-full">
            <img
              src={IMAGES.chauffeurTransfer}
              alt="Private Airport Chauffeur"
              className="w-full h-full object-cover"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent"></div>
            
            <div className="absolute top-3 left-3 bg-[#fdf9f0]/90 backdrop-blur-md px-2.5 py-0.5 rounded-full text-[#7f5700] font-label-sm text-[9px] uppercase tracking-widest font-bold">
              Included · Round-Trip
            </div>

            <div className="absolute top-3 right-3 bg-[#febe4f] px-2.5 py-0.5 rounded-full text-[#564121] font-label-sm text-[9px] uppercase font-bold tracking-wider">
              Confirmed
            </div>

            <div className="absolute bottom-3 left-4 text-white">
              <h3 className="font-headline-sm text-[19px] text-white">
                Private Airport Chauffeur
              </h3>
            </div>
          </div>

          <div className="p-4 flex flex-col gap-2.5">
            <p className="text-[12px] text-[#4e453c] leading-relaxed">
              Private high-line luxury SUV transfer direct from CUN or Tulum International (TQO). Accompanied by cooled lemongrass towels, sparkling mineral water, and curated organic snacks.
            </p>
            <div className="flex items-center justify-between pt-2 border-t border-[#f1ede5] text-[11px]">
              <span className="text-[#564121] font-medium">ESCALADE ESV · SARAH MILLER</span>
              <button
                onClick={() => onNavigate('transport')}
                className="text-[#7f5700] font-bold uppercase font-label-sm text-[10px] tracking-wider hover:underline"
              >
                Flight Sync Active →
              </button>
            </div>
          </div>
        </article>

        {/* Item 3: Catamaran Voyage */}
        <article className="bg-white border border-[#e6e2d9] rounded-2xl overflow-hidden shadow-xs flex flex-col">
          <div className="relative h-48 w-full">
            <img
              src={IMAGES.yacht}
              alt="Half-Day Catamaran Voyage"
              className="w-full h-full object-cover"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent"></div>
            
            <div className="absolute top-3 left-3 bg-[#fdf9f0]/90 backdrop-blur-md px-2.5 py-0.5 rounded-full text-[#7f5700] font-label-sm text-[9px] uppercase tracking-widest font-bold">
              Included · Private
            </div>

            <div className="absolute top-3 right-3 bg-white/20 backdrop-blur-md px-2 py-0.5 rounded-full text-white font-label-sm text-[9px]">
              4 Hours
            </div>

            <div className="absolute bottom-3 left-4 text-white">
              <h3 className="font-headline-sm text-[19px] text-white">
                Half-Day Catamaran Voyage
              </h3>
            </div>
          </div>

          <div className="p-4 flex flex-col gap-2.5">
            <p className="text-[12px] text-[#4e453c] leading-relaxed">
              Exclusive 4-hour navigation to the untouched Boca Paila biosphere reef. Featuring freshly prepared yellowtail ceviche, artisanal mezcal service, snorkeling gear, and paddleboards.
            </p>
            <div className="flex items-center justify-between pt-2 border-t border-[#f1ede5] text-[11px]">
              <span className="text-[#7f5700] font-semibold">SCHEDULED: NOV 14, 09:30</span>
              <button
                onClick={() => onNavigate('yacht')}
                className="text-[#564121] font-bold uppercase font-label-sm text-[10px] tracking-wider hover:underline"
              >
                Modify →
              </button>
            </div>
          </div>
        </article>

        {/* Item 4: Four-Course Chef Dinner */}
        <article className="bg-white border border-[#e6e2d9] rounded-2xl overflow-hidden shadow-xs flex flex-col">
          <div className="relative h-48 w-full">
            <img
              src={IMAGES.chefFire}
              alt="Four-Course Chef Dinner"
              className="w-full h-full object-cover"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent"></div>
            
            <div className="absolute top-3 left-3 bg-[#fdf9f0]/90 backdrop-blur-md px-2.5 py-0.5 rounded-full text-[#7f5700] font-label-sm text-[9px] uppercase tracking-widest font-bold">
              Included · In-Villa
            </div>

            <div className="absolute top-3 right-3 bg-[#564121]/80 backdrop-blur-md px-2.5 py-0.5 rounded-full text-[#ffddb2] font-label-sm text-[9px] uppercase">
              Sommelier Paired
            </div>

            <div className="absolute bottom-3 left-4 text-white">
              <h3 className="font-headline-sm text-[19px] text-white">
                Four-Course Chef Dinner
              </h3>
            </div>
          </div>

          <div className="p-4 flex flex-col gap-2.5">
            <p className="text-[12px] text-[#4e453c] leading-relaxed">
              Master culinary brigade led by Executive Chef Mateo prepares bespoke heirloom recipes inside Villa 102’s outdoor kitchen. Paired thoughtfully with Valle de Guadalupe reserve vintages.
            </p>
            <div className="flex items-center justify-between pt-2 border-t border-[#f1ede5] text-[11px]">
              <span className="text-[#7f5700] font-semibold">SELECTED EVENING: NOV 13</span>
              <button
                onClick={() => onNavigate('dining')}
                className="text-[#564121] font-bold uppercase font-label-sm text-[10px] tracking-wider hover:underline"
              >
                Custom Menu →
              </button>
            </div>
          </div>
        </article>

      </div>

      {/* Signature Benefit Switcher */}
      <div className="px-5 pt-8">
        <div className="bg-[#f7f3ea] border border-[#e6e2d9] rounded-2xl p-5 flex flex-col gap-3">
          <span className="font-label-sm text-[10px] uppercase tracking-widest text-[#7f5700] flex items-center gap-1.5 font-bold">
            <span className="material-symbols-outlined text-[15px]">stars</span>
            Choose Your Signature Experience
          </span>

          <h2 className="font-headline-sm text-[20px] text-[#564121]">
            Bespoke Ritual Selection
          </h2>

          <p className="font-body-sm text-[12px] text-[#4e453c] leading-relaxed">
            Your sanctuary package includes one curated bespoke experience for two guests. Select your preferred privilege below to tailor your stay:
          </p>

          <div className="space-y-3 pt-2">
            
            {/* Option A: Massages */}
            <div className={`p-4 rounded-xl border transition-all ${
              selectedSignature === 'massage'
                ? 'bg-white border-[#7f5700] shadow-sm'
                : 'bg-white/60 border-[#e6e2d9]'
            }`}>
              <div className="flex items-start justify-between gap-3">
                <div className="flex items-start gap-3">
                  <img
                    src={IMAGES.spa}
                    alt="Massages"
                    className="w-14 h-14 rounded-lg object-cover shrink-0"
                  />
                  <div>
                    <span className="font-label-sm text-[9px] uppercase text-[#7f5700] font-bold block">
                      Wellness Ritual
                    </span>
                    <h4 className="text-[14px] font-semibold text-[#564121]">
                      2 × 60-Min In-Villa Chukum Massages
                    </h4>
                  </div>
                </div>

                {selectedSignature === 'massage' && (
                  <span className="px-2 py-0.5 rounded-full bg-[#564121] text-white font-label-sm text-[9px] uppercase font-bold shrink-0">
                    ✓ Selected
                  </span>
                )}
              </div>

              <p className="text-[12px] text-[#4e453c] mt-2 leading-relaxed">
                Botanical copal balm and Mayan obsidian warm stone therapy performed by sanctuary therapists on your secluded villa terrace.
              </p>

              <div className="flex items-center justify-between pt-3 mt-2 border-t border-[#f1ede5] text-xs">
                <span className="text-[#7f756a] text-[11px]">⏱ 120 Total Mins</span>
                {selectedSignature === 'massage' ? (
                  <button
                    onClick={() => onNavigate('concierge')}
                    className="px-3 py-1.5 rounded-md bg-[#564121] text-white font-label-sm text-[10px] uppercase font-bold"
                  >
                    Schedule Time →
                  </button>
                ) : (
                  <button
                    onClick={() => handleSelectSignature('massage')}
                    className="px-3 py-1.5 rounded-md bg-[#ece8df] text-[#564121] font-label-sm text-[10px] uppercase font-bold hover:bg-[#e6e2d9]"
                  >
                    Switch to this option
                  </button>
                )}
              </div>
            </div>

            {/* Option B: PGA Golf */}
            <div className={`p-4 rounded-xl border transition-all ${
              selectedSignature === 'golf'
                ? 'bg-white border-[#7f5700] shadow-sm'
                : 'bg-white/60 border-[#e6e2d9]'
            }`}>
              <div className="flex items-start justify-between gap-3">
                <div className="flex items-start gap-3">
                  <img
                    src={IMAGES.golf}
                    alt="Golf"
                    className="w-14 h-14 rounded-lg object-cover shrink-0"
                  />
                  <div>
                    <span className="font-label-sm text-[9px] uppercase text-[#7f5700] font-bold block">
                      Sport &amp; Leisure
                    </span>
                    <h4 className="text-[14px] font-semibold text-[#564121]">
                      2 × Rounds at PGA Riviera Maya
                    </h4>
                  </div>
                </div>

                {selectedSignature === 'golf' && (
                  <span className="px-2 py-0.5 rounded-full bg-[#564121] text-white font-label-sm text-[9px] uppercase font-bold shrink-0">
                    ✓ Selected
                  </span>
                )}
              </div>

              <p className="text-[12px] text-[#4e453c] mt-2 leading-relaxed">
                18-hole championship green fees, complimentary Callaway Apex club rental sets, electric GPS cart, and warm-up driving range access.
              </p>

              <div className="flex items-center justify-between pt-3 mt-2 border-t border-[#f1ede5] text-xs">
                <span className="text-[#7f756a] text-[11px]">📍 Robert Trent Jones II</span>
                {selectedSignature === 'golf' ? (
                  <button
                    onClick={() => onNavigate('concierge')}
                    className="px-3 py-1.5 rounded-md bg-[#564121] text-white font-label-sm text-[10px] uppercase font-bold"
                  >
                    Schedule Tee Time →
                  </button>
                ) : (
                  <button
                    onClick={() => handleSelectSignature('golf')}
                    className="px-3 py-1.5 rounded-md bg-[#ece8df] text-[#564121] font-label-sm text-[10px] uppercase font-bold hover:bg-[#e6e2d9]"
                  >
                    Switch to this option
                  </button>
                )}
              </div>
            </div>

          </div>

          {/* Active summary pill */}
          <div className="p-2.5 rounded-lg bg-[#f1ede5] text-center text-xs font-semibold text-[#564121] mt-1">
            ✨ ACTIVE: {selectedSignature === 'massage' ? 'IN-VILLA CHUKUM MASSAGES FOR 2' : 'PGA RIVIERA MAYA GOLF FOR 2'}
          </div>
        </div>
      </div>

      {/* Unconditional Hospitality Promise */}
      <div className="px-5 pt-8">
        <div className="bg-[#f1ede5] border border-[#d1c5b8]/40 rounded-2xl p-6 text-center flex flex-col items-center gap-2">
          <div className="w-10 h-10 rounded-full bg-white flex items-center justify-center text-[#7f5700] shadow-xs">
            <span className="material-symbols-outlined text-[20px]">spa</span>
          </div>

          <h3 className="font-headline-sm text-[18px] text-[#564121]">
            Unconditional Sanctuary Hospitality
          </h3>

          <p className="font-body-sm text-[12px] text-[#4e453c] leading-relaxed max-w-sm">
            All listed privileges carry $0 additional balance. Majordomo gratuity, cenote conservancy fees, and resort service charges are entirely included.
          </p>

          <button
            onClick={() => onNavigate('home')}
            className="w-full mt-2 bg-[#564121] hover:bg-[#705836] text-white py-3 px-4 rounded-lg font-label-md text-[11px] uppercase tracking-widest transition-colors shadow-xs"
          >
            View in My Itinerary →
          </button>

          <span className="font-label-sm text-[10px] text-[#7f756a] uppercase tracking-wider pt-1">
            Villa 102 Butler Assigned · Eduardo M.
          </span>
        </div>
      </div>

    </div>
  );
};
