import React, { useState, useRef } from 'react';
import { ScreenId, ServiceRequest, RequestProgressStatus } from '../types';
import { IMAGES, SERVICE_REQUESTS } from '../data/sanctuaryData';

interface ConciergeScreenProps {
  onNavigate: (screen: ScreenId) => void;
}

type IssueCategory =
  | 'Air conditioning'
  | 'Wi-Fi'
  | 'Water'
  | 'Housekeeping'
  | 'Maintenance'
  | 'Noise'
  | 'Other';

const ISSUE_CATEGORIES: IssueCategory[] = [
  'Air conditioning',
  'Wi-Fi',
  'Water',
  'Housekeeping',
  'Maintenance',
  'Noise',
  'Other',
];

const PROGRESS_STEPS: RequestProgressStatus[] = [
  'Requested',
  'Assigned',
  'In Progress',
  'Completed',
];

export const ConciergeScreen: React.FC<ConciergeScreenProps> = () => {
  const [requests, setRequests] = useState<ServiceRequest[]>(SERVICE_REQUESTS);
  const [showHistory, setShowHistory] = useState<boolean>(false);
  const [selectedRequest, setSelectedRequest] = useState<ServiceRequest | null>(null);

  // Modals
  const [isIssueModalOpen, setIsIssueModalOpen] = useState<boolean>(false);
  const [issueSubmitted, setIssueSubmitted] = useState<boolean>(false);
  const [selectedCategory, setSelectedCategory] = useState<IssueCategory>('Air conditioning');
  const [issueDetails, setIssueDetails] = useState<string>('');
  const [issuePhoto, setIssuePhoto] = useState<string | null>(null);

  // General Action Modal (Request Something, Ask Concierge, Change a Reservation)
  const [activeActionModal, setActiveActionModal] = useState<{
    type: 'request' | 'ask' | 'reservation';
    title: string;
    subtitle: string;
    placeholder: string;
    quickPills: string[];
  } | null>(null);
  const [actionDetails, setActionDetails] = useState<string>('');

  const [toastMsg, setToastMsg] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const showToast = (msg: string) => {
    setToastMsg(msg);
    setTimeout(() => setToastMsg(null), 3500);
  };

  // Open & History filters
  const openRequests = requests.filter((r) => !r.isCompleted);
  const completedRequests = requests.filter((r) => r.isCompleted);

  // Submit Issue Flow
  const handleSubmitIssue = (e: React.FormEvent) => {
    e.preventDefault();
    const newIssue: ServiceRequest = {
      id: `issue-${Date.now()}`,
      title: `${selectedCategory} Attention`,
      category: selectedCategory,
      time: 'Requested just now',
      status: 'Assigned',
      currentStep: 2,
      assignedTo: 'Eduardo',
      details: issueDetails || `${selectedCategory} reported in Villa 102.`,
      notes: 'Eduardo has been notified and is coordinating immediate resolution.',
      photoUrl: issuePhoto || undefined,
      isCompleted: false,
    };

    setRequests((prev) => [newIssue, ...prev]);
    setIssueSubmitted(true);
  };

  const handleCloseIssueModal = () => {
    setIsIssueModalOpen(false);
    setIssueSubmitted(false);
    setIssueDetails('');
    setIssuePhoto(null);
    setSelectedCategory('Air conditioning');
  };

  // Handle Photo File selection
  const handlePhotoSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = () => {
        setIssuePhoto(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  // Submit General Action
  const handleSubmitAction = (e: React.FormEvent) => {
    e.preventDefault();
    if (!activeActionModal) return;

    const newReq: ServiceRequest = {
      id: `req-${Date.now()}`,
      title: activeActionModal.title,
      category: activeActionModal.type === 'reservation' ? 'Reservation' : 'Concierge',
      time: 'Requested just now',
      status: 'Assigned',
      currentStep: 2,
      assignedTo: 'Eduardo',
      details: actionDetails || activeActionModal.subtitle,
      notes: 'Received by Eduardo. You will receive an update here.',
      isCompleted: false,
    };

    setRequests((prev) => [newReq, ...prev]);
    setActiveActionModal(null);
    setActionDetails('');
    showToast(`Request received. Eduardo will keep you updated.`);
  };

  return (
    <div className="flex flex-col w-full pb-32 pt-2 px-5 max-w-md mx-auto">
      {/* Toast Feedback */}
      {toastMsg && (
        <div className="fixed top-20 left-1/2 -translate-x-1/2 z-50 bg-[#564121] text-white px-5 py-2.5 rounded-full text-[12px] font-medium shadow-xl animate-in fade-in slide-in-from-top-2 duration-200 flex items-center gap-2 max-w-[90vw]">
          <span className="material-symbols-outlined text-[16px] text-[#febe4f] shrink-0">check_circle</span>
          <span className="truncate">{toastMsg}</span>
        </div>
      )}

      {/* ======================================================== */}
      {/* 1. HEADER                                                */}
      {/* ======================================================== */}
      <div className="pt-2 pb-5">
        <h1 className="font-serif text-[28px] text-[#564121] leading-tight font-medium">
          How Can We Care for You?
        </h1>
        <p className="text-[13px] text-[#7f756a] mt-1.5 leading-relaxed">
          Your Kachava Concierge is here before, during and after your stay.
        </p>
      </div>

      {/* ======================================================== */}
      {/* 2. YOUR CONCIERGE (Clean Personal Concierge Card)        */}
      {/* ======================================================== */}
      <div className="bg-white rounded-2xl border border-[#e6e2d9] p-5 shadow-xs mb-6">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-3.5">
            <div className="relative shrink-0">
              <img
                src={IMAGES.mateoPortrait}
                alt="Eduardo"
                className="w-14 h-14 rounded-full object-cover ring-2 ring-[#e6e2d9]"
              />
              <span className="absolute bottom-0 right-0 w-3.5 h-3.5 rounded-full bg-[#3b6d41] border-2 border-white" />
            </div>

            <div>
              <h2 className="font-serif text-[20px] font-medium text-[#564121] leading-tight">
                Eduardo
              </h2>
              <p className="text-[12px] text-[#705836] mt-0.5">
                Kachava Concierge
              </p>
            </div>
          </div>

          <div className="flex items-center gap-1.5 bg-[#f4f8f3] text-[#3b6d41] px-2.5 py-1 rounded-full text-[11px] font-medium border border-[#e1eee0]">
            <span className="w-1.5 h-1.5 rounded-full bg-[#3b6d41]" />
            <span>Available</span>
          </div>
        </div>

        {/* Action CTAs */}
        <div className="grid grid-cols-2 gap-2.5 pt-1">
          <a
            href="https://wa.me/529841020000?text=Hello%20Eduardo,%20I%20am%20staying%20in%20Villa%20102."
            target="_blank"
            rel="noreferrer"
            className="w-full bg-[#564121] hover:bg-[#6c532d] active:scale-[0.99] text-white py-3 px-3 rounded-xl text-[11px] font-semibold uppercase tracking-[0.14em] flex items-center justify-center gap-1.5 transition-colors shadow-xs"
          >
            <span className="material-symbols-outlined text-[16px]">chat</span>
            <span>MESSAGE ON WHATSAPP</span>
          </a>

          <a
            href="tel:+529841020000"
            className="w-full bg-[#f7f3ea] hover:bg-[#ede7da] active:scale-[0.99] text-[#564121] border border-[#e6e2d9] py-3 px-3 rounded-xl text-[11px] font-semibold uppercase tracking-[0.14em] flex items-center justify-center gap-1.5 transition-colors"
          >
            <span className="material-symbols-outlined text-[16px]">call</span>
            <span>CALL CONCIERGE</span>
          </a>
        </div>
      </div>

      {/* ======================================================== */}
      {/* 3. HOW CAN WE HELP? (Four Simple Action Cards)           */}
      {/* ======================================================== */}
      <div className="mb-7">
        <h3 className="text-[10px] font-bold uppercase tracking-[0.18em] text-[#705836] mb-3">
          HOW CAN WE HELP?
        </h3>

        <div className="grid grid-cols-2 gap-2.5">
          {/* Card 1: Request Something */}
          <button
            type="button"
            onClick={() =>
              setActiveActionModal({
                type: 'request',
                title: 'Request Something',
                subtitle: 'Towels, amenities, housekeeping or villa needs',
                placeholder: 'e.g. Extra bath towels, ice bucket, or fresh linen...',
                quickPills: ['Extra towels', 'Ice bucket', 'Housekeeping', 'Toiletries'],
              })
            }
            className="p-3.5 rounded-2xl bg-white border border-[#e6e2d9] text-left hover:bg-[#fcfaf5] transition-all flex flex-col justify-between min-h-[110px] shadow-2xs group"
          >
            <div className="w-8 h-8 rounded-full bg-[#f7f3ea] flex items-center justify-center text-[#7f5700] mb-2 group-hover:bg-[#f1ede5] transition-colors">
              <span className="material-symbols-outlined text-[18px]">room_service</span>
            </div>
            <div>
              <span className="text-[13px] font-semibold text-[#564121] block leading-snug">
                Request Something
              </span>
              <span className="text-[11px] text-[#7f756a] mt-1 block leading-tight">
                Towels, amenities, housekeeping or villa needs
              </span>
            </div>
          </button>

          {/* Card 2: Ask Concierge */}
          <button
            type="button"
            onClick={() =>
              setActiveActionModal({
                type: 'ask',
                title: 'Ask Concierge',
                subtitle: 'Recommendations, transportation or anything else',
                placeholder: 'e.g. Beach club recommendations, cenote tours, private car...',
                quickPills: ['Local dinner', 'Transportation', 'Cenote visit', 'Beach clubs'],
              })
            }
            className="p-3.5 rounded-2xl bg-white border border-[#e6e2d9] text-left hover:bg-[#fcfaf5] transition-all flex flex-col justify-between min-h-[110px] shadow-2xs group"
          >
            <div className="w-8 h-8 rounded-full bg-[#f7f3ea] flex items-center justify-center text-[#7f5700] mb-2 group-hover:bg-[#f1ede5] transition-colors">
              <span className="material-symbols-outlined text-[18px]">chat_bubble_outline</span>
            </div>
            <div>
              <span className="text-[13px] font-semibold text-[#564121] block leading-snug">
                Ask Concierge
              </span>
              <span className="text-[11px] text-[#7f756a] mt-1 block leading-tight">
                Recommendations, transportation or anything else
              </span>
            </div>
          </button>

          {/* Card 3: Change a Reservation */}
          <button
            type="button"
            onClick={() =>
              setActiveActionModal({
                type: 'reservation',
                title: 'Change a Reservation',
                subtitle: 'Dining, yacht, wellness or experiences',
                placeholder: 'e.g. Reschedule private dinner, adjust yacht time...',
                quickPills: ['Private dining', 'Yacht charter', 'Spa massage', 'Golf tee time'],
              })
            }
            className="p-3.5 rounded-2xl bg-white border border-[#e6e2d9] text-left hover:bg-[#fcfaf5] transition-all flex flex-col justify-between min-h-[110px] shadow-2xs group"
          >
            <div className="w-8 h-8 rounded-full bg-[#f7f3ea] flex items-center justify-center text-[#7f5700] mb-2 group-hover:bg-[#f1ede5] transition-colors">
              <span className="material-symbols-outlined text-[18px]">calendar_month</span>
            </div>
            <div>
              <span className="text-[13px] font-semibold text-[#564121] block leading-snug">
                Change a Reservation
              </span>
              <span className="text-[11px] text-[#7f756a] mt-1 block leading-tight">
                Dining, yacht, wellness or experiences
              </span>
            </div>
          </button>

          {/* Card 4: Report an Issue */}
          <button
            type="button"
            onClick={() => {
              setIssueSubmitted(false);
              setIsIssueModalOpen(true);
            }}
            className="p-3.5 rounded-2xl bg-white border border-[#e6e2d9] text-left hover:bg-[#fcfaf5] transition-all flex flex-col justify-between min-h-[110px] shadow-2xs group"
          >
            <div className="w-8 h-8 rounded-full bg-[#f7f3ea] flex items-center justify-center text-[#7f5700] mb-2 group-hover:bg-[#f1ede5] transition-colors">
              <span className="material-symbols-outlined text-[18px]">build</span>
            </div>
            <div>
              <span className="text-[13px] font-semibold text-[#564121] block leading-snug">
                Report an Issue
              </span>
              <span className="text-[11px] text-[#7f756a] mt-1 block leading-tight">
                Something in the villa needs attention
              </span>
            </div>
          </button>
        </div>
      </div>

      {/* ======================================================== */}
      {/* 4. YOUR REQUESTS                                         */}
      {/* ======================================================== */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <h3 className="text-[10px] font-bold uppercase tracking-[0.18em] text-[#705836]">
              YOUR REQUESTS
            </h3>
            {!showHistory && openRequests.length > 0 && (
              <span className="px-2 py-0.5 rounded-full bg-[#fbf6ed] text-[#7f5700] text-[10px] font-bold border border-[#f0e3cc]">
                {openRequests.length} Open
              </span>
            )}
          </div>

          <button
            type="button"
            onClick={() => setShowHistory(!showHistory)}
            className="text-[11px] font-medium text-[#7f5700] hover:underline"
          >
            {showHistory ? 'Show Open Requests' : 'View request history'}
          </button>
        </div>

        {/* Requests List */}
        <div className="space-y-3">
          {(!showHistory ? openRequests : completedRequests).length === 0 ? (
            <div className="bg-white rounded-2xl border border-[#e6e2d9] p-6 text-center shadow-2xs">
              <span className="material-symbols-outlined text-[24px] text-[#a89f91] mb-1">
                check_circle
              </span>
              <p className="text-[13px] font-medium text-[#564121]">
                {showHistory ? 'No past request history.' : 'No open requests at this moment.'}
              </p>
              <p className="text-[11px] text-[#7f756a] mt-0.5">
                {showHistory
                  ? 'Completed requests will appear here.'
                  : 'Eduardo is available if you need anything in Villa 102.'}
              </p>
            </div>
          ) : (
            (!showHistory ? openRequests : completedRequests).map((req) => {
              const currentStepIndex = req.currentStep - 1;

              return (
                <div
                  key={req.id}
                  onClick={() => setSelectedRequest(req)}
                  className="bg-white rounded-2xl border border-[#e6e2d9] p-4 shadow-2xs cursor-pointer hover:border-[#d1c5b8] hover:bg-[#fcfaf5] transition-all"
                >
                  {/* Top Bar: Title & Status */}
                  <div className="flex items-start justify-between gap-2 mb-2">
                    <div>
                      <h4 className="text-[14px] font-semibold text-[#564121] leading-snug">
                        {req.title}
                      </h4>
                      <p className="text-[11px] text-[#7f756a] mt-0.5">
                        {req.time}
                      </p>
                    </div>

                    <span
                      className={`px-2.5 py-1 rounded-full text-[10px] font-semibold uppercase tracking-wider shrink-0 ${
                        req.status === 'Completed'
                          ? 'bg-[#f4f8f3] text-[#3b6d41] border border-[#e1eee0]'
                          : 'bg-[#fbf6ed] text-[#7f5700] border border-[#f0e3cc]'
                      }`}
                    >
                      {req.status}
                    </span>
                  </div>

                  {/* 4-Stage Progress Tracker */}
                  <div className="pt-2 pb-1">
                    <div className="grid grid-cols-4 gap-1.5 mb-1.5">
                      {PROGRESS_STEPS.map((step, idx) => {
                        const isPassed = idx <= currentStepIndex;
                        const isCurrent = idx === currentStepIndex;

                        return (
                          <div
                            key={step}
                            className={`h-1.5 rounded-full transition-all ${
                              isPassed
                                ? req.status === 'Completed'
                                  ? 'bg-[#3b6d41]'
                                  : 'bg-[#7f5700]'
                                : 'bg-[#e6e2d9]'
                            } ${isCurrent ? 'ring-1 ring-[#7f5700]/30' : ''}`}
                          />
                        );
                      })}
                    </div>

                    <div className="flex justify-between items-center text-[10px] text-[#7f756a]">
                      <span>
                        Assigned to: <strong className="text-[#564121] font-medium">{req.assignedTo}</strong>
                      </span>
                      <span className="text-[#7f5700] font-medium flex items-center gap-0.5">
                        <span>Details</span>
                        <span className="material-symbols-outlined text-[13px]">chevron_right</span>
                      </span>
                    </div>
                  </div>
                </div>
              );
            })
          )}
        </div>
      </div>

      {/* ======================================================== */}
      {/* MODAL 1: REPORT AN ISSUE (Service Recovery Flow)         */}
      {/* ======================================================== */}
      {isIssueModalOpen && (
        <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4 bg-black/60 backdrop-blur-xs animate-in fade-in duration-200">
          <div className="w-full max-w-md bg-[#fdf9f0] rounded-t-3xl sm:rounded-2xl p-6 shadow-2xl border border-[#d1c5b8] max-h-[90vh] overflow-y-auto">
            {!issueSubmitted ? (
              <form onSubmit={handleSubmitIssue} className="space-y-5">
                <div className="flex items-center justify-between pb-3 border-b border-[#e6e2d9]">
                  <div>
                    <span className="text-[10px] uppercase font-bold text-[#7f5700] tracking-widest block">
                      VILLA CARE
                    </span>
                    <h3 className="font-serif text-[22px] text-[#564121] font-medium mt-0.5">
                      What needs attention?
                    </h3>
                  </div>

                  <button
                    type="button"
                    onClick={handleCloseIssueModal}
                    className="w-8 h-8 rounded-full bg-[#f1ede5] hover:bg-[#e6e2d9] flex items-center justify-center text-[#564121] transition-colors"
                  >
                    <span className="material-symbols-outlined text-[18px]">close</span>
                  </button>
                </div>

                {/* Category Pills */}
                <div>
                  <label className="text-[12px] font-medium text-[#564121] block mb-2">
                    Select Category
                  </label>
                  <div className="flex flex-wrap gap-2">
                    {ISSUE_CATEGORIES.map((cat) => {
                      const isSelected = selectedCategory === cat;
                      return (
                        <button
                          key={cat}
                          type="button"
                          onClick={() => setSelectedCategory(cat)}
                          className={`px-3 py-1.5 rounded-lg text-[11px] font-medium transition-colors border ${
                            isSelected
                              ? 'bg-[#564121] text-white border-[#564121]'
                              : 'bg-white text-[#564121] border-[#e6e2d9] hover:bg-[#fcfaf5]'
                          }`}
                        >
                          {cat}
                        </button>
                      );
                    })}
                  </div>
                </div>

                {/* Add Details */}
                <div>
                  <label className="text-[12px] font-medium text-[#564121] block mb-1.5">
                    Add details
                  </label>
                  <textarea
                    rows={3}
                    value={issueDetails}
                    onChange={(e) => setIssueDetails(e.target.value)}
                    placeholder="Describe what needs attention..."
                    className="w-full bg-white border border-[#d1c5b8] rounded-xl p-3.5 text-[13px] text-[#564121] placeholder-[#a89f91] focus:outline-none focus:ring-1 focus:ring-[#7f5700] shadow-2xs resize-none"
                  />
                </div>

                {/* Add Photo */}
                <div>
                  <label className="text-[12px] font-medium text-[#564121] block mb-1.5">
                    Add photo (optional)
                  </label>
                  <input
                    type="file"
                    accept="image/*"
                    ref={fileInputRef}
                    onChange={handlePhotoSelect}
                    className="hidden"
                  />

                  {issuePhoto ? (
                    <div className="relative rounded-xl overflow-hidden border border-[#d1c5b8] w-28 h-28 bg-[#f1ede5]">
                      <img
                        src={issuePhoto}
                        alt="Issue preview"
                        className="w-full h-full object-cover"
                      />
                      <button
                        type="button"
                        onClick={() => setIssuePhoto(null)}
                        className="absolute top-1 right-1 w-6 h-6 rounded-full bg-black/60 text-white flex items-center justify-center text-[14px]"
                      >
                        <span className="material-symbols-outlined text-[14px]">close</span>
                      </button>
                    </div>
                  ) : (
                    <button
                      type="button"
                      onClick={() => fileInputRef.current?.click()}
                      className="flex items-center gap-2 px-3.5 py-2 rounded-xl bg-white border border-[#d1c5b8] text-[12px] text-[#564121] hover:bg-[#fcfaf5] transition-colors"
                    >
                      <span className="material-symbols-outlined text-[17px] text-[#7f5700]">add_a_photo</span>
                      <span>Attach photo</span>
                    </button>
                  )}
                </div>

                {/* Submit CTA */}
                <div className="pt-2">
                  <button
                    type="submit"
                    className="w-full bg-[#564121] hover:bg-[#6c532d] active:scale-[0.99] text-white py-3.5 px-4 rounded-xl text-[11px] font-semibold uppercase tracking-[0.16em] flex items-center justify-center gap-1.5 transition-colors shadow-xs"
                  >
                    <span>SEND TO KACHAVA</span>
                    <span className="material-symbols-outlined text-[15px]">arrow_forward</span>
                  </button>
                </div>
              </form>
            ) : (
              /* Confirmation Screen */
              <div className="py-6 text-center space-y-4 animate-in fade-in duration-200">
                <div className="w-12 h-12 rounded-full bg-[#fbf6ed] border border-[#f0e3cc] text-[#7f5700] mx-auto flex items-center justify-center">
                  <span className="material-symbols-outlined text-[24px]">check</span>
                </div>

                <div className="space-y-1.5">
                  <h3 className="font-serif text-[24px] text-[#564121] font-medium leading-tight">
                    We&apos;re on it.
                  </h3>
                  <p className="text-[13px] text-[#705836] leading-relaxed max-w-xs mx-auto">
                    Your Kachava team has received your request and will keep you updated here.
                  </p>
                </div>

                <div className="pt-3">
                  <button
                    type="button"
                    onClick={handleCloseIssueModal}
                    className="w-full bg-[#564121] hover:bg-[#6c532d] text-white py-3 rounded-xl text-[11px] font-semibold uppercase tracking-[0.16em] transition-colors"
                  >
                    VIEW IN YOUR REQUESTS
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* ======================================================== */}
      {/* MODAL 2: GENERAL ACTIONS (Request, Ask, Change)          */}
      {/* ======================================================== */}
      {activeActionModal && (
        <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4 bg-black/60 backdrop-blur-xs animate-in fade-in duration-200">
          <div className="w-full max-w-md bg-[#fdf9f0] rounded-t-3xl sm:rounded-2xl p-6 shadow-2xl border border-[#d1c5b8] max-h-[90vh] overflow-y-auto">
            <form onSubmit={handleSubmitAction} className="space-y-4">
              <div className="flex items-center justify-between pb-3 border-b border-[#e6e2d9]">
                <div>
                  <span className="text-[10px] uppercase font-bold text-[#7f5700] tracking-widest block">
                    CONCIERGE CARE
                  </span>
                  <h3 className="font-serif text-[22px] text-[#564121] font-medium mt-0.5">
                    {activeActionModal.title}
                  </h3>
                </div>

                <button
                  type="button"
                  onClick={() => setActiveActionModal(null)}
                  className="w-8 h-8 rounded-full bg-[#f1ede5] hover:bg-[#e6e2d9] flex items-center justify-center text-[#564121] transition-colors"
                >
                  <span className="material-symbols-outlined text-[18px]">close</span>
                </button>
              </div>

              <p className="text-[12px] text-[#7f756a] leading-relaxed">
                {activeActionModal.subtitle}
              </p>

              {/* Quick Pills */}
              <div>
                <span className="text-[11px] text-[#7f756a] block mb-1.5">
                  Suggestions:
                </span>
                <div className="flex flex-wrap gap-1.5">
                  {activeActionModal.quickPills.map((pill) => (
                    <button
                      key={pill}
                      type="button"
                      onClick={() =>
                        setActionDetails((prev) => (prev ? `${prev}, ${pill}` : pill))
                      }
                      className="px-2.5 py-1 rounded-lg text-[11px] bg-white border border-[#e6e2d9] text-[#564121] hover:bg-[#fcfaf5] transition-colors"
                    >
                      + {pill}
                    </button>
                  ))}
                </div>
              </div>

              {/* Details */}
              <div>
                <textarea
                  rows={3}
                  value={actionDetails}
                  onChange={(e) => setActionDetails(e.target.value)}
                  placeholder={activeActionModal.placeholder}
                  className="w-full bg-white border border-[#d1c5b8] rounded-xl p-3.5 text-[13px] text-[#564121] placeholder-[#a89f91] focus:outline-none focus:ring-1 focus:ring-[#7f5700] shadow-2xs resize-none"
                />
              </div>

              <div className="pt-2">
                <button
                  type="submit"
                  className="w-full bg-[#564121] hover:bg-[#6c532d] active:scale-[0.99] text-white py-3.5 px-4 rounded-xl text-[11px] font-semibold uppercase tracking-[0.16em] flex items-center justify-center gap-1.5 transition-colors shadow-xs"
                >
                  <span>SEND TO CONCIERGE</span>
                  <span className="material-symbols-outlined text-[15px]">arrow_forward</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ======================================================== */}
      {/* MODAL 3: REQUEST DETAILS SHEET                           */}
      {/* ======================================================== */}
      {selectedRequest && (
        <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4 bg-black/60 backdrop-blur-xs animate-in fade-in duration-200">
          <div className="w-full max-w-md bg-[#fdf9f0] rounded-t-3xl sm:rounded-2xl p-6 shadow-2xl border border-[#d1c5b8] max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between pb-3 border-b border-[#e6e2d9] mb-4">
              <div>
                <span className="text-[10px] uppercase font-bold text-[#7f5700] tracking-widest block">
                  REQUEST DETAILS
                </span>
                <h3 className="font-serif text-[22px] text-[#564121] font-medium mt-0.5">
                  {selectedRequest.title}
                </h3>
              </div>

              <button
                type="button"
                onClick={() => setSelectedRequest(null)}
                className="w-8 h-8 rounded-full bg-[#f1ede5] hover:bg-[#e6e2d9] flex items-center justify-center text-[#564121] transition-colors"
              >
                <span className="material-symbols-outlined text-[18px]">close</span>
              </button>
            </div>

            {/* Time & Assigned */}
            <div className="space-y-3 mb-5 text-[13px]">
              <div className="flex justify-between py-1 border-b border-[#f1ede5]">
                <span className="text-[#7f756a]">Timeline</span>
                <span className="font-medium text-[#564121]">{selectedRequest.time}</span>
              </div>
              <div className="flex justify-between py-1 border-b border-[#f1ede5]">
                <span className="text-[#7f756a]">Assigned To</span>
                <span className="font-medium text-[#564121]">{selectedRequest.assignedTo} (Concierge)</span>
              </div>
              <div className="flex justify-between py-1 border-b border-[#f1ede5]">
                <span className="text-[#7f756a]">Status</span>
                <span className="font-semibold text-[#7f5700] uppercase text-[11px] tracking-wider">
                  {selectedRequest.status}
                </span>
              </div>
            </div>

            {/* 4-Stage Progress Visualizer */}
            <div className="p-4 rounded-xl bg-white border border-[#e6e2d9] mb-5">
              <span className="text-[10px] font-bold uppercase tracking-wider text-[#705836] block mb-3">
                Current Progress
              </span>

              <div className="relative pl-6 space-y-4">
                {PROGRESS_STEPS.map((step, idx) => {
                  const isCurrent = idx === selectedRequest.currentStep - 1;
                  const isCompleted = idx < selectedRequest.currentStep - 1 || selectedRequest.status === 'Completed';

                  return (
                    <div key={step} className="relative flex items-center gap-3">
                      {/* Vertical line connecting nodes */}
                      {idx < PROGRESS_STEPS.length - 1 && (
                        <div
                          className={`absolute -left-6 top-3 w-0.5 h-7 ${
                            idx < selectedRequest.currentStep - 1 ? 'bg-[#7f5700]' : 'bg-[#e6e2d9]'
                          }`}
                        />
                      )}

                      {/* Node indicator */}
                      <span
                        className={`absolute -left-[27px] w-4 h-4 rounded-full flex items-center justify-center text-[9px] ${
                          isCompleted
                            ? 'bg-[#7f5700] text-white'
                            : isCurrent
                            ? 'bg-[#febe4f] text-[#564121] font-bold ring-2 ring-[#7f5700]/30'
                            : 'bg-[#f1ede5] border border-[#d1c5b8] text-transparent'
                        }`}
                      >
                        {isCompleted && '✓'}
                      </span>

                      <div>
                        <span
                          className={`text-[12px] block leading-tight ${
                            isCurrent
                              ? 'font-bold text-[#564121]'
                              : isCompleted
                              ? 'text-[#564121] font-medium'
                              : 'text-[#a89f91]'
                          }`}
                        >
                          {step}
                        </span>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Details & Notes */}
            {selectedRequest.details && (
              <div className="mb-4">
                <span className="text-[11px] text-[#7f756a] block mb-1">Request Notes</span>
                <p className="text-[12px] text-[#564121] bg-white p-3 rounded-xl border border-[#e6e2d9] leading-relaxed">
                  {selectedRequest.details}
                </p>
              </div>
            )}

            {selectedRequest.photoUrl && (
              <div className="mb-4">
                <span className="text-[11px] text-[#7f756a] block mb-1">Attached Photo</span>
                <img
                  src={selectedRequest.photoUrl}
                  alt="Attachment"
                  className="w-full h-40 object-cover rounded-xl border border-[#e6e2d9]"
                />
              </div>
            )}

            {/* Direct WhatsApp Contact CTA */}
            <div className="pt-2">
              <a
                href={`https://wa.me/529841020000?text=Hello%20Eduardo,%20checking%20on%20my%20request:%20${encodeURIComponent(
                  selectedRequest.title
                )}`}
                target="_blank"
                rel="noreferrer"
                className="w-full bg-[#564121] hover:bg-[#6c532d] text-white py-3 px-4 rounded-xl text-[11px] font-semibold uppercase tracking-[0.14em] flex items-center justify-center gap-1.5 transition-colors shadow-xs"
              >
                <span className="material-symbols-outlined text-[16px]">chat</span>
                <span>Message Eduardo About This</span>
              </a>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
