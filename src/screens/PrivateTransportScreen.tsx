import React, { useState } from 'react';
import { ScreenId } from '../types';
import { IMAGES } from '../data/sanctuaryData';

interface PrivateTransportScreenProps {
  onNavigate?: (screen: ScreenId) => void;
}

interface TransportData {
  airport: string;
  airline: string;
  flightNumber: string;
  arrivalDate: string;
  arrivalTime: string;
  guests: number;
  checkedBags: number;
  carryOnBags: number;
}

export const PrivateTransportScreen: React.FC<PrivateTransportScreenProps> = ({ onNavigate }) => {
  // Flight and transportation state
  const [transport, setTransport] = useState<TransportData>({
    airport: 'Cancun International Airport',
    airline: 'American Airlines',
    flightNumber: 'AA172',
    arrivalDate: 'Nov 12',
    arrivalTime: '11:35 AM',
    guests: 2,
    checkedBags: 3,
    carryOnBags: 2,
  });

  // Modal and toast state
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  // Form edit state
  const [tempAirline, setTempAirline] = useState(transport.airline);
  const [tempFlightNo, setTempFlightNo] = useState(transport.flightNumber);
  const [tempDate, setTempDate] = useState(transport.arrivalDate);
  const [tempTime, setTempTime] = useState(transport.arrivalTime);
  const [tempAirport, setTempAirport] = useState(transport.airport);
  const [tempGuests, setTempGuests] = useState(transport.guests);
  const [tempChecked, setTempChecked] = useState(transport.checkedBags);
  const [tempCarry, setTempCarry] = useState(transport.carryOnBags);

  // Collapsed expandable sections
  const [expandedSections, setExpandedSections] = useState<{ [key: string]: boolean }>({
    landing: false,
    vehicle: false,
    included: false,
  });

  const toggleSection = (sectionKey: string) => {
    setExpandedSections((prev) => ({
      ...prev,
      [sectionKey]: !prev[sectionKey],
    }));
  };

  const handleOpenEdit = () => {
    setTempAirline(transport.airline);
    setTempFlightNo(transport.flightNumber);
    setTempDate(transport.arrivalDate);
    setTempTime(transport.arrivalTime);
    setTempAirport(transport.airport);
    setTempGuests(transport.guests);
    setTempChecked(transport.checkedBags);
    setTempCarry(transport.carryOnBags);
    setIsEditModalOpen(true);
  };

  const handleSaveFlight = (e: React.FormEvent) => {
    e.preventDefault();
    setTransport({
      airport: tempAirport,
      airline: tempAirline,
      flightNumber: tempFlightNo,
      arrivalDate: tempDate,
      arrivalTime: tempTime,
      guests: tempGuests,
      checkedBags: tempChecked,
      carryOnBags: tempCarry,
    });
    setIsEditModalOpen(false);
    triggerToast('Flight details updated & synced with Concierge Eduardo');
  };

  const triggerToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3200);
  };

  const handleMessageConcierge = () => {
    if (onNavigate) {
      onNavigate('concierge');
    } else {
      window.open('https://wa.me/529841020000', '_blank');
    }
  };

  // Status tracker step definition
  const steps = [
    { label: 'Confirmed', status: 'current', icon: 'check_circle' },
    { label: 'Driver Assigned', status: 'upcoming', icon: 'person' },
    { label: 'En Route', status: 'upcoming', icon: 'directions_car' },
    { label: 'Waiting', status: 'upcoming', icon: 'schedule' },
  ];

  return (
    <div className="flex flex-col w-full pb-28 pt-2 px-5 max-w-md mx-auto">
      {/* Toast Feedback */}
      {toastMessage && (
        <div className="fixed top-20 left-1/2 -translate-x-1/2 z-50 bg-[#754d24] text-white px-4 py-2.5 rounded-full text-[12px] font-medium shadow-lg animate-in fade-in slide-in-from-top-2 duration-200 flex items-center gap-2">
          <span className="material-symbols-outlined text-[16px] text-[#c49a6c]">check</span>
          <span>{toastMessage}</span>
        </div>
      )}

      {/* TOP HEADER: Label & Title */}
      <div className="pt-2 pb-3">
        <span className="inline-block text-[10px] font-bold uppercase tracking-[0.2em] text-[#a67d52] mb-1.5">
          INCLUDED WITH YOUR STAY
        </span>
        <h1 className="font-serif text-[26px] leading-tight text-[#754d24] font-normal tracking-tight">
          Private Airport Transportation
        </h1>
      </div>

      {/* REFINED HERO IMAGE: Authentic Kachava Chauffeur Vehicle */}
      <div className="relative rounded-2xl overflow-hidden shadow-xs border border-[#e6e2d9] mb-4 aspect-[16/8.5] bg-[#ece8df]">
        <img
          src={IMAGES.chauffeurTransfer}
          alt="Private Airport Transportation"
          className="w-full h-full object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-black/15" />
        <div className="absolute bottom-3 left-4 right-4 flex items-center justify-between text-white">
          <div className="flex items-center gap-1.5">
            <span className="material-symbols-outlined text-[16px] text-[#f7e8d0]">directions_car</span>
            <span className="text-[11px] font-medium tracking-wide uppercase">Direct Villa 102 Escort</span>
          </div>
          <span className="text-[10px] text-white/90 bg-black/40 backdrop-blur-xs px-2 py-0.5 rounded-md font-sans">
            Private Chauffeur
          </span>
        </div>
      </div>

      {/* ABOVE THE FOLD: MAIN CONFIRMATION CARD */}
      <div className="bg-white rounded-2xl border border-[#e6e2d9] p-4.5 shadow-xs mb-4">
        {/* Status Confirmation Badge */}
        <div className="flex items-center justify-between pb-3.5 border-b border-[#f1ede5]">
          <div className="flex items-center gap-2">
            <span className="w-5 h-5 rounded-full bg-[#3b6d41] text-white flex items-center justify-center text-[13px] font-bold">
              ✓
            </span>
            <span className="font-serif text-[17px] font-medium text-[#754d24]">
              Transportation Confirmed ✓
            </span>
          </div>
          <span className="text-[10px] font-semibold text-[#a67d52] bg-[#f7f3ea] border border-[#e6dccc] px-2 py-0.5 rounded-full uppercase tracking-wider">
            Active
          </span>
        </div>

        {/* Essential Flight Details (4 lines visible at a glance) */}
        <div className="py-3.5 space-y-2 text-[#4e453c]">
          <div className="flex items-center gap-2.5">
            <span className="material-symbols-outlined text-[17px] text-[#a67d52] shrink-0">location_on</span>
            <span className="text-[14px] font-medium text-[#2c2621]">
              {transport.airport}
            </span>
          </div>

          <div className="flex items-center gap-2.5">
            <span className="material-symbols-outlined text-[17px] text-[#a67d52] shrink-0">flight</span>
            <span className="text-[13px] font-medium text-[#2c2621]">
              {transport.airline} {transport.flightNumber}
            </span>
          </div>

          <div className="flex items-center gap-2.5">
            <span className="material-symbols-outlined text-[17px] text-[#a67d52] shrink-0">schedule</span>
            <span className="text-[13px] text-[#754d24]">
              {transport.arrivalDate} · {transport.arrivalTime}
            </span>
          </div>

          <div className="flex items-center gap-2.5">
            <span className="material-symbols-outlined text-[17px] text-[#a67d52] shrink-0">group</span>
            <span className="text-[13px] text-[#754d24]">
              {transport.guests} guests
            </span>
            <span className="text-[11px] text-[#7f756a] ml-1">
              ({transport.checkedBags} checked · {transport.carryOnBags} carry-on)
            </span>
          </div>
        </div>

        {/* Transportation Status Tracker: Confirmed → Driver Assigned → En Route → Waiting */}
        <div className="pt-3.5 border-t border-[#f1ede5]">
          <span className="block text-[9px] font-bold uppercase tracking-[0.16em] text-[#7f756a] mb-2.5">
            Live Journey Status
          </span>

          <div className="grid grid-cols-4 gap-1.5 items-start">
            {steps.map((step, idx) => {
              const isConfirmed = idx === 0;
              return (
                <div key={step.label} className="flex flex-col items-center text-center">
                  <div className="w-full flex items-center">
                    <div
                      className={`h-1.5 w-full rounded-full transition-colors ${
                        isConfirmed ? 'bg-[#754d24]' : 'bg-[#e6e2d9]'
                      }`}
                    />
                  </div>
                  <div className="mt-2 flex flex-col items-center">
                    <span
                      className={`text-[10px] leading-tight font-medium ${
                        isConfirmed
                          ? 'text-[#754d24] font-semibold'
                          : 'text-[#9c9388]'
                      }`}
                    >
                      {step.label}
                    </span>
                    {isConfirmed && (
                      <span className="text-[8px] font-bold text-[#a67d52] uppercase tracking-wider mt-0.5">
                        Current
                      </span>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* PRIMARY AND SECONDARY ACTIONS */}
      <div className="space-y-2 mb-6">
        <button
          onClick={handleOpenEdit}
          className="w-full bg-[#754d24] hover:bg-[#603917] active:scale-[0.99] text-white py-3.5 px-4 rounded-xl text-[11px] font-semibold uppercase tracking-[0.15em] flex items-center justify-center gap-2 transition-all shadow-sm"
        >
          <span className="material-symbols-outlined text-[17px]">edit_calendar</span>
          <span>EDIT FLIGHT DETAILS</span>
        </button>

        <button
          onClick={handleMessageConcierge}
          className="w-full bg-white hover:bg-[#fbf9f4] active:scale-[0.99] border border-[#d1c5b8] text-[#754d24] py-3.5 px-4 rounded-xl text-[11px] font-semibold uppercase tracking-[0.15em] flex items-center justify-center gap-2 transition-all shadow-xs"
        >
          <span className="material-symbols-outlined text-[17px] text-[#a67d52]">support_agent</span>
          <span>MESSAGE CONCIERGE</span>
        </button>
      </div>

      {/* COLLAPSED EXPANDABLE SECTIONS */}
      <div className="space-y-2.5">
        {/* SECTION 1: What happens when I land? */}
        <div className="bg-white rounded-xl border border-[#e6e2d9] overflow-hidden transition-all shadow-xs">
          <button
            onClick={() => toggleSection('landing')}
            className="w-full px-4 py-3.5 flex items-center justify-between text-left hover:bg-[#fcfaf5] transition-colors"
            aria-expanded={expandedSections.landing}
          >
            <div className="flex items-center gap-2.5">
              <span className="material-symbols-outlined text-[19px] text-[#a67d52]">flight_land</span>
              <span className="font-serif text-[16px] font-medium text-[#754d24]">
                What happens when I land?
              </span>
            </div>
            <span
              className={`material-symbols-outlined text-[20px] text-[#7f756a] transition-transform duration-200 ${
                expandedSections.landing ? 'rotate-180 text-[#754d24]' : ''
              }`}
            >
              expand_more
            </span>
          </button>

          {expandedSections.landing && (
            <div className="px-4 pb-4 pt-1 border-t border-[#f1ede5] text-[#4e453c] text-[12px] space-y-3.5 animate-in fade-in duration-150">
              <div className="flex items-start gap-3 pt-2">
                <span className="w-5 h-5 rounded-full bg-[#754d24] text-white flex items-center justify-center text-[10px] font-bold shrink-0 mt-0.5">
                  1
                </span>
                <div>
                  <h4 className="font-semibold text-[#754d24] text-[13px]">Baggage Claim &amp; Customs</h4>
                  <p className="mt-0.5 text-[#5e5449] leading-relaxed">
                    Collect your baggage and proceed past Mexican Customs. Exit directly through the main terminal arrival glass doors.
                  </p>
                </div>
              </div>

              <div className="flex items-start gap-3">
                <span className="w-5 h-5 rounded-full bg-[#a67d52] text-white flex items-center justify-center text-[10px] font-bold shrink-0 mt-0.5">
                  2
                </span>
                <div>
                  <h4 className="font-semibold text-[#754d24] text-[13px]">Kachava Private Valet Greeting</h4>
                  <p className="mt-0.5 text-[#5e5449] leading-relaxed">
                    Your personal chauffeur will greet you curbside with a personalized Kachava Lux crest sign, chilled eucalyptus-scented organic towels, and fresh cold young coconuts.
                  </p>
                </div>
              </div>

              <div className="flex items-start gap-3">
                <span className="w-5 h-5 rounded-full bg-[#754d24] text-white flex items-center justify-center text-[10px] font-bold shrink-0 mt-0.5">
                  3
                </span>
                <div>
                  <h4 className="font-semibold text-[#754d24] text-[13px]">Direct Private Escort to Villa 102</h4>
                  <p className="mt-0.5 text-[#5e5449] leading-relaxed">
                    Relax during the ~90 minute scenic jungle corridor escort. Enjoy curated soundscapes, high-speed Wi-Fi, and artisanal refreshments along the journey.
                  </p>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* SECTION 2: Your vehicle */}
        <div className="bg-white rounded-xl border border-[#e6e2d9] overflow-hidden transition-all shadow-xs">
          <button
            onClick={() => toggleSection('vehicle')}
            className="w-full px-4 py-3.5 flex items-center justify-between text-left hover:bg-[#fcfaf5] transition-colors"
            aria-expanded={expandedSections.vehicle}
          >
            <div className="flex items-center gap-2.5">
              <span className="material-symbols-outlined text-[19px] text-[#a67d52]">directions_car</span>
              <span className="font-serif text-[16px] font-medium text-[#754d24]">
                Your vehicle
              </span>
            </div>
            <span
              className={`material-symbols-outlined text-[20px] text-[#7f756a] transition-transform duration-200 ${
                expandedSections.vehicle ? 'rotate-180 text-[#754d24]' : ''
              }`}
            >
              expand_more
            </span>
          </button>

          {expandedSections.vehicle && (
            <div className="px-4 pb-4 pt-1 border-t border-[#f1ede5] text-[#4e453c] text-[12px] space-y-3 animate-in fade-in duration-150">
              <div className="pt-2 rounded-lg overflow-hidden">
                <img
                  src={IMAGES.chauffeurTransfer}
                  alt="Cadillac Escalade ESV / Mercedes-Benz Suburban"
                  className="w-full h-36 object-cover rounded-lg"
                />
              </div>

              <div>
                <h4 className="font-semibold text-[#754d24] text-[13px]">
                  Cadillac Escalade ESV / Mercedes-Benz Suburban
                </h4>
                <p className="mt-0.5 text-[#5e5449] leading-relaxed">
                  Spacious luxury SUV fleet tailored for executive comfort, private luggage volume, and quiet travel across the Riviera Maya corridor.
                </p>
              </div>

              <div className="grid grid-cols-2 gap-2 pt-1">
                <div className="p-2.5 rounded-lg bg-[#fbf9f4] border border-[#e6e2d9]">
                  <span className="text-[10px] uppercase font-bold text-[#a67d52] block tracking-wider">In-Cabin Wi-Fi</span>
                  <span className="text-[12px] text-[#754d24]">High-Speed 5G Hotspot</span>
                </div>
                <div className="p-2.5 rounded-lg bg-[#fbf9f4] border border-[#e6e2d9]">
                  <span className="text-[10px] uppercase font-bold text-[#a67d52] block tracking-wider">Climate Control</span>
                  <span className="text-[12px] text-[#754d24]">Pre-chilled to 21°C</span>
                </div>
              </div>

              <div className="p-2.5 rounded-lg bg-[#f7f3ea] border border-[#e6e2d9] flex items-center justify-between">
                <div>
                  <span className="text-[10px] uppercase font-bold text-[#a67d52] block tracking-wider">Dedicated Chauffeur</span>
                  <span className="text-[12px] font-semibold text-[#754d24]">Carlos M. (Assigned 24h prior)</span>
                </div>
                <span className="material-symbols-outlined text-[#a67d52] text-[20px]">badge</span>
              </div>
            </div>
          )}
        </div>

        {/* SECTION 3: What's included */}
        <div className="bg-white rounded-xl border border-[#e6e2d9] overflow-hidden transition-all shadow-xs">
          <button
            onClick={() => toggleSection('included')}
            className="w-full px-4 py-3.5 flex items-center justify-between text-left hover:bg-[#fcfaf5] transition-colors"
            aria-expanded={expandedSections.included}
          >
            <div className="flex items-center gap-2.5">
              <span className="material-symbols-outlined text-[19px] text-[#a67d52]">verified</span>
              <span className="font-serif text-[16px] font-medium text-[#754d24]">
                What's included
              </span>
            </div>
            <span
              className={`material-symbols-outlined text-[20px] text-[#7f756a] transition-transform duration-200 ${
                expandedSections.included ? 'rotate-180 text-[#754d24]' : ''
              }`}
            >
              expand_more
            </span>
          </button>

          {expandedSections.included && (
            <div className="px-4 pb-4 pt-1 border-t border-[#f1ede5] text-[#4e453c] text-[12px] space-y-3 animate-in fade-in duration-150">
              <div className="pt-2 flex items-start gap-3">
                <img
                  src={IMAGES.coconuts}
                  alt="Chilled Organic Coconuts"
                  className="w-12 h-12 rounded-lg object-cover shadow-xs shrink-0"
                />
                <div>
                  <h4 className="font-semibold text-[#754d24] text-[13px]">
                    Arrival Refreshments &amp; Elixirs
                  </h4>
                  <p className="mt-0.5 text-[#5e5449] leading-relaxed">
                    Fresh cold young Mayan coconuts, bottled mineral waters, and chilled organic towels upon stepping into the vehicle.
                  </p>
                </div>
              </div>

              <div className="p-3 rounded-lg bg-[#fbf9f4] border border-[#e6e2d9] space-y-2">
                <div className="flex items-center gap-2 text-[#754d24] font-medium text-[12px]">
                  <span className="material-symbols-outlined text-[#a67d52] text-[17px]">shield</span>
                  <span>Zero-Friction Guarantee</span>
                </div>
                <p className="text-[11px] text-[#5e5449] leading-relaxed">
                  Automated satellite flight monitoring tracks your inbound flight AA172 in real time. Never worry about delays or schedule changes—your driver will automatically adjust without penalty.
                </p>
              </div>

              <div className="flex items-start gap-2 text-[#754d24] text-[12px]">
                <span className="material-symbols-outlined text-[#a67d52] text-[17px] shrink-0 mt-0.5">luggage</span>
                <p className="text-[#5e5449] leading-relaxed">
                  Complimentary full door-to-villa luggage handling from the curbside straight to the Villa 102 master wardrobe.
                </p>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* EDIT FLIGHT DETAILS MODAL */}
      {isEditModalOpen && (
        <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4 bg-black/60 backdrop-blur-xs animate-in fade-in">
          <div className="w-full max-w-md bg-[#fdf9f0] rounded-t-3xl sm:rounded-2xl p-6 shadow-2xl border border-[#d1c5b8] max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between pb-3.5 border-b border-[#e6e2d9]">
              <div>
                <span className="text-[10px] uppercase font-bold text-[#a67d52] tracking-widest block">
                  Flight Coordinates
                </span>
                <h3 className="font-serif text-[20px] text-[#754d24] font-medium mt-0.5">
                  Edit Flight Details
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

            <form onSubmit={handleSaveFlight} className="space-y-4 pt-4">
              <div>
                <label className="text-[10px] uppercase font-bold text-[#7f756a] tracking-wider block mb-1">
                  Arrival Airport
                </label>
                <input
                  type="text"
                  value={tempAirport}
                  onChange={(e) => setTempAirport(e.target.value)}
                  className="w-full p-2.5 rounded-xl bg-white border border-[#d1c5b8] text-[#2c2621] text-[13px] focus:outline-none focus:border-[#a67d52]"
                  required
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-[10px] uppercase font-bold text-[#7f756a] tracking-wider block mb-1">
                    Airline
                  </label>
                  <input
                    type="text"
                    value={tempAirline}
                    onChange={(e) => setTempAirline(e.target.value)}
                    className="w-full p-2.5 rounded-xl bg-white border border-[#d1c5b8] text-[#2c2621] text-[13px] focus:outline-none focus:border-[#a67d52]"
                    required
                  />
                </div>
                <div>
                  <label className="text-[10px] uppercase font-bold text-[#7f756a] tracking-wider block mb-1">
                    Flight Number
                  </label>
                  <input
                    type="text"
                    value={tempFlightNo}
                    onChange={(e) => setTempFlightNo(e.target.value)}
                    className="w-full p-2.5 rounded-xl bg-white border border-[#d1c5b8] text-[#2c2621] text-[13px] focus:outline-none focus:border-[#a67d52]"
                    required
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-[10px] uppercase font-bold text-[#7f756a] tracking-wider block mb-1">
                    Arrival Date
                  </label>
                  <input
                    type="text"
                    value={tempDate}
                    onChange={(e) => setTempDate(e.target.value)}
                    className="w-full p-2.5 rounded-xl bg-white border border-[#d1c5b8] text-[#2c2621] text-[13px] focus:outline-none focus:border-[#a67d52]"
                    required
                  />
                </div>
                <div>
                  <label className="text-[10px] uppercase font-bold text-[#7f756a] tracking-wider block mb-1">
                    Estimated Time
                  </label>
                  <input
                    type="text"
                    value={tempTime}
                    onChange={(e) => setTempTime(e.target.value)}
                    className="w-full p-2.5 rounded-xl bg-white border border-[#d1c5b8] text-[#2c2621] text-[13px] focus:outline-none focus:border-[#a67d52]"
                    required
                  />
                </div>
              </div>

              <div className="grid grid-cols-3 gap-2 pt-1">
                <div>
                  <label className="text-[9px] uppercase font-bold text-[#7f756a] tracking-wider block mb-1">
                    Guests
                  </label>
                  <input
                    type="number"
                    min="1"
                    max="8"
                    value={tempGuests}
                    onChange={(e) => setTempGuests(parseInt(e.target.value) || 1)}
                    className="w-full p-2 rounded-xl bg-white border border-[#d1c5b8] text-[#2c2621] text-[13px]"
                  />
                </div>
                <div>
                  <label className="text-[9px] uppercase font-bold text-[#7f756a] tracking-wider block mb-1">
                    Checked Bags
                  </label>
                  <input
                    type="number"
                    min="0"
                    max="10"
                    value={tempChecked}
                    onChange={(e) => setTempChecked(parseInt(e.target.value) || 0)}
                    className="w-full p-2 rounded-xl bg-white border border-[#d1c5b8] text-[#2c2621] text-[13px]"
                  />
                </div>
                <div>
                  <label className="text-[9px] uppercase font-bold text-[#7f756a] tracking-wider block mb-1">
                    Carry-on Bags
                  </label>
                  <input
                    type="number"
                    min="0"
                    max="10"
                    value={tempCarry}
                    onChange={(e) => setTempCarry(parseInt(e.target.value) || 0)}
                    className="w-full p-2 rounded-xl bg-white border border-[#d1c5b8] text-[#2c2621] text-[13px]"
                  />
                </div>
              </div>

              <div className="flex items-center gap-2.5 pt-4">
                <button
                  type="button"
                  onClick={() => setIsEditModalOpen(false)}
                  className="flex-1 py-3 rounded-xl bg-[#ece8df] text-[#754d24] text-[11px] font-semibold uppercase tracking-wider hover:bg-[#e4ded3] transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="flex-1 py-3 rounded-xl bg-[#754d24] text-white text-[11px] font-semibold uppercase tracking-wider hover:bg-[#603917] shadow-sm transition-colors"
                >
                  Save &amp; Sync
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
