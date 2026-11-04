import 'admin_task.dart';
import 'catalog_values.dart';
import 'json_read.dart';
import 'list_query.dart';
import 'paged_result.dart';
import 'service_catalog_enums.dart';

/// Staff actions of a section request; each is its own button in the detail.
enum RequestAction {
  confirm('CONFIRM'),
  start('START'),
  complete('COMPLETE'),
  cancel('CANCEL');

  const RequestAction(this.wire);
  final String wire;
}

/// Wire statuses of a request; the vocabulary the guest sees.
abstract final class RequestStatusValues {
  static const String received = 'RECEIVED';
  static const String confirmed = 'CONFIRMED';
  static const String preparing = 'PREPARING';
  static const String done = 'DONE';
  static const String cancelled = 'CANCELLED';

  /// Status filter value for every request still to be handled.
  static const String open = 'OPEN';

  static const List<String> all = [
    received,
    confirmed,
    preparing,
    done,
    cancelled
  ];
}

/// One item of an order (or the booked option) with its quantity.
class ServiceRequestLine {
  const ServiceRequestLine({required this.name, required this.quantity});

  final LocalizedText name;
  final int quantity;
}

/// A guest booking or order in a section queue (`GET /admin/requests`).
class ServiceRequest {
  const ServiceRequest({
    required this.id,
    required this.isOrder,
    required this.guestName,
    required this.villaName,
    required this.serviceName,
    required this.at,
    required this.quantity,
    required this.status,
    this.lines = const [],
    this.totalUSD,
    this.cancellationReason,
    String? usageType,
    this.section,
    this.notes = '',
    this.createdAt,
    this.stayId = '',
  }) : usageType = usageType ?? (isOrder ? 'ORDER' : 'BOOKING');

  factory ServiceRequest.fromJson(Map<String, dynamic> json) => ServiceRequest(
        id: JsonRead.requireId(json),
        isOrder: JsonRead.text(json, 'kind') == 'ORDER',
        guestName: JsonRead.text(json, 'guestName'),
        villaName: JsonRead.text(json, 'villaName'),
        serviceName: LocalizedText.fromJson(json['serviceName']),
        at: JsonRead.text(json, 'at'),
        quantity: JsonRead.intOrNull(json, 'quantity') ?? 0,
        status: JsonRead.text(json, 'status'),
        lines: [
          for (final l in JsonRead.objects(json, 'lines'))
            ServiceRequestLine(
                name: LocalizedText.fromJson(l['name']),
                quantity: JsonRead.intOrNull(l, 'quantity') ?? 0),
        ],
        totalUSD: JsonRead.doubleOrNull(json, 'totalUSD'),
        cancellationReason: JsonRead.textOrNull(json, 'cancellationReason'),
        usageType: JsonRead.textOrNull(json, 'usageType'),
        section: JsonRead.textOrNull(json, 'section'),
        notes: JsonRead.text(json, 'notes'),
        createdAt: DateTime.tryParse(JsonRead.text(json, 'createdAt'))?.toUtc(),
        stayId: JsonRead.text(json, 'stayId'),
      );

  /// The same request in another [status] (a server-confirmed move).
  ServiceRequest withStatus(String status, {String? cancellationReason}) =>
      ServiceRequest(
        id: id,
        isOrder: isOrder,
        guestName: guestName,
        villaName: villaName,
        serviceName: serviceName,
        at: at,
        quantity: quantity,
        status: status,
        lines: lines,
        totalUSD: totalUSD,
        cancellationReason: cancellationReason ?? this.cancellationReason,
        usageType: usageType,
        section: section,
        notes: notes,
        createdAt: createdAt,
        stayId: stayId,
      );

  final String id;

  /// An order (quantity = units) rather than a booking (quantity = guests).
  final bool isOrder;
  final String guestName;
  final String villaName;
  final LocalizedText serviceName;

  /// Resort wall time `YYYY-MM-DDTHH:mm`.
  final String at;
  final int quantity;
  final String status;
  final List<ServiceRequestLine> lines;
  final double? totalUSD;
  final String? cancellationReason;

  /// `ORDER`, `BOOKING` or `PREFERENCE` (older rows: from [isOrder]).
  final String usageType;

  /// Catalog section wire value (`IN_VILLA`, ...); null on older rows.
  final String? section;

  /// The guest's own words (booking notes); empty when none.
  final String notes;

  /// When the guest asked (UTC); null on older rows.
  final DateTime? createdAt;

  /// The guest's stay (conversation, reservation).
  final String stayId;

  /// `YYYY-MM-DD` part of [at].
  String get day => at.length >= 10 ? at.substring(0, 10) : at;

  /// `HH:mm` part of [at] (empty when absent).
  String get time => at.length >= 16 ? at.substring(11, 16) : '';

  /// The actions the backend accepts from the current status.
  List<RequestAction> get actions => switch (status) {
        RequestStatusValues.received => const [
            RequestAction.confirm,
            RequestAction.start,
            RequestAction.cancel
          ],
        RequestStatusValues.confirmed => const [
            RequestAction.start,
            RequestAction.complete,
            RequestAction.cancel
          ],
        RequestStatusValues.preparing => const [
            RequestAction.complete,
            RequestAction.cancel
          ],
        _ => const [],
      };
}

/// Section request queues and the Requests inbox (`/admin/requests`).
/// Filters: `status` (one status or `OPEN`), `usageType`, `section` (inbox),
/// the `range` day filter (`from`/`to`); search guest/service; sort `at` or
/// `queue` (new first, then in progress, then closed; oldest asked first).
abstract interface class ServiceRequestRepository {
  /// [section] null lists every section (the inbox).
  Future<PagedResult<ServiceRequest>> list(
      ServiceSection? section, ListQuery query);

  /// Server-confirmed request after the move (422 when not allowed).
  Future<ServiceRequest> transition(String id, RequestAction action,
      {String? reason});

  /// The request's operational task, created (prefilled) when missing.
  Future<AdminTask> ensureTask(String id);
}
