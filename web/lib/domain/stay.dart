import 'catalog.dart';
import 'json_read.dart';

/// Stay phase from the server lifecycle (used when dates are not published).
enum StayPhase {
  preArrival,
  inStay,
  departed;

  static StayPhase parse(String raw) => switch (raw) {
        'ACTIVE_STAY' => inStay,
        'CHECKED_OUT' || 'EXPIRED' || 'CANCELLED' => departed,
        _ => preArrival,
      };
}

/// Snapshot stored with an order/booking/trip (ADR-009).
class ServiceSnapshot {
  const ServiceSnapshot({
    this.serviceName = LocalizedText.empty,
    this.section = '',
    this.lines = const [],
    this.totalUSD,
    this.capturedAt,
  });

  factory ServiceSnapshot.fromJson(Object? json) {
    final map = asJson(json);
    return ServiceSnapshot(
      serviceName: LocalizedText.fromJson(map['serviceName']),
      section: asString(map['section']),
      lines: asJsonList(map['lines'])
          .map((l) => SnapshotLine(
                name: LocalizedText.fromJson(l['name']),
                quantity: asInt(l['quantity']) ?? 1,
                lineTotalUSD: asDouble(l['lineTotalUSD']),
              ))
          .toList(),
      totalUSD: asDouble(map['totalUSD']),
      capturedAt: asDateTime(map['capturedAt']),
    );
  }

  final LocalizedText serviceName;
  final String section;
  final List<SnapshotLine> lines;
  final double? totalUSD;
  final DateTime? capturedAt;
}

class SnapshotLine {
  const SnapshotLine(
      {required this.name, this.quantity = 1, this.lineTotalUSD});
  final LocalizedText name;
  final int quantity;
  final double? lineTotalUSD;
}

class LarderOrderLine {
  const LarderOrderLine({
    required this.orderItemId,
    required this.serviceId,
    required this.itemId,
    required this.name,
    required this.quantity,
    this.unitPriceUSD = 0,
    this.lineTotalUSD = 0,
    this.status = '',
  });

  factory LarderOrderLine.fromJson(Json json) => LarderOrderLine(
        orderItemId: asString(json['orderItemId']),
        serviceId: asString(json['serviceId']),
        itemId: asString(json['catalogItemId']),
        name: LocalizedText.fromJson(json['itemName']).isEmpty
            ? LocalizedText(
                en: asString(json['name']), es: asString(json['name']))
            : LocalizedText.fromJson(json['itemName']),
        quantity: asInt(json['quantity']) ?? 0,
        unitPriceUSD: asDouble(json['unitPriceUSD']) ?? 0,
        lineTotalUSD: asDouble(json['lineTotalUSD']) ?? 0,
        status: asString(json['provisioningStatus']),
      );

  final String orderItemId;
  final String serviceId;
  final String itemId;
  final LocalizedText name;
  final int quantity;
  final double unitPriceUSD;
  final double lineTotalUSD;
  final String status;
}

class GuestBooking {
  const GuestBooking({
    required this.id,
    required this.serviceId,
    this.itemId,
    this.section = '',
    this.usageType = UsageType.booking,
    this.snapshot = const ServiceSnapshot(),
    this.title = '',
    this.scheduledDate = '',
    this.scheduledTimeSlot = '',
    this.partySize = 0,
    this.status = 'REQUESTED',
  });

  factory GuestBooking.fromJson(Json json) {
    final snapshot = ServiceSnapshot.fromJson(json['snapshot']);
    return GuestBooking(
      id: asString(json['bookingId']),
      serviceId: asString(json['serviceId']),
      itemId: asStringOrNull(json['itemId']),
      section: asString(json['section']).isNotEmpty
          ? asString(json['section'])
          : snapshot.section,
      usageType: UsageType.parse(asString(json['usageType'])),
      snapshot: snapshot,
      title: asString(json['title']),
      scheduledDate: asString(json['scheduledDate']),
      scheduledTimeSlot: asString(json['scheduledTimeSlot']),
      partySize: asInt(json['partySize']) ?? 0,
      status: asString(json['status']),
    );
  }

  final String id;
  final String serviceId;
  final String? itemId;
  final String section;
  final UsageType usageType;
  final ServiceSnapshot snapshot;
  final String title;
  final String scheduledDate;
  final String scheduledTimeSlot;
  final int partySize;
  final String status;
}

enum MessageSender { guest, host }

class ChatMessage {
  const ChatMessage({
    required this.sender,
    required this.text,
    required this.sentAt,
    this.senderName = '',
    this.hasPhoto = false,
  });

  final MessageSender sender;
  final String senderName;
  final String text;
  final DateTime? sentAt;

  /// The thread this message opened was sent with a photo.
  final bool hasPhoto;
}

/// A Resort Host thread (`concierge-requests`).
class HostThread {
  const HostThread({
    required this.id,
    this.type = 'request',
    this.category = '',
    this.title = '',
    this.status = 'Requested',
    this.isCompleted = false,
    this.messages = const [],
    this.createdAt,
  });

  /// Category used by the portal for chat threads (type `ask`).
  static const String chatCategory = 'Resort Host chat';

  /// Category used for chat threads opened with a photo.
  static const String photoCategory = 'Resort Host photo';

  factory HostThread.fromJson(Json json) {
    final category = asString(json['category']);
    final withPhoto = category == photoCategory;
    final messages = asJsonList(json['messages']);
    return HostThread(
      id: asString(json['requestId']),
      type: asString(json['type']),
      category: category,
      title: asString(json['title']),
      status: asString(json['status']),
      isCompleted: asBool(json['isCompleted']),
      createdAt: asDateTime(json['createdAt']),
      messages: [
        for (var i = 0; i < messages.length; i++)
          ChatMessage(
            sender: asString(messages[i]['sender']) == 'GUEST'
                ? MessageSender.guest
                : MessageSender.host,
            senderName: asString(messages[i]['senderName']),
            text: asString(messages[i]['text']),
            sentAt: asDateTime(messages[i]['sentAt']),
            hasPhoto: withPhoto && i == 0,
          ),
      ],
    );
  }

  final String id;
  final String type;
  final String category;
  final String title;
  final String status;
  final bool isCompleted;
  final List<ChatMessage> messages;
  final DateTime? createdAt;

  /// Chat threads live in the Host tab, not in My requests.
  bool get isChat => type == 'ask';
}

class GuestStay {
  const GuestStay({
    required this.guestUuid,
    this.phase = StayPhase.preArrival,
    this.villaName = '',
    this.datesLabel = '',
    this.nights = 0,
    this.guestsCount = 0,
    this.guestName = '',
    this.hostName = '',
    this.hostAvatarUrl = '',
    this.wifiSsid = '',
    this.wifiPassword = '',
    this.checkIn,
    this.checkOut,
    this.dietary = '',
    this.allergies = const [],
    this.larderOrders = const [],
    this.bookings = const [],
    this.threads = const [],
    this.ratingsSent = 0,
  });

  factory GuestStay.fromJson(String guestUuid, Json json) {
    final profile = asJson(json['guestProfile']);
    final host = asJson(json['hostInfo']);
    final access = asJson(json['villaAccess']);
    final personalization = asJson(json['personalization']);
    return GuestStay(
      guestUuid: guestUuid,
      phase: StayPhase.parse(asString(json['status'])),
      villaName: asString(json['villaName']),
      datesLabel: asString(json['stayDatesLabel']),
      nights: asInt(json['nights']) ?? 0,
      guestsCount: asInt(json['guestsCount']) ?? 0,
      guestName: asString(profile['name']),
      hostName: asString(host['shortName']).isNotEmpty
          ? asString(host['shortName'])
          : asString(host['name']),
      hostAvatarUrl: asString(host['avatarUrl']),
      wifiSsid: asString(access['wifiSsid']),
      wifiPassword: asString(access['wifiPasscode']),
      checkIn: _date(json['checkInDate']),
      checkOut: _date(json['checkOutDate']),
      dietary: asString(personalization['dietary']),
      allergies: asStringList(personalization['dietaryAllergies']),
      larderOrders: asJsonList(json['larderOrders'])
          .map(LarderOrderLine.fromJson)
          .toList(),
      bookings: asJsonList(json['experienceBookings'])
          .map(GuestBooking.fromJson)
          .toList(),
      threads: asJsonList(json['conciergeRequests'])
          .map(HostThread.fromJson)
          .toList(),
      ratingsSent: asJsonList(json['midstayFeedback']).length,
    );
  }

  /// `YYYY-MM-DD` resort calendar day; null when not published.
  static DateTime? _date(Object? raw) {
    final s = asString(raw);
    if (s.length < 10) return null;
    final d = DateTime.tryParse(s.substring(0, 10));
    return d == null ? null : DateTime.utc(d.year, d.month, d.day);
  }

  final String guestUuid;
  final StayPhase phase;
  final String villaName;
  final String datesLabel;
  final int nights;
  final int guestsCount;
  final String guestName;
  final String hostName;
  final String hostAvatarUrl;
  final String wifiSsid;
  final String wifiPassword;

  /// Resort calendar days (UTC midnight). The guest view does not publish
  /// them yet; when null the phase comes from [phase].
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String dietary;
  final List<String> allergies;
  final List<LarderOrderLine> larderOrders;
  final List<GuestBooking> bookings;
  final List<HostThread> threads;
  final int ratingsSent;

  /// Resort Host chat threads (type `ask`).
  List<HostThread> get chatThreads => threads.where((t) => t.isChat).toList();

  /// Newest open chat thread; new messages are appended to it.
  HostThread? get openChatThread {
    final open = chatThreads.where((t) => !t.isCompleted).toList()
      ..sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return open.isEmpty ? null : open.first;
  }

  /// Every chat message, oldest first.
  List<ChatMessage> get chatMessages =>
      [for (final t in chatThreads) ...t.messages]..sort((a, b) =>
          (a.sentAt ?? DateTime(0)).compareTo(b.sentAt ?? DateTime(0)));
}
