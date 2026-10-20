<div align="center">

  <img src="public/logotype.svg" alt="Kachava Lux Logo" width="220" />

  # Kachava Lux — Guest Experience Portal
  **Exclusive Residency & Private Concierge Sanctuary for Villa 102**

  [![React](https://img.shields.io/badge/React-19.0.1-61DAFB?style=flat-square&logo=react&logoColor=black)](https://react.dev/)
  [![TypeScript](https://img.shields.io/badge/TypeScript-7.0-3178C6?style=flat-square&logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
  [![Vite](https://img.shields.io/badge/Vite-8.3-646CFF?style=flat-square&logo=vite&logoColor=white)](https://vitejs.dev/)
  [![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-v4.3-38B2AC?style=flat-square&logo=tailwind-css&logoColor=white)](https://tailwindcss.com/)
  [![Audio](https://img.shields.io/badge/Web_Audio-432Hz_Soundscape-8B6339?style=flat-square)](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API)
  [![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg?style=flat-square)](LICENSE)

  <p align="center">
    A bespoke, ultra-luxury digital hospitality platform designed for guests of <b>Kachava Lux</b>. Built to deliver an effortless, intuitive, and elevated residency experience from pre-arrival planning through seamless departure.
  </p>

</div>

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Key Features & Screens](#-key-features--screens)
- [Design System & Brand Identity](#-design-system--brand-identity)
  - [Color Palette](#color-palette)
  - [Typography](#typography)
  - [Synthesized 432Hz Soundscape](#synthesized-432hz-soundscape)
- [Technical Stack](#-technical-stack)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Running Locally](#running-locally)
  - [Build & Preview](#build--preview)
- [Brand Customization & Asset Swap Points](#-brand-customization--asset-swap-points)
- [Prototype Navigation](#-prototype-navigation)
- [License](#-license)

---

## 🌟 Overview

The **Kachava Lux Guest Experience App** is an editorial-grade, mobile-optimized web application crafted for guests staying at **Villa 102 (Ceiba Suite)** at Kachava Lux in the Riviera Maya & Puerto Cancún.

It combines intuitive guest concierge services, transparent folio management, pre-arrival bespoke stocking, private transport tracking, and custom yacht charters with warm biophilic aesthetics, soothing micro-animations, and an ambient procedural audio engine.

---

## 📱 Key Features & Screens

The application features 13 distinct interactive screens and services:

| Screen | Identifier | Core Functionality |
| :--- | :--- | :--- |
| **Residency Home** | `home` | Personalized sanctuary dashboard, Villa 102 climate status, private host contact (`Eduardo Rivera`), live Mayan Riviera weather, and day itinerary. |
| **Private Aviation & Transfer** | `transport` | Chauffeur coordination, real-time arrival flight tracking, terminal bay guidance, luggage handling, and direct driver status. |
| **Stay Personalization** | `personalize` | Pre-arrival curation: pillow atelier, ambient room temperature curves, bespoke botanical room scenting, and circadian lighting rhythms. |
| **Included Privileges** | `included` | Curated showcase of complimentary guest amenities (daily sunrise yoga, hydrotherapy circuit, private beach cabana, and sunset sailing). |
| **Curated Excursions** | `explore` | Tailored Riviera Maya adventures: private cenote diving, Sian Ka'an biosphere expeditions, PGA golf, and Mayan ruins. |
| **Private Yacht Charter** | `yacht` | On-demand charter of Kachava Marine's 55ft Galeon 500 FLY (*"Solaria"*): half-day sunset, full-day Isla Mujeres, and custom marine itineraries. |
| **In-Villa Private Dining** | `dining` | Dedicated chef bookings, Mayan Fire tasting menus, Coastal Omakase, and sommelier cellar pairings directly at Villa 102. |
| **Villa Stocking & Larder** | `stock-villa` | Pre-arrival pantry provisioning: organic elixirs, exotic fruit crates, grand cru selections, cold-pressed juices, and artisanal bakery items. |
| **24/7 Dedicated Concierge** | `concierge` | Direct host requests with a 4-stage lifecycle tracker (`Requested` → `Assigned` → `In Progress` → `Completed`), photo upload for villa maintenance, and live chat. |
| **Mid-Stay Check-In** | `midstay` | Proactive preference recalibration, housekeeping schedule adjustments, and itinerary balance halfway through the stay. |
| **Departure & Folio Ledger** | `departure` | Itemized incidentals breakdown, transparent digital billing review, express digital checkout, and outbound flight transport confirmation. |
| **Biophilic Architecture** | `philosophy` | Architectural narrative celebrating rammed earth, local zapote timber, open-air cenote ventilation, and interactive soundscape player. |
| **Guest Profile & Keycard** | `profile` | Digital villa key, Wi-Fi NFC passcodes, security emergency contacts, dietary alerts, and guest identification. |

---

## 🎨 Design System & Brand Identity

The app follows the official **Kachava Lux** brand specifications, balancing timeless elegance, natural Caribbean warmth, and editorial luxury.

### Color Palette

Derived from `src/index.css` design tokens:

- **Primary Espresso** (`#754d24` / Container `#8b6339`): Earthy Mayan timber foundation, buttons, and prominent typography.
- **Secondary Sand & Amber** (`#a67d52` / Container `#c49a6c`): Warm accents, badges, luxury highlights, and interactive triggers.
- **Surface Cream** (`#fdf9f0` / Container Low `#f7f3ea`): Warm, paper-like background evoking organic linen and white sand.
- **On-Surface Obsidian** (`#1c1c16` / Variant `#544741`): High-contrast editorial typography and body copy.
- **Outline & Borders** (`#c6b198` / `#988575`): Subtle, luxurious borders that mimic handcrafted bookbinding.

### Typography

Self-hosted from `/public/fonts/` for maximum performance and zero external font latency:
- **Display & Headings**: `Libre Baskerville` (Serif — Regular, Italic, Bold)
- **Body & Controls**: `Libre Franklin` (Sans-Serif — Variable Font)
- **Iconography**: Google `Material Symbols Outlined` and `Lucide React`

### Synthesized 432Hz Soundscape

Located in `src/utils/soundscape.ts`, the app includes a pure Web Audio API synthesizer that procedurally generates an organic sanctuary soundscape without external audio file streaming:
- **432 Hz Root Harmonic Drone** for natural relaxation and mindfulness
- **216 Hz Sub-Harmonic Triangle** oscillator for grounded warmth
- **Bandpass-Filtered Low-Pink Noise** simulating ocean breeze and cenote currents
- **Harmonic Chime** triggered dynamically with realistic exponential volume decay

---

## 💻 Technical Stack

- **Framework**: [React 19](https://react.dev/) with TypeScript
- **Bundler & Dev Server**: [Vite 8](https://vitejs.dev/)
- **Styling**: [Tailwind CSS v4](https://tailwindcss.com/) with `@tailwindcss/vite`
- **Animations**: [Motion](https://motion.dev/)
- **Icons**: [Lucide React](https://lucide.dev/) & Material Symbols Outlined
- **Audio Synthesis**: Native Browser Web Audio API (`AudioContext`, `BiquadFilterNode`, `OscillatorNode`)
- **AI Readiness**: `@google/genai` integration hook ready for server-side concierge automation

---

## 📁 Project Structure

```text
kachava-lux-guest-experience-app/
├── Kachava Lux - Brand Assets/    # Brand guidelines, vector logos, color PDFs
├── public/                        # Static assets, local photography & fonts
│   ├── brand/                     # Brand identity graphics
│   ├── fonts/                     # Libre Baskerville & Libre Franklin font files
│   ├── yacht/                     # Galeon 500 FLY high-res imagery
│   └── logotype.svg               # SVG brand logotype
├── src/
│   ├── components/                # Reusable navigation & framing elements
│   │   ├── BottomNav.tsx          # 4-tab bottom navigation bar
│   │   ├── Header.tsx             # Sticky luxury header with soundscape control
│   │   └── ScreenSwitcherDrawer.tsx # Prototype screen navigation drawer
│   ├── data/
│   │   └── sanctuaryData.ts       # Central source of truth (guest data & images)
│   ├── screens/                   # 13 dedicated experience screens
│   │   ├── ArchitecturePhilosophyScreen.tsx
│   │   ├── ConciergeScreen.tsx
│   │   ├── DepartureLedgerScreen.tsx
│   │   ├── ExploreScreen.tsx
│   │   ├── HomeScreen.tsx
│   │   ├── IncludedPrivilegesScreen.tsx
│   │   ├── MidStayCheckInScreen.tsx
│   │   ├── PrivateDiningScreen.tsx
│   │   ├── PrivateTransportScreen.tsx
│   │   ├── ProfileScreen.tsx
│   │   ├── StockVillaScreen.tsx
│   │   ├── VacationPersonalizationScreen.tsx
│   │   └── YachtCharterScreen.tsx
│   ├── utils/
│   │   └── soundscape.ts          # Procedural Web Audio sanctuary drone
│   ├── App.tsx                    # Root component & screen routing orchestrator
│   ├── index.css                  # Tailwind v4 theme tokens & typography scale
│   ├── main.tsx                   # React 19 entrypoint
│   └── types.ts                   # TypeScript interfaces & types
├── .env.example                   # Environment variable template
├── index.html                     # HTML5 shell & viewport settings
├── package.json                   # Dependencies & npm scripts
├── tsconfig.json                  # Strict TypeScript configuration
└── vite.config.ts                 # Vite bundler configuration
```

---

## 🚀 Getting Started

### Prerequisites

Ensure you have installed:
- **Node.js**: v18.0.0 or higher
- **npm**: v9.0.0 or higher

### Installation

1. Clone or download the repository to your local workspace:
   ```bash
   git clone <repository-url>
   cd kachava-lux-guest-experience-app
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

### Running Locally

Start the Vite development server:
```bash
npm run dev
```

The application will be available at:
`http://localhost:3000`

### Build & Preview

To compile the production build:
```bash
npm run build
```

To test the production build locally:
```bash
npm run preview
```

To run type checks across the codebase:
```bash
npm run lint
```

---

## 🔄 Brand Customization & Asset Swap Points

The project is structured to allow instant brand asset replacement without rewriting business logic:

1. **Guest & Property Data**:
   Modify `src/data/sanctuaryData.ts`:
   - `GUEST_INFO`: Change guest names, celebration details, room number, or stay dates.
   - `IMAGES`: Replace property photos, aerial drone shots, and amenity imagery.
   - `INITIAL_LARDER_ITEMS`: Adjust stocked pantry items, pricing, and origin notes.
   - `SERVICE_REQUESTS`: Modify concierge ticket history.

2. **Design System & Theme**:
   Modify `@theme` in `src/index.css` to update typography, border radii, or surface colors.

---

## 🧭 Prototype Navigation

For design review, stakeholder walkthroughs, and quality assurance testing:

- A discreet **"prototype screens"** floating button is available in the bottom-right corner of the interface.
- Clicking it opens `ScreenSwitcherDrawer.tsx`, providing instant one-click switching to any of the 13 screens in the guest journey.
- The drawer can also be accessed anytime through the **Profile** screen.

---

## 📄 License

This project is licensed under the [Apache-2.0 License](LICENSE).
