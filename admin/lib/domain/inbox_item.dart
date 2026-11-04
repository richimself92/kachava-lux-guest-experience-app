import 'admin_trip.dart';
import 'service_request.dart';

/// What the guest asked for, as the Requests inbox shows it.
enum InboxType {
  order('ORDER'),
  booking('BOOKING'),
  preference('PREFERENCE'),
  trip('TRIP');

  const InboxType(this.wire);
  final String wire;

  static InboxType ofRequest(ServiceRequest r) => switch (r.usageType) {
        'ORDER' => order,
        'PREFERENCE' => preference,
        _ => r.isOrder ? order : booking,
      };
}

/// Where a request stands: new (needs action), in progress, closed.
enum InboxStage { fresh, active, closed }

/// The plain label of the one obvious next step.
enum InboxStepLabel {
  confirm,
  startPreparing,
  markDelivered,
  markDone,
  sendToProvider,
  confirmDriver,
  onTheWay,
  completed,
}

/// The single forward move of an inbox item.
sealed class InboxNextStep {
  const InboxNextStep(this.label);
  final InboxStepLabel label;
}

/// `POST /admin/requests/:id/transition {action}`.
final class RequestStep extends InboxNextStep {
  const RequestStep(this.action, super.label);
  final RequestAction action;
}

/// `POST /admin/trips/:id/transition {to}` ([needsProvider] / [needsDriver]
/// ask for a form first).
final class TripStep extends InboxNextStep {
  const TripStep(this.to, super.label);
  final String to;

  bool get needsProvider => to == 'SENT_TO_PROVIDER';
  bool get needsDriver => to == 'CONFIRMED';
}

/// One row of the Requests inbox: a section request (order, booking,
/// preference) or a transport trip.
sealed class InboxItem {
  const InboxItem();

  /// New requests wait at most this long before they turn urgent.
  static const Duration waitThreshold = Duration(minutes: 30);

  String get id;
  InboxType get type;
  String get guestName;
  String get villaName;
  String get stayId;

  /// Catalog section wire value; null when unknown.
  String? get section;
  String get status;
  InboxStage get stage;

  /// When the guest asked (UTC); null when unknown.
  DateTime? get askedAt;
  InboxNextStep? get nextStep;

  /// Wire statuses of the forward flow (the timeline).
  List<String> get flow;

  bool get canCancel => stage != InboxStage.closed;

  /// Unique across requests and trips (list row keys).
  String get rowId => type == InboxType.trip ? 'trip-$id' : id;

  /// The operational task generated for this request (backend
  /// `sourceTaskId`): `task_<type>_<refId>`.
  String get taskId =>
      'task_${type.wire.toLowerCase()}_${id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}';

  /// A new request waiting longer than [waitThreshold].
  bool isOverdue(DateTime now) {
    final asked = askedAt;
    return stage == InboxStage.fresh &&
        asked != null &&
        now.difference(asked) > waitThreshold;
  }

  /// New first, then in progress, then closed; oldest asked first.
  static int queueOrder(InboxItem a, InboxItem b) {
    final byStage = a.stage.index.compareTo(b.stage.index);
    if (byStage != 0) return byStage;
    final x = a.askedAt, y = b.askedAt;
    if (x == null || y == null) return x == null ? (y == null ? 0 : 1) : -1;
    return x.compareTo(y);
  }
}

final class RequestInboxItem extends InboxItem {
  const RequestInboxItem(this.request);

  final ServiceRequest request;

  @override
  String get id => request.id;
  @override
  InboxType get type => InboxType.ofRequest(request);
  @override
  String get stayId => request.stayId;
  @override
  String get guestName => request.guestName;
  @override
  String get villaName => request.villaName;
  @override
  String? get section => request.section;
  @override
  String get status => request.status;
  @override
  DateTime? get askedAt => request.createdAt;

  @override
  InboxStage get stage => switch (status) {
        RequestStatusValues.received => InboxStage.fresh,
        RequestStatusValues.done ||
        RequestStatusValues.cancelled =>
          InboxStage.closed,
        _ => InboxStage.active,
      };

  @override
  List<String> get flow => [
        RequestStatusValues.received,
        RequestStatusValues.confirmed,
        if (type == InboxType.order) RequestStatusValues.preparing,
        RequestStatusValues.done,
      ];

  @override
  InboxNextStep? get nextStep {
    final order = type == InboxType.order;
    return switch (status) {
      RequestStatusValues.received =>
        const RequestStep(RequestAction.confirm, InboxStepLabel.confirm),
      RequestStatusValues.confirmed => order
          ? const RequestStep(
              RequestAction.start, InboxStepLabel.startPreparing)
          : const RequestStep(RequestAction.complete, InboxStepLabel.markDone),
      RequestStatusValues.preparing => RequestStep(RequestAction.complete,
          order ? InboxStepLabel.markDelivered : InboxStepLabel.markDone),
      _ => null,
    };
  }
}

final class TripInboxItem extends InboxItem {
  const TripInboxItem(this.trip);

  final AdminTrip trip;

  @override
  String get id => trip.id;
  @override
  InboxType get type => InboxType.trip;
  @override
  String get stayId => trip.stayId;
  @override
  String get guestName => trip.guestName;
  @override
  String get villaName => trip.villaName;
  @override
  String? get section => 'TRANSPORTATION';
  @override
  String get status => trip.status;
  @override
  DateTime? get askedAt =>
      trip.history.isEmpty ? trip.pickupAt : trip.history.first.at;
  @override
  List<String> get flow => TripValues.flow;

  /// Staff-created trips are not guest requests (no chime).
  bool get guestAsked => trip.createdBy != 'STAFF';

  @override
  InboxStage get stage => trip.isFinal
      ? InboxStage.closed
      : (status == 'REQUESTED' ? InboxStage.fresh : InboxStage.active);

  @override
  InboxNextStep? get nextStep => switch (trip.nextStatus) {
        'SENT_TO_PROVIDER' =>
          const TripStep('SENT_TO_PROVIDER', InboxStepLabel.sendToProvider),
        'CONFIRMED' =>
          const TripStep('CONFIRMED', InboxStepLabel.confirmDriver),
        'EN_ROUTE' => const TripStep('EN_ROUTE', InboxStepLabel.onTheWay),
        'COMPLETED' => const TripStep('COMPLETED', InboxStepLabel.completed),
        _ => null,
      };
}
