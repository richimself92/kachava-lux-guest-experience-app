import 'package:flutter/material.dart';

/// All 13 interactive experience screens in the Kachava Lux Guest Portal.
enum ScreenId {
  home(
    wireId: 'home',
    title: 'Residency Home',
    shortTitle: 'Residency Home',
    subtitle: 'Countdown, priority actions & Villa 102 — Ceiba Suite',
    category: 'Overview',
    icon: Icons.villa_outlined,
    isSubScreen: false,
  ),
  transport(
    wireId: 'transport',
    title: '1. Flight & Airport Transfer',
    shortTitle: 'Private Transport',
    subtitle: 'Flight AA 1492 / AA 172, Chauffeur HOST ADMIN & terminal bay',
    category: 'Arrival & Logistics',
    icon: Icons.directions_car_outlined,
    isSubScreen: true,
  ),
  personalize(
    wireId: 'personalize',
    title: '2. Room Comfort, Diet & Allergies',
    shortTitle: 'Personalize Stay',
    subtitle: 'Room Comfort & Temperature, Dietary & Allergies',
    category: 'Arrival & Logistics',
    icon: Icons.tune_outlined,
    isSubScreen: true,
  ),
  stockVilla(
    wireId: 'stock-villa',
    title: '3. Minibar & Welcome Drinks',
    shortTitle: 'Stock My Villa',
    subtitle: 'Artisanal pantry, cold-pressed elixirs & cellar selection',
    category: 'Experiences',
    icon: Icons.kitchen_outlined,
    isSubScreen: false,
  ),
  explore(
    wireId: 'explore',
    title: '4. Curated Excursions & Tours',
    shortTitle: 'Curated Excursions',
    subtitle: 'Cenote Dos Ojos Dive, Sian Ka\'an, PGA Golf & Mayan Ruins',
    category: 'Sanctuary Privileges',
    icon: Icons.explore_outlined,
    isSubScreen: false,
  ),
  yacht(
    wireId: 'yacht',
    title: '5. Private Yacht Charter',
    shortTitle: 'Private Yacht',
    subtitle: 'Kachava Caribe · Galeon 470 Sky / 500 FLY & Marine Team',
    category: 'Experiences',
    icon: Icons.sailing_outlined,
    isSubScreen: true,
  ),
  dining(
    wireId: 'dining',
    title: '6. In-Villa Private Chef Dining',
    shortTitle: 'Private Dining',
    subtitle: 'Culinary Team Fuego y Mar, Tierra Sagrada & Flora Silvestre',
    category: 'Experiences',
    icon: Icons.restaurant_outlined,
    isSubScreen: true,
  ),
  concierge(
    wireId: 'concierge',
    title: '7. 24/7 Chat & Concierge Requests',
    shortTitle: '24/7 Concierge',
    subtitle: 'HOST ADMIN, 4-stage lifecycle tracker & live chat',
    category: 'Majordomo Care',
    icon: Icons.support_agent_outlined,
    isSubScreen: false,
  ),
  midstay(
    wireId: 'midstay',
    title: '8. Mid-Stay Check-In',
    shortTitle: 'Mid-Stay Care',
    subtitle: 'Satisfaction pulse rating, housekeeping & < 7 Min callback',
    category: 'Majordomo Care',
    icon: Icons.spa_outlined,
    isSubScreen: true,
  ),
  departure(
    wireId: 'departure',
    title: '9. Stay & Departure Summary',
    shortTitle: 'Stay Summary',
    subtitle: 'Stay dates, requested experiences & minibar summary',
    category: 'Departure',
    icon: Icons.event_note_outlined,
    isSubScreen: true,
  ),
  profile(
    wireId: 'profile',
    title: '10. Guest Profile, Wi-Fi & Allergies',
    shortTitle: 'Guest Profile',
    subtitle: 'Digital NFC Villa 102 Keycard, Wi-Fi & Dietary alert badges',
    category: 'Identity & Security',
    icon: Icons.badge_outlined,
    isSubScreen: true,
  ),
  philosophy(
    wireId: 'philosophy',
    title: '11. Resort Architecture & Nature',
    shortTitle: 'Architecture',
    subtitle: '432Hz Soundscape player, Chukum plaster & 1% Biosphere',
    category: 'Sanctuary Lore',
    icon: Icons.auto_stories_outlined,
    isSubScreen: true,
  ),
  included(
    wireId: 'included',
    title: 'Included Privileges',
    shortTitle: 'Included Privileges',
    subtitle: 'Complimentary amenities, Sunrise Cenote Yoga, Spa & Golf',
    category: 'Sanctuary Privileges',
    icon: Icons.stars_outlined,
    isSubScreen: false,
  );

  const ScreenId({
    required this.wireId,
    required this.title,
    required this.shortTitle,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.isSubScreen,
  });

  final String wireId;
  final String title;
  final String shortTitle;
  final String subtitle;
  final String category;
  final IconData icon;
  final bool isSubScreen;

  static ScreenId fromWireId(String id) {
    for (final screen in ScreenId.values) {
      if (screen.wireId == id || screen.name == id) {
        return screen;
      }
    }
    return ScreenId.home;
  }
}
