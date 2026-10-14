import React from 'react';
import { ScreenId } from '../types';

interface ScreenSwitcherDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  currentScreen: ScreenId;
  onSelectScreen: (screen: ScreenId) => void;
}

const SCREENS_LIST: { id: ScreenId; title: string; subtitle: string; icon: string; category: string }[] = [
  { id: 'home', title: '1. Home & Welcome Haven', subtitle: 'Countdown, priority actions & Ceiba Suite', icon: 'villa', category: 'Overview' },
  { id: 'transport', title: '2. Private Airport Transportation', subtitle: 'Escalade transfer, live status & arrival rituals', icon: 'directions_car', category: 'Arrival & Logistics' },
  { id: 'personalize', title: '3. Personalize Vacation (Step 1 of 3)', subtitle: 'Intent tags, interests & dietary profile', icon: 'tune', category: 'Arrival & Logistics' },
  { id: 'included', title: '4. Included in Your Stay', subtitle: 'All-inclusive privileges, breakfast, yacht & chef', icon: 'stars', category: 'Sanctuary Privileges' },
  { id: 'explore', title: '5. Explore Kachava Lux', subtitle: 'Curated guest expeditions, cenote & golf', icon: 'explore', category: 'Sanctuary Privileges' },
  { id: 'yacht', title: '6. Kachava Caribe · Galeon 470 Sky', subtitle: 'Private yacht experience, Beach Mode & booking', icon: 'sailing', category: 'Experiences' },
  { id: 'dining', title: '7. In-Villa & Sanctuary Dining', subtitle: 'Chef Mateo 5-course degustation & table setup', icon: 'restaurant', category: 'Experiences' },
  { id: 'stock-villa', title: '8. Stock My Villa (Artisanal Larder)', subtitle: 'Tropical fruits, cold-pressed elixirs & bar kit', icon: 'kitchen', category: 'Experiences' },
  { id: 'concierge', title: '9. Dedicated Concierge & Majordomo', subtitle: 'Eduardo, 4 live service trackers & chime', icon: 'support_agent', category: 'Majordomo Care' },
  { id: 'midstay', title: '10. Mid-Stay Check-In', subtitle: 'In-moment sentiment, temperature tuning & vow', icon: 'spa', category: 'Majordomo Care' },
  { id: 'departure', title: '11. A Peaceful Departure & Folio', subtitle: 'Flight AA 172, EQS transfer & final settled ledger', icon: 'flight_takeoff', category: 'Departure' },
  { id: 'philosophy', title: '12. Architecture of Stillness', subtitle: '432Hz soundscape, Chukum history & 1% covenant', icon: 'auto_stories', category: 'Sanctuary Lore' },
];

export const ScreenSwitcherDrawer: React.FC<ScreenSwitcherDrawerProps> = ({
  isOpen,
  onClose,
  currentScreen,
  onSelectScreen,
}) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4 bg-black/50 backdrop-blur-sm transition-opacity">
      <div className="w-full max-w-lg bg-[#fdf9f0] rounded-t-3xl sm:rounded-2xl max-h-[85vh] flex flex-col shadow-2xl overflow-hidden border border-[#d1c5b8]/40 animate-in fade-in slide-in-from-bottom duration-200">
        
        {/* Header */}
        <div className="p-4 border-b border-[#e6e2d9] flex items-center justify-between bg-[#f7f3ea]">
          <div className="flex items-center gap-2">
            <span className="w-2 h-2 rounded-full bg-[#a67d52]"></span>
            <div>
              <h3 className="font-headline-sm text-[18px] text-[#754d24]">App Screens</h3>
              <p className="text-[11px] text-[#7f756a] uppercase tracking-wider font-semibold">12 Prototype Screens</p>
            </div>
          </div>
          <button 
            onClick={onClose}
            className="w-8 h-8 rounded-full bg-[#ece8df] flex items-center justify-center text-[#754d24] hover:bg-[#e6e2d9] transition-colors"
            aria-label="Close"
          >
            <span className="material-symbols-outlined text-[18px]">close</span>
          </button>
        </div>

        {/* Screens List */}
        <div className="overflow-y-auto p-4 space-y-2 no-scrollbar">
          <p className="text-xs text-[#4e453c] px-1 pb-2">
            Select any of the 12 prototype screens to explore each section of the Kachava Lux experience:
          </p>

          <div className="grid grid-cols-1 gap-2">
            {SCREENS_LIST.map((screen) => {
              const isActive = currentScreen === screen.id;
              return (
                <button
                  key={screen.id}
                  onClick={() => {
                    onSelectScreen(screen.id);
                    onClose();
                  }}
                  className={`w-full text-left p-3 rounded-xl transition-all flex items-start gap-3 border ${
                    isActive 
                      ? 'bg-[#754d24] text-white border-[#754d24] shadow-md' 
                      : 'bg-white hover:bg-[#f7f3ea] text-[#1c1c16] border-[#e6e2d9]'
                  }`}
                >
                  <div className={`w-9 h-9 rounded-lg flex items-center justify-center shrink-0 mt-0.5 ${
                    isActive ? 'bg-[#8b6339] text-[#f7e8d0]' : 'bg-[#f1ede5] text-[#a67d52]'
                  }`}>
                    <span className="material-symbols-outlined text-[20px]">{screen.icon}</span>
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between">
                      <span className={`text-sm font-semibold truncate ${isActive ? 'text-white' : 'text-[#754d24]'}`}>
                        {screen.title}
                      </span>
                      {isActive && (
                        <span className="text-[10px] uppercase font-bold tracking-wider px-2 py-0.5 rounded-full bg-[#a67d52] text-white shrink-0 ml-1">
                          Active
                        </span>
                      )}
                    </div>
                    <p className={`text-xs mt-0.5 truncate ${isActive ? 'text-white/80' : 'text-[#7f756a]'}`}>
                      {screen.subtitle}
                    </p>
                  </div>
                </button>
              );
            })}
          </div>
        </div>

        {/* Footer */}
        <div className="p-3 border-t border-[#e6e2d9] bg-[#f7f3ea] flex items-center justify-between text-xs text-[#7f756a]">
          <span>Villa 102 · Kachava Lux</span>
          <button 
            onClick={onClose} 
            className="px-4 py-1.5 rounded-md bg-[#754d24] text-white text-xs font-semibold uppercase tracking-wider"
          >
            Close
          </button>
        </div>

      </div>
    </div>
  );
};
