/// Artisanal larder / pantry item for Villa 102 (`FR-08`).
class LarderItem {
  const LarderItem({
    required this.id,
    required this.name,
    required this.origin,
    required this.description,
    required this.priceUsd,
    required this.category,
    required this.quantity,
    required this.tag,
    required this.storageType,
    this.dietaryBadge,
    this.isConfirmed = false,
    this.provisioningStatus = '',
  });

  final String id;
  final String name;
  final String origin;
  final String description;
  final int priceUsd;
  final String category;
  final int quantity;
  final String tag;
  final String storageType;
  final String? dietaryBadge;
  final bool isConfirmed;
  final String provisioningStatus;

  LarderItem copyWith({
    int? quantity,
    bool? isConfirmed,
    String? provisioningStatus,
  }) {
    return LarderItem(
      id: id,
      name: name,
      origin: origin,
      description: description,
      priceUsd: priceUsd,
      category: category,
      quantity: quantity ?? this.quantity,
      tag: tag,
      storageType: storageType,
      dietaryBadge: dietaryBadge,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      provisioningStatus: provisioningStatus ?? this.provisioningStatus,
    );
  }
}

/// Curated Riviera Maya excursion or complimentary privilege (`FR-04`, `FR-05`).
class ExperienceItem {
  const ExperienceItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.location,
    required this.priceText,
    required this.priceUsd,
    required this.isIncluded,
    required this.category,
    required this.description,
    required this.amenities,
    required this.isScheduled,
    this.scheduledSlot,
    this.scheduledDate = '',
    this.scheduledTimeSlot = '',
    this.bookingStatus = '',
    this.cancellationReason = '',
    this.targetScreenWireId,
  });

  final String id;
  final String title;
  final String subtitle;
  final String duration;
  final String location;
  final String priceText;
  final int priceUsd;
  final bool isIncluded;
  final String category;
  final String description;
  final List<String> amenities;
  final bool isScheduled;
  final String? scheduledSlot;
  final String scheduledDate;
  final String scheduledTimeSlot;
  final String bookingStatus;
  final String cancellationReason;
  final String? targetScreenWireId;

  bool get isReserved => bookingStatus.isNotEmpty || isScheduled;

  ExperienceItem copyWith({
    bool? isScheduled,
    bool? isReserved,
    String? scheduledSlot,
    String? scheduledDate,
    String? scheduledTimeSlot,
    String? bookingStatus,
    String? cancellationReason,
  }) {
    final nextDate = scheduledDate ?? this.scheduledDate;
    final nextTime = scheduledTimeSlot ?? this.scheduledTimeSlot;
    final nextStatus = bookingStatus ?? this.bookingStatus;
    final nextScheduled =
        isReserved ?? isScheduled ?? nextStatus.isNotEmpty || this.isScheduled;
    final computedSlot = scheduledSlot ??
        ((nextDate.isNotEmpty || nextTime.isNotEmpty)
            ? '$nextDate · $nextTime'.trim()
            : this.scheduledSlot);
    return ExperienceItem(
      id: id,
      title: title,
      subtitle: subtitle,
      duration: duration,
      location: location,
      priceText: priceText,
      priceUsd: priceUsd,
      isIncluded: isIncluded,
      category: category,
      description: description,
      amenities: amenities,
      isScheduled: nextScheduled,
      scheduledSlot: computedSlot,
      scheduledDate: nextDate,
      scheduledTimeSlot: nextTime,
      bookingStatus: nextStatus,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      targetScreenWireId: targetScreenWireId,
    );
  }
}

typedef CuratedExperience = ExperienceItem;

/// Kachava Caribe Galeon 470 Sky / 500 FLY yacht charter package (`FR-06`).
class YachtPackageOption {
  const YachtPackageOption({
    required this.id,
    required this.title,
    required this.tagline,
    required this.durationHours,
    required this.valuationUsd,
    required this.netUpgradeUsd,
    required this.isIncludedWithStay,
    required this.priceLabel,
    required this.description,
    required this.highlights,
    required this.suggestedRoute,
  });

  final String id;
  final String title;
  final String tagline;
  final int durationHours;
  final int valuationUsd;
  final int netUpgradeUsd;
  final bool isIncludedWithStay;
  final String priceLabel;
  final String description;
  final List<String> highlights;
  final String suggestedRoute;
}

/// Active yacht charter configuration (`FR-06`).
class YachtCharterConfig {
  const YachtCharterConfig({
    required this.vesselModel,
    required this.selectedPackageId,
    required this.selectedDestinationId,
    required this.selectedDate,
    required this.departureWindow,
    required this.guestCount,
    required this.selectedAddOns,
    required this.isConfirmed,
    this.bookingStatus = '',
    this.cancellationReason = '',
  });

  final String vesselModel;
  final String selectedPackageId;
  final String selectedDestinationId;
  final String selectedDate;
  final String departureWindow;
  final int guestCount;
  final List<String> selectedAddOns;
  final bool isConfirmed;
  final String bookingStatus;
  final String cancellationReason;

  String get selectedSlot => departureWindow;

  YachtCharterConfig copyWith({
    String? vesselModel,
    String? selectedPackageId,
    String? selectedDestinationId,
    String? selectedDate,
    String? departureWindow,
    String? selectedSlot,
    int? guestCount,
    List<String>? selectedAddOns,
    bool? isConfirmed,
    String? bookingStatus,
    String? cancellationReason,
  }) {
    return YachtCharterConfig(
      vesselModel: vesselModel ?? this.vesselModel,
      selectedPackageId: selectedPackageId ?? this.selectedPackageId,
      selectedDestinationId:
          selectedDestinationId ?? this.selectedDestinationId,
      selectedDate: selectedDate ?? this.selectedDate,
      departureWindow: selectedSlot ?? departureWindow ?? this.departureWindow,
      guestCount: guestCount ?? this.guestCount,
      selectedAddOns: selectedAddOns ?? this.selectedAddOns,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}

typedef YachtCharterState = YachtCharterConfig;

/// Five-course private chef menu option (`FR-07`).
class DiningMenuOption {
  const DiningMenuOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.courses,
    required this.sommelierPairing,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<String> courses;
  final String sommelierPairing;
}

/// Active in-villa private dining reservation (`FR-07`).
class DiningReservation {
  const DiningReservation({
    required this.selectedMenuId,
    required this.selectedEvening,
    required this.serviceTime,
    required this.guestCount,
    required this.tableSetting,
    required this.dietaryNotes,
    required this.isConfirmed,
    this.bookingStatus = '',
    this.cancellationReason = '',
  });

  final String selectedMenuId;
  final String selectedEvening;
  final String serviceTime;
  final int guestCount;
  final String tableSetting;
  final String dietaryNotes;
  final bool isConfirmed;
  final String bookingStatus;
  final String cancellationReason;

  String get selectedDate => selectedEvening;
  String get selectedTime => serviceTime;
  String get selectedVenue => selectedMenuId;

  DiningReservation copyWith({
    String? selectedMenuId,
    String? selectedEvening,
    String? selectedDate,
    String? serviceTime,
    String? selectedTime,
    int? guestCount,
    String? tableSetting,
    String? dietaryNotes,
    bool? isConfirmed,
    String? bookingStatus,
    String? cancellationReason,
  }) {
    return DiningReservation(
      selectedMenuId: selectedMenuId ?? this.selectedMenuId,
      selectedEvening: selectedDate ?? selectedEvening ?? this.selectedEvening,
      serviceTime: selectedTime ?? serviceTime ?? this.serviceTime,
      guestCount: guestCount ?? this.guestCount,
      tableSetting: tableSetting ?? this.tableSetting,
      dietaryNotes: dietaryNotes ?? this.dietaryNotes,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}

typedef DiningReservationState = DiningReservation;
