import React from 'react';
import { MainTab, ScreenId } from '../types';

interface BottomNavProps {
  currentScreen: ScreenId;
  onNavigate: (screen: ScreenId) => void;
}

export const BottomNav: React.FC<BottomNavProps> = ({ currentScreen, onNavigate }) => {
  // Map sub-screens to main tabs for active highlight
  const getActiveTab = (): MainTab | null => {
    if (['home', 'transport', 'personalize'].includes(currentScreen)) return 'home';
    if (['included', 'stock-villa', 'midstay', 'departure'].includes(currentScreen)) return 'my-stay';
    if (['explore', 'yacht', 'dining', 'philosophy'].includes(currentScreen)) return 'explore';
    if (currentScreen === 'concierge') return 'concierge';
    return null;
  };

  const activeTab = getActiveTab();

  const navItems: { tab: MainTab; screenTarget: ScreenId; label: string; icon: string; hasDot?: boolean }[] = [
    { tab: 'home', screenTarget: 'home', label: 'Home', icon: 'villa' },
    { tab: 'my-stay', screenTarget: 'included', label: 'My Stay', icon: 'calendar_today' },
    { tab: 'explore', screenTarget: 'explore', label: 'Explore', icon: 'explore' },
    { tab: 'concierge', screenTarget: 'concierge', label: 'Concierge', icon: 'support_agent', hasDot: true },
  ];

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-40 bg-[#fdf9f0]/95 backdrop-blur-xl border-t border-[#8b6339]/15 shadow-[0_-4px_24px_rgba(112,88,54,0.06)] pb-safe">
      <div className="max-w-md mx-auto h-16 px-3 grid grid-cols-4 items-center">
        {navItems.map((item) => {
          const isActive = activeTab === item.tab;
          return (
            <button
              key={item.tab}
              onClick={() => onNavigate(item.screenTarget)}
              className={`flex flex-col items-center justify-center py-1 transition-all ${
                isActive ? 'text-[#754d24]' : 'text-[#7f756a] hover:text-[#754d24]'
              }`}
            >
              <div className="relative flex items-center justify-center">
                <span 
                  className={`material-symbols-outlined text-[22px] transition-transform ${
                    isActive ? 'scale-110' : ''
                  }`}
                  style={isActive ? { fontVariationSettings: "'FILL' 1" } : undefined}
                >
                  {item.icon}
                </span>
                {item.hasDot && (
                  <span className="absolute -top-0.5 -right-1 w-2 h-2 rounded-full bg-[#c49a6c] ring-2 ring-[#fdf9f0]" />
                )}
              </div>
              <span className={`text-[10px] tracking-widest uppercase mt-0.5 ${
                isActive ? 'font-bold text-[#754d24]' : 'font-medium text-[#7f756a]'
              }`}>
                {item.label}
              </span>
            </button>
          );
        })}
      </div>
    </nav>
  );
};
