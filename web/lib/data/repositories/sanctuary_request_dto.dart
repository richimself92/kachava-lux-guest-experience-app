import '../../domain/entities/concierge_folio_entities.dart';
import '../../domain/entities/experience_entities.dart';
import '../../domain/entities/stay_entities.dart';

/// Outbound request bodies for guest mutations on `/api/v1/stays/:guestUuid/*`.
abstract final class SanctuaryRequestDto {
  /// The guest's typed answer: digits mean a villa number, else a last name.
  static Map<String, dynamic> toStepUpDto(String answer) {
    final trimmed = answer.trim();
    return RegExp(r'\d').hasMatch(trimmed)
        ? {'villaNumber': trimmed}
        : {'lastName': trimmed};
  }

  static Map<String, dynamic> toTransferDto(FlightTransport t) => {
        'arrivalDate': t.arrivalDate,
        'arrivalAirport': t.arrivalAirport,
        'airline': t.airline,
        'flightNumber': t.flightNumber,
        'estimatedLanding': t.estimatedLanding,
        'terminal': t.terminalBay,
        'partySize': t.partySize,
        'luggageChecked': t.luggageChecked,
        'luggageCarryOn': t.luggageCarryOn,
      };

  static Map<String, dynamic> toPersonalizationDto(
          PersonalizationPreferences p) =>
      {
        'tripPurpose': p.tripPurpose,
        'occasionDetails': p.occasionNote,
        'selectedInterests': p.interests,
        'pillowType': p.pillowType,
        'temperatureCurve': '${p.ambientTempCelsius}°C',
        'scentProfile': p.scentProfile,
        'lightingRhythm': p.circadianLighting,
        'dietary': p.dietaryRegimen,
        'allergies': p.allergyAlerts,
        'commChannel': p.communicationChannel,
        'housekeepingCadence': p.housekeepingCadence,
      };

  static Map<String, dynamic> toLarderDto(List<LarderItem> items) => {
        'items': items
            .where((i) => i.quantity > 0)
            .map((i) => {'itemId': i.id, 'quantity': i.quantity})
            .toList(),
      };

  static Map<String, dynamic> toYachtBookingDto(YachtCharterConfig charter) => {
        'bookingType': 'YACHT_CHARTER',
        'category': 'yacht',
        'catalogRefId': charter.selectedPackageId,
        'title': charter.vesselModel,
        'scheduledDate': charter.selectedDate,
        'scheduledTimeSlot': charter.departureWindow,
        'partySize': charter.guestCount,
        'metadata': {
          'destinationId': charter.selectedDestinationId,
          'selectedAddOns': charter.selectedAddOns,
        },
      };

  static Map<String, dynamic> toDiningBookingDto(
          DiningReservation reservation) =>
      {
        'bookingType': 'PRIVATE_DINING',
        'category': 'dining',
        'catalogRefId': reservation.selectedMenuId,
        'title': reservation.selectedMenuId,
        'scheduledDate': reservation.selectedEvening,
        'scheduledTimeSlot': reservation.serviceTime,
        'partySize': reservation.guestCount,
        'metadata': {
          'tableSetting': reservation.tableSetting,
          'dietaryNotes': reservation.dietaryNotes,
        },
      };

  static Map<String, dynamic> toExperienceBookingDto(
          ExperienceItem exp, String slot, int partySize) =>
      {
        'bookingType': 'EXCURSION',
        'category': 'Excursions',
        'catalogRefId': exp.id,
        'title': exp.title,
        'scheduledDate': exp.scheduledDate.isNotEmpty
            ? exp.scheduledDate
            : slot.split('·').first.trim(),
        'scheduledTimeSlot': exp.scheduledTimeSlot.isNotEmpty
            ? exp.scheduledTimeSlot
            : (slot.contains('·') ? slot.split('·').last.trim() : ''),
        'partySize': partySize,
      };

  static Map<String, dynamic> toConciergeRequestDto(ConciergeRequest req) => {
        'type': 'request',
        'category': req.category,
        'title': req.title,
        'details': req.details,
        if (req.photoUrl != null) 'photoStoragePath': req.photoUrl,
      };

  static Map<String, dynamic> toMidStayDto(MidStayCheckIn checkIn) => {
        'rating': checkIn.rating,
        'selectedSentiment': checkIn.sentimentId,
        'selectedAspects': checkIn.focusAreas,
        'housekeepingPreferences': [checkIn.housekeepingWindow],
        'note': checkIn.notes,
      };
}
