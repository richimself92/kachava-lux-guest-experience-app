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
  });

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

/// Section request queues (`/admin/requests`). Filters: `status` (one status
/// or `OPEN`), the `range` day filter (`from`/`to`); search guest/service;
/// sort `at`.
abstract interface class ServiceRequestRepository {
  Future<PagedResult<ServiceRequest>> list(
      ServiceSection section, ListQuery query);

  /// Server-confirmed request after the move (422 when not allowed).
  Future<ServiceRequest> transition(String id, RequestAction action,
      {String? reason});
}
