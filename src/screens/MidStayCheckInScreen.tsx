import React, { useState } from 'react';
import { ScreenId } from '../types';
import { GUEST_INFO, IMAGES } from '../data/sanctuaryData';

interface MidStayCheckInScreenProps {
  onNavigate: (screen: ScreenId) => void;
}

export const MidStayCheckInScreen: React.FC<MidStayCheckInScreenProps> = ({ onNavigate }) => {
  const [selectedSentiment, setSelectedSentiment] = useState<'transcendent' | 'serene' | 'tuned' | 'direct'>('tuned');
  const [selectedAspects, setSelectedAspects] = useState<string[]>([
    'Villa Climate & Night Temp',
    'Pool Terrace Plunge Heat',
  ]);
  const [note, setNote] = useState<string>(
    'The plunge pool terrace temperature was slightly crisp after twilight, and we would love the copal incense diffused 30 minutes earlier before dinner...'
  );
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);
  const [isRecording, setIsRecording] = useState(false);

  const aspects = [
    { title: 'Villa Climate & Night Temp', icon: 'thermostat' },
    { title: 'Pool Terrace Plunge Heat', icon: 'pool' },
    { title: 'Dining & Course Timing', icon: 'restaurant' },
    { title: 'Turn-Down & Linen Cadence', icon: 'bed' },
    { title: 'Aroma & Copal Balms', icon: 'local_florist' },
    { title: 'Private Driver & Transfers', icon: 'directions_car' },
    { title: 'Something Else', icon: 'more_horiz' },
  ];

  const toggleAspect = (title: string) => {
    if (selectedAspects.includes(title)) {
      setSelectedAspects(selectedAspects.filter(a => a !== title));
    } else {
      setSelectedAspects([...selectedAspects, title]);
    }
  };

  const handleSubmit = () => {
    setIsSubmitting(true);
    setTimeout(() => {
      setIsSubmitting(false);
      setIsSuccess(true);
    }, 1200);
  };

  const toggleDictation = () => {
    if (!isRecording) {
      setIsRecording(true);
      setTimeout(() => {
        setNote(prev => prev + ' Also, please reserve two coconuts for morning sunrise.');
        setIsRecording(false);
      }, 2500);
    }
  };

  return (
    <div className="flex flex-col w-full pb-28 pt-2">
      
      {/* Header Info */}
      <div className="px-5 pt-3 pb-2 flex flex-col gap-1.5">
        <div className="flex items-center justify-between">
          <span className="font-label-sm text-[10px] uppercase tracking-widest text-[#7f5700] flex items-center gap-1.5 font-bold">
            <span className="w-1.5 h-1.5 rounded-full bg-[#7f5700]"></span>
            Villa 102 · Mid-Stay Check-In
          </span>
          <span className="px-2.5 py-1 rounded-full bg-[#ece8df] text-[#564121] font-label-sm text-[10px]">
            Day 2 of 4 · 4th Anniversary
          </span>
        </div>

        <h1 className="font-headline-lg text-[#564121] tracking-tight leading-tight mt-1">
          How Is Your Stay Unfolding, {GUEST_INFO.name.split(' ')[0]}?
        </h1>

        <p className="font-body-sm text-[13px] text-[#4e453c] leading-relaxed">
          Your comfort in the sanctuary is our singular pursuit. Whether every moment has been effortless or there is a gentle nuance we can refine, whisper to us so we may curate your remaining days seamlessly.
        </p>
      </div>

      {/* Visual Ambient Vignette */}
      <div className="px-5 pt-3">
        <div className="relative w-full h-44 rounded-2xl overflow-hidden shadow-xs border border-[#e6e2d9]">
          <img
            src={IMAGES.terracePlunge}
            alt="Private Sanctuary Villa 102"
            className="w-full h-full object-cover"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent flex items-end p-4">
            <div className="flex items-center justify-between w-full text-white">
              <div className="flex items-center gap-2">
                <span className="material-symbols-outlined text-[18px] text-[#ffddb2]">spa</span>
                <span className="font-label-md text-[10px] tracking-wider uppercase text-white font-bold">
                  Private Sanctuary Villa 102
                </span>
              </div>
              <span className="font-label-sm text-[9px] px-2.5 py-0.5 rounded-full bg-white/20 backdrop-blur-md text-white font-medium">
                Private Garden
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Primary Sentiment Selector */}
      <div className="px-5 pt-5 space-y-3">
        <div className="flex items-center justify-between">
          <span className="font-label-md text-[10px] uppercase tracking-wider text-[#7f5700] font-bold">
            In-Moment Sentiment
          </span>
          <span className="font-label-sm text-[11px] text-[#7f756a] italic">
            Select to adjust experience
          </span>
        </div>

        <div className="grid grid-cols-1 gap-2.5">
          {/* Sentiment 1 */}
          <button
            onClick={() => setSelectedSentiment('transcendent')}
            className={`w-full text-left p-3.5 rounded-xl transition-all flex items-center justify-between border ${
              selectedSentiment === 'transcendent'
                ? 'bg-[#564121] text-white border-[#564121] shadow-xs'
                : 'bg-white border-[#e6e2d9] text-[#564121] hover:bg-[#f7f3ea]'
            }`}
          >
            <div className="flex items-center gap-3">
              <span className={`w-8 h-8 rounded-full flex items-center justify-center ${selectedSentiment === 'transcendent' ? 'bg-[#705836] text-[#ffddb2]' : 'bg-[#f1ede5] text-[#7f5700]'}`}>
                <span className="material-symbols-outlined text-[18px]">auto_awesome</span>
              </span>
              <div>
                <span className="text-[14px] font-semibold block leading-tight">Transcendent &amp; Flawless</span>
                <span className={`text-[12px] ${selectedSentiment === 'transcendent' ? 'text-white/80' : 'text-[#7f756a]'}`}>Every detail exceeds our hopes</span>
              </div>
            </div>
            <span className={`w-4 h-4 rounded-full border flex items-center justify-center ${selectedSentiment === 'transcendent' ? 'border-white bg-[#ffddb2]' : 'border-[#d1c5b8]'}`}>
              {selectedSentiment === 'transcendent' && <span className="w-1.5 h-1.5 rounded-full bg-[#564121]"></span>}
            </span>
          </button>

          {/* Sentiment 2 */}
          <button
            onClick={() => setSelectedSentiment('serene')}
            className={`w-full text-left p-3.5 rounded-xl transition-all flex items-center justify-between border ${
              selectedSentiment === 'serene'
                ? 'bg-[#564121] text-white border-[#564121] shadow-xs'
                : 'bg-white border-[#e6e2d9] text-[#564121] hover:bg-[#f7f3ea]'
            }`}
          >
            <div className="flex items-center gap-3">
              <span className={`w-8 h-8 rounded-full flex items-center justify-center ${selectedSentiment === 'serene' ? 'bg-[#705836] text-[#ffddb2]' : 'bg-[#f1ede5] text-[#7f5700]'}`}>
                <span className="material-symbols-outlined text-[18px]">nature_people</span>
              </span>
              <div>
                <span className="text-[14px] font-semibold block leading-tight">Serene &amp; Delightful</span>
                <span className={`text-[12px] ${selectedSentiment === 'serene' ? 'text-white/80' : 'text-[#7f756a]'}`}>Restful and deeply peaceful</span>
              </div>
            </div>
            <span className={`w-4 h-4 rounded-full border flex items-center justify-center ${selectedSentiment === 'serene' ? 'border-white bg-[#ffddb2]' : 'border-[#d1c5b8]'}`}>
              {selectedSentiment === 'serene' && <span className="w-1.5 h-1.5 rounded-full bg-[#564121]"></span>}
            </span>
          </button>

          {/* Sentiment 3 (Default Active) */}
          <button
            onClick={() => setSelectedSentiment('tuned')}
            className={`w-full text-left p-3.5 rounded-xl transition-all flex items-center justify-between border ${
              selectedSentiment === 'tuned'
                ? 'bg-[#564121] text-white border-[#564121] shadow-xs'
                : 'bg-white border-[#e6e2d9] text-[#564121] hover:bg-[#f7f3ea]'
            }`}
          >
            <div className="flex items-center gap-3">
              <span className={`w-8 h-8 rounded-full flex items-center justify-center ${selectedSentiment === 'tuned' ? 'bg-[#705836] text-[#ffddb2]' : 'bg-[#f1ede5] text-[#7f5700]'}`}>
                <span className="material-symbols-outlined text-[18px]">tune</span>
              </span>
              <div>
                <span className="text-[14px] font-semibold block leading-tight">A Detail Could Be Tuned</span>
                <span className={`text-[12px] ${selectedSentiment === 'tuned' ? 'text-white/80' : 'text-[#7f756a]'}`}>We have a subtle wish or refinement</span>
              </div>
            </div>
            <span className={`w-4 h-4 rounded-full border flex items-center justify-center ${selectedSentiment === 'tuned' ? 'border-white bg-[#ffddb2]' : 'border-[#d1c5b8]'}`}>
              {selectedSentiment === 'tuned' && <span className="w-1.5 h-1.5 rounded-full bg-[#564121]"></span>}
            </span>
          </button>

          {/* Sentiment 4 */}
          <button
            onClick={() => setSelectedSentiment('direct')}
            className={`w-full text-left p-3.5 rounded-xl transition-all flex items-center justify-between border ${
              selectedSentiment === 'direct'
                ? 'bg-[#564121] text-white border-[#564121] shadow-xs'
                : 'bg-white border-[#e6e2d9] text-[#564121] hover:bg-[#f7f3ea]'
            }`}
          >
            <div className="flex items-center gap-3">
              <span className={`w-8 h-8 rounded-full flex items-center justify-center ${selectedSentiment === 'direct' ? 'bg-[#705836] text-[#ffddb2]' : 'bg-[#f1ede5] text-[#7f5700]'}`}>
                <span className="material-symbols-outlined text-[18px]">support_agent</span>
              </span>
              <div>
                <span className="text-[14px] font-semibold block leading-tight">Need Direct Assistance</span>
                <span className={`text-[12px] ${selectedSentiment === 'direct' ? 'text-white/80' : 'text-[#7f756a]'}`}>Request Majordomo to villa immediately</span>
              </div>
            </div>
            <span className={`w-4 h-4 rounded-full border flex items-center justify-center ${selectedSentiment === 'direct' ? 'border-white bg-[#ffddb2]' : 'border-[#d1c5b8]'}`}>
              {selectedSentiment === 'direct' && <span className="w-1.5 h-1.5 rounded-full bg-[#564121]"></span>}
            </span>
          </button>
        </div>
      </div>

      {/* Active Service Recovery Container */}
      <div className="px-5 pt-6">
        <div className="bg-[#f7f3ea] border border-[#e6e2d9] rounded-2xl p-5 space-y-4 shadow-xs">
          <div className="flex items-center justify-between">
            <h2 className="font-headline-sm text-[18px] text-[#564121]">
              Tell Us What We Can Refine
            </h2>
            <span className="px-2.5 py-0.5 rounded-full bg-[#ffdead] text-[#7f5700] font-label-sm text-[8px] uppercase font-bold">
              Discreet Priority
            </span>
          </div>

          <p className="text-[12px] text-[#4e453c] leading-relaxed">
            Routed in confidence to Head Majordomo Eduardo &amp; Sanctuary Director Elena. No forms or questionnaires—just immediate care.
          </p>

          {/* Aspect Chips */}
          <div>
            <span className="font-label-sm text-[9px] uppercase tracking-wider text-[#7f5700] font-bold block mb-2">
              Focus Areas (Tap all that apply)
            </span>

            <div className="flex flex-wrap gap-2">
              {aspects.map(a => {
                const isSelected = selectedAspects.includes(a.title);
                return (
                  <button
                    key={a.title}
                    onClick={() => toggleAspect(a.title)}
                    className={`px-3 py-1.5 rounded-full text-[12px] flex items-center gap-1.5 transition-all border ${
                      isSelected
                        ? 'bg-[#564121] text-white border-[#564121] shadow-xs'
                        : 'bg-white text-[#564121] border-[#e6e2d9] hover:bg-[#f1ede5]'
                    }`}
                  >
                    <span className="material-symbols-outlined text-[15px]">{a.icon}</span>
                    <span>{a.title}</span>
                    {isSelected && <span className="text-[11px] font-bold">✓</span>}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Personal Note */}
          <div>
            <div className="flex items-center justify-between mb-1">
              <label className="font-label-sm text-[9px] uppercase tracking-wider text-[#7f756a] font-bold">
                Sarah's Personal Note to Majordomo Team
              </label>
              <span className="text-[11px] text-[#7f5700] italic">optional voice or text</span>
            </div>

            <div className="bg-white rounded-xl p-3 border border-[#d1c5b8] space-y-2">
              <textarea
                value={note}
                onChange={(e) => setNote(e.target.value)}
                rows={3}
                className="w-full text-sm text-[#1c1c16] placeholder:text-[#7f756a]/60 focus:outline-none resize-none leading-relaxed"
                placeholder="Type your quiet preferences or requests here..."
              />

              <div className="flex items-center justify-between pt-1 border-t border-[#f1ede5] text-xs">
                <button
                  type="button"
                  onClick={toggleDictation}
                  className={`flex items-center gap-1 text-[11px] font-semibold transition-colors ${
                    isRecording ? 'text-[#ba1a1a] animate-pulse' : 'text-[#7f5700] hover:text-[#564121]'
                  }`}
                >
                  <span className="material-symbols-outlined text-[16px]">mic</span>
                  <span>{isRecording ? 'Recording voice note...' : 'Tap to dictate audio note'}</span>
                </button>
                <span className="text-[10px] text-[#7f756a]">{note.length} chars</span>
              </div>
            </div>
          </div>

          {/* Response Commitment */}
          <div className="p-3 rounded-xl bg-white border border-[#e6e2d9] flex items-center gap-3 text-xs">
            <div className="w-8 h-8 rounded-full bg-[#ffdead] flex items-center justify-center text-[#7f5700] shrink-0 font-bold">
              <span className="material-symbols-outlined text-[18px]">timer</span>
            </div>
            <div>
              <span className="font-bold text-[#564121] block">Estimated Response: Under 7 Minutes</span>
              <p className="text-[11px] text-[#7f756a] mt-0.5 leading-snug">
                Eduardo will quietly dispatch our thermal engineer and confirm seamlessly via private WhatsApp.
              </p>
            </div>
          </div>

          {/* Primary Action Button */}
          <button
            onClick={handleSubmit}
            disabled={isSubmitting || isSuccess}
            className={`w-full py-3.5 px-4 rounded-xl font-label-md text-[10px] uppercase tracking-widest flex items-center justify-center gap-2 transition-all shadow-sm ${
              isSuccess
                ? 'bg-[#7f5700] text-white'
                : 'bg-[#564121] hover:bg-[#705836] text-white'
            }`}
          >
            {isSubmitting ? (
              <>
                <span className="material-symbols-outlined text-[16px] animate-spin">progress_activity</span>
                <span>Discreetly Dispatching to Eduardo...</span>
              </>
            ) : isSuccess ? (
              <>
                <span className="material-symbols-outlined text-[16px]">check_circle</span>
                <span>Received · Eduardo is Attending to Villa 102</span>
              </>
            ) : (
              <>
                <span>Share With Villa Majordomo</span>
                <span className="material-symbols-outlined text-[16px]">arrow_forward</span>
              </>
            )}
          </button>
        </div>
      </div>

      {/* Direct Line */}
      <div className="px-5 pt-5 space-y-2">
        <div className="flex items-center justify-between text-xs">
          <span className="font-label-sm text-[9px] uppercase tracking-wider text-[#7f5700] font-bold">
            Direct Majordomo Line
          </span>
          <span className="text-[11px] text-[#7f756a]">Prefer immediate conversation?</span>
        </div>

        <div className="grid grid-cols-2 gap-2">
          <a
            href="tel:+529841020000"
            className="py-2.5 px-3 rounded-xl bg-white border border-[#e6e2d9] flex items-center justify-center gap-2 text-[#564121] text-xs font-semibold hover:bg-[#f7f3ea]"
          >
            <span className="material-symbols-outlined text-[#7f5700] text-[18px]">call</span>
            <span>Call Butler Desk</span>
          </a>
          <a
            href="https://wa.me/529841020000"
            target="_blank"
            rel="noreferrer"
            className="py-2.5 px-3 rounded-xl bg-white border border-[#e6e2d9] flex items-center justify-center gap-2 text-[#564121] text-xs font-semibold hover:bg-[#f7f3ea]"
          >
            <span className="material-symbols-outlined text-[#7f5700] text-[18px]">chat</span>
            <span>WhatsApp Concierge</span>
          </a>
        </div>
      </div>

      {/* Majordomo Snapshot */}
      <div className="px-5 pt-4">
        <div className="p-3.5 rounded-2xl bg-white border border-[#e6e2d9] flex items-center justify-between shadow-xs">
          <div className="flex items-center gap-3">
            <div className="relative">
              <img
                src={IMAGES.mateoClose}
                alt="Eduardo"
                className="w-11 h-11 rounded-full object-cover shadow-xs"
              />
              <span className="absolute bottom-0 right-0 w-2.5 h-2.5 rounded-full bg-[#7f5700] ring-2 ring-white"></span>
            </div>
            <div>
              <div className="flex items-center gap-1.5">
                <span className="text-[13px] font-bold text-[#564121]">Eduardo</span>
                <span className="px-1.5 py-0.2 rounded bg-[#ffdead]/50 text-[#7f5700] font-label-sm text-[8px] uppercase font-bold">
                  Majordomo
                </span>
              </div>
              <p className="text-[11px] text-[#7f756a]">Assigned exclusively to Villa 102</p>
            </div>
          </div>

          <div className="text-right">
            <span className="font-label-sm text-[9px] uppercase tracking-wider text-[#7f5700] font-bold block">
              ON GROUNDS
            </span>
            <span className="text-[10px] text-[#7f756a]">Ready to Assist</span>
          </div>
        </div>
      </div>

      {/* The Kachava Sanctuary Vow */}
      <div className="px-5 pt-6">
        <div className="p-5 rounded-2xl bg-[#ece8df]/60 border border-[#d1c5b8]/50 space-y-2">
          <div className="flex items-center gap-2 text-[#7f5700]">
            <span className="material-symbols-outlined text-[18px]">verified</span>
            <span className="font-label-sm text-[10px] uppercase tracking-widest font-bold">
              The Kachava Sanctuary Vow
            </span>
          </div>

          <p className="text-[12px] text-[#4e453c] leading-relaxed italic">
            “You will never receive an automated questionnaire upon departure. We attend to each breath of your journey while you are here, preserving your final departure as nothing short of pure serenity.”
          </p>

          <div className="flex items-center justify-between pt-1 text-[11px]">
            <span className="text-[#564121] font-semibold">— Elena Valdés, Resident Sanctuary Director</span>
            <span className="text-[#7f5700]">Tulum, Quintana Roo</span>
          </div>
        </div>
      </div>

    </div>
  );
};
