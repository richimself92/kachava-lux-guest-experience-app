import React, { useState } from 'react';
import { ScreenId } from '../types';
import {
  GUEST_INFO,
  YACHT_VESSEL_SPECS,
  CAPTAIN_INFO,
  YACHT_PACKAGES,
  NAVIGABLE_DESTINATIONS,
  YACHT_GALLERY,
} from '../data/sanctuaryData';

interface YachtCharterScreenProps {
  onNavigate: (screen: ScreenId) => void;
}

export const YachtCharterScreen: React.FC<YachtCharterScreenProps> = ({ onNavigate }) => {
  const [selectedPackageId, setSelectedPackageId] = useState<string>('half-day');
  const [selectedDay, setSelectedDay] = useState<string>('Fri 14');
  const [selectedWindow, setSelectedWindow] = useState<'morning' | 'sunset' | 'custom'>('morning');
  const [selectedDestination, setSelectedDestination] = useState<string>('isla-mujeres');
  const [activeGalleryIndex, setActiveGalleryIndex] = useState<number>(0);
  const [guestsCount, setGuestsCount] = useState<number>(2);
  const [toastMsg, setToastMsg] = useState<string | null>(null);

  const days = [
    { day: 'WED', date: '12', status: 'Arrival' },
    { day: 'THU', date: '13', status: 'Available' },
    { day: 'FRI', date: '14', status: 'Optimal' },
    { day: 'SAT', date: '15', status: 'Available' },
  ];

  const currentPkg = YACHT_PACKAGES.find((p) => p.id === selectedPackageId) || YACHT_PACKAGES[0];

  const calculateTotal = () => {
    if (currentPkg.id === 'half-day') return 0;
    if (currentPkg.id === 'extended') return 1000;
    if (currentPkg.id === 'full-day') return 2000;
    return 0;
  };

  const handleReserve = () => {
    const timeLabel =
      selectedWindow === 'morning'
        ? 'Morning Caribbean Sail (09:30 AM)'
        : selectedWindow === 'sunset'
        ? 'Sunset Golden Voyage (2:30 PM)'
        : 'Custom Maritime Itinerary';

    setToastMsg(
      `Charter confirmed: ${currentPkg.title} for ${selectedDay} · ${timeLabel}. Dispatched to Captain Eduardo & Villa Host.`
    );
    setTimeout(() => {
      onNavigate('home');
    }, 2000);
  };

  return (
    <div className="flex flex-col w-full pb-36 pt-2">
      {/* Toast Notification */}
      {toastMsg && (
        <div className="fixed top-20 left-1/2 -translate-x-1/2 z-50 bg-[#0B1F33] text-white px-5 py-3 rounded-full text-xs font-medium shadow-2xl border border-[#c49a6c]/40 animate-in fade-in duration-200 text-center max-w-[90%]">
          {toastMsg}
        </div>
      )}

      {/* Top navigation row */}
      <div className="px-5 pt-2 pb-2 flex items-center justify-between">
        <button
          onClick={() => onNavigate('explore')}
          className="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-wider text-[#754d24] hover:text-[#a67d52] transition-colors"
        >
          <span className="material-symbols-outlined text-[16px]">arrow_back</span>
          <span>Back to Explore</span>
        </button>

        <div className="flex items-center gap-3 text-[#754d24]">
          <button
            onClick={() => {
              if (navigator.share) {
                navigator.share({
                  title: 'Kachava Caribe · Galeon 470 Sky Experience',
                  url: 'https://kachavacaribe.com/',
                });
              } else {
                setToastMsg('Link copied: https://kachavacaribe.com/');
                setTimeout(() => setToastMsg(null), 2500);
              }
            }}
            className="hover:text-[#a67d52] p-1 transition-colors"
            title="Share"
          >
            <span className="material-symbols-outlined text-[18px]">share</span>
          </button>
          <a
            href="https://kachavacaribe.com/"
            target="_blank"
            rel="noopener noreferrer"
            className="hover:text-[#a67d52] p-1 transition-colors flex items-center text-[11px] font-semibold text-[#a67d52]"
            title="Visit Kachava Caribe Online"
          >
            <span className="material-symbols-outlined text-[18px]">open_in_new</span>
          </a>
        </div>
      </div>

      {/* Sub-Brand Strip */}
      <div className="px-5 pb-2">
        <div className="bg-[#0B1F33] text-[#F6EFE4] px-4 py-2 rounded-xl flex items-center justify-between border border-[#18B7C9]/20 shadow-xs">
          <div className="flex items-center gap-2.5">
            <span className="w-2 h-2 rounded-full bg-[#18B7C9] animate-pulse"></span>
            <div className="flex flex-col">
              <span className="text-[12px] font-bold tracking-widest uppercase font-serif text-white">
                KACHAVA CARIBE
              </span>
              <span className="text-[8px] uppercase tracking-[0.25em] text-[#C9A45C] font-semibold">
                by kachava lux
              </span>
            </div>
          </div>
          <span className="px-2.5 py-0.5 rounded-full bg-[#18B7C9]/20 border border-[#18B7C9]/30 text-[#18B7C9] text-[9px] font-bold uppercase tracking-wider">
            Galeon 470 Sky
          </span>
        </div>
      </div>

      {/* Hero Banner & Interactive Photo Carousel */}
      <div className="px-5 pt-1">
        <div className="relative rounded-2xl overflow-hidden shadow-xl border border-[#e6e2d9] group bg-[#0B1F33]">
          <div className="relative h-72 sm:h-80 w-full overflow-hidden">
            <img
              src={YACHT_GALLERY[activeGalleryIndex].src}
              alt={YACHT_GALLERY[activeGalleryIndex].caption}
              className="w-full h-full object-cover transition-all duration-700 group-hover:scale-105"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/30 to-transparent pointer-events-none"></div>

            {/* Top Badges */}
            <div className="absolute top-3 left-3 right-3 flex items-center justify-between pointer-events-none">
              <span className="px-3 py-1 rounded-full bg-white/95 backdrop-blur-md text-[#754d24] text-[9px] uppercase tracking-widest font-bold shadow-sm">
                Villa 102 Inherent Privilege
              </span>
              <span className="px-2.5 py-1 rounded-full bg-[#0B1F33]/85 backdrop-blur-md text-[#C9A45C] text-[8px] uppercase tracking-wider font-semibold border border-[#C9A45C]/30">
                {YACHT_GALLERY[activeGalleryIndex].tag}
              </span>
            </div>

            {/* Overlay Copy */}
            <div className="absolute bottom-3 left-4 right-4 text-white pointer-events-none">
              <span className="inline-block px-2.5 py-0.5 rounded-md bg-[#c49a6c] text-[#754d24] font-label-sm text-[9px] uppercase font-bold tracking-wider mb-1.5 shadow-sm">
                4N/5D Stay Inclusion · $0 Due
              </span>
              <h1 className="font-serif text-[22px] sm:text-[24px] text-white leading-tight font-light">
                Private Yacht Experience
              </h1>
              <p className="text-[11px] text-white/90 mt-0.5 line-clamp-1">
                {YACHT_GALLERY[activeGalleryIndex].caption}
              </p>
            </div>
          </div>

          {/* Thumbnail Strip */}
          <div className="p-2.5 bg-[#07131f] flex gap-2 overflow-x-auto scrollbar-none border-t border-white/10">
            {YACHT_GALLERY.map((item, idx) => (
              <button
                key={idx}
                onClick={() => setActiveGalleryIndex(idx)}
                className={`relative w-14 h-11 rounded-lg overflow-hidden shrink-0 transition-all border-2 ${
                  activeGalleryIndex === idx
                    ? 'border-[#C9A45C] scale-105 shadow-md'
                    : 'border-transparent opacity-60 hover:opacity-100'
                }`}
              >
                <img src={item.src} alt={item.caption} className="w-full h-full object-cover" />
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* The Vessel: Galeon 470 Sky & Specifications */}
      <div className="px-5 pt-6">
        <div className="flex items-center justify-between mb-3">
          <div>
            <span className="font-label-sm text-[9px] uppercase tracking-wider text-[#a67d52] font-bold block">
              The Sanctuary Vessel
            </span>
            <h2 className="font-serif text-[20px] text-[#754d24]">
              Galeon 470 Sky
            </h2>
          </div>
          <span className="text-[10px] text-[#7f756a] font-medium">Custom Commission</span>
        </div>

        <p className="text-[12px] text-[#4e453c] leading-relaxed mb-4">
          A custom-commissioned 47-foot vessel blending aerodynamic coupe sportiness with a triple-deck flybridge and revolutionary fold-down beach mode balconies for navigating Cancún, Isla Mujeres, and the Riviera Maya.
        </p>

        {/* Specs Grid */}
        <div className="bg-[#f7f3ea] border border-[#e6e2d9] rounded-2xl p-4 grid grid-cols-2 gap-3 text-xs">
          <div className="flex items-center gap-2.5">
            <span className="material-symbols-outlined text-[#a67d52] text-[18px]">straighten</span>
            <div>
              <span className="text-[9px] text-[#7f756a] uppercase font-semibold block">Overall Length</span>
              <span className="font-semibold text-[#754d24]">{YACHT_VESSEL_SPECS.overallLength}</span>
            </div>
          </div>

          <div className="flex items-center gap-2.5">
            <span className="material-symbols-outlined text-[#a67d52] text-[18px]">open_in_full</span>
            <div>
              <span className="text-[9px] text-[#7f756a] uppercase font-semibold block">Beach Mode Beam</span>
              <span className="font-semibold text-[#754d24]">{YACHT_VESSEL_SPECS.beachModeBeam}</span>
            </div>
          </div>

          <div className="flex items-center gap-2.5">
            <span className="material-symbols-outlined text-[#a67d52] text-[18px]">group</span>
            <div>
              <span className="text-[9px] text-[#7f756a] uppercase font-semibold block">Day Capacity</span>
              <span className="font-semibold text-[#754d24]">{YACHT_VESSEL_SPECS.capacity}</span>
            </div>
          </div>

          <div className="flex items-center gap-2.5">
            <span className="material-symbols-outlined text-[#a67d52] text-[18px]">bed</span>
            <div>
              <span className="text-[9px] text-[#7f756a] uppercase font-semibold block">Accommodations</span>
              <span className="font-semibold text-[#754d24]">{YACHT_VESSEL_SPECS.accommodations}</span>
            </div>
          </div>

          <div className="flex items-center gap-2.5">
            <span className="material-symbols-outlined text-[#a67d52] text-[18px]">speed</span>
            <div>
              <span className="text-[9px] text-[#7f756a] uppercase font-semibold block">Engines</span>
              <span className="font-semibold text-[#754d24]">{YACHT_VESSEL_SPECS.engines}</span>
            </div>
          </div>

          <div className="flex items-center gap-2.5">
            <span className="material-symbols-outlined text-[#a67d52] text-[18px]">anchor</span>
            <div>
              <span className="text-[9px] text-[#7f756a] uppercase font-semibold block">Home Port</span>
              <span className="font-semibold text-[#754d24]">Puerto Cancún</span>
            </div>
          </div>
        </div>

        {/* Feature Callouts */}
        <div className="mt-3 grid grid-cols-2 gap-2 text-xs">
          <div className="p-3 rounded-xl bg-white border border-[#e6e2d9]">
            <span className="text-[11px] font-bold text-[#754d24] block mb-0.5">🏖️ Beach Mode Balconies</span>
            <p className="text-[10px] text-[#7f756a] leading-tight">
              Port &amp; starboard side balconies fold down over water into an expansive 19ft floating deck.
            </p>
          </div>
          <div className="p-3 rounded-xl bg-white border border-[#e6e2d9]">
            <span className="text-[11px] font-bold text-[#754d24] block mb-0.5">☀️ Dynamic Skydeck</span>
            <p className="text-[10px] text-[#7f756a] leading-tight">
              Retractable canvas roof, elevated helm, and wrap-around panoramic lounges.
            </p>
          </div>
        </div>
      </div>

      {/* Package Tier Selection */}
      <div className="px-5 pt-6">
        <span className="font-label-sm text-[9px] uppercase tracking-wider text-[#a67d52] font-bold block mb-1">
          Select Your Experience
        </span>
        <h2 className="font-serif text-[20px] text-[#754d24] mb-3">
          Curated Charter Packages
        </h2>

        <div className="space-y-3">
          {YACHT_PACKAGES.map((pkg) => {
            const isSelected = selectedPackageId === pkg.id;
            return (
              <div
                key={pkg.id}
                onClick={() => setSelectedPackageId(pkg.id)}
                className={`p-4 rounded-2xl border cursor-pointer transition-all ${
                  isSelected
                    ? 'bg-white border-[#754d24] shadow-md ring-1 ring-[#754d24]'
                    : 'bg-white/80 border-[#e6e2d9] hover:bg-white hover:border-[#c49a6c]'
                }`}
              >
                <div className="flex items-start justify-between gap-2">
                  <div className="flex items-center gap-2">
                    <span
                      className={`w-4 h-4 rounded-full border flex items-center justify-center shrink-0 ${
                        isSelected ? 'border-[#754d24] bg-[#754d24]' : 'border-[#d1c5b8]'
                      }`}
                    >
                      {isSelected && <span className="w-1.5 h-1.5 rounded-full bg-white"></span>}
                    </span>
                    <div>
                      <h3 className="text-[14px] font-bold text-[#754d24]">{pkg.title}</h3>
                      <span className="text-[10px] text-[#a67d52] font-semibold block">{pkg.tagline}</span>
                    </div>
                  </div>

                  <span
                    className={`px-2.5 py-0.5 rounded-full text-[9px] font-bold uppercase tracking-wider shrink-0 ${
                      pkg.isIncludedWithStay
                        ? 'bg-[#e2f0d9] text-[#386b24]'
                        : 'bg-[#f7f3ea] text-[#754d24] border border-[#e6e2d9]'
                    }`}
                  >
                    {pkg.isIncludedWithStay ? 'Included Privileged' : pkg.priceLabel.split('(')[0]}
                  </span>
                </div>

                <p className="text-[11px] text-[#7f756a] mt-2 pl-6 leading-relaxed">
                  {pkg.description}
                </p>

                {isSelected && (
                  <div className="mt-3 pl-6 pt-3 border-t border-[#f1ede5] space-y-1.5">
                    <span className="text-[9px] font-bold uppercase tracking-wider text-[#a67d52] block mb-1">
                      Package Inclusions:
                    </span>
                    {pkg.highlights.map((h: string, i: number) => (
                      <div key={i} className="flex items-center gap-2 text-[11px] text-[#4e453c]">
                        <span className="material-symbols-outlined text-[14px] text-[#18B7C9]">check_circle</span>
                        <span>{h}</span>
                      </div>
                    ))}
                    <div className="mt-2 pt-2 text-[10px] text-[#7f756a] italic">
                      Path: {pkg.suggestedPaths}
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* Navigable Waters Destinations */}
      <div className="px-5 pt-6">
        <div className="flex items-center justify-between mb-3">
          <div>
            <span className="font-label-sm text-[9px] uppercase tracking-wider text-[#a67d52] font-bold block">
              Curated Routes
            </span>
            <h2 className="font-serif text-[20px] text-[#754d24]">
              Navigable Waters
            </h2>
          </div>
          <span className="text-[10px] text-[#a67d52] font-semibold">3 Featured Havens</span>
        </div>

        <div className="space-y-3">
          {NAVIGABLE_DESTINATIONS.map((dest) => {
            const isSelected = selectedDestination === dest.id;
            return (
              <div
                key={dest.id}
                onClick={() => setSelectedDestination(dest.id)}
                className={`rounded-2xl border overflow-hidden cursor-pointer transition-all bg-white ${
                  isSelected ? 'border-[#754d24] shadow-md' : 'border-[#e6e2d9]'
                }`}
              >
                <div className="relative h-28 w-full">
                  <img src={dest.image} alt={dest.title} className="w-full h-full object-cover" />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/85 via-black/30 to-transparent"></div>
                  <div className="absolute top-2.5 right-2.5">
                    <span className="px-2 py-0.5 rounded-full bg-[#0B1F33]/85 text-[#18B7C9] text-[8px] font-bold uppercase tracking-wider border border-[#18B7C9]/40">
                      {dest.badge}
                    </span>
                  </div>
                  <div className="absolute bottom-2 left-3 right-3 text-white">
                    <span className="text-[9px] uppercase tracking-widest text-[#C9A45C] block">
                      {dest.region}
                    </span>
                    <h4 className="text-[15px] font-serif font-medium">{dest.title}</h4>
                  </div>
                </div>

                <div className="p-3.5 space-y-2">
                  <p className="text-[11px] text-[#7f756a] leading-relaxed">
                    {dest.description}
                  </p>
                  <div className="flex flex-wrap gap-1.5 pt-1">
                    {dest.highlights.map((h: string, i: number) => (
                      <span
                        key={i}
                        className="px-2 py-0.5 rounded-md bg-[#f7f3ea] text-[#754d24] text-[9px] font-medium border border-[#e6e2d9]"
                      >
                        ✓ {h}
                      </span>
                    ))}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Meet Your Captain */}
      <div className="px-5 pt-6">
        <div className="bg-[#0B1F33] text-white rounded-2xl p-5 border border-[#c49a6c]/30 shadow-lg relative overflow-hidden">
          <div className="relative z-10 flex flex-col sm:flex-row items-center sm:items-start gap-4">
            <div className="relative w-20 h-20 rounded-full overflow-hidden border-2 border-[#C9A45C] shrink-0 shadow-md">
              <img
                src={CAPTAIN_INFO.image}
                alt={CAPTAIN_INFO.name}
                className="w-full h-full object-cover"
              />
            </div>

            <div className="text-center sm:text-left space-y-1.5">
              <div className="flex flex-col sm:flex-row sm:items-center gap-1 sm:gap-2">
                <h3 className="font-serif text-[18px] text-[#F6EFE4] font-medium">
                  {CAPTAIN_INFO.name}
                </h3>
                <span className="px-2 py-0.5 rounded bg-[#C9A45C]/20 border border-[#C9A45C]/40 text-[#C9A45C] text-[9px] uppercase font-bold tracking-wider self-center sm:self-auto">
                  {CAPTAIN_INFO.role}
                </span>
              </div>

              <p className="text-[10px] text-[#18B7C9] uppercase tracking-wider font-semibold">
                {CAPTAIN_INFO.experience} · {CAPTAIN_INFO.origin}
              </p>

              <blockquote className="text-[11px] text-white/85 italic border-l-2 border-[#C9A45C] pl-2.5 mt-2 leading-relaxed text-left">
                "{CAPTAIN_INFO.quote}"
              </blockquote>

              <p className="text-[10px] text-white/70 pt-1 leading-relaxed text-left">
                {CAPTAIN_INFO.bio}
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Date & Departure Selector */}
      <div className="px-5 pt-6">
        <span className="font-label-sm text-[9px] uppercase tracking-wider text-[#a67d52] font-bold block mb-1">
          Custom Reservation
        </span>
        <h2 className="font-serif text-[20px] text-[#754d24] mb-3">
          Select Date &amp; Window
        </h2>

        {/* Date Selector */}
        <div className="grid grid-cols-4 gap-2 mb-4">
          {days.map((d) => {
            const isSel = selectedDay === `${d.day} ${d.date}`;
            return (
              <button
                key={d.date}
                onClick={() => setSelectedDay(`${d.day} ${d.date}`)}
                className={`p-2.5 rounded-xl text-center transition-all border ${
                  isSel
                    ? 'bg-[#754d24] text-white border-[#754d24] shadow-xs'
                    : 'bg-white text-[#754d24] border-[#e6e2d9] hover:bg-[#f7f3ea]'
                }`}
              >
                <span
                  className={`font-label-sm text-[9px] uppercase block ${
                    isSel ? 'text-[#f7e8d0]' : 'text-[#7f756a]'
                  }`}
                >
                  {d.day}
                </span>
                <span className="text-[18px] font-bold block leading-tight">{d.date}</span>
                <span
                  className={`font-label-sm text-[8px] uppercase tracking-wider block mt-0.5 ${
                    isSel ? 'text-white' : 'text-[#a67d52]'
                  }`}
                >
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
                ? 'bg-white border-[#a67d52] shadow-xs ring-1 ring-[#a67d52]'
                : 'bg-white/70 border-[#e6e2d9]'
            }`}
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span
                  className={`w-3.5 h-3.5 rounded-full border flex items-center justify-center ${
                    selectedWindow === 'morning' ? 'border-[#754d24] bg-[#754d24]' : 'border-[#d1c5b8]'
                  }`}
                >
                  {selectedWindow === 'morning' && <span className="w-1.5 h-1.5 rounded-full bg-white"></span>}
                </span>
                <span className="text-[13px] font-bold text-[#754d24]">
                  Morning Sail · 09:30 AM – 1:30 PM
                </span>
              </div>
              <span className="px-2 py-0.5 rounded bg-[#ffdead] text-[#a67d52] font-label-sm text-[8px] uppercase font-bold">
                Optimal Coral Sun
              </span>
            </div>
            <p className="text-[11px] text-[#7f756a] pl-5 mt-1">
              Calm seas, maximum reef visibility, and swimming with sea turtles.
            </p>
          </div>

          {/* Sunset */}
          <div
            onClick={() => setSelectedWindow('sunset')}
            className={`p-3.5 rounded-xl border cursor-pointer transition-all ${
              selectedWindow === 'sunset'
                ? 'bg-white border-[#a67d52] shadow-xs ring-1 ring-[#a67d52]'
                : 'bg-white/70 border-[#e6e2d9]'
            }`}
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span
                  className={`w-3.5 h-3.5 rounded-full border flex items-center justify-center ${
                    selectedWindow === 'sunset' ? 'border-[#754d24] bg-[#754d24]' : 'border-[#d1c5b8]'
                  }`}
                >
                  {selectedWindow === 'sunset' && <span className="w-1.5 h-1.5 rounded-full bg-white"></span>}
                </span>
                <span className="text-[13px] font-bold text-[#754d24]">
                  Golden Sunset Voyage · 2:30 PM – 6:30 PM
                </span>
              </div>
              <span className="px-2 py-0.5 rounded bg-[#ece8df] text-[#7f756a] font-label-sm text-[8px] uppercase font-bold">
                Sundown Champagne
              </span>
            </div>
            <p className="text-[11px] text-[#7f756a] pl-5 mt-1">
              Warm Caribbean breeze, golden hour photography, and sunset champagne toast.
            </p>
          </div>
        </div>

        {/* Guest Manifest */}
        <div className="mt-4 p-3.5 rounded-xl bg-white border border-[#e6e2d9] flex items-center justify-between">
          <div>
            <span className="font-label-sm text-[9px] uppercase tracking-wider text-[#7f756a] block">
              Guest Manifest
            </span>
            <span className="text-[13px] font-semibold text-[#754d24]">
              {guestsCount} Guests ({GUEST_INFO.name} + {guestsCount - 1})
            </span>
            <p className="text-[10px] text-[#7f756a]">Galeon 470 Sky day capacity: Up to 12 guests</p>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => setGuestsCount(Math.max(1, guestsCount - 1))}
              className="w-8 h-8 rounded-lg bg-[#f1ede5] text-[#754d24] flex items-center justify-center font-bold text-sm hover:bg-[#e4ded3]"
            >
              -
            </button>
            <span className="w-6 text-center font-bold text-sm">{guestsCount}</span>
            <button
              onClick={() => setGuestsCount(Math.min(12, guestsCount + 1))}
              className="w-8 h-8 rounded-lg bg-[#f1ede5] text-[#754d24] flex items-center justify-center font-bold text-sm hover:bg-[#e4ded3]"
            >
              +
            </button>
          </div>
        </div>

        {/* Dietary Sync Card */}
        <div className="mt-3 p-3.5 rounded-xl bg-[#f7f3ea] border border-[#e6e2d9]">
          <div className="flex items-center justify-between text-xs">
            <span className="font-label-sm text-[9px] uppercase text-[#a67d52] font-bold flex items-center gap-1">
              <span className="material-symbols-outlined text-[14px]">sync</span>
              Concierge Profile Sync
            </span>
            <button
              onClick={() => onNavigate('personalize')}
              className="text-[#a67d52] font-semibold hover:underline"
            >
              Edit Preferences
            </button>
          </div>
          <p className="text-[12px] text-[#4e453c] mt-1 leading-relaxed">
            Pescatarian &amp; Gluten-Sensitive onboard catering, strictly no shellfish. Fresh yellowtail ceviche &amp; artisanal Mexican tapas prepared onboard.
          </p>
        </div>
      </div>

      {/* Transparent Billing Summary */}
      <div className="px-5 pt-6">
        <div className="p-4 rounded-xl bg-white border border-[#e6e2d9] space-y-2 text-xs">
          <div className="flex items-center justify-between">
            <div>
              <span className="font-label-sm text-[9px] uppercase tracking-wider text-[#7f756a] block">
                Billing Summary
              </span>
              <h3 className="font-headline-sm text-[16px] text-[#754d24]">
                {currentPkg.title} Valuation
              </h3>
            </div>
            <div className="text-right">
              <span className="line-through text-[#7f756a] text-xs block">
                ${currentPkg.valuationUSD.toLocaleString()}.00 USD
              </span>
              <span className="font-headline-sm text-[20px] text-[#754d24] leading-none">
                ${calculateTotal().toLocaleString()}.00 USD
              </span>
            </div>
          </div>

          <div className="pt-2 border-t border-[#f1ede5] space-y-1.5 text-[#4e453c]">
            <div className="flex justify-between">
              <span>Villa 102 (4N/5D) Entitlement Credit</span>
              <span className="font-semibold text-[#a67d52]">-$2,000.00 USD</span>
            </div>
            <div className="flex justify-between">
              <span>Master Captain &amp; Host Maritime Fees</span>
              <span className="font-semibold text-[#a67d52]">Prepaid by Villa</span>
            </div>
            <div className="flex justify-between">
              <span>Bahía de Mujeres &amp; Reef Marine Permits</span>
              <span className="font-semibold text-[#a67d52]">Included</span>
            </div>
          </div>

          <div className="pt-2 border-t border-[#f1ede5] flex items-center gap-2 text-[11px] text-[#7f756a]">
            <span className="material-symbols-outlined text-[15px] text-[#a67d52]">shield</span>
            <span>Zero incidental holds required. Completely protected under Villa 102 portfolio ledger.</span>
          </div>
        </div>
      </div>

      {/* Online Fleet Portal Link */}
      <div className="px-5 pt-6">
        <a
          href="https://kachavacaribe.com/"
          target="_blank"
          rel="noopener noreferrer"
          className="p-4 rounded-2xl bg-gradient-to-r from-[#0B1F33] to-[#122e49] text-white flex items-center justify-between border border-[#18B7C9]/30 hover:border-[#18B7C9] transition-all group"
        >
          <div className="space-y-0.5">
            <span className="text-[9px] uppercase tracking-[0.2em] text-[#C9A45C] font-semibold block">
              Official Fleet Portal
            </span>
            <h4 className="text-[14px] font-serif font-medium text-white flex items-center gap-1.5">
              <span>Explore Kachava Caribe Online</span>
              <span className="material-symbols-outlined text-[14px] group-hover:translate-x-1 transition-transform">
                arrow_forward
              </span>
            </h4>
            <p className="text-[10px] text-white/70">
              Browse full charter journals, vessel blueprints &amp; Caribbean photography at kachavacaribe.com
            </p>
          </div>
          <span className="w-9 h-9 rounded-full bg-white/10 flex items-center justify-center shrink-0 text-[#18B7C9]">
            <span className="material-symbols-outlined text-[18px]">launch</span>
          </span>
        </a>
      </div>

      {/* Floating Bottom Booking Action */}
      <div className="fixed bottom-16 left-0 right-0 z-30 bg-[#fdf9f0]/95 backdrop-blur-md border-t border-[#e6e2d9] p-3 shadow-lg">
        <div className="max-w-md mx-auto flex items-center justify-between gap-3">
          <div>
            <span className="font-label-sm text-[9px] uppercase tracking-wider text-[#7f756a] block">
              Total Investment
            </span>
            <div className="flex items-baseline gap-1">
              <span className="font-headline-sm text-[20px] text-[#754d24] leading-none">
                ${calculateTotal().toLocaleString()}.00
              </span>
              <span className="text-[11px] text-[#7f756a]">USD Net</span>
            </div>
            <span className="text-[10px] text-[#a67d52] font-medium block">
              {selectedDay} · {currentPkg.title.split(' ')[0]} Sail
            </span>
          </div>

          <button
            onClick={handleReserve}
            className="flex-1 max-w-[220px] bg-[#754d24] hover:bg-[#8b6339] text-white py-3.5 px-4 rounded-xl font-label-md text-[10px] uppercase tracking-widest flex items-center justify-center gap-1.5 transition-colors shadow-sm"
          >
            <span>Reserve Experience</span>
            <span className="material-symbols-outlined text-[16px]">arrow_forward</span>
          </button>
        </div>
      </div>
    </div>
  );
};
