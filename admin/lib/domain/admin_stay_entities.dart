import '../core/app_config.dart';
import 'admin_enums.dart';

/// Registered sanctuary villa record for Stays & Magic Link creation.
class AdminVillaInfo {
  const AdminVillaInfo({
    required this.villaId,
    required this.villaName,
    required this.suiteType,
    required this.maxGuests,
    this.wifiSsid = 'Kachava_Sanctuary_102',
    this.wifiPasscode = 'stillness2026',
  });

  final String villaId;
  final String villaName;
  final String suiteType;
  final String maxGuests;
  final String wifiSsid;
  final String wifiPasscode;

  String get displayLabel =>
      suiteType.isEmpty ? villaName : '$villaName — $suiteType';
}

/// Staff member record from `staff_members/{staffId}`.
class StaffMember {
  const StaffMember({
    required this.staffId,
    required this.fullName,
    required this.shortName,
    required this.role,
    required this.department,
    required this.rbacRole,
    required this.email,
    required this.phone,
    this.isActive = true,
  });

  final String staffId;
  final String fullName;
  final String shortName;
  final String role;
  final StaffDepartment department;
  final StaffRole rbacRole;
  final String email;
  final String phone;
  final bool isActive;
}

/// Guest 3-step personalization preferences (Step 1: Comfort, Step 2: Rhythm, Step 3: Dietary).
class GuestPersonalizationProfile {
  const GuestPersonalizationProfile({
    required this.pillowType,
    required this.dayTemp,
    required this.nightTemp,
    required this.scentProfile,
    required this.lightingScene,
    required this.occasion,
    required this.morningCoffee,
    required this.housekeepingCadence,
    required this.dietaryBadges,
    required this.allergies,
    required this.interests,
  });

  final String pillowType;
  final String dayTemp;
  final String nightTemp;
  final String scentProfile;
  final String lightingScene;
  final String occasion;
  final String morningCoffee;
  final String housekeepingCadence;
  final List<String> dietaryBadges;
  final List<String> allergies;
  final List<String> interests;

  bool get hasCriticalAllergy => allergies.isNotEmpty;
}

/// Private aviation and chauffeur transfer coordination record.
class AviationTransferInfo {
  const AviationTransferInfo({
    required this.inboundFlight,
    required this.inboundRoute,
    required this.inboundEta,
    required this.outboundFlight,
    required this.outboundRoute,
    required this.outboundEtd,
    required this.cabinTemp,
    required this.cabinBeverage,
    required this.cabinAudio,
    required this.assignedChauffeurId,
    required this.assignedChauffeurName,
    required this.vehicleLabel,
    required this.transferStatus,
    this.arrivalDate = '',
    this.airline = '',
    this.terminal = '',
  });

  final String inboundFlight;
  final String inboundRoute;
  final String inboundEta;
  final String outboundFlight;
  final String outboundRoute;
  final String outboundEtd;
  final String cabinTemp;
  final String cabinBeverage;
  final String cabinAudio;
  final String assignedChauffeurId;
  final String assignedChauffeurName;
  final String vehicleLabel;
  final String transferStatus;
  final String arrivalDate;
  final String airline;
  final String terminal;

  AviationTransferInfo copyWith({
    String? assignedChauffeurId,
    String? assignedChauffeurName,
    String? vehicleLabel,
    String? transferStatus,
    String? cabinBeverage,
    String? outboundRoute,
    String? arrivalDate,
    String? airline,
    String? terminal,
  }) {
    return AviationTransferInfo(
      inboundFlight: inboundFlight,
      inboundRoute: inboundRoute,
      inboundEta: inboundEta,
      outboundFlight: outboundFlight,
      outboundRoute: outboundRoute ?? this.outboundRoute,
      outboundEtd: outboundEtd,
      cabinTemp: cabinTemp,
      cabinBeverage: cabinBeverage ?? this.cabinBeverage,
      cabinAudio: cabinAudio,
      assignedChauffeurId: assignedChauffeurId ?? this.assignedChauffeurId,
      assignedChauffeurName:
          assignedChauffeurName ?? this.assignedChauffeurName,
      vehicleLabel: vehicleLabel ?? this.vehicleLabel,
      transferStatus: transferStatus ?? this.transferStatus,
      arrivalDate: arrivalDate ?? this.arrivalDate,
      airline: airline ?? this.airline,
      terminal: terminal ?? this.terminal,
    );
  }
}

/// Master guest stay record (`stays/{stayId}`) with Magic Link and folio state.
class AdminStayRecord {
  const AdminStayRecord({
    required this.stayId,
    required this.guestTokenUuid,
    required this.villaId,
    required this.villaName,
    required this.guestNames,
    required this.checkInDate,
    required this.checkOutDate,
    required this.lifecycleStatus,
    required this.assignedMajordomoName,
    required this.personalization,
    required this.transfer,
    required this.cardReference,
    this.nights = 3,
    this.wifiSsid = 'Kachava_Sanctuary_102',
    this.wifiPasscode = 'stillness2026',
    this.lateCheckoutApproved = false,
    this.paymentStatus = 'PRE_AUTHORIZED',
  });

  final String stayId;
  final String guestTokenUuid;
  final String villaId;
  final String villaName;
  final String guestNames;
  final String checkInDate;
  final String checkOutDate;
  final int nights;
  final StayLifecycleStatus lifecycleStatus;
  final String assignedMajordomoName;
  final GuestPersonalizationProfile personalization;
  final AviationTransferInfo transfer;
  final String cardReference;
  final String wifiSsid;
  final String wifiPasscode;
  final bool lateCheckoutApproved;
  final String paymentStatus;

  /// Full passwordless Welcome Email Magic Link URL.
  String get magicLinkUrl =>
      '${AdminAppConfig.sanctuaryPortalUrl}/?guestId=$guestTokenUuid';

  AdminStayRecord copyWith({
    String? guestTokenUuid,
    int? nights,
    StayLifecycleStatus? lifecycleStatus,
    AviationTransferInfo? transfer,
    String? wifiSsid,
    String? wifiPasscode,
    bool? lateCheckoutApproved,
    String? paymentStatus,
  }) {
    return AdminStayRecord(
      stayId: stayId,
      guestTokenUuid: guestTokenUuid ?? this.guestTokenUuid,
      villaId: villaId,
      villaName: villaName,
      guestNames: guestNames,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      nights: nights ?? this.nights,
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
      assignedMajordomoName: assignedMajordomoName,
      personalization: personalization,
      transfer: transfer ?? this.transfer,
      cardReference: cardReference,
      wifiSsid: wifiSsid ?? this.wifiSsid,
      wifiPasscode: wifiPasscode ?? this.wifiPasscode,
      lateCheckoutApproved: lateCheckoutApproved ?? this.lateCheckoutApproved,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }
}
