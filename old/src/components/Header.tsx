import React from 'react';
import { ScreenId } from '../types';
import { GUEST_INFO } from '../data/sanctuaryData';

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
    <header className="fixed top-0 left-0 right-0 z-40 bg-[#fdf9f0]/95 backdrop-blur-xl border-b border-[#8b6339]/10 shadow-[0_1px_8px_rgba(117,77,36,0.04)]">
      <div className="max-w-md mx-auto h-16 px-4 flex items-center justify-between">
        
        {/* Left: Back button (sub-screens) OR Logotype (main screens) */}
        <div className="flex items-center gap-2">
          {isSubScreen ? (
            <button
              onClick={() => onNavigate('home')}
              className="flex items-center gap-2 text-[#754d24] hover:text-[#a67d52] transition-colors py-1.5 pr-2 active:scale-95"
              aria-label="Back to Home"
            >
              <span className="material-symbols-outlined text-[20px]">arrow_back</span>
              <span className="font-serif text-[17px] tracking-tight font-medium text-[#754d24]">
                {getSubScreenTitle(currentScreen)}
              </span>
            </button>
          ) : (
            <button 
              onClick={() => onNavigate('home')} 
              className="flex items-center text-left py-1"
              aria-label="Kachava Lux Home"
            >
              {/* Official brand logotype — Logotype 1.png (dark brown on cream) */}
              <img
                src="/logotype.png"
                alt="KACHAVA LUX"
                className="h-[16px] sm:h-[18px] w-auto max-w-[160px] object-contain transition-opacity hover:opacity-80"
              />
            </button>
          )}
        </div>

        {/* Right: Villa indicator + Isotype as profile button */}
        <div className="flex items-center gap-3">
          {/* Villa label */}
          <div className="flex flex-col items-end justify-center pr-0.5">
            <span className="text-[8px] uppercase tracking-[0.18em] text-[#a67d52] font-bold leading-none">
              Villa
            </span>
            <span className="font-serif text-[13px] font-semibold text-[#754d24] leading-tight">
              102
            </span>
          </div>

          {/* 
            Profile access via Isotype medallion 
            Uses the official Kachava Lux isotype (Mayan-inspired medallion) 
            instead of a guest avatar photo.
          */}
          <button 
            onClick={() => onNavigate('profile')}
            className={`relative flex items-center justify-center transition-all active:scale-95 focus:outline-none rounded-full ${
              currentScreen === 'profile'
                ? 'ring-2 ring-[#a67d52] ring-offset-2 ring-offset-[#fdf9f0]'
                : 'hover:opacity-80'
            }`}
            title={`${GUEST_INFO.name} — Guest Profile`}
            aria-label="Open Guest Profile"
          >
            <img
              src="/isotype-brown.png"
              alt="Guest Profile"
              className="w-9 h-9 object-contain"
            />
          </button>
        </div>

      </div>
    </header>
  );
};
