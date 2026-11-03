import 'admin_catalog_repositories.dart';
import 'json_read.dart';
import 'list_query.dart';
import 'paged_result.dart';
import 'reservation_folio.dart';

export 'reservation_folio.dart';

/// Stay lifecycle wire values and the staff moves (ADR-011 §4).
abstract final class StayValues {
  static const String preArrival = 'PRE_ARRIVAL';
  static const String inHouse = 'ACTIVE_STAY';
  static const String checkedOut = 'CHECKED_OUT';
  static const String expired = 'EXPIRED';
  static const String cancelled = 'CANCELLED';
  static const List<String> statuses = [
    preArrival,
    inHouse,
    checkedOut,
    cancelled,
    expired,
  ];

  static const String checkIn = 'CHECK_IN';
  static const String checkOut = 'CHECK_OUT';
  static const String cancel = 'CANCEL';

  static bool isOpen(String status) =>
      status == preArrival || status == inHouse;

  /// Moves allowed from [status]: Check-in/Cancel before arrival, Check-out
  /// in house, none once closed.
  static List<String> actionsFor(String status) => switch (status) {
        preArrival => const [checkIn, cancel],
        inHouse => const [checkOut],
        _ => const [],
      };
}

/// One `GET /admin/stays` row (a projection, not the whole record).
class ReservationRow {
  const ReservationRow({
    required this.id,
    required this.guestName,
    required this.villaId,
    required this.villaName,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    required this.resortHostName,
    required this.magicLinkUrl,
  });

  factory ReservationRow.fromJson(Map<String, dynamic> json) => ReservationRow(
        id: JsonRead.requireId(json),
        guestName: JsonRead.text(json, 'guestName'),
        villaId: JsonRead.text(json, 'villaId'),
        villaName: JsonRead.text(json, 'villaName'),
        checkIn: JsonRead.textOrNull(json, 'checkIn'),
        checkOut: JsonRead.textOrNull(json, 'checkOut'),
        status: JsonRead.text(json, 'status'),
        resortHostName: JsonRead.textOrNull(json, 'resortHostName'),
        magicLinkUrl: JsonRead.text(json, 'magicLinkUrl'),
      );

  final String id;
  final String guestName;
  final String villaId;
  final String villaName;

  /// Calendar days `YYYY-MM-DD`.
  final String? checkIn;
  final String? checkOut;
  final String status;

  /// `null` until staff assign a Resort Host.
  final String? resortHostName;
  final String magicLinkUrl;

  bool get isOpen => StayValues.isOpen(status);
}

/// One status move of a stay.
class StayStatusChange {
  const StayStatusChange({
    required this.from,
    required this.to,
    required this.at,
    required this.by,
    this.reason,
  });

  factory StayStatusChange.fromJson(Map<String, dynamic> json) =>
      StayStatusChange(
        from: JsonRead.text(json, 'from'),
        to: JsonRead.text(json, 'to'),
        at: DateTime.tryParse(JsonRead.text(json, 'at'))?.toUtc(),
        by: JsonRead.text(json, 'by'),
        reason: JsonRead.textOrNull(json, 'reason'),
      );

  final String from;
  final String to;
  final DateTime? at;
  final String by;
  final String? reason;
}

/// `GET/PATCH /admin/stays/:id`: the row plus staff-only details.
class StayDetail {
  const StayDetail({
    required this.row,
    required this.nights,
    required this.guestsCount,
    required this.email,
    required this.phone,
    required this.language,
    required this.occasion,
    required this.resortHostStaffId,
    required this.wifiSsid,
    required this.wifiPassword,
    required this.internalNotes,
    required this.cancellationReason,
    required this.statusHistory,
  });

  factory StayDetail.fromJson(Map<String, dynamic> json) {
    final wifi = JsonRead.object(json, 'wifi');
    final host = JsonRead.object(json, 'resortHost');
    return StayDetail(
      row: ReservationRow.fromJson(json),
      nights: JsonRead.intOrNull(json, 'nights') ?? 0,
      guestsCount: JsonRead.intOrNull(json, 'guestsCount') ?? 0,
      email: JsonRead.text(json, 'email'),
      phone: JsonRead.text(json, 'phone'),
      language: JsonRead.textOrNull(json, 'language'),
      occasion: JsonRead.text(json, 'occasion'),
      resortHostStaffId: JsonRead.textOrNull(host, 'staffId'),
      wifiSsid: JsonRead.text(wifi, 'ssid'),
      wifiPassword: JsonRead.text(wifi, 'password'),
      internalNotes: JsonRead.text(json, 'internalNotes'),
      cancellationReason: JsonRead.textOrNull(json, 'cancellationReason'),
      statusHistory: [
        for (final c in JsonRead.objects(json, 'statusHistory'))
          StayStatusChange.fromJson(c),
      ],
    );
  }

  final ReservationRow row;
  final int nights;
  final int guestsCount;
  final String email;
  final String phone;
  final String? language;
  final String occasion;
  final String? resortHostStaffId;
  final String wifiSsid;
  final String wifiPassword;
  final String internalNotes;
  final String? cancellationReason;
  final List<StayStatusChange> statusHistory;

  String get id => row.id;
}

/// `PATCH /admin/stays/:id`: only the set fields are sent; [action] moves
/// the status (`CANCEL` needs [reason]).
class ReservationPatch {
  const ReservationPatch({
    this.resortHostName,
    this.resortHostStaffId,
    this.internalNotes,
    this.language,
    this.wifiSsid,
    this.wifiPassword,
    this.action,
    this.reason,
  });

  final String? resortHostName;
  final String? resortHostStaffId;
  final String? internalNotes;
  final String? language;
  final String? wifiSsid;
  final String? wifiPassword;
  final String? action;
  final String? reason;

  Map<String, dynamic> toJson() => {
        if (resortHostName != null) 'resortHostName': resortHostName,
        if (resortHostStaffId != null) 'resortHostStaffId': resortHostStaffId,
        if (internalNotes != null) 'internalNotes': internalNotes,
        if (language != null) 'language': language,
        if (wifiSsid != null || wifiPassword != null)
          'wifi': {
            if (wifiSsid != null) 'ssid': wifiSsid,
            if (wifiPassword != null) 'password': wifiPassword,
          },
        if (action != null) 'action': action,
        if (reason != null) 'reason': reason,
      };
}

/// `POST /admin/stays`: villa, ISO dates and the guest data.
class NewReservation {
  const NewReservation({
    required this.guestName,
    required this.villaId,
    required this.checkIn,
    required this.checkOut,
    this.guestsCount,
    this.email = '',
    this.phone = '',
    this.language,
    this.occasion = '',
  });

  final String guestName;
  final String villaId;
  final String checkIn;
  final String checkOut;
  final int? guestsCount;
  final String email;
  final String phone;
  final String? language;
  final String occasion;

  Map<String, dynamic> toJson() => {
        'guestName': guestName.trim(),
        'villaId': villaId,
        'checkIn': checkIn,
        'checkOut': checkOut,
        if (guestsCount != null) 'guestsCount': guestsCount,
        if (email.trim().isNotEmpty) 'email': email.trim(),
        if (phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (language != null) 'language': language,
        if (occasion.trim().isNotEmpty) 'celebration': occasion.trim(),
      };
}

/// Reservations (`/admin/stays`). Filters `status`, `villaId` and a date
/// range on the sort date; sortable by `checkIn` / `checkOut`.
abstract interface class ReservationRepository implements StayListRepository {
  @override
  Future<PagedResult<ReservationRow>> list(ListQuery query);
  Future<StayDetail> get(String id);

  /// Returns the new stay id (server-confirmed).
  Future<String> create(NewReservation reservation);
  Future<StayDetail> update(String id, ReservationPatch patch);
  Future<StayFolio> folio(String id);
}
