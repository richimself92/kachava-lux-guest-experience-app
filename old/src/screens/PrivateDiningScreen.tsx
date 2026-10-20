import React, { useState } from 'react';
import { ScreenId } from '../types';
import { GUEST_INFO, IMAGES } from '../data/sanctuaryData';

interface PrivateDiningScreenProps {
  onNavigate: (screen: ScreenId) => void;
}

export const PrivateDiningScreen: React.FC<PrivateDiningScreenProps> = ({ onNavigate }) => {
  const [diningTab, setDiningTab] = useState<'chef' | 'breakfast'>('chef');
  const [selectedEvening, setSelectedEvening] = useState<string>('Fri 14');
  const [selectedTime, setSelectedTime] = useState<string>('Degustation 8:00 PM');
  const [tableSetting, setTableSetting] = useState<'terrace' | 'pergola' | 'palapa'>('terrace');
  const [selectedMenu, setSelectedMenu] = useState<'fuego' | 'tierra' | 'flora'>('fuego');
  const [guests, setGuests] = useState<number>(2);
  const [toast, setToast] = useState<string | null>(null);

  const handleConfirm = () => {
    setToast('In-Villa Dining confirmed for Nov 14 at 8:00 PM. Chef Mateo & Sommelier Elena notified.');
    setTimeout(() => {
      onNavigate('home');
    }, 1500);
  };

  return (
    <div className="flex flex-col w-full pb-32 pt-2">
      
      {/* Toast */}
      {toast && (
        <div className="fixed top-20 left-1/2 -translate-x-1/2 z-50 bg-[#754d24] text-white px-5 py-2.5 rounded-full text-xs font-medium shadow-xl animate-in fade-in duration-200">
          {toast}
        </div>
      )}

      {/* Header Eyebrow & Title */}
      <div className="px-5 pt-3 pb-2 flex flex-col gap-1.5">
        <span className="font-label-sm text-[10px] uppercase tracking-widest text-[#a67d52] flex items-center gap-1.5 font-bold">
          <span className="w-1.5 h-1.5 rounded-full bg-[#a67d52]"></span>
          Villa 102 Bespoke Gastronomy · Included
        </span>

        <h1 className="font-headline-lg text-[#754d24] tracking-tight leading-tight mt-1">
          In-Villa &amp; Sanctuary Dining
        </h1>

        <p className="font-body-sm text-[13px] text-[#4e453c] leading-relaxed">
          Curated culinary moments by Executive Chef Mateo. Organic endemic ingredients, fire-pit roasted Mayan traditions, and ocean-to-table freshness.
        </p>
      </div>

      {/* Segmented Controls */}
      <div className="px-5 pt-2">
        <div className="bg-[#ece8df] p-1 rounded-xl flex items-center">
          <button
            onClick={() => setDiningTab('chef')}
            className={`flex-1 py-2.5 rounded-lg font-label-md text-[10px] uppercase tracking-wider font-semibold transition-all ${
              diningTab === 'chef'
                ? 'bg-[#754d24] text-white shadow-xs'
                : 'text-[#754d24] hover:text-[#a67d52]'
            }`}
          >
            In-Villa Chef Experience
          </button>
          <button
            onClick={() => setDiningTab('breakfast')}
            className={`flex-1 py-2.5 rounded-lg font-label-md text-[10px] uppercase tracking-wider font-semibold transition-all ${
              diningTab === 'breakfast'
                ? 'bg-[#754d24] text-white shadow-xs'
                : 'text-[#754d24] hover:text-[#a67d52]'
            }`}
          >
            Artisanal Breakfast
          </button>
        </div>
      </div>

      {diningTab === 'breakfast' ? (
        /* Breakfast Info View */
        <div className="px-5 pt-5 space-y-4">
          <div className="bg-white border border-[#e6e2d9] rounded-2xl overflow-hidden shadow-xs">
            <img src={IMAGES.breakfast} alt="Breakfast" className="w-full h-52 object-cover" />
            <div className="p-4 space-y-2">
              <span className="font-label-sm text-[10px] text-[#a67d52] uppercase font-bold">Daily Privilege</span>
              <h3 className="font-headline-sm text-[20px] text-[#754d24]">Sanctuary Breakfast In-Suite</h3>
              <p className="text-[12px] text-[#4e453c] leading-relaxed">
                Enjoy wood-fired sourdough, freshly squeezed mamey &amp; passionfruit elixirs, organic pasture eggs with epazote, and hot Mayan spiced hot chocolate served on your pool terrace every morning from 7:00 to 11:30 AM.
              </p>
              <div className="p-3 bg-[#f7f3ea] rounded-xl text-xs text-[#754d24] font-semibold mt-2">
                ✓ No reservation needed — simply dial Butler Desk or message Mateo on WhatsApp when you wake.
              </div>
            </div>
          </div>
        </div>
      ) : (
        /* Chef In-Villa View */
        <>
          {/* Privilege Banner */}
          <div className="px-5 pt-4">
            <div className="bg-[#f7f3ea] border border-[#e6e2d9] rounded-2xl p-4 flex items-center justify-between">
              <div>
                <span className="font-label-sm text-[9px] uppercase tracking-wider text-[#a67d52] font-bold block">
                  1 Complimentary Dinner Credit
                </span>
                <h3 className="font-headline-sm text-[18px] text-[#754d24] mt-0.5">
                  Private Degustation
                </h3>
                <p className="text-[11px] text-[#7f756a]">
                  Private outdoor copal fire terrace prep
                </p>
              </div>

              <div className="text-right">
                <span className="text-[10px] text-[#7f756a] line-through block">Valued at $650 USD</span>
                <span className="font-headline-sm text-[20px] text-[#754d24] leading-none">$0 Due</span>
                <span className="text-[10px] text-[#a67d52] font-semibold block mt-0.5">Villa 102 Entitlement</span>
              </div>
            </div>
          </div>

          {/* Lead Alchemist Card */}
          <div className="px-5 pt-4">
            <div className="bg-white border border-[#e6e2d9] rounded-2xl overflow-hidden shadow-xs">
              <div className="relative h-48 w-full">
                <img
                  src={IMAGES.dinnerChef}
                  alt="Chef Mateo & Sommelier Elena"
                  className="w-full h-full object-cover"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/85 via-black/25 to-transparent"></div>

                <div className="absolute bottom-3 left-4 right-4 text-white flex items-end justify-between">
                  <div>
                    <span className="font-label-sm text-[9px] uppercase text-[#f7e8d0] tracking-wider block">
                      Lead Alchemist
                    </span>
                    <h3 className="font-headline-sm text-[19px] text-white">
                      Chef Mateo &amp; Sommelier Elena
                    </h3>
                  </div>
                  <span className="w-8 h-8 rounded-full bg-white/20 backdrop-blur-md flex items-center justify-center text-white">
                    <span className="material-symbols-outlined text-[18px]">restaurant</span>
                  </span>
                </div>
              </div>

              <div className="p-4 bg-[#fdf9f0]">
                <p className="text-[12px] text-[#4e453c] italic leading-relaxed">
                  “Every dish is a ritual of memory, fire, and limestone soil. We prepare the catch delivered this morning by fishermen from Punta Allen directly on your villa's private terrace.”
                </p>
              </div>
            </div>
          </div>

          {/* 4th Anniversary Honoring */}
          <div className="px-5 pt-4">
            <div className="p-3.5 rounded-xl bg-[#f7f3ea] border border-[#e6e2d9] flex items-start gap-3">
              <span className="material-symbols-outlined text-[#a67d52] text-[20px] shrink-0 mt-0.5">celebration</span>
              <div className="flex-1">
                <div className="flex items-center justify-between">
                  <span className="font-label-sm text-[9px] uppercase tracking-wider text-[#a67d52] font-bold">
                    4th Anniversary Honoring
                  </span>
                  <span className="px-2 py-0.5 rounded bg-[#ffdead] text-[#a67d52] font-label-sm text-[8px] uppercase font-bold">
                    Pre-Arranged
                  </span>
                </div>
                <p className="text-[12px] text-[#4e453c] mt-1 leading-relaxed">
                  Anniversary copal candlelit ambiance, pre-chilled Ruinart Brut Champagne, and personalized confection script: <strong className="text-[#754d24]">“Happy 4th Anniversary Sarah &amp; Mark”</strong>.
                </p>
              </div>
            </div>
          </div>

          {/* Select Evening Ritual */}
          <div className="px-5 pt-6">
            <div className="flex items-center justify-between mb-2">
              <h2 className="font-headline-sm text-[18px] text-[#754d24]">
                Select Evening Ritual
              </h2>
              <span className="font-label-sm text-[10px] text-[#7f756a]">Nov 12 – Nov 16</span>
            </div>

            <div className="space-y-2">
              {/* Wed 12 */}
              <div className="p-3 rounded-xl bg-white/60 border border-[#e6e2d9] flex items-center justify-between opacity-70">
                <div className="flex items-center gap-2">
                  <span className="material-symbols-outlined text-[16px] text-[#a67d52]">check_circle</span>
                  <span className="text-[13px] font-medium text-[#754d24]">Wed, Nov 12</span>
                </div>
                <span className="text-[11px] text-[#7f756a]">Arrival Dinner (Booked)</span>
              </div>

              {/* Thu 13 */}
              <div
                onClick={() => setSelectedEvening('Thu 13')}
                className={`p-3 rounded-xl border cursor-pointer transition-all flex items-center justify-between ${
                  selectedEvening === 'Thu 13' ? 'bg-[#754d24] text-white border-[#754d24]' : 'bg-white border-[#e6e2d9]'
                }`}
              >
                <div className="flex items-center gap-2">
                  <span className={`w-3.5 h-3.5 rounded-full border ${selectedEvening === 'Thu 13' ? 'border-white bg-[#f7e8d0]' : 'border-[#d1c5b8]'}`}></span>
                  <span className="text-[13px] font-medium">Thu, Nov 13</span>
                </div>
                <span className={`text-[11px] ${selectedEvening === 'Thu 13' ? 'text-white/80' : 'text-[#7f756a]'}`}>Open for Booking</span>
              </div>

              {/* Fri 14 (Selected) */}
              <div
                onClick={() => setSelectedEvening('Fri 14')}
                className={`p-3.5 rounded-xl border cursor-pointer transition-all ${
                  selectedEvening === 'Fri 14'
                    ? 'bg-[#754d24] text-white border-[#754d24] shadow-xs'
                    : 'bg-white border-[#e6e2d9]'
                }`}
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <span className="w-3.5 h-3.5 rounded-full border border-white bg-[#f7e8d0]"></span>
                    <span className="text-[13px] font-bold">Fri, Nov 14</span>
                  </div>
                  <span className="px-2 py-0.5 rounded bg-[#ffdead] text-[#754d24] font-label-sm text-[8px] uppercase font-bold">
                    Anniversary Night
                  </span>
                </div>
                <p className={`text-[11px] mt-1 pl-5 ${selectedEvening === 'Fri 14' ? 'text-[#f7e8d0]' : 'text-[#7f756a]'}`}>
                  Selected: Optimal pairing with twilight ocean breeze and copal ceremony
                </p>
              </div>

              {/* Sat 15 */}
              <div
                onClick={() => setSelectedEvening('Sat 15')}
                className={`p-3 rounded-xl border cursor-pointer transition-all flex items-center justify-between ${
                  selectedEvening === 'Sat 15' ? 'bg-[#754d24] text-white border-[#754d24]' : 'bg-white border-[#e6e2d9]'
                }`}
              >
                <div className="flex items-center gap-2">
                  <span className={`w-3.5 h-3.5 rounded-full border ${selectedEvening === 'Sat 15' ? 'border-white bg-[#f7e8d0]' : 'border-[#d1c5b8]'}`}></span>
                  <span className="text-[13px] font-medium">Sat, Nov 15</span>
                </div>
                <span className={`text-[11px] ${selectedEvening === 'Sat 15' ? 'text-white/80' : 'text-[#7f756a]'}`}>Farewell Evening (Available)</span>
              </div>
            </div>

            {/* Service Time Window */}
            <div className="mt-4">
              <span className="font-label-sm text-[9px] uppercase tracking-wider text-[#7f756a] block mb-1.5 font-bold">
                Service Time Window
              </span>
              <div className="grid grid-cols-3 gap-2">
                {[
                  { id: 'Sunset 6:30 PM', label: 'Sunset', time: '6:30 PM' },
                  { id: 'Degustation 8:00 PM', label: 'Degustation', time: '8:00 PM' },
                  { id: 'Late Copal 9:00 PM', label: 'Late Copal', time: '9:00 PM' },
                ].map(t => {
                  const isSel = selectedTime === t.id;
                  return (
                    <button
                      key={t.id}
                      onClick={() => setSelectedTime(t.id)}
                      className={`py-2 px-1 rounded-xl text-center border transition-all ${
                        isSel
                          ? 'bg-[#754d24] text-white border-[#754d24] shadow-xs'
                          : 'bg-white text-[#754d24] border-[#e6e2d9]'
                      }`}
                    >
                      <span className={`font-label-sm text-[8px] uppercase block ${isSel ? 'text-[#f7e8d0]' : 'text-[#7f756a]'}`}>
                        {t.label}
                      </span>
                      <span className="text-[12px] font-bold block">{t.time}</span>
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Guest count */}
            <div className="mt-4 p-3 rounded-xl bg-white border border-[#e6e2d9] flex items-center justify-between">
              <div>
                <span className="font-label-sm text-[9px] uppercase text-[#7f756a] block">Guest Count</span>
                <span className="text-[13px] font-semibold text-[#754d24]">{guests} Guests (Included with Villa 102)</span>
                <p className="text-[10px] text-[#7f756a]">+$180 per additional visiting guest</p>
              </div>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => setGuests(Math.max(1, guests - 1))}
                  className="w-8 h-8 rounded-lg bg-[#f1ede5] text-[#754d24] font-bold"
                >
                  -
                </button>
                <span className="w-4 text-center font-bold text-sm">{guests}</span>
                <button
                  onClick={() => setGuests(Math.min(6, guests + 1))}
                  className="w-8 h-8 rounded-lg bg-[#f1ede5] text-[#754d24] font-bold"
                >
                  +
                </button>
              </div>
            </div>

            {/* Table Setting */}
            <div className="mt-4">
              <span className="font-label-sm text-[9px] uppercase tracking-wider text-[#7f756a] block mb-1.5 font-bold">
                Private Table Setting
              </span>

              <div className="space-y-2">
                {/* Setting 1: Terrace */}
                <div
                  onClick={() => setTableSetting('terrace')}
                  className={`p-3 rounded-xl border cursor-pointer transition-all flex items-center justify-between ${
                    tableSetting === 'terrace' ? 'bg-[#f7f3ea] border-[#a67d52]' : 'bg-white border-[#e6e2d9]'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <span className="material-symbols-outlined text-[#a67d52] text-[20px]">deck</span>
                    <div>
                      <h4 className="text-[13px] font-bold text-[#754d24]">Villa 102 Oceanfront Pool Terrace</h4>
                      <p className="text-[11px] text-[#7f756a]">Beside plunge pool under natural star canopy</p>
                    </div>
                  </div>
                  <span className={`w-4 h-4 rounded-full border flex items-center justify-center ${tableSetting === 'terrace' ? 'border-[#754d24] bg-[#754d24]' : 'border-[#d1c5b8]'}`}>
                    {tableSetting === 'terrace' && <span className="w-1.5 h-1.5 rounded-full bg-white"></span>}
                  </span>
                </div>

                {/* Setting 2: Pergola */}
                <div
                  onClick={() => setTableSetting('pergola')}
                  className={`p-3 rounded-xl border cursor-pointer transition-all flex items-center justify-between ${
                    tableSetting === 'pergola' ? 'bg-[#f7f3ea] border-[#a67d52]' : 'bg-white border-[#e6e2d9]'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <span className="material-symbols-outlined text-[#a67d52] text-[20px]">roofing</span>
                    <div>
                      <h4 className="text-[13px] font-bold text-[#754d24]">Indoor Chukum Dining Pergola</h4>
                      <p className="text-[11px] text-[#7f756a]">Air-conditioned sheltered limestone room</p>
                    </div>
                  </div>
                  <span className={`w-4 h-4 rounded-full border flex items-center justify-center ${tableSetting === 'pergola' ? 'border-[#754d24] bg-[#754d24]' : 'border-[#d1c5b8]'}`}>
                    {tableSetting === 'pergola' && <span className="w-1.5 h-1.5 rounded-full bg-white"></span>}
                  </span>
                </div>

                {/* Setting 3: Palapa */}
                <div
                  onClick={() => setTableSetting('palapa')}
                  className={`p-3 rounded-xl border cursor-pointer transition-all flex items-center justify-between ${
                    tableSetting === 'palapa' ? 'bg-[#f7f3ea] border-[#a67d52]' : 'bg-white border-[#e6e2d9]'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <span className="material-symbols-outlined text-[#a67d52] text-[20px]">beach_access</span>
                    <div>
                      <h4 className="text-[13px] font-bold text-[#754d24]">Secluded Beachfront Palapa</h4>
                      <p className="text-[11px] text-[#7f756a]">Private dunes torchlit setup (10 min walk)</p>
                    </div>
                  </div>
                  <span className={`w-4 h-4 rounded-full border flex items-center justify-center ${tableSetting === 'palapa' ? 'border-[#754d24] bg-[#754d24]' : 'border-[#d1c5b8]'}`}>
                    {tableSetting === 'palapa' && <span className="w-1.5 h-1.5 rounded-full bg-white"></span>}
                  </span>
                </div>
              </div>
            </div>
          </div>

          {/* Tasting Selections: Five-Course Curations */}
          <div className="px-5 pt-8">
            <span className="font-label-sm text-[9px] uppercase tracking-wider text-[#a67d52] font-bold block mb-1">
              Tasting Selections
            </span>
            <h2 className="font-headline-sm text-[20px] text-[#754d24] mb-4">
              Five-Course Curations
            </h2>

            <div className="space-y-6">
              
              {/* Menu 1: Fuego y Mar Tasting Menu */}
              <div className="bg-white border border-[#e6e2d9] rounded-2xl overflow-hidden shadow-xs">
                <div className="relative h-48 w-full">
                  <img src={IMAGES.lobsterDish} alt="Fuego y Mar Tasting Menu" className="w-full h-full object-cover" />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-transparent"></div>
                  
                  <div className="absolute top-3 left-3 bg-[#c49a6c] text-[#754d24] px-2.5 py-0.5 rounded-full font-label-sm text-[8px] uppercase font-bold tracking-wider">
                    Recommended for Anniversary
                  </div>
                </div>

                <div className="p-4 space-y-3">
                  <div className="flex items-center justify-between">
                    <div>
                      <h3 className="font-headline-sm text-[18px] text-[#754d24]">Fuego y Mar Tasting Menu</h3>
                      <span className="font-label-sm text-[9px] text-[#7f756a] uppercase">Ocean &amp; Smoke Degustation</span>
                    </div>
                    <span className="material-symbols-outlined text-[#a67d52] text-[20px]">verified</span>
                  </div>

                  <ul className="space-y-1.5 text-[12px] text-[#4e453c] border-t border-[#f1ede5] pt-2.5">
                    <li>• <strong>First Course:</strong> Wild Pacific Yellowtail ceviche, green aguachile, charred habanero ash.</li>
                    <li>• <strong>Second Course:</strong> Wood-fired tender octopus, recado negro glaze, smoked sweet potato puree.</li>
                    <li>• <strong>Main Course:</strong> Grilled Caribbean lobster tail, Mayan honey butter, charred plantain mousse.</li>
                    <li>• <strong>Dessert:</strong> Chiapas dark cacao stone ganache, infused sea salt, copal-smoked cream.</li>
                  </ul>

                  <div className="p-2.5 bg-[#f7f3ea] rounded-xl flex items-center gap-2 text-xs text-[#754d24]">
                    <span className="material-symbols-outlined text-[16px] text-[#a67d52]">wine_bar</span>
                    <span>Pairing: Sommelier reserve pairing from Valle de Guadalupe included.</span>
                  </div>

                  <button
                    onClick={() => setSelectedMenu('fuego')}
                    className={`w-full py-2.5 rounded-lg font-label-md text-[10px] uppercase tracking-wider font-bold transition-all ${
                      selectedMenu === 'fuego'
                        ? 'bg-[#754d24] text-white'
                        : 'bg-[#ece8df] text-[#754d24] hover:bg-[#e6e2d9]'
                    }`}
                  >
                    {selectedMenu === 'fuego' ? '✓ Selected Menu' : 'Switch to Fuego y Mar Tasting Menu'}
                  </button>
                </div>
              </div>

              {/* Menu 2: Tierra Sagrada */}
              <div className="bg-white border border-[#e6e2d9] rounded-2xl overflow-hidden shadow-xs">
                <div className="relative h-44 w-full">
                  <img src={IMAGES.cochinitaDish} alt="Tierra Sagrada" className="w-full h-full object-cover" />
                </div>

                <div className="p-4 space-y-3">
                  <div>
                    <h3 className="font-headline-sm text-[18px] text-[#754d24]">Tierra Sagrada</h3>
                    <span className="font-label-sm text-[9px] text-[#7f756a] uppercase">Sacred Earth &amp; Mayan Heritage</span>
                  </div>

                  <p className="text-[12px] text-[#4e453c] leading-relaxed">
                    Subterranean pit-cooked Berkshire cochinita wrapped in scorched banana leaf, heirloom corn masa varietals, and endemic squash blossom velouté.
                  </p>

                  <div className="p-2.5 bg-[#f7f3ea] rounded-xl flex items-center gap-2 text-xs text-[#754d24]">
                    <span className="material-symbols-outlined text-[16px] text-[#a67d52]">wine_bar</span>
                    <span>Pairing: Ancestral agave flights &amp; Querétaro natural orange wines.</span>
                  </div>

                  <button
                    onClick={() => setSelectedMenu('tierra')}
                    className={`w-full py-2.5 rounded-lg font-label-md text-[10px] uppercase tracking-wider font-bold transition-all ${
                      selectedMenu === 'tierra'
                        ? 'bg-[#754d24] text-white'
                        : 'bg-[#ece8df] text-[#754d24] hover:bg-[#e6e2d9]'
                    }`}
                  >
                    {selectedMenu === 'tierra' ? '✓ Selected Menu' : 'Switch to Tierra Sagrada'}
                  </button>
                </div>
              </div>

              {/* Menu 3: Flora Silvestre */}
              <div className="bg-white border border-[#e6e2d9] rounded-2xl overflow-hidden shadow-xs">
                <div className="relative h-44 w-full">
                  <img src={IMAGES.veggieDish} alt="Flora Silvestre" className="w-full h-full object-cover" />
                </div>

                <div className="p-4 space-y-3">
                  <div>
                    <h3 className="font-headline-sm text-[18px] text-[#754d24]">Flora Silvestre</h3>
                    <span className="font-label-sm text-[9px] text-[#7f756a] uppercase">Botanical &amp; Plant-Forward</span>
                  </div>

                  <p className="text-[12px] text-[#4e453c] leading-relaxed">
                    Roasted Yucatecan endemic root vegetables, charred avocado with copal oil infusion, cenote watercress salad, and smoked young coconut ceviche.
                  </p>

                  <div className="p-2.5 bg-[#f7f3ea] rounded-xl flex items-center gap-2 text-xs text-[#754d24]">
                    <span className="material-symbols-outlined text-[16px] text-[#a67d52]">wine_bar</span>
                    <span>Pairing: Biodynamic pet-nat and botanical wild herb fermentations.</span>
                  </div>

                  <button
                    onClick={() => setSelectedMenu('flora')}
                    className={`w-full py-2.5 rounded-lg font-label-md text-[10px] uppercase tracking-wider font-bold transition-all ${
                      selectedMenu === 'flora'
                        ? 'bg-[#754d24] text-white'
                        : 'bg-[#ece8df] text-[#754d24] hover:bg-[#e6e2d9]'
                    }`}
                  >
                    {selectedMenu === 'flora' ? '✓ Selected Menu' : 'Switch to Flora Silvestre'}
                  </button>
                </div>
              </div>

            </div>
          </div>

          {/* Concierge Profile Sync Note */}
          <div className="px-5 pt-6">
            <div className="p-4 rounded-xl bg-white border border-[#e6e2d9] space-y-2">
              <div className="flex items-center gap-2 text-xs font-semibold text-[#754d24]">
                <span className="material-symbols-outlined text-[16px] text-[#a67d52]">verified</span>
                <span>Concierge Profile Sync Active</span>
              </div>
              <p className="text-[12px] text-[#4e453c]">
                Chef Mateo has tailored all recipes to Sarah's recorded preferences:
              </p>
              <div className="flex flex-wrap gap-1.5 pt-1">
                <span className="px-2 py-0.5 rounded bg-[#f1ede5] text-[#754d24] text-[11px]">
                  Pescatarian &amp; Gluten-Sensitive
                </span>
                <span className="px-2 py-0.5 rounded bg-[#ffdad6] text-[#ba1a1a] text-[11px] font-medium">
                  No Crustacean Shellfish for Sarah
                </span>
                <span className="px-2 py-0.5 rounded bg-[#f1ede5] text-[#754d24] text-[11px]">
                  Mark: Omnivore Enjoyment
                </span>
              </div>
            </div>
          </div>

          {/* Sommelier Inquiries */}
          <div className="px-5 pt-4">
            <div className="p-3.5 rounded-xl bg-[#f7f3ea] border border-[#e6e2d9] flex items-center justify-between">
              <div className="flex items-center gap-2.5">
                <span className="material-symbols-outlined text-[#a67d52] text-[20px]">wine_bar</span>
                <div>
                  <span className="font-label-sm text-[9px] uppercase text-[#7f756a] font-bold block">
                    Sommelier Inquiries
                  </span>
                  <p className="text-[12px] text-[#754d24]">Ask Elena about rare Mexican vintages</p>
                </div>
              </div>
              <a
                href="https://wa.me/529841020000"
                target="_blank"
                rel="noreferrer"
                className="px-3 py-1.5 rounded-lg bg-white border border-[#d1c5b8] text-[#754d24] font-label-sm text-[10px] uppercase font-bold hover:bg-[#f1ede5]"
              >
                Message
              </a>
            </div>
          </div>
        </>
      )}

      {/* Floating Confirmation Bar */}
      {diningTab === 'chef' && (
        <div className="fixed bottom-16 left-0 right-0 z-30 bg-[#fdf9f0]/95 backdrop-blur-md border-t border-[#e6e2d9] p-3 shadow-lg">
          <div className="max-w-md mx-auto flex items-center justify-between gap-3">
            <div>
              <span className="font-label-sm text-[9px] uppercase text-[#7f756a] block">Total Balance Due</span>
              <div className="flex items-baseline gap-1">
                <span className="font-headline-sm text-[20px] text-[#754d24] leading-none">$0.00</span>
                <span className="text-[11px] text-[#a67d52] font-semibold">USD · Included</span>
              </div>
              <span className="text-[10px] text-[#7f756a] block">{selectedEvening} · 8:00 PM · {guests} Guests</span>
            </div>

            <button
              onClick={handleConfirm}
              className="flex-1 max-w-[210px] bg-[#754d24] hover:bg-[#8b6339] text-white py-3.5 px-4 rounded-xl font-label-md text-[10px] uppercase tracking-widest flex items-center justify-center gap-1.5 transition-colors shadow-sm"
            >
              <span className="material-symbols-outlined text-[16px]">dinner_dining</span>
              <span>Confirm Dining</span>
            </button>
          </div>
        </div>
      )}

    </div>
  );
};
