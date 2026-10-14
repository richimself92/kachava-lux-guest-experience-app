/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect } from 'react';
import { ScreenId } from './types';
import { Header } from './components/Header';
import { BottomNav } from './components/BottomNav';
import { ScreenSwitcherDrawer } from './components/ScreenSwitcherDrawer';
import { HomeScreen } from './screens/HomeScreen';
import { PrivateTransportScreen } from './screens/PrivateTransportScreen';
import { VacationPersonalizationScreen } from './screens/VacationPersonalizationScreen';
import { IncludedPrivilegesScreen } from './screens/IncludedPrivilegesScreen';
import { ExploreScreen } from './screens/ExploreScreen';
import { YachtCharterScreen } from './screens/YachtCharterScreen';
import { PrivateDiningScreen } from './screens/PrivateDiningScreen';
import { StockVillaScreen } from './screens/StockVillaScreen';
import { ConciergeScreen } from './screens/ConciergeScreen';
import { MidStayCheckInScreen } from './screens/MidStayCheckInScreen';
import { DepartureLedgerScreen } from './screens/DepartureLedgerScreen';
import { ArchitecturePhilosophyScreen } from './screens/ArchitecturePhilosophyScreen';
import { ProfileScreen } from './screens/ProfileScreen';
import { soundscape } from './utils/soundscape';

export default function App() {
  const [currentScreen, setCurrentScreen] = useState<ScreenId>('home');
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const [isSoundscapeActive, setIsSoundscapeActive] = useState(false);

  // Scroll to top when screen changes
  useEffect(() => {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }, [currentScreen]);

  const toggleSoundscape = () => {
    const newState = soundscape.toggle();
    setIsSoundscapeActive(newState);
  };

  const renderCurrentScreen = () => {
    switch (currentScreen) {
      case 'home':
        return <HomeScreen onNavigate={setCurrentScreen} />;
      case 'transport':
        return <PrivateTransportScreen onNavigate={setCurrentScreen} />;
      case 'personalize':
        return <VacationPersonalizationScreen onNavigate={setCurrentScreen} />;
      case 'included':
        return <IncludedPrivilegesScreen onNavigate={setCurrentScreen} />;
      case 'explore':
        return <ExploreScreen onNavigate={setCurrentScreen} />;
      case 'yacht':
        return <YachtCharterScreen onNavigate={setCurrentScreen} />;
      case 'dining':
        return <PrivateDiningScreen onNavigate={setCurrentScreen} />;
      case 'stock-villa':
        return <StockVillaScreen onNavigate={setCurrentScreen} />;
      case 'concierge':
        return <ConciergeScreen onNavigate={setCurrentScreen} />;
      case 'midstay':
        return <MidStayCheckInScreen onNavigate={setCurrentScreen} />;
      case 'departure':
        return <DepartureLedgerScreen onNavigate={setCurrentScreen} />;
      case 'philosophy':
        return (
          <ArchitecturePhilosophyScreen
            onNavigate={setCurrentScreen}
            isSoundscapeActive={isSoundscapeActive}
            onToggleSoundscape={toggleSoundscape}
          />
        );
      case 'profile':
        return (
          <ProfileScreen
            onNavigate={setCurrentScreen}
            onOpenScreenSwitcher={() => setIsDrawerOpen(true)}
          />
        );
      default:
        return <HomeScreen onNavigate={setCurrentScreen} />;
    }
  };

  return (
    <div className="min-h-screen bg-[#f7f3ea] flex justify-center">
      {/* Container framing for mobile device aesthetic on desktop while fully responsive on mobile */}
      <div className="w-full max-w-md min-h-screen bg-[#fdf9f0] text-[#1c1c16] flex flex-col relative shadow-[0_0_50px_rgba(112,88,54,0.08)]">
        
        {/* Top Sticky Luxury Header */}
        <Header
          currentScreen={currentScreen}
          onNavigate={setCurrentScreen}
          onOpenScreenSwitcher={() => setIsDrawerOpen(true)}
          isSoundscapeActive={isSoundscapeActive}
          onToggleSoundscape={toggleSoundscape}
        />

        {/* Main Content Area */}
        <main className="flex-1 pt-16">
          {renderCurrentScreen()}
        </main>

        {/* Persistent 4-Tab Bottom Navigation (HOME | MY STAY | EXPLORE | CONCIERGE) */}
        <BottomNav
          currentScreen={currentScreen}
          onNavigate={setCurrentScreen}
        />

        {/* DISCREET PROTOTYPE CONTROL:
            Visually separate from the luxury Kachava UI, placed for evaluator testing,
            can easily be removed completely prior to production. */}
        <aside className="fixed bottom-20 right-3.5 z-30 pointer-events-auto">
          <button
            onClick={() => setIsDrawerOpen(true)}
            className="flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-stone-900/85 hover:bg-stone-900 text-stone-300 hover:text-white text-[10px] font-mono shadow-md backdrop-blur-md transition-all border border-stone-700/80 active:scale-95"
            title="Prototype screen navigator (temporary evaluator tool)"
            aria-label="Open prototype screens drawer"
          >
            <span className="w-1.5 h-1.5 rounded-full bg-[#c49a6c] animate-pulse" />
            <span className="tracking-wide">prototype screens</span>
          </button>
        </aside>

        {/* Screen Switcher Drawer for All Prototype Screens */}
        <ScreenSwitcherDrawer
          isOpen={isDrawerOpen}
          onClose={() => setIsDrawerOpen(false)}
          currentScreen={currentScreen}
          onSelectScreen={setCurrentScreen}
        />

      </div>
    </div>
  );
}
