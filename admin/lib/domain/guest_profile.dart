import 'json_read.dart';
import 'list_query.dart';
import 'paged_result.dart';

/// One `GET /admin/guests` row (one per stay).
class GuestRow {
  const GuestRow({
    required this.stayId,
    required this.guestName,
    required this.villaName,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    required this.language,
    required this.hasAllergies,
    required this.openRequests,
  });

  factory GuestRow.fromJson(Map<String, dynamic> json) => GuestRow(
        stayId: JsonRead.requireId(json, 'stayId'),
        guestName: JsonRead.text(json, 'guestName'),
        villaName: JsonRead.text(json, 'villaName'),
        checkIn: JsonRead.textOrNull(json, 'checkIn'),
        checkOut: JsonRead.textOrNull(json, 'checkOut'),
        status: JsonRead.text(json, 'status'),
        language: JsonRead.textOrNull(json, 'language'),
        hasAllergies: JsonRead.flag(json, 'hasAllergies'),
        openRequests: JsonRead.intOrNull(json, 'openRequests') ?? 0,
      );

  final String stayId;
  final String guestName;
  final String villaName;
  final String? checkIn;
  final String? checkOut;
  final String status;
  final String? language;
  final bool hasAllergies;
  final int openRequests;
}

/// A label/value preference of the guest (empty values are dropped).
class GuestPreference {
  const GuestPreference(this.key, this.value);

  /// `pillow`, `scent`, `dietary`, `temperature`, `lighting`,
  /// `housekeeping`, `communication`, `interests` or `choice`.
  final String key;
  final String value;
}

/// One past or open request of the stay.
class GuestRequestEntry {
  const GuestRequestEntry({
    required this.type,
    required this.title,
    required this.status,
    required this.open,
  });

  factory GuestRequestEntry.fromJson(Map<String, dynamic> json) =>
      GuestRequestEntry(
        type: JsonRead.text(json, 'type'),
        title: JsonRead.text(json, 'title'),
        status: JsonRead.text(json, 'status'),
        open: JsonRead.flag(json, 'open'),
      );

  final String type;
  final String title;
  final String status;
  final bool open;
}

/// Staff-only guest profile of one stay (`GET /admin/guests/:stayId`).
class GuestProfile {
  const GuestProfile({
    required this.row,
    required this.email,
    required this.phone,
    required this.preferences,
    required this.allergies,
    required this.occasion,
    required this.requestHistory,
    required this.internalNotes,
  });

  static const List<String> _preferenceKeys = [
    'pillow',
    'scent',
    'dietary',
    'temperature',
    'lighting',
    'housekeeping',
    'communication',
  ];

  factory GuestProfile.fromJson(Map<String, dynamic> json) {
    final allergies = JsonRead.object(json, 'allergies');
    final occasion = JsonRead.object(json, 'occasion');
    return GuestProfile(
      row: GuestRow.fromJson(json),
      email: JsonRead.text(json, 'email'),
      phone: JsonRead.text(json, 'phone'),
      preferences: _preferences(JsonRead.object(json, 'preferences')),
      allergies: JsonRead.strings(allergies, 'items'),
      occasion: [
        JsonRead.text(occasion, 'celebration'),
        JsonRead.text(occasion, 'details'),
      ].where((t) => t.isNotEmpty).join(' · '),
      requestHistory: [
        for (final r in JsonRead.objects(json, 'requestHistory'))
          GuestRequestEntry.fromJson(r),
      ],
      internalNotes: JsonRead.text(json, 'internalNotes'),
    );
  }

  static List<GuestPreference> _preferences(Map<String, dynamic> json) => [
        for (final key in _preferenceKeys)
          if (JsonRead.text(json, key) case final v when v.isNotEmpty)
            GuestPreference(key, v),
        if (JsonRead.strings(json, 'interests') case final i when i.isNotEmpty)
          GuestPreference('interests', i.join(', ')),
        for (final c in JsonRead.objects(json, 'choices'))
          GuestPreference('choice', JsonRead.text(c, 'title')),
      ];

  final GuestRow row;
  final String email;
  final String phone;
  final List<GuestPreference> preferences;
  final List<String> allergies;
  final String occasion;
  final List<GuestRequestEntry> requestHistory;
  final String internalNotes;
}

/// Guests (`/admin/guests`): one row per stay; `q` searches the guest name.
abstract interface class GuestRepository {
  Future<PagedResult<GuestRow>> list(ListQuery query);
  Future<GuestProfile> get(String stayId);
}
