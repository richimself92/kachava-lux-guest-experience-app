import '../../domain/entities/experience_entities.dart';

/// Maps `experienceBookings` and the experience catalog onto booking state.
abstract final class BookingWireMapper {
  /// Experiences come only from the server catalog, with the guest's
  /// bookings applied on top.
  static List<ExperienceItem> mergeExperiences(
    List<Map<String, dynamic>> catalogExperiences,
    List<Map<String, dynamic>> bookings,
  ) {
    return catalogExperiences.map((c) {
      final exp = _mapCatalogExperience(c);
      final booking = bookings
          .where((b) => b['catalogRefId'] == exp.id || b['title'] == exp.title)
          .firstOrNull;
      return booking == null ? exp : _applyBooking(exp, booking);
    }).toList();
  }

  static ExperienceItem _applyBooking(
      ExperienceItem exp, Map<String, dynamic> b) {
    final sDate = (b['scheduledDate'] ?? '').toString();
    final sTime = (b['scheduledTimeSlot'] ?? '').toString();
    return exp.copyWith(
      isScheduled: true,
      isReserved: true,
      scheduledSlot: '$sDate · $sTime'.trim(),
      scheduledDate: sDate,
      scheduledTimeSlot: sTime,
      bookingStatus: (b['status'] ?? 'REQUESTED').toString().toUpperCase(),
      cancellationReason: (b['cancellationReason'] ?? '').toString(),
    );
  }

  static YachtCharterConfig mergeYachtCharter(
    YachtCharterConfig current,
    List<Map<String, dynamic>> bookings,
    String defaultDate,
  ) {
    final b = _lastBooking(bookings, type: 'YACHT_CHARTER', category: 'yacht');
    if (b == null) {
      return current.bookingStatus.isNotEmpty
          ? current
          : current.copyWith(
              selectedDate: _orElse(current.selectedDate, defaultDate),
              isConfirmed: false,
              bookingStatus: '',
              cancellationReason: '');
    }
    return current.copyWith(
      selectedDate: _orElse(b.date, defaultDate),
      selectedSlot: _orElse(b.time, current.selectedSlot),
      guestCount: b.partySize,
      isConfirmed: b.status == 'CONFIRMED',
      bookingStatus: b.status,
      cancellationReason: b.cancellationReason,
    );
  }

  static DiningReservation mergeDiningReservation(
    DiningReservation current,
    List<Map<String, dynamic>> bookings,
    String defaultDate,
  ) {
    final b =
        _lastBooking(bookings, type: 'PRIVATE_DINING', category: 'dining');
    if (b == null) {
      return current.bookingStatus.isNotEmpty
          ? current
          : current.copyWith(
              selectedDate: _orElse(current.selectedDate, defaultDate),
              isConfirmed: false,
              bookingStatus: '',
              cancellationReason: '');
    }
    return current.copyWith(
      selectedDate: _orElse(b.date, defaultDate),
      selectedTime: _orElse(b.time, current.selectedTime),
      guestCount: b.partySize,
      isConfirmed: b.status == 'CONFIRMED',
      bookingStatus: b.status,
      cancellationReason: b.cancellationReason,
    );
  }

  static String _orElse(String value, String fallback) =>
      value.isNotEmpty ? value : fallback;

  /// The guest's latest booking of [type] (or whose category mentions
  /// [category]), or `null` when there is none.
  static ({
    String status,
    String date,
    String time,
    int? partySize,
    String cancellationReason,
  })? _lastBooking(List<Map<String, dynamic>> bookings,
      {required String type, required String category}) {
    final match = bookings.where((b) {
      final bType = (b['bookingType'] ?? '').toString().toUpperCase();
      final bCategory = (b['category'] ?? '').toString().toLowerCase();
      return bType == type || bCategory.contains(category);
    }).lastOrNull;
    if (match == null) return null;
    return (
      status: (match['status'] ?? 'REQUESTED').toString().toUpperCase(),
      date: (match['scheduledDate'] ?? '').toString(),
      time: (match['scheduledTimeSlot'] ?? '').toString(),
      partySize: (match['partySize'] as num?)?.toInt(),
      cancellationReason: (match['cancellationReason'] ?? '').toString(),
    );
  }

  static ExperienceItem _mapCatalogExperience(Map<String, dynamic> c) {
    final price = ((c['basePriceUSD'] ??
            c['priceUSD'] ??
            c['priceUsd'] ??
            c['price'] ??
            0) as num)
        .round();
    final included = c['isIncluded'] == true || price == 0;
    return ExperienceItem(
      id: (c['id'] ?? c['catalogId'] ?? '').toString(),
      title: (c['title'] ?? c['name'] ?? '').toString(),
      subtitle: (c['subtitle'] ?? c['category'] ?? '').toString(),
      duration: (c['duration'] ?? '').toString(),
      location: (c['location'] ?? '').toString(),
      priceText:
          (c['priceText'] ?? (included ? 'Included with Stay' : '\$$price USD'))
              .toString(),
      priceUsd: price,
      isIncluded: included,
      category: (c['category'] ?? '').toString(),
      description: (c['description'] ?? '').toString(),
      amenities: (c['amenities'] is List)
          ? (c['amenities'] as List).map((e) => e.toString()).toList()
          : const [],
      isScheduled: false,
      targetScreenWireId:
          (c['actionScreen'] ?? c['targetScreenWireId']) as String?,
    );
  }
}
