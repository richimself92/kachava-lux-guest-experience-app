import React from 'react';
import { ScreenId } from '../types';
import { GUEST_INFO, IMAGES } from '../data/sanctuaryData';

interface HeaderProps {
  currentScreen: ScreenId;
  onNavigate: (screen: ScreenId) => void;
  onOpenScreenSwitcher?: () => void;
  isSoundscapeActive?: boolean;
  onToggleSoundscape?: () => void;
}

export const Header: React.FC<HeaderProps> = ({
  currentScreen,
  onNavigate,
}) => {
  const isSubScreen = [
    'transport',
    'personalize',
    'yacht',
    'dining',
    'midstay',
    'departure',
    'philosophy',
    'profile',
  ].includes(currentScreen);

  const getSubScreenTitle = (screen: ScreenId) => {
    switch (screen) {
      case 'transport':
        return 'Private Transport';
      case 'personalize':
        return 'Personalize Stay';
      case 'yacht':
        return 'Private Yacht';
      case 'dining':
        return 'Private Dining';
      case 'midstay':
        return 'Mid-Stay Care';
      case 'departure':
        return 'Departure Folio';
      case 'philosophy':
        return 'Architecture';
      case 'profile':
        return 'Guest Profile';
      default:
        return '';
    }
  };

  return (
    <header className="fixed top-0 left-0 right-0 z-40 bg-[#fdf9f0]/95 backdrop-blur-xl border-b border-[#705836]/10 shadow-[0_1px_8px_rgba(112,88,54,0.03)]">
      <div className="max-w-md mx-auto h-16 px-4 flex items-center justify-between">
        
        {/* Left: Back button if subscreen OR Logo */}
        <div className="flex items-center gap-2">
          {isSubScreen ? (
            <button
              onClick={() => onNavigate('home')}
              className="flex items-center gap-2 text-[#564121] hover:text-[#7f5700] transition-colors py-1.5 pr-2 active:scale-95"
              aria-label="Back to Home"
            >
              <span className="material-symbols-outlined text-[20px]">arrow_back</span>
              <span className="font-serif text-[17px] tracking-tight font-medium text-[#564121]">
                {getSubScreenTitle(currentScreen)}
              </span>
            </button>
          ) : (
            <button 
              onClick={() => onNavigate('home')} 
              className="flex items-center text-left py-1"
              aria-label="Kachava Lux Home"
            >
              <img
                src="/Logotype 5.png"
                alt="KACHAVA LUX"
                className="h-[18px] sm:h-[19px] w-auto max-w-[155px] object-contain transition-opacity hover:opacity-85"
                onError={(e) => {
                  e.currentTarget.onerror = null;
                  e.currentTarget.src = '/logotype.svg';
                }}
              />
            </button>
          )}
        </div>

        {/* Right Controls: Villa 102 & Guest Avatar (opens Profile) */}
        <div className="flex items-center gap-3">
          {/* Contextual Villa indicator */}
          <div className="flex flex-col items-end justify-center pr-0.5">
            <span className="text-[8px] uppercase tracking-[0.18em] text-[#7f5700] font-bold leading-none">
              Villa
            </span>
            <span className="font-serif text-[13px] font-semibold text-[#564121] leading-tight">
              102
            </span>
          </div>

          {/* Profile Access via Avatar */}
          <button 
            onClick={() => onNavigate('profile')}
            className={`relative flex items-center justify-center p-0.5 rounded-full transition-all focus:outline-none ${
              currentScreen === 'profile'
                ? 'ring-2 ring-[#7f5700] ring-offset-2 ring-offset-[#fdf9f0]'
                : 'hover:ring-1 hover:ring-[#705836]/30'
            }`}
            title="Guest Profile & Settings"
            aria-label="Open Guest Profile"
          >
            <img
              src={IMAGES.avatar}
              alt={GUEST_INFO.name}
              className="w-8 h-8 rounded-full object-cover shadow-2xs"
              onError={(e) => {
                e.currentTarget.src = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80';
              }}
            />
          </button>
        </div>

      </div>
    </header>
  );
};
