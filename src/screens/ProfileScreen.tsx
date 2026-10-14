import React, { useState } from 'react';
import { ScreenId } from '../types';
import { GUEST_INFO, IMAGES } from '../data/sanctuaryData';

interface ProfileScreenProps {
  onNavigate: (screen: ScreenId) => void;
  onOpenScreenSwitcher?: () => void;
}

export const ProfileScreen: React.FC<ProfileScreenProps> = ({ onNavigate }) => {
  // Guest profile state
  const [guestName, setGuestName] = useState(GUEST_INFO.name);
  const [partnerName, setPartnerName] = useState(GUEST_INFO.partner);
  const [celebration, setCelebration] = useState('4th Wedding Anniversary');
  const [dietaryProfile, setDietaryProfile] = useState('Pescatarian · Gluten Sensitive');
  const [allergies, setAllergies] = useState('Shellfish · Chef Notified');
  const [interests, setInterests] = useState<string[]>([
    'Wellness',
    'Gastronomy',
    'Yacht',
    'Privacy',
  ]);
  const [preferredCommunication, setPreferredCommunication] = useState('WhatsApp');
  const [paymentMethod, setPaymentMethod] = useState('Visa •••• 8412');

  // Modals & Feedback
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [editSection, setEditSection] = useState<'guest' | 'preferences' | 'payment'>('preferences');
  const [isPrivacyModalOpen, setIsPrivacyModalOpen] = useState(false);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  // Temp editing states
  const [tempDietary, setTempDietary] = useState(dietaryProfile);
  const [tempAllergies, setTempAllergies] = useState(allergies);
  const [tempInterests, setTempInterests] = useState<string[]>(interests);
  const [tempCommunication, setTempCommunication] = useState(preferredCommunication);
  const [tempGuestName, setTempGuestName] = useState(guestName);
  const [tempPartnerName, setTempPartnerName] = useState(partnerName);
  const [tempCelebration, setTempCelebration] = useState(celebration);
  const [tempPayment, setTempPayment] = useState(paymentMethod);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3200);
  };

  const handleOpenEdit = (section: 'guest' | 'preferences' | 'payment') => {
    setEditSection(section);
    setTempGuestName(guestName);
    setTempPartnerName(partnerName);
    setTempCelebration(celebration);
    setTempDietary(dietaryProfile);
    setTempAllergies(allergies);
    setTempInterests([...interests]);
    setTempCommunication(preferredCommunication);
    setTempPayment(paymentMethod);
    setIsEditModalOpen(true);
  };

  const handleSavePreferences = (e: React.FormEvent) => {
    e.preventDefault();
    if (editSection === 'guest') {
      setGuestName(tempGuestName);
      setPartnerName(tempPartnerName);
      setCelebration(tempCelebration);
      showToast('Guest profile details updated.');
    } else if (editSection === 'preferences') {
      setDietaryProfile(tempDietary);
      setAllergies(tempAllergies);
      setInterests(tempInterests);
      setPreferredCommunication(tempCommunication);
      showToast('Stay preferences synced with Villa 102 Majordomo.');
    } else if (editSection === 'payment') {
      setPaymentMethod(tempPayment);
      showToast('Payment method saved to encrypted residency folio.');
    }
    setIsEditModalOpen(false);
  };

  const toggleInterest = (tag: string) => {
    setTempInterests((prev) =>
      prev.includes(tag) ? prev.filter((t) => t !== tag) : [...prev, tag]
    );
  };

  const availableInterests = [
    'Wellness',
    'Gastronomy',
    'Yacht',
    'Privacy',
    'Cenotes & Caverns',
    'Architecture',
    'Golf',
    'Ocean Sports',
  ];

  return (
    <div className="flex flex-col w-full pb-32 pt-2 px-5 max-w-md mx-auto">
      {/* Toast Feedback */}
      {toastMessage && (
        <div className="fixed top-20 left-1/2 -translate-x-1/2 z-50 bg-[#754d24] text-white px-4 py-2.5 rounded-full text-[12px] font-medium shadow-xl animate-in fade-in slide-in-from-top-2 duration-200 flex items-center gap-2 max-w-[90vw]">
          <span className="material-symbols-outlined text-[16px] text-[#c49a6c] shrink-0">check_circle</span>
          <span className="truncate">{toastMessage}</span>
        </div>
      )}

      {/* HEADER: Profile */}
      <div className="pt-2 pb-4">
        <span className="text-[10px] font-bold uppercase tracking-[0.2em] text-[#a67d52] block mb-1">
          SANCTUARY RESIDENCY
        </span>
        <h1 className="font-serif text-[28px] text-[#754d24] font-normal tracking-tight">
          Profile
        </h1>
      </div>

      {/* 1. GUEST INFORMATION */}
      <div className="bg-white rounded-2xl border border-[#e6e2d9] p-5 shadow-xs mb-4">
        <div className="flex items-center justify-between pb-3 mb-3 border-b border-[#f1ede5]">
          <span className="text-[10px] font-bold uppercase tracking-[0.18em] text-[#7f756a]">
            GUEST INFORMATION
          </span>
          <button
            onClick={() => handleOpenEdit('guest')}
            className="text-[11px] font-medium text-[#a67d52] hover:underline"
          >
            Edit
          </button>
        </div>

        <div className="flex items-center gap-4">
          <div className="relative shrink-0">
            <img
              src={IMAGES.avatar}
              alt={guestName}
              className="w-16 h-16 rounded-full object-cover ring-2 ring-[#e6e2d9]"
            />
            <span className="absolute bottom-0 right-0 w-4 h-4 rounded-full bg-[#3b6d41] border-2 border-white" />
          </div>

          <div className="flex-1 min-w-0">
            <h2 className="font-serif text-[20px] font-medium text-[#754d24] leading-tight">
              {guestName}
            </h2>
            <p className="text-[13px] text-[#5e5449] mt-0.5">
              Guest &amp; {partnerName}
            </p>

            <div className="flex items-center gap-1.5 mt-2.5">
              <span className="material-symbols-outlined text-[14px] text-[#a67d52]">favorite</span>
              <span className="text-[11px] font-medium text-[#a67d52] bg-[#f7f3ea] border border-[#e6dccc] px-2.5 py-0.5 rounded-full">
                {celebration}
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* 2. STAY DETAILS */}
      <div className="bg-white rounded-2xl border border-[#e6e2d9] p-5 shadow-xs mb-4">
        <div className="flex items-center justify-between pb-3 border-b border-[#f1ede5]">
          <span className="text-[10px] font-bold uppercase tracking-[0.18em] text-[#7f756a]">
            STAY DETAILS
          </span>
          <button
            onClick={() => onNavigate('home')}
            className="text-[11px] font-medium text-[#a67d52] hover:underline flex items-center gap-0.5"
          >
            <span>Home Overview</span>
            <span className="material-symbols-outlined text-[14px]">chevron_right</span>
          </button>
        </div>

        <div className="pt-3.5 space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-[13px] text-[#7f756a]">Residence</span>
            <span className="font-serif text-[16px] font-medium text-[#754d24]">
              Villa 102
            </span>
          </div>

          <div className="flex items-center justify-between">
            <span className="text-[13px] text-[#7f756a]">Dates</span>
            <span className="text-[13px] font-medium text-[#754d24]">
              November 12–16, 2026
            </span>
          </div>

          <div className="flex items-center justify-between">
            <span className="text-[13px] text-[#7f756a]">Stay Length &amp; Party</span>
            <span className="text-[13px] text-[#754d24]">
              4 nights · 2 guests
            </span>
          </div>
        </div>
      </div>

      {/* 3. PREFERENCES */}
      <div className="bg-white rounded-2xl border border-[#e6e2d9] p-5 shadow-xs mb-4 space-y-3.5">
        <div className="flex items-center justify-between pb-2 border-b border-[#f1ede5]">
          <span className="text-[10px] font-bold uppercase tracking-[0.18em] text-[#7f756a]">
            PREFERENCES
          </span>
          <button
            onClick={() => onNavigate('personalize')}
            className="text-[11px] font-medium text-[#a67d52] hover:underline"
          >
            Onboarding Flow
          </button>
        </div>

        <div>
          <span className="text-[11px] text-[#7f756a] block mb-1">
            Villa Aromatherapy &amp; Comfort
          </span>
          <p className="text-[13px] font-medium text-[#754d24]">
            Copal &amp; Amber · Goose Down Pillows
          </p>
        </div>

        <div className="pt-2 border-t border-[#f1ede5]">
          <span className="text-[11px] text-[#7f756a] block mb-1.5">
            Curated Interests
          </span>
          <div className="flex flex-wrap gap-1.5">
            {interests.map((item) => (
              <span
                key={item}
                className="text-[11px] text-[#754d24] bg-[#f7f3ea] border border-[#e6e2d9] px-2.5 py-0.5 rounded-full font-medium"
              >
                {item}
              </span>
            ))}
          </div>
        </div>
      </div>

      {/* 4. DIETARY & ALLERGIES */}
      <div className="bg-white rounded-2xl border border-[#e6e2d9] p-5 shadow-xs mb-4 space-y-3.5">
        <div className="flex items-center justify-between pb-2 border-b border-[#f1ede5]">
          <span className="text-[10px] font-bold uppercase tracking-[0.18em] text-[#7f756a]">
            DIETARY &amp; ALLERGIES
          </span>
          <button
            onClick={() => handleOpenEdit('preferences')}
            className="text-[11px] font-medium text-[#a67d52] hover:underline"
          >
            Edit
          </button>
        </div>

        <div>
          <span className="text-[11px] text-[#7f756a] block mb-0.5">
            Dietary Regimen
          </span>
          <p className="text-[13px] font-medium text-[#754d24]">
            {dietaryProfile}
          </p>
        </div>

        <div className="pt-2 border-t border-[#f1ede5]">
          <span className="text-[11px] text-[#ba1a1a] font-semibold flex items-center gap-1 mb-0.5">
            <span className="material-symbols-outlined text-[14px]">warning</span>
            Allergy Caution
          </span>
          <p className="text-[13px] font-medium text-[#754d24]">
            {allergies}
          </p>
        </div>
      </div>

      {/* 5. COMMUNICATION PREFERENCE */}
      <div className="bg-white rounded-2xl border border-[#e6e2d9] p-5 shadow-xs mb-4">
        <div className="flex items-center justify-between pb-2 border-b border-[#f1ede5]">
          <span className="text-[10px] font-bold uppercase tracking-[0.18em] text-[#7f756a]">
            COMMUNICATION PREFERENCE
          </span>
          <button
            onClick={() => handleOpenEdit('preferences')}
            className="text-[11px] font-medium text-[#a67d52] hover:underline"
          >
            Change
          </button>
        </div>

        <div className="pt-3 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-[#f7f3ea] border border-[#e6e2d9] flex items-center justify-center text-[#3b6d41]">
              <span className="material-symbols-outlined text-[20px]">chat</span>
            </div>
            <div>
              <span className="text-[13px] font-medium text-[#754d24] block">
                {preferredCommunication}
              </span>
              <span className="text-[11px] text-[#7f756a]">
                Direct line with Majordomo Eduardo
              </span>
            </div>
          </div>
          <button
            onClick={() => onNavigate('concierge')}
            className="text-[11px] font-semibold text-[#a67d52] hover:underline"
          >
            Open Chat
          </button>
        </div>
      </div>

      {/* 6. PAYMENT METHOD */}
      <div className="bg-white rounded-2xl border border-[#e6e2d9] p-5 shadow-xs mb-4">
        <div className="flex items-center justify-between pb-2 border-b border-[#f1ede5]">
          <span className="text-[10px] font-bold uppercase tracking-[0.18em] text-[#7f756a]">
            PAYMENT METHOD
          </span>
          <button
            onClick={() => handleOpenEdit('payment')}
            className="text-[11px] font-medium text-[#a67d52] hover:underline"
          >
            Manage
          </button>
        </div>

        <div className="pt-3 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-[#f7f3ea] border border-[#e6e2d9] flex items-center justify-center text-[#754d24]">
              <span className="material-symbols-outlined text-[20px]">credit_card</span>
            </div>
            <div>
              <span className="text-[13px] font-medium text-[#754d24] block">
                {paymentMethod}
              </span>
              <span className="text-[11px] text-[#7f756a]">
                Encrypted residency folio · Zero hold
              </span>
            </div>
          </div>
          <span className="text-[10px] uppercase font-bold text-[#3b6d41] bg-[#eef5ed] px-2 py-0.5 rounded">
            Active
          </span>
        </div>
      </div>

      {/* 7. PRIVACY & SETTINGS */}
      <div className="bg-white rounded-2xl border border-[#e6e2d9] p-5 shadow-xs mb-6">
        <div className="pb-2 border-b border-[#f1ede5]">
          <span className="text-[10px] font-bold uppercase tracking-[0.18em] text-[#7f756a]">
            PRIVACY &amp; SETTINGS
          </span>
        </div>

        <div className="pt-3 space-y-2 text-xs">
          <div className="flex items-center justify-between py-1.5 border-b border-[#f1ede5]">
            <span className="text-[#754d24]">Guest Data Confidentiality</span>
            <span className="text-[#3b6d41] font-semibold">Strict Encrypted</span>
          </div>
          <div className="flex items-center justify-between py-1.5 border-b border-[#f1ede5]">
            <span className="text-[#754d24]">Digital Key &amp; Proximity</span>
            <span className="text-[#a67d52] font-semibold">Enabled (Villa 102)</span>
          </div>
          <div className="flex items-center justify-between py-1.5">
            <span className="text-[#754d24]">Data Retention Period</span>
            <span className="text-[#7f756a]">Post-Departure Purge</span>
          </div>
        </div>

        <div className="pt-3 text-center">
          <button
            onClick={() => setIsPrivacyModalOpen(true)}
            className="text-[11px] text-[#a67d52] hover:underline font-medium"
          >
            Review Full Sanctuary Privacy Policy
          </button>
        </div>
      </div>

      {/* ENDING ACTIONS: Contact Concierge & Privacy */}
      <div className="space-y-3 pt-1 pb-4">
        <button
          onClick={() => onNavigate('concierge')}
          className="w-full bg-[#754d24] hover:bg-[#603917] active:scale-[0.99] text-white py-3.5 px-4 rounded-xl text-[11px] font-semibold uppercase tracking-[0.15em] flex items-center justify-center gap-2 transition-all shadow-sm"
        >
          <span className="material-symbols-outlined text-[17px]">support_agent</span>
          <span>Contact Concierge</span>
        </button>

        <div className="text-center pt-2">
          <button
            onClick={() => setIsPrivacyModalOpen(true)}
            className="text-[12px] text-[#7f756a] hover:text-[#754d24] underline transition-colors"
          >
            Privacy &amp; Guest Data
          </button>
        </div>
      </div>

      {/* EDIT MODAL */}
      {isEditModalOpen && (
        <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4 bg-black/60 backdrop-blur-xs animate-in fade-in duration-200">
          <div className="w-full max-w-md bg-[#fdf9f0] rounded-t-3xl sm:rounded-2xl p-6 shadow-2xl border border-[#d1c5b8] max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between pb-3.5 border-b border-[#e6e2d9]">
              <div>
                <span className="text-[10px] uppercase font-bold text-[#a67d52] tracking-widest block">
                  Residency Preferences
                </span>
                <h3 className="font-serif text-[20px] text-[#754d24] font-medium mt-0.5">
                  {editSection === 'guest' && 'Edit Guest Details'}
                  {editSection === 'preferences' && 'Edit Stay Preferences'}
                  {editSection === 'payment' && 'Manage Payment Method'}
                </h3>
              </div>
              <button
                onClick={() => setIsEditModalOpen(false)}
                className="w-8 h-8 rounded-full bg-[#ece8df] hover:bg-[#dfd9cd] flex items-center justify-center text-[#754d24] transition-colors"
                aria-label="Close"
              >
                <span className="material-symbols-outlined text-[18px]">close</span>
              </button>
            </div>

            <form onSubmit={handleSavePreferences} className="space-y-4 pt-4">
              {editSection === 'guest' && (
                <>
                  <div>
                    <label className="text-[10px] uppercase font-bold text-[#7f756a] tracking-wider block mb-1">
                      Primary Guest Name
                    </label>
                    <input
                      type="text"
                      value={tempGuestName}
                      onChange={(e) => setTempGuestName(e.target.value)}
                      className="w-full p-2.5 rounded-xl bg-white border border-[#d1c5b8] text-[#2c2621] text-[13px] focus:outline-none focus:border-[#a67d52]"
                      required
                    />
                  </div>

                  <div>
                    <label className="text-[10px] uppercase font-bold text-[#7f756a] tracking-wider block mb-1">
                      Accompanying Guest
                    </label>
                    <input
                      type="text"
                      value={tempPartnerName}
                      onChange={(e) => setTempPartnerName(e.target.value)}
                      className="w-full p-2.5 rounded-xl bg-white border border-[#d1c5b8] text-[#2c2621] text-[13px] focus:outline-none focus:border-[#a67d52]"
                      required
                    />
                  </div>

                  <div>
                    <label className="text-[10px] uppercase font-bold text-[#7f756a] tracking-wider block mb-1">
                      Special Celebration
                    </label>
                    <input
                      type="text"
                      value={tempCelebration}
                      onChange={(e) => setTempCelebration(e.target.value)}
                      className="w-full p-2.5 rounded-xl bg-white border border-[#d1c5b8] text-[#2c2621] text-[13px] focus:outline-none focus:border-[#a67d52]"
                    />
                  </div>
                </>
              )}

              {editSection === 'preferences' && (
                <>
                  <div>
                    <label className="text-[10px] uppercase font-bold text-[#7f756a] tracking-wider block mb-1">
                      Dietary Profile
                    </label>
                    <input
                      type="text"
                      value={tempDietary}
                      onChange={(e) => setTempDietary(e.target.value)}
                      className="w-full p-2.5 rounded-xl bg-white border border-[#d1c5b8] text-[#2c2621] text-[13px] focus:outline-none focus:border-[#a67d52]"
                      required
                    />
                  </div>

                  <div>
                    <label className="text-[10px] uppercase font-bold text-[#ba1a1a] tracking-wider block mb-1">
                      Allergy Alert (Culinary Team Flagged)
                    </label>
                    <input
                      type="text"
                      value={tempAllergies}
                      onChange={(e) => setTempAllergies(e.target.value)}
                      className="w-full p-2.5 rounded-xl bg-white border border-[#d1c5b8] text-[#2c2621] text-[13px] focus:outline-none focus:border-[#ba1a1a]"
                      required
                    />
                  </div>

                  <div>
                    <label className="text-[10px] uppercase font-bold text-[#7f756a] tracking-wider block mb-1.5">
                      Interests &amp; Encounters
                    </label>
                    <div className="flex flex-wrap gap-2">
                      {availableInterests.map((interest) => {
                        const isSelected = tempInterests.includes(interest);
                        return (
                          <button
                            type="button"
                            key={interest}
                            onClick={() => toggleInterest(interest)}
                            className={`px-3 py-1.5 rounded-full text-[11px] font-medium transition-all ${
                              isSelected
                                ? 'bg-[#754d24] text-white'
                                : 'bg-white text-[#754d24] border border-[#d1c5b8]'
                            }`}
                          >
                            {interest} {isSelected ? '✓' : '+'}
                          </button>
                        );
                      })}
                    </div>
                  </div>

                  <div>
                    <label className="text-[10px] uppercase font-bold text-[#7f756a] tracking-wider block mb-1">
                      Preferred Communication
                    </label>
                    <select
                      value={tempCommunication}
                      onChange={(e) => setTempCommunication(e.target.value)}
                      className="w-full p-2.5 rounded-xl bg-white border border-[#d1c5b8] text-[#2c2621] text-[13px] focus:outline-none focus:border-[#a67d52]"
                    >
                      <option value="WhatsApp">WhatsApp</option>
                      <option value="In-Villa Chime">In-Villa Chime</option>
                      <option value="SMS / Text">SMS / Text</option>
                      <option value="Email">Email</option>
                    </select>
                  </div>
                </>
              )}

              {editSection === 'payment' && (
                <>
                  <div>
                    <label className="text-[10px] uppercase font-bold text-[#7f756a] tracking-wider block mb-1">
                      Residency Folio Card
                    </label>
                    <input
                      type="text"
                      value={tempPayment}
                      onChange={(e) => setTempPayment(e.target.value)}
                      className="w-full p-2.5 rounded-xl bg-white border border-[#d1c5b8] text-[#2c2621] text-[13px] focus:outline-none focus:border-[#a67d52]"
                      required
                    />
                    <p className="text-[11px] text-[#7f756a] mt-1.5 leading-relaxed">
                      All incidentals and unlisted experiences will be billed smoothly to this card upon checkout without requiring paper signatures.
                    </p>
                  </div>
                </>
              )}

              <div className="flex items-center gap-2.5 pt-4">
                <button
                  type="button"
                  onClick={() => setIsEditModalOpen(false)}
                  className="flex-1 py-3 rounded-xl bg-[#ece8df] text-[#754d24] text-[11px] font-semibold uppercase tracking-wider hover:bg-[#dfd9cd] transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="flex-1 py-3 rounded-xl bg-[#754d24] text-white text-[11px] font-semibold uppercase tracking-wider hover:bg-[#603917] shadow-sm transition-colors"
                >
                  Save Changes
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* PRIVACY & GUEST DATA MODAL */}
      {isPrivacyModalOpen && (
        <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4 bg-black/60 backdrop-blur-xs animate-in fade-in duration-200">
          <div className="w-full max-w-md bg-[#fdf9f0] rounded-t-3xl sm:rounded-2xl p-6 shadow-2xl border border-[#d1c5b8] max-h-[85vh] overflow-y-auto">
            <div className="flex items-center justify-between pb-3.5 border-b border-[#e6e2d9]">
              <div>
                <span className="text-[10px] uppercase font-bold text-[#a67d52] tracking-widest block">
                  Guest Confidentiality
                </span>
                <h3 className="font-serif text-[20px] text-[#754d24] font-medium mt-0.5">
                  Privacy &amp; Guest Data
                </h3>
              </div>
              <button
                onClick={() => setIsPrivacyModalOpen(false)}
                className="w-8 h-8 rounded-full bg-[#ece8df] hover:bg-[#dfd9cd] flex items-center justify-center text-[#754d24] transition-colors"
                aria-label="Close"
              >
                <span className="material-symbols-outlined text-[18px]">close</span>
              </button>
            </div>

            <div className="space-y-4 pt-4 text-[12px] text-[#4e453c] leading-relaxed">
              <div className="p-3.5 rounded-xl bg-white border border-[#e6e2d9]">
                <h4 className="font-semibold text-[#754d24] text-[13px] mb-1">
                  Absolute Discretion Guarantee
                </h4>
                <p>
                  At Kachava Lux, your personal coordinates, itinerary selections, dietary requirements, and folio transactions are held in strict sanctuary confidentiality. No data is ever shared with third-party advertising or commercial networks.
                </p>
              </div>

              <div className="p-3.5 rounded-xl bg-white border border-[#e6e2d9]">
                <h4 className="font-semibold text-[#754d24] text-[13px] mb-1">
                  Encrypted Residency Folio
                </h4>
                <p>
                  Payment methods and folio records are processed using bank-grade tokenization. Your Majordomo and culinary teams receive only authorized hospitality directives necessary to tailor your stay.
                </p>
              </div>

              <div className="p-3.5 rounded-xl bg-white border border-[#e6e2d9]">
                <h4 className="font-semibold text-[#754d24] text-[13px] mb-1">
                  Data Retention &amp; Post-Departure
                </h4>
                <p>
                  Upon departure, your stay profile is placed in secure archival status to ensure your preferences are remembered for your next return to Kachava Lux.
                </p>
              </div>

              <button
                onClick={() => setIsPrivacyModalOpen(false)}
                className="w-full py-3 rounded-xl bg-[#754d24] text-white text-[11px] font-semibold uppercase tracking-wider hover:bg-[#603917] shadow-sm transition-colors mt-2"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
