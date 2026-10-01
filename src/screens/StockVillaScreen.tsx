import React, { useState } from 'react';
import { ScreenId, LarderItem } from '../types';
import { INITIAL_LARDER_ITEMS } from '../data/sanctuaryData';

interface StockVillaScreenProps {
  onNavigate: (screen: ScreenId) => void;
}

export const StockVillaScreen: React.FC<StockVillaScreenProps> = ({ onNavigate }) => {
  const [items, setItems] = useState<LarderItem[]>(INITIAL_LARDER_ITEMS);
  const [selectedCat, setSelectedCat] = useState<string>('All Items');
  const [toast, setToast] = useState<string | null>(null);

  const categories = [
    'All Items',
    'Fresh Fruit & Botanicals',
    'Chilled Elixirs',
    'Cellar Selection',
    'GF Bakery',
    'Snacks',
    'Recovery',
  ];

  const categoryMap: Record<string, string> = {
    'Fresh Fruit & Botanicals': 'fruit',
    'Chilled Elixirs': 'elixirs',
    'Cellar Selection': 'cellar',
    'GF Bakery': 'bakery',
    'Snacks': 'snacks',
    'Recovery': 'recovery',
  };

  const updateQuantity = (id: string, delta: number) => {
    setItems(prev =>
      prev.map(item => {
        if (item.id === id) {
          const newQty = Math.max(0, item.quantity + delta);
          return { ...item, quantity: newQty };
        }
        return item;
      })
    );
  };

  const totalAmount = items.reduce((acc, item) => acc + item.price * item.quantity, 0);
  const totalCount = items.reduce((acc, item) => acc + item.quantity, 0);

  const filteredItems = items.filter(item => {
    if (selectedCat === 'All Items') return true;
    return item.category === categoryMap[selectedCat];
  });

  const handleOrder = () => {
    setToast(`Larder order for ${totalCount} items ($${totalAmount}.00 USD) saved. Majordomo Eduardo will unpack before check-in.`);
    setTimeout(() => {
      onNavigate('home');
    }, 1800);
  };

  return (
    <div className="flex flex-col w-full pb-36 pt-2">
      
      {/* Toast */}
      {toast && (
        <div className="fixed top-20 left-1/2 -translate-x-1/2 z-50 bg-[#564121] text-white px-5 py-2.5 rounded-full text-xs font-medium shadow-xl animate-in fade-in duration-200">
          {toast}
        </div>
      )}

      {/* Header Info */}
      <div className="px-5 pt-3 pb-2 flex flex-col gap-1.5">
        <div className="flex items-center justify-between">
          <span className="font-label-sm text-[10px] uppercase tracking-widest text-[#7f5700] font-bold">
            Villa 102 · Sanctuary Arrival
          </span>
          <span className="font-label-sm text-[10px] text-[#7f756a]">
            Nov 12–16 · 2 Guests
          </span>
        </div>

        <h1 className="font-headline-lg text-[#564121] tracking-tight leading-tight mt-1">
          Stock My Villa
        </h1>

        <p className="font-body-sm text-[13px] text-[#4e453c] leading-relaxed">
          Arrive to a villa prepared exactly how you want it.
        </p>
      </div>

      {/* Majordomo Unpacking Promise Card */}
      <div className="px-5 pt-3">
        <div className="bg-[#f7f3ea] border border-[#e6e2d9] rounded-2xl p-4 space-y-3">
          <div className="flex items-start gap-3">
            <span className="material-symbols-outlined text-[#7f5700] text-[22px] shrink-0 mt-0.5">kitchen</span>
            <div>
              <h3 className="font-headline-sm text-[16px] text-[#564121]">
                Majordomo Unpacking Promise
              </h3>
              <p className="text-[12px] text-[#4e453c] mt-1 leading-relaxed">
                Every provision is unpacked, chilled, and artisanal-arranged across Villa 102's Sub-Zero refrigerator and open chukum limestone larder prior to your 2:00 PM check-in on Nov 12.
              </p>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-2 pt-2 border-t border-[#e6e2d9]/60 text-[11px] text-[#564121]">
            <div className="flex items-center gap-1.5">
              <span className="material-symbols-outlined text-[#7f5700] text-[15px]">eco</span>
              <span>Zero Transit Packaging</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="material-symbols-outlined text-[#7f5700] text-[15px]">dry_cleaning</span>
              <span>Placed in ceramic tableware</span>
            </div>
          </div>

          <div className="p-2.5 rounded-xl bg-white flex items-center justify-between text-xs text-[#564121]">
            <div className="flex items-center gap-2">
              <span className="material-symbols-outlined text-[#7f5700] text-[16px]">tune</span>
              <span className="font-medium truncate">Synced with Sarah's Preferences: Gluten-Free &amp; Pescatarian</span>
            </div>
            <span className="material-symbols-outlined text-[#7f756a] text-[16px]">chevron_right</span>
          </div>
        </div>
      </div>

      {/* Category Pills */}
      <div className="w-full overflow-x-auto no-scrollbar pl-5 pr-3 py-4 flex items-center gap-2">
        {categories.map(cat => {
          const isActive = selectedCat === cat;
          return (
            <button
              key={cat}
              onClick={() => setSelectedCat(cat)}
              className={`whitespace-nowrap px-3.5 py-1.5 rounded-full font-label-md text-[10px] uppercase tracking-wider transition-all border ${
                isActive
                  ? 'bg-[#564121] text-white border-[#564121]'
                  : 'bg-[#f1ede5] text-[#4e453c] border-transparent hover:text-[#564121]'
              }`}
            >
              {cat}
            </button>
          );
        })}
      </div>

      {/* Items List */}
      <div className="px-5 space-y-6">
        {filteredItems.map(item => (
          <article
            key={item.id}
            className="bg-white border border-[#e6e2d9] rounded-2xl overflow-hidden shadow-xs flex flex-col"
          >
            {/* Image */}
            <div className="relative h-48 w-full">
              <img
                src={item.image}
                alt={item.name}
                className="w-full h-full object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-transparent"></div>

              {/* Tags */}
              <div className="absolute top-3 left-3 flex flex-wrap gap-1.5">
                {item.tag && (
                  <span className="px-2.5 py-0.5 rounded-full bg-[#fdf9f0]/90 backdrop-blur-md text-[#7f5700] font-label-sm text-[8px] uppercase tracking-widest font-bold">
                    {item.tag}
                  </span>
                )}
                {item.dietary && (
                  <span className="px-2 py-0.5 rounded-full bg-[#febe4f] text-[#564121] font-label-sm text-[8px] uppercase font-bold">
                    {item.dietary}
                  </span>
                )}
              </div>
            </div>

            {/* Details */}
            <div className="p-4 flex flex-col gap-2.5">
              <div className="flex items-start justify-between gap-2">
                <div>
                  <h3 className="font-headline-sm text-[17px] text-[#564121] leading-snug">
                    {item.name}
                  </h3>
                  <span className="font-label-sm text-[10px] text-[#7f756a] mt-0.5 block">
                    {item.origin}
                  </span>
                </div>

                <div className="text-right shrink-0">
                  <span className="font-headline-sm text-[19px] text-[#564121] leading-none block">
                    ${item.price}
                  </span>
                  <span className="font-label-sm text-[9px] text-[#7f756a] uppercase">USD / FOLIO</span>
                </div>
              </div>

              <p className="text-[12px] text-[#4e453c] leading-relaxed">
                {item.description}
              </p>

              {/* Storage & Quantity Counter */}
              <div className="pt-2 border-t border-[#f1ede5] flex items-center justify-between">
                <span className="font-label-sm text-[9px] text-[#7f5700] uppercase font-bold tracking-wider">
                  {item.storageType || 'CHILLED IN LARDER'}
                </span>

                {item.quantity === 0 ? (
                  <button
                    onClick={() => updateQuantity(item.id, 1)}
                    className="px-3 py-1.5 rounded-lg bg-[#564121] hover:bg-[#705836] text-white font-label-md text-[10px] uppercase font-bold flex items-center gap-1 shadow-xs"
                  >
                    <span className="text-xs">+</span>
                    <span>Add to Villa</span>
                  </button>
                ) : (
                  <div className="flex items-center gap-2 bg-[#f1ede5] px-2 py-1 rounded-lg">
                    <button
                      onClick={() => updateQuantity(item.id, -1)}
                      className="w-6 h-6 rounded bg-white text-[#564121] flex items-center justify-center font-bold text-xs shadow-xs"
                    >
                      -
                    </button>
                    <span className="w-4 text-center font-bold text-xs text-[#564121]">
                      {item.quantity}
                    </span>
                    <button
                      onClick={() => updateQuantity(item.id, 1)}
                      className="w-6 h-6 rounded bg-white text-[#564121] flex items-center justify-center font-bold text-xs shadow-xs"
                    >
                      +
                    </button>
                  </div>
                )}
              </div>
            </div>
          </article>
        ))}
      </div>

      {/* Standard In-Villa Inclusions ($0 USD) */}
      <div className="px-5 pt-8">
        <div className="p-4 rounded-2xl bg-[#f7f3ea] border border-[#e6e2d9] space-y-3">
          <div className="flex items-center gap-2 text-[#564121]">
            <span className="material-symbols-outlined text-[#7f5700] text-[20px]">check_circle</span>
            <h3 className="font-headline-sm text-[16px] text-[#564121]">
              Standard In-Villa Inclusions ($0 USD)
            </h3>
          </div>

          <p className="text-[12px] text-[#4e453c] leading-relaxed">
            Your residency automatically includes the following complimentary staples, refreshed twice daily by your Majordomo:
          </p>

          <ul className="space-y-2 text-[12px] text-[#564121] pt-1">
            <li className="flex justify-between border-b border-[#e6e2d9]/60 pb-1.5">
              <span>• Chilled fresh cracked coconut on arrival (x2)</span>
              <span className="font-semibold text-[#7f5700] font-label-sm text-[9px] uppercase">Included</span>
            </li>
            <li className="flex justify-between border-b border-[#e6e2d9]/60 pb-1.5">
              <span>• Sparkling &amp; still glass-bottled Mexican mineral water</span>
              <span className="font-semibold text-[#7f5700] font-label-sm text-[9px] uppercase">Unlimited</span>
            </li>
            <li className="flex justify-between border-b border-[#e6e2d9]/60 pb-1.5">
              <span>• Oaxacan organic espresso pods &amp; Mayan herbal teas</span>
              <span className="font-semibold text-[#7f5700] font-label-sm text-[9px] uppercase">Included</span>
            </li>
            <li className="flex justify-between">
              <span>• Raw unpasteurized agave nectar &amp; organic sea salts</span>
              <span className="font-semibold text-[#7f5700] font-label-sm text-[9px] uppercase">Included</span>
            </li>
          </ul>
        </div>
      </div>

      {/* Special Sourcing Request */}
      <div className="px-5 pt-5">
        <div className="p-4 rounded-2xl bg-white border border-[#e6e2d9] flex flex-col gap-2">
          <div className="flex items-center gap-2 text-[#7f5700]">
            <span className="material-symbols-outlined text-[18px]">auto_awesome</span>
            <h4 className="text-[13px] font-bold text-[#564121]">Special Sourcing Request</h4>
          </div>
          <p className="text-[12px] text-[#4e453c] leading-relaxed">
            Craving a specific vintage, rare botanical digestif, or customized baby purees? Tap our lead concierge to custom-source across Quintana Roo prior to your arrival.
          </p>
          <a
            href="https://wa.me/529841020000"
            target="_blank"
            rel="noreferrer"
            className="mt-1 inline-flex items-center justify-center gap-2 py-2 px-3 rounded-lg bg-[#f1ede5] text-[#564121] font-label-sm text-[10px] uppercase font-bold hover:bg-[#ece8df]"
          >
            <span className="material-symbols-outlined text-[16px] text-[#7f5700]">chat</span>
            <span>Message Concierge</span>
          </a>
        </div>
      </div>

      {/* Floating Bottom Cart Bar */}
      <div className="fixed bottom-16 left-0 right-0 z-30 bg-[#fdf9f0]/95 backdrop-blur-md border-t border-[#e6e2d9] p-3 shadow-lg">
        <div className="max-w-md mx-auto space-y-1.5">
          <div className="flex items-center justify-between">
            <div>
              <div className="flex items-baseline gap-1.5">
                <span className="font-headline-sm text-[20px] text-[#564121] leading-none">
                  ${totalAmount}.00
                </span>
                <span className="text-[11px] text-[#7f756a]">USD · {totalCount} items selected</span>
              </div>
              <span className="font-label-sm text-[9px] text-[#7f5700] uppercase font-semibold">
                Villa 102 Folio
              </span>
            </div>

            <button
              onClick={handleOrder}
              disabled={totalCount === 0}
              className={`py-3.5 px-4 rounded-xl font-label-md text-[10px] uppercase tracking-widest flex items-center justify-center gap-1.5 transition-colors shadow-sm ${
                totalCount > 0
                  ? 'bg-[#564121] hover:bg-[#705836] text-white'
                  : 'bg-[#d1c5b8] text-white cursor-not-allowed'
              }`}
            >
              <span>Review Provisioning &amp; Stock</span>
              <span className="material-symbols-outlined text-[16px]">arrow_forward</span>
            </button>
          </div>

          <p className="text-center font-label-sm text-[9px] text-[#7f756a]">
            Delivered &amp; chilled before 2:00 PM arrival on Nov 12
          </p>
        </div>
      </div>

    </div>
  );
};
