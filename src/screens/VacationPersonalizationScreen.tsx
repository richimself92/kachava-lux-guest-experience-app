import React, { useState } from 'react';
import { ScreenId } from '../types';

interface VacationPersonalizationProps {
  onNavigate: (screen: ScreenId) => void;
}

type TripPurpose =
  | 'Anniversary'
  | 'Birthday'
  | 'Honeymoon'
  | 'Family'
  | 'Friends'
  | 'Wellness'
  | 'Just Getting Away'
  | 'Other';

type CommChannel = 'WhatsApp' | 'SMS' | 'Email';

const TRIP_PURPOSES: TripPurpose[] = [
  'Anniversary',
  'Birthday',
  'Honeymoon',
  'Family',
  'Friends',
  'Wellness',
  'Just Getting Away',
  'Other',
];

const INTEREST_OPTIONS: { id: string; label: string; icon: string }[] = [
  { id: 'spa', label: 'Wellness & Spa', icon: 'spa' },
  { id: 'yacht', label: 'Private Yacht', icon: 'sailing' },
  { id: 'gastronomy', label: 'Gastronomy', icon: 'restaurant' },
  { id: 'cenotes', label: 'Cenotes', icon: 'water_drop' },
  { id: 'mayan', label: 'Mayan Culture', icon: 'temple_buddhist' },
  { id: 'golf', label: 'Golf', icon: 'sports_golf' },
  { id: 'diving', label: 'Diving & Snorkeling', icon: 'scuba_diving' },
  { id: 'beach', label: 'Beach Clubs', icon: 'deck' },
  { id: 'art', label: 'Art & Culture', icon: 'palette' },
  { id: 'nightlife', label: 'Nightlife', icon: 'nightlife' },
  { id: 'fitness', label: 'Fitness', icon: 'fitness_center' },
  { id: 'privacy', label: 'Privacy & Relaxation', icon: 'lock' },
];

const DIETARY_OPTIONS = [
  'No restrictions',
  'Pescatarian',
  'Plant-based',
  'Vegetarian',
  'Gluten-conscious',
  'Custom',
];

const SCENT_OPTIONS = [
  'Copal & Amber',
  'Orange Blossom',
  'White Cedar',
  'Unscented',
];

const PILLOW_OPTIONS = [
  'Goose Down',
  'Memory Foam',
  'Hypoallergenic Firm',
];

export const VacationPersonalizationScreen: React.FC<VacationPersonalizationProps> = ({ onNavigate }) => {
  // Step state: 1 | 2 | 3 | 4 (completed)
  const [currentStep, setCurrentStep] = useState<1 | 2 | 3 | 4>(1);

  // Step 1: Your Trip
  const [selectedPurpose, setSelectedPurpose] = useState<TripPurpose>('Anniversary');
  const [occasionDetails, setOccasionDetails] = useState<string>('4th Wedding Anniversary');

  // Step 2: Your Interests
  const [selectedInterests, setSelectedInterests] = useState<string[]>([
    'Wellness & Spa',
    'Private Yacht',
    'Gastronomy',
    'Privacy & Relaxation',
  ]);

  // Step 3: Your Preferences
  const [dietary, setDietary] = useState<string>('Pescatarian');
  const [allergies, setAllergies] = useState<string>('Shellfish (mild)');
  const [villaScent, setVillaScent] = useState<string>('Copal & Amber');
  const [pillowType, setPillowType] = useState<string>('Goose Down');
  const [commChannel, setCommChannel] = useState<CommChannel>('WhatsApp');

  const toggleInterest = (label: string) => {
    setSelectedInterests(prev =>
      prev.includes(label) ? prev.filter(item => item !== label) : [...prev, label]
    );
  };

  const isOccasionSpecial = ['Anniversary', 'Birthday', 'Honeymoon'].includes(selectedPurpose);

  const handleSave = () => {
    setCurrentStep(4);
  };

  return (
    <div className="flex flex-col w-full min-h-[calc(100vh-4rem)] pb-32 pt-4 px-5 max-w-md mx-auto">
      {/* Top Progress Line (Steps 1–3) */}
      {currentStep <= 3 && (
        <div className="w-full mb-6">
          <div className="flex items-center justify-between mb-2">
            <span className="text-[10px] font-bold uppercase tracking-[0.2em] text-[#705836]">
              {currentStep === 1 && 'YOUR TRIP'}
              {currentStep === 2 && 'YOUR INTERESTS'}
              {currentStep === 3 && 'YOUR PREFERENCES'}
            </span>
            <span className="text-[11px] font-medium text-[#7f756a]">
              Step {currentStep} of 3
            </span>
          </div>
          <div className="w-full h-1 bg-[#e6e2d9] rounded-full overflow-hidden flex">
            <div
              className="h-full bg-[#7f5700] rounded-full transition-all duration-300"
              style={{ width: `${(currentStep / 3) * 100}%` }}
            />
          </div>
        </div>
      )}

      {/* ======================================================== */}
      {/* STEP 1 OF 3: YOUR TRIP                                  */}
      {/* ======================================================== */}
      {currentStep === 1 && (
        <div className="space-y-6 animate-in fade-in duration-200">
          {/* Header & Subtitle */}
          <div>
            <h1 className="font-serif text-[26px] text-[#564121] leading-tight font-medium">
              Personalize Your Stay
            </h1>
            <p className="text-[13px] text-[#7f756a] mt-1.5 leading-relaxed">
              Help us make your time at Kachava feel like yours.
            </p>
          </div>

          {/* Question */}
          <div className="pt-2">
            <label className="text-[14px] font-medium text-[#564121] block mb-3">
              What brings you to Tulum?
            </label>

            <div className="grid grid-cols-2 gap-2.5">
              {TRIP_PURPOSES.map(purpose => {
                const isSelected = selectedPurpose === purpose;
                return (
                  <button
                    key={purpose}
                    type="button"
                    onClick={() => setSelectedPurpose(purpose)}
                    className={`py-3 px-3.5 rounded-xl text-left border transition-all flex items-center justify-between text-[13px] ${
                      isSelected
                        ? 'bg-[#564121] text-white border-[#564121] shadow-xs'
                        : 'bg-white text-[#564121] border-[#e6e2d9] hover:bg-[#fcfaf5]'
                    }`}
                  >
                    <span className="font-medium truncate">{purpose}</span>
                    <span
                      className={`w-4 h-4 rounded-full flex items-center justify-center text-[10px] shrink-0 ml-1.5 ${
                        isSelected
                          ? 'bg-[#febe4f] text-[#564121] font-bold'
                          : 'border border-[#d1c5b8]'
                      }`}
                    >
                      {isSelected && '✓'}
                    </span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Conditional Occasion Field */}
          {isOccasionSpecial && (
            <div className="pt-2 animate-in fade-in slide-in-from-top-2 duration-200">
              <label className="text-[12px] font-medium text-[#564121] block mb-1.5">
                Tell us about the occasion
              </label>
              <input
                type="text"
                value={occasionDetails}
                onChange={e => setOccasionDetails(e.target.value)}
                placeholder="4th Wedding Anniversary"
                className="w-full bg-white border border-[#d1c5b8] rounded-xl px-4 py-3 text-[13px] text-[#564121] placeholder-[#a89f91] focus:outline-none focus:ring-1 focus:ring-[#7f5700] shadow-2xs"
              />
            </div>
          )}

          {/* Actions */}
          <div className="pt-6">
            <button
              onClick={() => setCurrentStep(2)}
              className="w-full bg-[#564121] hover:bg-[#6c532d] active:scale-[0.99] text-white py-3.5 px-4 rounded-xl text-[11px] font-semibold uppercase tracking-[0.16em] flex items-center justify-center gap-1.5 transition-colors shadow-xs"
            >
              <span>CONTINUE</span>
              <span className="material-symbols-outlined text-[15px]">arrow_forward</span>
            </button>
            <p className="text-center text-[11px] text-[#7f756a] mt-3">
              Step 1 of 3
            </p>
          </div>
        </div>
      )}

      {/* ======================================================== */}
      {/* STEP 2 OF 3: YOUR INTERESTS                             */}
      {/* ======================================================== */}
      {currentStep === 2 && (
        <div className="space-y-6 animate-in fade-in duration-200">
          <div>
            <h1 className="font-serif text-[26px] text-[#564121] leading-tight font-medium">
              What would you love to experience?
            </h1>
            <p className="text-[13px] text-[#7f756a] mt-1.5 leading-relaxed">
              Select all that appeal to your rhythm.
            </p>
          </div>

          {/* Smaller, elegant selectable cards */}
          <div className="grid grid-cols-2 gap-2.5 pt-1">
            {INTEREST_OPTIONS.map(item => {
              const isSelected = selectedInterests.includes(item.label);
              return (
                <button
                  key={item.id}
                  type="button"
                  onClick={() => toggleInterest(item.label)}
                  className={`p-3 rounded-xl text-left border transition-all flex items-center justify-between min-h-[58px] ${
                    isSelected
                      ? 'bg-[#564121] text-white border-[#564121] shadow-xs'
                      : 'bg-white text-[#564121] border-[#e6e2d9] hover:bg-[#fcfaf5]'
                  }`}
                >
                  <div className="flex items-center gap-2.5 min-w-0 pr-1">
                    <span
                      className={`material-symbols-outlined text-[19px] shrink-0 ${
                        isSelected ? 'text-[#febe4f]' : 'text-[#7f5700]'
                      }`}
                    >
                      {item.icon}
                    </span>
                    <span className="text-[12px] font-medium leading-tight truncate">
                      {item.label}
                    </span>
                  </div>

                  <span
                    className={`w-3.5 h-3.5 rounded-full flex items-center justify-center text-[9px] shrink-0 ${
                      isSelected
                        ? 'bg-[#febe4f] text-[#564121] font-bold'
                        : 'border border-[#d1c5b8]'
                    }`}
                  >
                    {isSelected && '✓'}
                  </span>
                </button>
              );
            })}
          </div>

          {/* Navigation Controls */}
          <div className="pt-6 space-y-3">
            <button
              onClick={() => setCurrentStep(3)}
              className="w-full bg-[#564121] hover:bg-[#6c532d] active:scale-[0.99] text-white py-3.5 px-4 rounded-xl text-[11px] font-semibold uppercase tracking-[0.16em] flex items-center justify-center gap-1.5 transition-colors shadow-xs"
            >
              <span>CONTINUE</span>
              <span className="material-symbols-outlined text-[15px]">arrow_forward</span>
            </button>

            <button
              onClick={() => setCurrentStep(1)}
              className="w-full py-2.5 text-[11px] font-semibold uppercase tracking-wider text-[#705836] hover:text-[#564121] transition-colors"
            >
              ← Back to Trip
            </button>

            <p className="text-center text-[11px] text-[#7f756a]">
              Step 2 of 3
            </p>
          </div>
        </div>
      )}

      {/* ======================================================== */}
      {/* STEP 3 OF 3: YOUR PREFERENCES                           */}
      {/* ======================================================== */}
      {currentStep === 3 && (
        <div className="space-y-6 animate-in fade-in duration-200">
          <div>
            <h1 className="font-serif text-[26px] text-[#564121] leading-tight font-medium">
              Your Preferences
            </h1>
            <p className="text-[13px] text-[#7f756a] mt-1.5 leading-relaxed">
              Essential details for your villa and culinary care.
            </p>
          </div>

          <div className="space-y-5 pt-1">
            {/* 1. Dietary preferences */}
            <div>
              <label className="text-[12px] font-medium text-[#564121] block mb-2">
                Dietary preferences
              </label>
              <div className="flex flex-wrap gap-2">
                {DIETARY_OPTIONS.map(opt => {
                  const isSelected = dietary === opt;
                  return (
                    <button
                      key={opt}
                      type="button"
                      onClick={() => setDietary(opt)}
                      className={`px-3 py-1.5 rounded-lg text-[11px] font-medium transition-colors border ${
                        isSelected
                          ? 'bg-[#564121] text-white border-[#564121]'
                          : 'bg-white text-[#564121] border-[#e6e2d9] hover:bg-[#fcfaf5]'
                      }`}
                    >
                      {opt}
                    </button>
                  );
                })}
              </div>
            </div>

            {/* 2. Allergies */}
            <div>
              <label className="text-[12px] font-medium text-[#564121] block mb-1.5">
                Allergies
              </label>
              <input
                type="text"
                value={allergies}
                onChange={e => setAllergies(e.target.value)}
                placeholder="e.g. Shellfish, tree nuts, or none"
                className="w-full bg-white border border-[#d1c5b8] rounded-xl px-4 py-2.5 text-[13px] text-[#564121] placeholder-[#a89f91] focus:outline-none focus:ring-1 focus:ring-[#7f5700] shadow-2xs"
              />
            </div>

            {/* 3. Villa preferences */}
            <div className="p-4 rounded-xl bg-white border border-[#e6e2d9] space-y-3.5">
              <span className="text-[11px] font-bold uppercase tracking-wider text-[#705836] block">
                Villa Preferences
              </span>

              {/* Aromatherapy */}
              <div>
                <span className="text-[11px] text-[#7f756a] block mb-1.5">
                  Arrival Aromatherapy
                </span>
                <div className="grid grid-cols-2 gap-2">
                  {SCENT_OPTIONS.map(scent => {
                    const isSelected = villaScent === scent;
                    return (
                      <button
                        key={scent}
                        type="button"
                        onClick={() => setVillaScent(scent)}
                        className={`py-1.5 px-2.5 rounded-lg text-[11px] text-left border transition-colors ${
                          isSelected
                            ? 'bg-[#fbf6ed] border-[#7f5700] text-[#7f5700] font-semibold'
                            : 'bg-[#faf8f4] border-[#e6e2d9] text-[#564121]'
                        }`}
                      >
                        {scent}
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* Pillow selection */}
              <div>
                <span className="text-[11px] text-[#7f756a] block mb-1.5">
                  Pillow Selection
                </span>
                <div className="flex flex-wrap gap-1.5">
                  {PILLOW_OPTIONS.map(pillow => {
                    const isSelected = pillowType === pillow;
                    return (
                      <button
                        key={pillow}
                        type="button"
                        onClick={() => setPillowType(pillow)}
                        className={`py-1 px-2.5 rounded-lg text-[11px] border transition-colors ${
                          isSelected
                            ? 'bg-[#fbf6ed] border-[#7f5700] text-[#7f5700] font-semibold'
                            : 'bg-[#faf8f4] border-[#e6e2d9] text-[#564121]'
                        }`}
                      >
                        {pillow}
                      </button>
                    );
                  })}
                </div>
              </div>
            </div>

            {/* 4. Preferred concierge communication */}
            <div>
              <label className="text-[12px] font-medium text-[#564121] block mb-2">
                Preferred concierge communication
              </label>
              <div className="grid grid-cols-3 gap-2">
                {(['WhatsApp', 'SMS', 'Email'] as CommChannel[]).map(channel => {
                  const isSelected = commChannel === channel;
                  return (
                    <button
                      key={channel}
                      type="button"
                      onClick={() => setCommChannel(channel)}
                      className={`py-2.5 px-3 rounded-xl text-[11px] font-semibold uppercase tracking-wider transition-all border ${
                        isSelected
                          ? 'bg-[#564121] text-white border-[#564121] shadow-xs'
                          : 'bg-white text-[#7f756a] border-[#e6e2d9] hover:bg-[#fcfaf5]'
                      }`}
                    >
                      {channel}
                    </button>
                  );
                })}
              </div>
            </div>
          </div>

          {/* Actions */}
          <div className="pt-6 space-y-3">
            <button
              onClick={handleSave}
              className="w-full bg-[#564121] hover:bg-[#6c532d] active:scale-[0.99] text-white py-3.5 px-4 rounded-xl text-[11px] font-semibold uppercase tracking-[0.16em] flex items-center justify-center gap-1.5 transition-colors shadow-xs"
            >
              <span>SAVE MY PREFERENCES</span>
              <span className="material-symbols-outlined text-[15px]">check</span>
            </button>

            <button
              onClick={() => setCurrentStep(2)}
              className="w-full py-2.5 text-[11px] font-semibold uppercase tracking-wider text-[#705836] hover:text-[#564121] transition-colors"
            >
              ← Back to Interests
            </button>

            <p className="text-center text-[11px] text-[#7f756a]">
              Step 3 of 3
            </p>
          </div>
        </div>
      )}

      {/* ======================================================== */}
      {/* COMPLETION VIEW                                          */}
      {/* ======================================================== */}
      {currentStep === 4 && (
        <div className="my-auto py-10 space-y-7 text-center animate-in fade-in duration-300">
          <div className="w-14 h-14 rounded-full bg-[#fbf6ed] border border-[#f0e3cc] text-[#7f5700] mx-auto flex items-center justify-center shadow-xs">
            <span className="material-symbols-outlined text-[28px]">check</span>
          </div>

          <div className="space-y-2.5 px-2">
            <h1 className="font-serif text-[28px] text-[#564121] font-medium leading-tight">
              Your stay is taking shape.
            </h1>
            <p className="text-[14px] text-[#705836] leading-relaxed max-w-xs mx-auto">
              Your Kachava concierge will use these preferences to personalize your experience.
            </p>
          </div>

          {/* Quiet Summary Card */}
          <div className="bg-white border border-[#e6e2d9] rounded-2xl p-4 text-left shadow-xs space-y-2 text-xs">
            <div className="flex justify-between py-1 border-b border-[#f1ede5]">
              <span className="text-[#7f756a]">Occasion</span>
              <span className="font-medium text-[#564121]">
                {selectedPurpose} {occasionDetails ? `(${occasionDetails})` : ''}
              </span>
            </div>
            <div className="flex justify-between py-1 border-b border-[#f1ede5]">
              <span className="text-[#7f756a]">Interests</span>
              <span className="font-medium text-[#564121]">
                {selectedInterests.length} selected
              </span>
            </div>
            <div className="flex justify-between py-1 border-b border-[#f1ede5]">
              <span className="text-[#7f756a]">Dietary</span>
              <span className="font-medium text-[#564121]">{dietary}</span>
            </div>
            <div className="flex justify-between py-1">
              <span className="text-[#7f756a]">Communication</span>
              <span className="font-medium text-[#564121]">{commChannel}</span>
            </div>
          </div>

          <div className="pt-2 space-y-3">
            <button
              onClick={() => onNavigate('included')}
              className="w-full bg-[#564121] hover:bg-[#6c532d] active:scale-[0.99] text-white py-3.5 px-4 rounded-xl text-[11px] font-semibold uppercase tracking-[0.16em] flex items-center justify-center gap-1.5 transition-colors shadow-xs"
            >
              <span>REVIEW MY STAY</span>
              <span className="material-symbols-outlined text-[15px]">arrow_forward</span>
            </button>

            <button
              onClick={() => setCurrentStep(1)}
              className="text-[12px] text-[#7f5700] hover:underline font-medium"
            >
              Edit Preferences
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
