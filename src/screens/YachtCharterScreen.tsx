import React, { useState } from 'react';
import { ScreenId } from '../types';
import { GUEST_INFO, IMAGES } from '../data/sanctuaryData';

interface YachtCharterScreenProps {
  onNavigate: (screen: ScreenId) => void;
}

export const YachtCharterScreen: React.FC<YachtCharterScreenProps> = ({ onNavigate }) => {
  const [selectedDay, setSelectedDay] = useState<string>('Fri 14');
  const [selectedWindow, setSelectedWindow] = useState<'morning' | 'sunset' | 'twilight'>('morning');
  const [guestsCount, setGuestsCount] = useState<number>(2);
  const [toastMsg, setToastMsg] = useState<string | null>(null);

  const days = [
    { day: 'WED', date: '12', status: 'Arrival' },
    { day: 'THU', date: '13', status: 'Available' },
    { day: 'FRI', date: '14', status: 'Optimal' },
    { day: 'SAT', date: '15', status: 'Available' },
  ];

  const handleReserve = () => {
    setToastMsg(`Charter confirmed for ${selectedDay} · ${selectedWindow === 'morning' ? 'Morning Reef Sail' : 'Sunset Voyage'}. Dispatched to Captain & Villa Host.`);
    setTimeout(() => {
      onNavigate('home');
    }, 1500);
  };

  return (
    <div className="flex flex-col w-full pb-32 pt-2">
      
      {/* Toast */}
      {toastMsg && (
        <div className="fixed top-20 left-1/2 -translate-x-1/2 z-50 bg-[#564121] text-white px-5 py-2.5 rounded-full text-xs font-medium shadow-xl animate-in fade-in duration-200">
          {toastMsg}
        </div>
      )}

      {/* Top action row */}
      <div className="px-5 pt-2 pb-2 flex items-center justify-between">
        <button
          onClick={() => onNavigate('explore')}
          className="flex items-center gap-1 text-[11px] font-bold uppercase tracking-wider text-[#564121] hover:text-[#7f5700]"
        >
          <span className="material-symbols-outlined text-[16px]">arrow_back</span>
          <span>Back to Explore</span>
        </button>

        <div className="flex items-center gap-3 text-[#564121]">
          <button 
            onClick={() => {
              if (navigator.share) {
                navigator.share({ title: 'Kachava Private Yacht Voyage', url: window.location.href });
              } else {
                setToastMsg('Link copied to clipboard');
                setTimeout(() => setToastMsg(null), 2000);
              }
            }}
            className="hover:text-[#7f5700]"
            title="Share"
          >
            <span className="material-symbols-outlined text-[18px]">share</span>
          </button>
          <button className="hover:text-[#7f5700]" title="Save">
            <span className="material-symbols-outlined text-[18px]">bookmark_border</span>
          </button>
        </div>
      </div>

      {/* Hero Yacht Banner */}
      <div className="px-5 pt-2">
        <div className="relative rounded-2xl overflow-hidden shadow-lg border border-[#e6e2d9] group">
          <img
            src={IMAGES.yacht}
            alt="Kachava Private Yacht Voyage"
            className="w-full h-64 object-cover group-hover:scale-105 transition-transform duration-700"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-black/85 via-black/35 to-transparent"></div>

          <div className="absolute top-3 left-3 flex items-center gap-2">
            <span className="px-3 py-1 rounded-full bg-white/90 backdrop-blur-md text-[#564121] font-label-sm text-[9px] uppercase tracking-widest font-bold">
              Villa 102 Inherent Privilege
            </span>
            <span className="px-2.5 py-0.5 rounded-full bg-black/40 backdrop-blur-md text-white font-label-sm text-[8px] uppercase">
              Sanctuary Fleet
            </span>
          </div>

          <div className="absolute bottom-4 left-4 right-4 text-white">
            <span className="inline-block px-2.5 py-0.5 rounded-md bg-[#febe4f] text-[#564121] font-label-sm text-[9px] uppercase font-bold tracking-wider mb-1.5">
              Included with Stay · $0 Due
            </span>
            <h1 className="font-headline-md text-[24px] text-white leading-tight">
              Kachava Private Yacht Voyage
            </h1>
            <p className="text-[12px] text-white/90 mt-1 line-clamp-2">
              4-Hour secluded navigation into the untouched Boca Paila marine biosphere with private chauffeur...
            </p>
          </div>
        </div>
      </div>

      {/* Quick Specs Grid */}
      <div className="px-5 pt-4">
        <div className="bg-[#f7f3ea] border border-[#e6e2d9] rounded-2xl p-4 grid grid-cols-2 gap-3 text-xs">
          <div className="flex items-center gap-2.5">
            <span className="material-symbols-outlined text-[#7f5700] text-[18px]">schedule</span>
            <div>
              <span className="font-label-sm text-[9px] text-[#7f756a] uppercase block">Duration</span>
              <span className="font-semibold text-[#564121]">4 Hours</span>
            </div>
          </div>

          <div className="flex items-center gap-2.5">
            <span className="material-symbols-outlined text-[#7f5700] text-[18px]">group</span>
            <div>
              <span className="font-label-sm text-[9px] text-[#7f756a] uppercase block">Capacity</span>
              <span className="font-semibold text-[#564121]">Up to 6 Guests</span>
            </div>
          </div>

          <div className="flex items-center gap-2.5">
            <span className="material-symbols-outlined text-[#7f5700] text-[18px]">sailing</span>
            <div>
              <span className="font-label-sm text-[9px] text-[#7f756a] uppercase block">Vessel</span>
              <span className="font-semibold text-[#564121]">44ft Leopard Catamaran</span>
            </div>
          </div>

          <div className="flex items-center gap-2.5">
            <span className="material-symbols-outlined text-[#7f5700] text-[18px]">directions_car</span>
            <div>
              <span className="font-label-sm text-[9px] text-[#7f756a] uppercase block">Transfer</span>
              <span className="font-semibold text-[#564121]">Private Suburban</span>
            </div>
          </div>
        </div>

        <div className="mt-2 p-2.5 rounded-xl bg-white border border-[#e6e2d9] flex items-center gap-2 text-xs text-[#7f756a]">
          <span className="material-symbols-outlined text-[#7f5700] text-[16px] shrink-0">location_on</span>
          <span>Puerto Aventuras Marina (Chauffeur Pick-up at Villa 102 Lobby)</span>
        </div>
      </div>

      {/* In-Depth Inclusions */}
      <div className="px-5 pt-6">
        <div className="flex items-center justify-between mb-3">
          <h2 className="font-headline-sm text-[19px] text-[#564121]">
            In-Depth Inclusions
          </h2>
          <span className="font-label-sm text-[9px] uppercase tracking-wider text-[#7f5700] font-bold">
            Zero Surcharges
          </span>
        </div>

        <div className="space-y-2.5">
          <div className="p-3.5 rounded-xl bg-white border border-[#e6e2d9] flex items-start gap-3">
            <span className="material-symbols-outlined text-[#7f5700] text-[20px] shrink-0 mt-0.5">person</span>
            <div>
              <h4 className="text-[13px] font-semibold text-[#564121]">
                Dedicated Marine Crew &amp; Villa Host
              </h4>
              <p className="text-[11px] text-[#7f756a] mt-0.5 leading-relaxed">
                Licensed Captain, First Mate, and a dedicated hospitality butler attending exclusively to your party.
              </p>
            </div>
          </div>

          <div className="p-3.5 rounded-xl bg-white border border-[#e6e2d9] flex items-start gap-3">
            <span className="material-symbols-outlined text-[#7f5700] text-[20px] shrink-0 mt-0.5">restaurant</span>
            <div>
              <h4 className="text-[13px] font-semibold text-[#564121]">
                Artisanal Coastal Culinary Board
              </h4>
              <p className="text-[11px] text-[#7f756a] mt-0.5 leading-relaxed">
                Wild yellowtail ceviche, freshly crushed guacamole, heirloom blue corn tostadas, and chilled tropical fruits.
              </p>
            </div>
          </div>

          <div className="p-3.5 rounded-xl bg-white border border-[#e6e2d9] flex items-start gap-3">
            <span className="material-symbols-outlined text-[#7f5700] text-[20px] shrink-0 mt-0.5">wine_bar</span>
            <div>
              <h4 className="text-[13px] font-semibold text-[#564121]">
                Curated Mezcal &amp; Cellar Reserve Bar
              </h4>
              <p className="text-[11px] text-[#7f756a] mt-0.5 leading-relaxed">
                Small-batch Oaxacan mezcals, chilled Ruinart champagne, cold-pressed green coconuts, and sparkling mineral water.
              </p>
            </div>
          </div>

          <div className="p-3.5 rounded-xl bg-white border border-[#e6e2d9] flex items-start gap-3">
            <span className="material-symbols-outlined text-[#7f5700] text-[20px] shrink-0 mt-0.5">scuba_diving</span>
            <div>
              <h4 className="text-[13px] font-semibold text-[#564121]">
                Biosphere Watersports Arsenal
              </h4>
              <p className="text-[11px] text-[#7f756a] mt-0.5 leading-relaxed">
                Dual carbon fiber stand-up paddleboards, sanitized Cressi reef snorkel gear, and an underwater Seabob F5-S.
              </p>
            </div>
          </div>

          <div className="p-3.5 rounded-xl bg-white border border-[#e6e2d9] flex items-start gap-3">
            <span className="material-symbols-outlined text-[#7f5700] text-[20px] shrink-0 mt-0.5">directions_car</span>
            <div>
              <h4 className="text-[13px] font-semibold text-[#564121]">
                Door-to-Dock Mercedes-Benz Chauffeur
              </h4>
              <p className="text-[11px] text-[#7f756a] mt-0.5 leading-relaxed">
                Private luxury transfer direct from Villa 102 portico to the vessel berth with chilled eucalyptus towels.
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Custom Reservation / Date & Window */}
      <div className="px-5 pt-6">
        <span className="font-label-sm text-[9px] uppercase tracking-wider text-[#7f5700] font-bold block mb-1">
          Custom Reservation
        </span>
        <h2 className="font-headline-sm text-[19px] text-[#564121] mb-2">
          Select Date &amp; Departure
        </h2>

        {/* Date Selector */}
        <div className="grid grid-cols-4 gap-2 mb-4">
          {days.map(d => {
            const isSel = selectedDay === `${d.day} ${d.date}`;
            return (
              <button
                key={d.date}
                onClick={() => setSelectedDay(`${d.day} ${d.date}`)}
                className={`p-2.5 rounded-xl text-center transition-all border ${
                  isSel
                    ? 'bg-[#564121] text-white border-[#564121] shadow-xs'
                    : 'bg-white text-[#564121] border-[#e6e2d9] hover:bg-[#f7f3ea]'
                }`}
              >
                <span className={`font-label-sm text-[9px] uppercase block ${isSel ? 'text-[#ffddb2]' : 'text-[#7f756a]'}`}>
                  {d.day}
                </span>
                <span className="text-[18px] font-bold block leading-tight">
                  {d.date}
                </span>
                <span className={`font-label-sm text-[8px] uppercase tracking-wider block mt-0.5 ${isSel ? 'text-white' : 'text-[#7f5700]'}`}>
                  {d.status}
                </span>
              </button>
            );
          })}
        </div>

        {/* Departure Window */}
        <div className="space-y-2.5">
          {/* Morning */}
          <div
            onClick={() => setSelectedWindow('morning')}
            className={`p-3.5 rounded-xl border cursor-pointer transition-all ${
              selectedWindow === 'morning'
                ? 'bg-white border-[#7f5700] shadow-xs'
                : 'bg-white/70 border-[#e6e2d9]'
            }`}
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span className={`w-3.5 h-3.5 rounded-full border flex items-center justify-center ${
                  selectedWindow === 'morning' ? 'border-[#564121] bg-[#564121]' : 'border-[#d1c5b8]'
                }`}>
                  {selectedWindow === 'morning' && <span className="w-1.5 h-1.5 rounded-full bg-white"></span>}
                </span>
                <span className="text-[13px] font-bold text-[#564121]">
                  Morning Reef Sail · 09:30 AM – 1:30 PM
                </span>
              </div>
              <span className="px-2 py-0.5 rounded bg-[#ffdead] text-[#7f5700] font-label-sm text-[8px] uppercase font-bold">
                Recommended
              </span>
            </div>
            <p className="text-[11px] text-[#7f756a] pl-5 mt-1">
              Glass-calm seas, optimal coral visibility &amp; sea turtle observation
            </p>
          </div>

          {/* Sunset */}
          <div
            onClick={() => setSelectedWindow('sunset')}
            className={`p-3.5 rounded-xl border cursor-pointer transition-all ${
              selectedWindow === 'sunset'
                ? 'bg-white border-[#7f5700] shadow-xs'
                : 'bg-white/70 border-[#e6e2d9]'
            }`}
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span className={`w-3.5 h-3.5 rounded-full border flex items-center justify-center ${
                  selectedWindow === 'sunset' ? 'border-[#564121] bg-[#564121]' : 'border-[#d1c5b8]'
                }`}>
                  {selectedWindow === 'sunset' && <span className="w-1.5 h-1.5 rounded-full bg-white"></span>}
                </span>
                <span className="text-[13px] font-bold text-[#564121]">
                  Golden Sunset Voyage · 2:30 PM – 6:30 PM
                </span>
              </div>
              <span className="px-2 py-0.5 rounded bg-[#ece8df] text-[#7f756a] font-label-sm text-[8px] uppercase font-bold">
                Open
              </span>
            </div>
            <p className="text-[11px] text-[#7f756a] pl-5 mt-1">
              Warm ocean breeze, golden hour photography &amp; sundown champagne
            </p>
          </div>

          {/* Twilight (Reserved) */}
          <div className="p-3.5 rounded-xl border border-[#e6e2d9] bg-white/40 opacity-70">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span className="w-3.5 h-3.5 rounded-full border border-[#d1c5b8]"></span>
                <span className="text-[13px] font-medium text-[#7f756a]">
                  Twilight Glow Sail · 5:00 PM – 9:00 PM
                </span>
              </div>
              <span className="px-2 py-0.5 rounded bg-[#ffdad6] text-[#ba1a1a] font-label-sm text-[8px] uppercase font-bold">
                Reserved
              </span>
            </div>
            <p className="text-[11px] text-[#7f756a] pl-5 mt-1">
              Bioluminescent bay tour &amp; candlelit deck degustation
            </p>
          </div>
        </div>

        {/* Guest Manifest */}
        <div className="mt-4 p-3.5 rounded-xl bg-white border border-[#e6e2d9] flex items-center justify-between">
          <div>
            <span className="font-label-sm text-[9px] uppercase tracking-wider text-[#7f756a] block">
              Guest Manifest
            </span>
            <span className="text-[13px] font-semibold text-[#564121]">
              {guestsCount} Guests ({GUEST_INFO.name} + {guestsCount - 1})
            </span>
            <p className="text-[10px] text-[#7f756a]">Included entitlement covers up to 6 guests</p>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => setGuestsCount(Math.max(1, guestsCount - 1))}
              className="w-8 h-8 rounded-lg bg-[#f1ede5] text-[#564121] flex items-center justify-center font-bold text-sm"
            >
              -
            </button>
            <span className="w-6 text-center font-bold text-sm">{guestsCount}</span>
            <button
              onClick={() => setGuestsCount(Math.min(6, guestsCount + 1))}
              className="w-8 h-8 rounded-lg bg-[#f1ede5] text-[#564121] flex items-center justify-center font-bold text-sm"
            >
              +
            </button>
          </div>
        </div>

        {/* Dietary Sync Card */}
        <div className="mt-3 p-3.5 rounded-xl bg-[#f7f3ea] border border-[#e6e2d9]">
          <div className="flex items-center justify-between text-xs">
            <span className="font-label-sm text-[9px] uppercase text-[#7f5700] font-bold flex items-center gap-1">
              <span className="material-symbols-outlined text-[14px]">sync</span>
              Concierge Profile Sync
            </span>
            <button 
              onClick={() => onNavigate('personalize')} 
              className="text-[#7f5700] font-semibold hover:underline"
            >
              Edit Preferences
            </button>
          </div>
          <p className="text-[12px] text-[#4e453c] mt-1 leading-relaxed">
            Pescatarian &amp; Gluten-Sensitive onboard catering, strictly no shellfish. Hydration preference: Chilled sparkling coconut water.
          </p>
        </div>
      </div>

      {/* Billing Summary */}
      <div className="px-5 pt-6">
        <div className="p-4 rounded-xl bg-white border border-[#e6e2d9] space-y-2 text-xs">
          <div className="flex items-center justify-between">
            <div>
              <span className="font-label-sm text-[9px] uppercase tracking-wider text-[#7f756a] block">
                Billing Summary
              </span>
              <h3 className="font-headline-sm text-[16px] text-[#564121]">
                Charter Package Valuation
              </h3>
            </div>
            <div className="text-right">
              <span className="line-through text-[#7f756a] text-xs block">$2,450.00 USD</span>
              <span className="font-headline-sm text-[20px] text-[#564121] leading-none">$0.00 USD</span>
            </div>
          </div>

          <div className="pt-2 border-t border-[#f1ede5] space-y-1.5 text-[#4e453c]">
            <div className="flex justify-between">
              <span>Villa 102 Master Suite Entitlement</span>
              <span className="font-semibold text-[#7f5700]">Complimentary</span>
            </div>
            <div className="flex justify-between">
              <span>Captain &amp; First Mate Gratuities</span>
              <span className="font-semibold text-[#7f5700]">Prepaid by Villa</span>
            </div>
            <div className="flex justify-between">
              <span>Boca Paila Biosphere Sanctuary Permits</span>
              <span className="font-semibold text-[#7f5700]">Included</span>
            </div>
          </div>

          <div className="pt-2 border-t border-[#f1ede5] flex items-center gap-2 text-[11px] text-[#7f756a]">
            <span className="material-symbols-outlined text-[15px] text-[#7f5700]">shield</span>
            <span>Zero incidental holds required. Completely protected under Villa 102 portfolio ledger.</span>
          </div>
        </div>
      </div>

      {/* Floating Bottom Booking Action */}
      <div className="fixed bottom-16 left-0 right-0 z-30 bg-[#fdf9f0]/95 backdrop-blur-md border-t border-[#e6e2d9] p-3 shadow-lg">
        <div className="max-w-md mx-auto flex items-center justify-between gap-3">
          <div>
            <span className="font-label-sm text-[9px] uppercase tracking-wider text-[#7f756a] block">
              Total Investment
            </span>
            <div className="flex items-baseline gap-1">
              <span className="font-headline-sm text-[20px] text-[#564121] leading-none">$0.00</span>
              <span className="text-[11px] text-[#7f756a]">USD Net</span>
            </div>
            <span className="text-[10px] text-[#7f5700] font-medium block">{selectedDay} · Morning Sail</span>
          </div>

          <button
            onClick={handleReserve}
            className="flex-1 max-w-[220px] bg-[#564121] hover:bg-[#705836] text-white py-3.5 px-4 rounded-xl font-label-md text-[10px] uppercase tracking-widest flex items-center justify-center gap-1.5 transition-colors shadow-sm"
          >
            <span>Reserve Experience</span>
            <span className="material-symbols-outlined text-[16px]">arrow_forward</span>
          </button>
        </div>
      </div>

    </div>
  );
};
