import React, { useState } from 'react';
import { ScreenId } from '../types';
import { GUEST_INFO, IMAGES } from '../data/sanctuaryData';

interface HomeScreenProps {
  onNavigate: (screen: ScreenId) => void;
}

export const HomeScreen: React.FC<HomeScreenProps> = ({ onNavigate }) => {
  const [heroImgSrc, setHeroImgSrc] = useState<string>(
    'https://cdn.prod.website-files.com/689e55f0b5978802e2e73831/68a61638112df9ffdb54c165_3.-Fachada-Frontal-Individual-p-1080.jpg'
  );
  const [shareToast, setShareToast] = useState<string | null>(null);
  const [isShareModalOpen, setIsShareModalOpen] = useState<boolean>(false);
  const [showAllTasks, setShowAllTasks] = useState<boolean>(false);

  const showToast = (message: string) => {
    setShareToast(message);
    setTimeout(() => setShareToast(null), 3200);
  };

  const handleCopyLink = () => {
    if (navigator.clipboard) {
      navigator.clipboard.writeText(window.location.href);
    }
    setIsShareModalOpen(false);
    showToast('Reservation link copied to clipboard.');
  };

  return (
    <div className="flex flex-col w-full pb-32 pt-2 px-5 max-w-md mx-auto">
      {/* Toast Feedback */}
      {shareToast && (
        <div className="fixed top-20 left-1/2 -translate-x-1/2 z-50 bg-[#754d24] text-white px-5 py-2.5 rounded-full text-[12px] font-medium shadow-xl animate-in fade-in slide-in-from-top-2 duration-200 flex items-center gap-2 max-w-[90vw]">
          <span className="material-symbols-outlined text-[16px] text-[#c49a6c] shrink-0">check_circle</span>
          <span className="truncate">{shareToast}</span>
        </div>
      )}

      {/* 1. HERO: Authentic Kachava Property Photograph */}
      <div className="pt-2">
        <div className="relative rounded-2xl overflow-hidden shadow-md border border-[#e6e2d9] aspect-[16/10] w-full bg-[#2c2621]">
          <img
            src={heroImgSrc}
            srcSet="https://cdn.prod.website-files.com/689e55f0b5978802e2e73831/68a61638112df9ffdb54c165_3.-Fachada-Frontal-Individual-p-800.jpg 800w, https://cdn.prod.website-files.com/689e55f0b5978802e2e73831/68a61638112df9ffdb54c165_3.-Fachada-Frontal-Individual-p-1080.jpg 1080w, /kachava-villa-facade.jpg 1600w"
            sizes="(max-width: 640px) 100vw, 448px"
            alt="Kachava Sanctuary Villa 102"
            onError={() => {
              if (heroImgSrc !== '/kachava-villa-facade.jpg') {
                setHeroImgSrc('/kachava-villa-facade.jpg');
              }
            }}
            className="w-full h-full object-cover object-center transition-opacity duration-700"
          />
          {/* Subtle warm shadow vignette */}
          <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/30 to-black/20 pointer-events-none" />

          {/* Overlay: WELCOME TO KACHAVA · Sarah, your Tulum experience begins in 42 days. */}
          <div className="absolute inset-x-0 bottom-0 p-5 text-white flex flex-col justify-end">
            <span className="text-[10px] font-bold uppercase tracking-[0.25em] text-[#f7e8d0] mb-1 drop-shadow-xs">
              WELCOME TO KACHAVA
            </span>
            <p className="font-serif text-[18px] sm:text-[20px] font-normal leading-snug text-white/95 drop-shadow-sm">
              Sarah, your Tulum experience begins in 42 days.
            </p>
          </div>
        </div>
      </div>

      {/* 2. RESERVATION CARD */}
      <div className="pt-5">
        <div className="bg-white border border-[#e6e2d9] rounded-2xl p-5 shadow-xs relative">
          {/* Header Row: VILLA 102 + Share Stay icon */}
          <div className="flex items-start justify-between">
            <div>
              <span className="text-[10px] font-bold uppercase tracking-[0.18em] text-[#a67d52] block mb-0.5">
                YOUR RESIDENCE
              </span>
              <h1 className="font-serif text-[26px] text-[#754d24] tracking-tight leading-tight font-medium">
                VILLA 102
              </h1>
            </div>

            {/* Share Stay Icon in upper-right corner */}
            <button
              onClick={() => setIsShareModalOpen(true)}
              className="w-9 h-9 rounded-full bg-[#f7f3ea] hover:bg-[#ece8df] text-[#754d24] flex items-center justify-center transition-colors -mr-1 -mt-1 active:scale-95 shadow-xs"
              title="Share Stay"
              aria-label="Share Stay"
            >
              <span className="material-symbols-outlined text-[18px]">ios_share</span>
            </button>
          </div>

          {/* Reservation Details */}
          <div className="mt-3.5 pt-3.5 border-t border-[#f1ede5] space-y-1.5">
            <p className="font-sans text-[14px] font-medium text-[#754d24]">
              November 12–16, 2026
            </p>
            <p className="text-[12px] text-[#7f756a]">
              4 nights · 2 guests
            </p>
          </div>
        </div>
      </div>

      {/* 3. THREE PRIMARY ACTIONS DIRECTLY UNDERNEATH */}
      <div className="pt-4">
        <div className="grid grid-cols-3 gap-2.5">
          {/* CONCIERGE */}
          <button
            onClick={() => onNavigate('concierge')}
            className="flex flex-col items-center justify-center py-4 px-2 rounded-2xl bg-white border border-[#e6e2d9] shadow-xs hover:border-[#a67d52]/50 hover:bg-[#fcfaf5] transition-all group active:scale-[0.98]"
          >
            <span className="material-symbols-outlined text-[22px] text-[#a67d52] mb-1.5 group-hover:scale-105 transition-transform">
              support_agent
            </span>
            <span className="text-[10px] uppercase tracking-wider font-bold text-[#754d24] text-center leading-tight">
              CONCIERGE
            </span>
          </button>

          {/* PREPARE MY STAY */}
          <button
            onClick={() => onNavigate('personalize')}
            className="flex flex-col items-center justify-center py-4 px-2 rounded-2xl bg-white border border-[#e6e2d9] shadow-xs hover:border-[#a67d52]/50 hover:bg-[#fcfaf5] transition-all group active:scale-[0.98]"
          >
            <span className="material-symbols-outlined text-[22px] text-[#a67d52] mb-1.5 group-hover:scale-105 transition-transform">
              tune
            </span>
            <span className="text-[10px] uppercase tracking-wider font-bold text-[#754d24] text-center leading-tight">
              PREPARE MY STAY
            </span>
          </button>

          {/* STAY DETAILS */}
          <button
            onClick={() => onNavigate('included')}
            className="flex flex-col items-center justify-center py-4 px-2 rounded-2xl bg-white border border-[#e6e2d9] shadow-xs hover:border-[#a67d52]/50 hover:bg-[#fcfaf5] transition-all group active:scale-[0.98]"
          >
            <span className="material-symbols-outlined text-[22px] text-[#a67d52] mb-1.5 group-hover:scale-105 transition-transform">
              receipt_long
            </span>
            <span className="text-[10px] uppercase tracking-wider font-bold text-[#754d24] text-center leading-tight">
              STAY DETAILS
            </span>
          </button>
        </div>
      </div>

      {/* 4. BEFORE YOU ARRIVE (3 of 6 completed) */}
      <div className="pt-8">
        <div className="flex items-center justify-between mb-3 px-0.5">
          <div>
            <h2 className="text-[11px] uppercase tracking-[0.2em] font-bold text-[#8b6339]">
              BEFORE YOU ARRIVE
            </h2>
          </div>
          <span className="text-[11px] font-semibold text-[#a67d52] bg-[#f7f3ea] border border-[#e6dccc] px-2.5 py-0.5 rounded-full">
            3 of 6 completed
          </span>
        </div>

        {/* Progress Bar */}
        <div className="w-full h-1.5 bg-[#e6e2d9] rounded-full overflow-hidden mb-3.5">
          <div className="h-full bg-[#a67d52] rounded-full w-1/2 transition-all duration-500" />
        </div>

        {/* Incomplete items shown first (progressive disclosure) */}
        <div className="space-y-2.5">
          {/* ○ Complete preferences (Priority Action) */}
          <div
            onClick={() => onNavigate('personalize')}
            className="p-3.5 rounded-2xl bg-white border border-[#c49a6c] shadow-xs flex items-center justify-between cursor-pointer hover:bg-[#fdfaf3] transition-all group"
          >
            <div className="flex items-center gap-3">
              <div className="w-5 h-5 rounded-full border-2 border-[#a67d52] flex items-center justify-center shrink-0">
                <span className="w-2 h-2 rounded-full bg-[#a67d52]" />
              </div>
              <div>
                <span className="text-[13px] font-semibold text-[#754d24] block">
                  Complete preferences
                </span>
                <span className="text-[11px] text-[#7f756a]">
                  Dietary, room scent &amp; pillow selection
                </span>
              </div>
            </div>
            <span className="text-[10px] font-bold uppercase tracking-wider text-[#a67d52] bg-[#f7f3ea] px-2.5 py-1 rounded-md shrink-0">
              Start →
            </span>
          </div>

          {/* ○ Choose Spa or Golf */}
          <div
            onClick={() => onNavigate('included')}
            className="p-3.5 rounded-2xl bg-white border border-[#e6e2d9] shadow-xs flex items-center justify-between cursor-pointer hover:bg-[#fcfaf5] transition-all"
          >
            <div className="flex items-center gap-3">
              <div className="w-5 h-5 rounded-full border border-[#d1c5b8] flex items-center justify-center text-[#7f756a] shrink-0">
                <span className="w-1.5 h-1.5 rounded-full bg-[#d1c5b8]" />
              </div>
              <div>
                <span className="text-[13px] font-medium text-[#754d24] block">
                  Choose Spa or Golf
                </span>
                <span className="text-[11px] text-[#7f756a]">
                  Complimentary residency entitlement
                </span>
              </div>
            </div>
            <span className="material-symbols-outlined text-[18px] text-[#7f756a]">
              chevron_right
            </span>
          </div>

          {/* ○ Schedule Yacht */}
          <div
            onClick={() => onNavigate('yacht')}
            className="p-3.5 rounded-2xl bg-white border border-[#e6e2d9] shadow-xs flex items-center justify-between cursor-pointer hover:bg-[#fcfaf5] transition-all"
          >
            <div className="flex items-center gap-3">
              <div className="w-5 h-5 rounded-full border border-[#d1c5b8] flex items-center justify-center text-[#7f756a] shrink-0">
                <span className="w-1.5 h-1.5 rounded-full bg-[#d1c5b8]" />
              </div>
              <div>
                <span className="text-[13px] font-medium text-[#754d24] block">
                  Schedule Private Yacht
                </span>
                <span className="text-[11px] text-[#7f756a]">
                  Kachava Caribe · Galeon 470 Sky cruise
                </span>
              </div>
            </div>
            <span className="material-symbols-outlined text-[18px] text-[#7f756a]">
              chevron_right
            </span>
          </div>

          {/* Completed Items (shown if "View all" is toggled) */}
          {showAllTasks && (
            <div className="space-y-2 pt-1 border-t border-[#f1ede5] animate-in fade-in duration-200">
              {/* ✓ Reservation confirmed */}
              <div className="p-3 rounded-xl bg-[#fcfaf5] border border-[#e6e2d9]/60 flex items-center justify-between text-xs">
                <div className="flex items-center gap-2.5">
                  <span className="material-symbols-outlined text-[17px] text-[#3b6d41]">
                    check_circle
                  </span>
                  <span className="text-[#754d24] font-medium">Reservation confirmed</span>
                </div>
                <span className="text-[10px] text-[#3b6d41] font-semibold uppercase">Confirmed</span>
              </div>

              {/* ✓ Airport transportation confirmed */}
              <div
                onClick={() => onNavigate('transport')}
                className="p-3 rounded-xl bg-[#fcfaf5] border border-[#e6e2d9]/60 flex items-center justify-between text-xs cursor-pointer hover:bg-white"
              >
                <div className="flex items-center gap-2.5">
                  <span className="material-symbols-outlined text-[17px] text-[#3b6d41]">
                    check_circle
                  </span>
                  <span className="text-[#754d24] font-medium">Airport transportation confirmed</span>
                </div>
                <span className="text-[10px] text-[#3b6d41] font-semibold uppercase">Confirmed</span>
              </div>

              {/* ✓ Guest profile started */}
              <div
                onClick={() => onNavigate('profile')}
                className="p-3 rounded-xl bg-[#fcfaf5] border border-[#e6e2d9]/60 flex items-center justify-between text-xs cursor-pointer hover:bg-white"
              >
                <div className="flex items-center gap-2.5">
                  <span className="material-symbols-outlined text-[17px] text-[#3b6d41]">
                    check_circle
                  </span>
                  <span className="text-[#754d24] font-medium">Guest profile started</span>
                </div>
                <span className="text-[10px] text-[#3b6d41] font-semibold uppercase">Completed</span>
              </div>
            </div>
          )}

          {/* "View all" Progressive Disclosure Toggle */}
          <div className="text-center pt-1">
            <button
              onClick={() => setShowAllTasks(!showAllTasks)}
              className="text-[12px] font-medium text-[#a67d52] hover:underline inline-flex items-center gap-1 transition-colors"
            >
              <span>{showAllTasks ? 'Show fewer items' : 'View all 6 checklist items'}</span>
              <span className="material-symbols-outlined text-[15px]">
                {showAllTasks ? 'expand_less' : 'expand_more'}
              </span>
            </button>
          </div>
        </div>
      </div>

      {/* 5. COMING UP */}
      <div className="pt-8">
        <h2 className="text-[11px] uppercase tracking-[0.2em] font-bold text-[#8b6339] mb-3 px-0.5">
          COMING UP
        </h2>

        <div
          onClick={() => onNavigate('transport')}
          className="bg-white border border-[#e6e2d9] rounded-2xl p-4 shadow-xs flex items-center justify-between cursor-pointer hover:bg-[#fcfaf5] transition-all"
        >
          <div className="flex items-center gap-3.5">
            <div className="w-10 h-10 rounded-xl bg-[#f7f3ea] border border-[#e6e2d9] flex items-center justify-center text-[#a67d52] shrink-0">
              <span className="material-symbols-outlined text-[20px]">directions_car</span>
            </div>
            <div>
              <h3 className="font-serif text-[16px] font-medium text-[#754d24] leading-tight">
                Private Airport Transportation
              </h3>
              <p className="font-sans text-[12px] text-[#7f756a] mt-0.5">
                Nov 12 · 11:35 AM
              </p>
            </div>
          </div>

          <div className="flex items-center gap-1.5 shrink-0">
            <span className="text-[11px] font-semibold text-[#3b6d41] bg-[#eef5ed] border border-[#d6ebd3] px-2.5 py-1 rounded-md">
              Confirmed ✓
            </span>
          </div>
        </div>
      </div>

      {/* 6. DISCOVER KACHAVA (One Small Editorial Section) */}
      <div className="pt-8">
        <h2 className="text-[11px] uppercase tracking-[0.2em] font-bold text-[#8b6339] mb-3 px-0.5">
          DISCOVER KACHAVA
        </h2>

        <div className="bg-white border border-[#e6e2d9] rounded-2xl overflow-hidden shadow-xs">
          <div className="relative aspect-[16/9] w-full bg-[#ece8df]">
            <img
              src={IMAGES.yacht}
              alt="Discover Kachava"
              className="w-full h-full object-cover"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent" />
            <span className="absolute bottom-3 left-3 text-white text-[11px] font-medium tracking-wide">
              Bespoke Sanctuary Encounters
            </span>
          </div>

          <div className="p-4 space-y-3">
            <p className="text-[13px] text-[#5e5449] leading-relaxed">
              From private Galeon 470 Sky turquoise cruises to subterranean cenotes and ancestral fire degustations, discover private moments crafted for your stay.
            </p>

            <button
              onClick={() => onNavigate('explore')}
              className="w-full bg-[#754d24] hover:bg-[#603917] active:scale-[0.99] text-white py-3 px-4 rounded-xl text-[11px] font-semibold uppercase tracking-[0.14em] flex items-center justify-center gap-1.5 transition-colors shadow-xs"
            >
              <span>Explore Experiences</span>
              <span className="material-symbols-outlined text-[15px]">arrow_forward</span>
            </button>
          </div>
        </div>
      </div>

      {/* SHARE MODAL DIALOG */}
      {isShareModalOpen && (
        <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4 bg-black/60 backdrop-blur-xs animate-in fade-in duration-200">
          <div className="w-full max-w-sm bg-[#fdf9f0] border border-[#d1c5b8] rounded-t-3xl sm:rounded-2xl p-5 shadow-2xl">
            <div className="flex items-start justify-between pb-3 border-b border-[#e6e2d9]">
              <div>
                <span className="text-[9px] uppercase font-bold text-[#a67d52] tracking-widest block">
                  Residency Share
                </span>
                <h3 className="font-serif text-[19px] text-[#754d24] font-medium mt-0.5">
                  Share Stay Details
                </h3>
              </div>
              <button
                onClick={() => setIsShareModalOpen(false)}
                className="w-7 h-7 rounded-full bg-[#ece8df] flex items-center justify-center text-[#754d24]"
                aria-label="Close"
              >
                <span className="material-symbols-outlined text-[16px]">close</span>
              </button>
            </div>

            <div className="py-4 space-y-2.5 text-xs text-[#754d24]">
              <div className="p-3 rounded-xl bg-white border border-[#e6e2d9]">
                <p className="font-serif text-[15px] font-semibold text-[#754d24]">Villa 102 · Sarah Miller</p>
                <p className="text-[#7f756a] text-[11px] mt-0.5">November 12–16, 2026 · 4 nights · 2 guests</p>
              </div>

              <button
                onClick={handleCopyLink}
                className="w-full py-3 px-4 rounded-xl bg-[#754d24] hover:bg-[#603917] text-white text-[11px] font-semibold uppercase tracking-wider flex items-center justify-center gap-2 transition-colors shadow-xs"
              >
                <span className="material-symbols-outlined text-[16px]">content_copy</span>
                <span>Copy Reservation Link</span>
              </button>

              <button
                onClick={() => {
                  setIsShareModalOpen(false);
                  showToast('Stay invitation sent to Mark.');
                }}
                className="w-full py-2.5 px-4 rounded-xl bg-white border border-[#e6e2d9] text-[#754d24] text-[11px] font-semibold uppercase tracking-wider flex items-center justify-center gap-2 hover:bg-[#f7f3ea] transition-colors"
              >
                <span className="material-symbols-outlined text-[16px] text-[#a67d52]">send</span>
                <span>Share with Mark (Partner)</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
