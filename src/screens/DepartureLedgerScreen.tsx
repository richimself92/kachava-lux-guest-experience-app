import React, { useState } from 'react';
import { ScreenId } from '../types';
import { GUEST_INFO, IMAGES } from '../data/sanctuaryData';

interface DepartureLedgerScreenProps {
  onNavigate: (screen: ScreenId) => void;
}

export const DepartureLedgerScreen: React.FC<DepartureLedgerScreenProps> = ({ onNavigate }) => {
  const [isCheckedOut, setIsCheckedOut] = useState(false);
  const [toast, setToast] = useState<string | null>(null);

  const handleDownloadFolio = () => {
    setToast('Downloading Villa_102_Final_Folio_Sarah_Miller.pdf...');
    setTimeout(() => {
      window.print();
    }, 500);
  };

  const handleDownloadGallery = () => {
    setToast('Preparing high-resolution 18-photo sanctuary keepsake archive...');
    setTimeout(() => setToast(null), 3000);
  };

  const handleCompleteCheckOut = () => {
    setIsCheckedOut(true);
    setToast('Check-out completed peacefully. Carlos M. is waiting at Villa 102 Portico.');
  };

  return (
    <div className="flex flex-col w-full pb-32 pt-2">
      
      {/* Toast */}
      {toast && (
        <div className="fixed top-20 left-1/2 -translate-x-1/2 z-50 bg-[#754d24] text-white px-5 py-2.5 rounded-full text-xs font-medium shadow-xl animate-in fade-in duration-200">
          {toast}
        </div>
      )}

      {/* Header Info */}
      <div className="px-5 pt-3 pb-2 flex flex-col gap-1.5">
        <span className="font-label-sm text-[10px] uppercase tracking-widest text-[#a67d52] font-bold">
          Villa 102 · Unhurried Departure
        </span>
        <span className="text-[12px] text-[#7f756a]">
          Sunday, Nov 16 · AA 172 to MIA
        </span>

        <h1 className="font-headline-lg text-[#754d24] tracking-tight leading-tight mt-1">
          A Peaceful Departure, {GUEST_INFO.name.split(' ')[0]}
        </h1>

        <p className="font-body-sm text-[13px] text-[#4e453c] leading-relaxed">
          Linger in the sanctuary until your final moment. Your check-out, luggage collection, and airport transfer have been orchestrated seamlessly in the background.
        </p>
      </div>

      {/* Flight Card */}
      <div className="px-5 pt-3">
        <div className="p-4 rounded-2xl bg-white border border-[#e6e2d9] shadow-xs flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-[#f1ede5] text-[#754d24] flex items-center justify-center shrink-0">
              <span className="material-symbols-outlined text-[20px]">flight_takeoff</span>
            </div>
            <div>
              <span className="font-label-sm text-[9px] uppercase tracking-wider text-[#7f756a] block">
                American Airlines · AA 172
              </span>
              <span className="text-[15px] font-bold text-[#754d24]">
                CUN → MIA
              </span>
            </div>
          </div>

          <div className="text-right">
            <span className="px-2 py-0.5 rounded-full bg-[#eee3b3] text-[#665f39] font-label-sm text-[8px] uppercase font-bold">
              ● On Time
            </span>
            <span className="text-[11px] text-[#7f756a] block mt-1">3:45 PM · Term 3</span>
          </div>
        </div>
      </div>

      {/* Departure Timeline */}
      <div className="px-5 pt-6">
        <span className="font-label-sm text-[9px] uppercase tracking-wider text-[#a67d52] font-bold block mb-3">
          Seamless Departure Itinerary
        </span>

        <div className="space-y-4 relative before:absolute before:left-3 before:top-4 before:bottom-4 before:w-0.5 before:bg-[#e6e2d9]">
          
          {/* 11:30 AM */}
          <div className="flex items-start gap-3.5 relative z-10">
            <div className="w-6 h-6 rounded-full bg-[#ffdead] text-[#a67d52] flex items-center justify-center font-bold text-[10px] shrink-0 mt-0.5 shadow-xs">
              ●
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="text-[12px] font-bold text-[#754d24]">11:30 AM</span>
                <span className="text-[10px] text-[#7f756a] uppercase">Scheduled</span>
              </div>
              <h4 className="text-[13px] font-semibold text-[#754d24]">
                In-Villa Farewell Brunch &amp; Fresh Coconuts
              </h4>
              <p className="text-[11px] text-[#4e453c] mt-0.5">
                Prepared on your pool terrace by Chef Mateo.
              </p>
            </div>
          </div>

          {/* 12:45 PM */}
          <div className="flex items-start gap-3.5 relative z-10">
            <div className="w-6 h-6 rounded-full bg-[#ffdead] text-[#a67d52] flex items-center justify-center font-bold text-[10px] shrink-0 mt-0.5 shadow-xs">
              ●
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="text-[12px] font-bold text-[#754d24]">12:45 PM</span>
                <span className="text-[10px] text-[#7f756a] uppercase">Confirmed</span>
              </div>
              <h4 className="text-[13px] font-semibold text-[#754d24]">
                Discreet Luggage Retrieval
              </h4>
              <p className="text-[11px] text-[#4e453c] mt-0.5">
                Majordomo Eduardo collects tagged bags from foyer.
              </p>
            </div>
          </div>

          {/* 1:00 PM */}
          <div className="flex items-start gap-3.5 relative z-10">
            <div className="w-6 h-6 rounded-full bg-[#754d24] text-white flex items-center justify-center font-bold text-[10px] shrink-0 mt-0.5 shadow-xs">
              ●
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="text-[12px] font-bold text-[#754d24]">1:00 PM</span>
                <span className="text-[10px] text-[#a67d52] font-bold uppercase">Chauffeur Ready</span>
              </div>
              <h4 className="text-[13px] font-semibold text-[#754d24]">
                Private Mercedes-Benz EQS at Villa Portico
              </h4>
              <p className="text-[11px] text-[#4e453c] mt-0.5">
                Chauffeur Carlos waiting curbside with chilled amenities.
              </p>
            </div>
          </div>

          {/* 1:15 PM */}
          <div className="flex items-start gap-3.5 relative z-10">
            <div className="w-6 h-6 rounded-full bg-[#d1c5b8] text-white flex items-center justify-center font-bold text-[10px] shrink-0 mt-0.5">
              ●
            </div>
            <div>
              <span className="text-[12px] font-bold text-[#754d24]">1:15 PM</span>
              <h4 className="text-[13px] font-semibold text-[#754d24]">
                Scenic Sanctuary Transit to CUN Airport
              </h4>
              <p className="text-[11px] text-[#4e453c] mt-0.5">
                Estimated 70 min smooth transfer via 307 Bypass.
              </p>
            </div>
          </div>

          {/* 2:25 PM */}
          <div className="flex items-start gap-3.5 relative z-10">
            <div className="w-6 h-6 rounded-full bg-[#d1c5b8] text-white flex items-center justify-center font-bold text-[10px] shrink-0 mt-0.5">
              ●
            </div>
            <div>
              <span className="text-[12px] font-bold text-[#754d24]">2:25 PM</span>
              <h4 className="text-[13px] font-semibold text-[#754d24]">
                Curbside Skycap Escort · Terminal 3
              </h4>
              <p className="text-[11px] text-[#4e453c] mt-0.5">
                Dedicated porter escort to VIP security fast-track.
              </p>
            </div>
          </div>

        </div>

        <button
          onClick={() => {
            setToast('Late checkout request (up to 2:00 PM) dispatched to Eduardo.');
            setTimeout(() => setToast(null), 3000);
          }}
          className="mt-4 w-full py-2.5 rounded-xl bg-white border border-[#e6e2d9] text-[#754d24] text-xs font-semibold uppercase font-label-md hover:bg-[#f7f3ea] flex items-center justify-center gap-1.5"
        >
          <span className="material-symbols-outlined text-[16px] text-[#a67d52]">schedule</span>
          <span>Request Custom Timing / Late Check-Out</span>
        </button>
      </div>

      {/* Door to Terminal Transfer */}
      <div className="px-5 pt-6">
        <div className="p-4 rounded-2xl bg-[#f7f3ea] border border-[#e6e2d9] space-y-3">
          <div className="flex items-center justify-between">
            <span className="font-label-sm text-[9px] uppercase tracking-wider text-[#7f756a] font-bold">
              Door-To-Terminal Transfer
            </span>
            <span className="px-2 py-0.5 rounded bg-white text-[#a67d52] font-label-sm text-[8px] font-bold uppercase">
              Fleet #04
            </span>
          </div>

          <div className="flex items-center gap-3">
            <img
              src={IMAGES.carlosChauffeur}
              alt="Carlos M."
              className="w-12 h-12 rounded-full object-cover shadow-xs"
            />
            <div>
              <h3 className="font-headline-sm text-[16px] text-[#754d24]">Carlos M.</h3>
              <p className="text-[11px] text-[#7f756a]">Private Chauffeur · 7-Year Sanctuary Veteran</p>
              <span className="text-[10px] text-[#a67d52] font-semibold">★ Dedicated Sanctuary Care</span>
            </div>
          </div>

          <div className="p-3 bg-white rounded-xl space-y-2 text-xs">
            <div className="flex items-center justify-between">
              <span className="font-bold text-[#754d24]">Mercedes-Benz EQS SUV</span>
              <span className="font-label-sm text-[8px] text-[#a67d52] uppercase font-bold">Whisper Electric</span>
            </div>
            <div className="grid grid-cols-2 gap-1 text-[11px] text-[#4e453c]">
              <span>🌡 Pre-cooled 71°F</span>
              <span>📶 High-Speed Wi-Fi</span>
              <span>🌿 Chilled Eucalyptus</span>
              <span>💧 Artisan Water</span>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-2 pt-1">
            <a
              href="tel:+529841020000"
              className="py-2 rounded-lg bg-white border border-[#d1c5b8] text-center text-xs font-semibold text-[#754d24] flex items-center justify-center gap-1.5"
            >
              <span className="material-symbols-outlined text-[15px] text-[#a67d52]">call</span>
              <span>Call Carlos</span>
            </a>
            <button
              onClick={() => onNavigate('concierge')}
              className="py-2 rounded-lg bg-white border border-[#d1c5b8] text-center text-xs font-semibold text-[#754d24] flex items-center justify-center gap-1.5"
            >
              <span className="material-symbols-outlined text-[15px] text-[#a67d52]">support_agent</span>
              <span>Majordomo Desk</span>
            </button>
          </div>
        </div>
      </div>

      {/* Effortless Luggage Care */}
      <div className="px-5 pt-4">
        <div className="p-4 rounded-2xl bg-white border border-[#e6e2d9] space-y-2">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2 text-[#754d24]">
              <span className="material-symbols-outlined text-[#a67d52] text-[20px]">luggage</span>
              <h3 className="font-headline-sm text-[16px] text-[#754d24]">Effortless Luggage Care</h3>
            </div>
            <span className="text-[11px] text-[#7f756a] font-bold">12:45 PM</span>
          </div>

          <p className="text-[12px] text-[#4e453c] leading-relaxed">
            Simply leave your packed cases inside the Villa 102 vestibule. Eduardo will attach hand-stamped leather destination tags and place them directly into Carlos’s vehicle.
          </p>

          <div className="p-2.5 bg-[#f7f3ea] rounded-xl flex items-center justify-between text-xs text-[#754d24]">
            <div className="flex items-center gap-2">
              <span className="material-symbols-outlined text-[#a67d52] text-[16px]">check</span>
              <span>Artisanal Packing Assistance (Garment tissue wrap &amp; cedar sachet)</span>
            </div>
            <span className="font-label-sm text-[8px] uppercase font-bold text-[#a67d52]">Included</span>
          </div>
        </div>
      </div>

      {/* Villa 102 Final Ledger */}
      <div className="px-5 pt-6">
        <div className="p-5 rounded-2xl bg-white border border-[#e6e2d9] shadow-xs space-y-3">
          <div className="flex items-center justify-between">
            <div>
              <span className="font-label-sm text-[9px] uppercase tracking-wider text-[#a67d52] font-bold block">
                Discreet Settle
              </span>
              <h3 className="font-headline-sm text-[19px] text-[#754d24]">
                Villa 102 Final Ledger
              </h3>
            </div>
            <span className="text-[10px] text-[#7f756a]">Automatic at 2:00 PM</span>
          </div>

          <p className="text-[11px] text-[#7f756a] leading-relaxed">
            Zero front-desk queues. Charged smoothly to {GUEST_INFO.folioCard} without paper signatures.
          </p>

          {/* Line items */}
          <div className="space-y-3 pt-2 border-t border-[#f1ede5] text-xs">
            {/* 1 */}
            <div className="flex items-start justify-between">
              <div>
                <span className="font-semibold text-[#754d24] block">In-Villa Degustation by Chef Mateo</span>
                <span className="text-[10px] text-[#7f756a]">Nov 14 · Private 5-course garden dinner</span>
                <span className="inline-block px-1.5 py-0.2 rounded bg-[#f1ede5] text-[#a67d52] text-[8px] uppercase font-bold mt-0.5">Stay Privilege</span>
              </div>
              <div className="text-right">
                <span className="font-bold text-[#754d24] block">$0.00 USD</span>
                <span className="text-[10px] text-[#7f756a] line-through">$420.00</span>
              </div>
            </div>

            {/* 2 */}
            <div className="flex items-start justify-between">
              <div>
                <span className="font-semibold text-[#754d24] block">Kachava Caribe · Galeon 470 Sky Cruise</span>
                <span className="text-[10px] text-[#7f756a]">Nov 14 · 4-Hour Half-Day Experience</span>
                <span className="inline-block px-1.5 py-0.2 rounded bg-[#f1ede5] text-[#a67d52] text-[8px] uppercase font-bold mt-0.5">Stay Privilege</span>
              </div>
              <div className="text-right">
                <span className="font-bold text-[#754d24] block">$0.00 USD</span>
                <span className="text-[10px] text-[#7f756a] line-through">$2,000.00</span>
              </div>
            </div>

            {/* 3 */}
            <div className="flex items-start justify-between">
              <div>
                <span className="font-semibold text-[#754d24] block">Daily Organic Artisanal Breakfast</span>
                <span className="text-[10px] text-[#7f756a]">Nov 11–Nov 16 · In-suite service</span>
                <span className="inline-block px-1.5 py-0.2 rounded bg-[#f1ede5] text-[#a67d52] text-[8px] uppercase font-bold mt-0.5">Villa Entitlement</span>
              </div>
              <div className="text-right">
                <span className="font-bold text-[#754d24] block">$0.00 USD</span>
              </div>
            </div>

            {/* 4 */}
            <div className="flex items-start justify-between border-t border-[#f1ede5] pt-2">
              <div>
                <span className="font-semibold text-[#754d24] block">Subterranean Cenote Dos Ojos Dive</span>
                <span className="text-[10px] text-[#7f756a]">Private guide, gear &amp; cavern certification (2 guests)</span>
              </div>
              <span className="font-bold text-[#754d24]">$760.00 USD</span>
            </div>

            {/* 5 */}
            <div className="flex items-start justify-between">
              <div>
                <span className="font-semibold text-[#754d24] block">Stock My Villa Curated Larder</span>
                <span className="text-[10px] text-[#7f756a]">Cold-pressed botanical elixirs &amp; cacao provisions</span>
              </div>
              <span className="font-bold text-[#754d24]">$128.00 USD</span>
            </div>

            {/* 6 */}
            <div className="flex items-start justify-between">
              <div>
                <span className="font-semibold text-[#754d24] block">Organic Sun &amp; Ocean Recovery Kit</span>
                <span className="text-[10px] text-[#7f756a]">Artisanal aloe, chukum body mist &amp; SPF 50</span>
              </div>
              <span className="font-bold text-[#754d24]">$65.00 USD</span>
            </div>

            {/* 7 */}
            <div className="flex items-start justify-between">
              <div>
                <span className="font-semibold text-[#754d24] block">Sanctuary Ecological Biosphere Levy</span>
                <span className="text-[10px] text-[#7f756a]">Direct coral reef &amp; cenote conservation grant</span>
              </div>
              <span className="font-bold text-[#754d24]">$32.00 USD</span>
            </div>

            {/* Total */}
            <div className="pt-3 border-t border-[#d1c5b8] flex items-baseline justify-between">
              <div>
                <span className="font-label-md text-[11px] uppercase font-bold text-[#754d24] block">
                  Final Settled Total
                </span>
                <span className="text-[11px] text-[#7f756a]">{GUEST_INFO.folioCard}</span>
              </div>
              <div className="text-right">
                <span className="font-headline-sm text-[22px] text-[#754d24] block leading-none">
                  $985.00
                </span>
                <span className="text-[10px] text-[#a67d52] font-semibold uppercase">Pre-authorized</span>
              </div>
            </div>
          </div>

          {/* Action buttons */}
          <div className="grid grid-cols-2 gap-2 pt-3 border-t border-[#f1ede5]">
            <button
              onClick={handleDownloadFolio}
              className="py-2.5 px-2 rounded-xl bg-[#f1ede5] text-[#754d24] font-label-md text-[9px] uppercase font-bold flex items-center justify-center gap-1 hover:bg-[#ece8df]"
            >
              <span className="material-symbols-outlined text-[15px]">download</span>
              <span>Download PDF Folio</span>
            </button>
            <button
              onClick={() => onNavigate('concierge')}
              className="py-2.5 px-2 rounded-xl bg-[#f1ede5] text-[#754d24] font-label-md text-[9px] uppercase font-bold flex items-center justify-center gap-1 hover:bg-[#ece8df]"
            >
              <span className="material-symbols-outlined text-[15px]">help</span>
              <span>Folio Inquiry</span>
            </button>
          </div>
        </div>
      </div>

      {/* Sanctuary Memento Keepsake */}
      <div className="px-5 pt-6">
        <div className="p-5 rounded-2xl bg-[#f7f3ea] border border-[#e6e2d9] space-y-3">
          <div className="flex items-center justify-between">
            <span className="font-label-sm text-[9px] uppercase tracking-wider text-[#a67d52] font-bold">
              Sanctuary Memento
            </span>
            <span className="px-2 py-0.5 rounded bg-white text-[#a67d52] font-label-sm text-[8px] font-bold">
              18 Moments
            </span>
          </div>

          <h3 className="font-headline-sm text-[18px] text-[#754d24]">
            Your Curated Tulum Keepsake
          </h3>

          <p className="text-[12px] text-[#4e453c] leading-relaxed">
            Our resident photographer has curated your private yacht excursion and cenote blessing into a private archival album.
          </p>

          <div className="grid grid-cols-2 gap-2 py-1">
            <img src={IMAGES.yacht} alt="Keepsake 1" className="w-full h-28 object-cover rounded-xl" />
            <img src={IMAGES.cenote} alt="Keepsake 2" className="w-full h-28 object-cover rounded-xl" />
          </div>

          <div className="p-3 bg-white rounded-xl flex items-center gap-3 text-xs">
            <span className="material-symbols-outlined text-[#a67d52] text-[20px]">card_giftcard</span>
            <div>
              <span className="font-bold text-[#754d24] block">Amber &amp; Copal Sacred Diffuser</span>
              <p className="text-[11px] text-[#7f756a]">Placed in Carlos’s vehicle for your return home.</p>
            </div>
          </div>

          <button
            onClick={handleDownloadGallery}
            className="w-full py-2.5 rounded-xl bg-white border border-[#d1c5b8] text-[#754d24] font-label-md text-[10px] uppercase font-bold flex items-center justify-center gap-1.5 hover:bg-[#ece8df]"
          >
            <span className="material-symbols-outlined text-[16px] text-[#a67d52]">photo_library</span>
            <span>Download Sanctuary Gallery (18 Photos)</span>
          </button>
        </div>
      </div>

      {/* Team Blessing */}
      <div className="px-5 pt-6 text-center">
        <p className="font-body-sm text-[12px] text-[#7f756a] italic leading-relaxed max-w-xs mx-auto">
          “May the quiet memory of the jungle breeze and cenote stillness follow you across every horizon.”
        </p>
        <span className="font-label-sm text-[9px] text-[#a67d52] uppercase tracking-wider block mt-1 font-bold">
          — Eduardo &amp; The Kachava Care Team
        </span>
      </div>

      {/* Floating Bottom Check-out Action */}
      <div className="fixed bottom-16 left-0 right-0 z-30 bg-[#fdf9f0]/95 backdrop-blur-md border-t border-[#e6e2d9] p-3 shadow-lg">
        <div className="max-w-md mx-auto flex items-center justify-between gap-3">
          <div>
            <span className="font-label-sm text-[8px] uppercase tracking-wider text-[#7f756a] block">
              Departure Confirmed
            </span>
            <span className="font-headline-sm text-[18px] text-[#754d24] leading-none block">
              1:00 PM
            </span>
            <span className="text-[10px] text-[#a67d52] truncate max-w-[130px] block">
              Villa key stays live...
            </span>
          </div>

          <button
            onClick={handleCompleteCheckOut}
            className={`flex-1 py-3.5 px-4 rounded-xl font-label-md text-[10px] uppercase tracking-widest flex items-center justify-center gap-1.5 transition-colors shadow-sm ${
              isCheckedOut
                ? 'bg-[#a67d52] text-white'
                : 'bg-[#754d24] hover:bg-[#8b6339] text-white'
            }`}
          >
            <span>{isCheckedOut ? '✓ Check-Out Completed' : 'Complete Check-Out'}</span>
            <span className="material-symbols-outlined text-[16px]">arrow_forward</span>
          </button>
        </div>
      </div>

    </div>
  );
};
