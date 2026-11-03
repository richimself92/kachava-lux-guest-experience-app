import 'json_read.dart';

/// The six dashboard KPIs (`GET /admin/dashboard`, ADR-011). Values are the
/// server's; a missing one is a [FormatException], never a made-up zero.
class DashboardKpis {
  const DashboardKpis({
    required this.occupiedVillas,
    required this.availableVillas,
    required this.occupancyPct,
    required this.arrivals,
    required this.departures,
    required this.openRequests,
  });

  factory DashboardKpis.fromJson(Map<String, dynamic> json) {
    int read(String key) =>
        JsonRead.intOrNull(json, key) ??
        (throw FormatException('kpis.$key is missing.'));
    return DashboardKpis(
      occupiedVillas: read('occupiedVillas'),
      availableVillas: read('availableVillas'),
      occupancyPct: read('occupancyPct'),
      arrivals: read('arrivals'),
      departures: read('departures'),
      openRequests: read('openRequests'),
    );
  }

  final int occupiedVillas;
  final int availableVillas;
  final int occupancyPct;
  final int arrivals;
  final int departures;
  final int openRequests;
}

/// One row of "Today's activity". [status] is `ARRIVAL`, `IN_HOUSE` or
/// `DEPARTURE`; [overdue] marks an in-house guest past the check-out date.
class ActivityRow {
  const ActivityRow({
    required this.stayId,
    required this.guestName,
    required this.villaId,
    required this.villaName,
    required this.status,
    required this.overdue,
  });

  factory ActivityRow.fromJson(Map<String, dynamic> json) => ActivityRow(
        stayId: JsonRead.requireId(json, 'stayId'),
        guestName: JsonRead.text(json, 'guestName'),
        villaId: JsonRead.text(json, 'villaId'),
        villaName: JsonRead.text(json, 'villaName'),
        status: JsonRead.text(json, 'status'),
        overdue: JsonRead.flag(json, 'overdue'),
      );

  final String stayId;
  final String guestName;
  final String villaId;
  final String villaName;
  final String status;
  final bool overdue;
}

/// The dashboard: resort day, KPIs and at most 8 activity rows ([total]
/// counts all of today's activity for "View all").
class DashboardView {
  const DashboardView({
    required this.resortDate,
    required this.kpis,
    required this.rows,
    required this.total,
  });

  factory DashboardView.fromJson(Map<String, dynamic> json) {
    final activity = JsonRead.object(json, 'activity');
    final date = JsonRead.text(json, 'resortDate');
    if (date.isEmpty) throw const FormatException('resortDate is missing.');
    return DashboardView(
      resortDate: date,
      kpis: DashboardKpis.fromJson(JsonRead.object(json, 'kpis')),
      rows: [
        for (final row in JsonRead.objects(activity, 'rows'))
          ActivityRow.fromJson(row),
      ],
      total: JsonRead.intOrNull(activity, 'total') ?? 0,
    );
  }

  /// `YYYY-MM-DD` in the Settings time zone.
  final String resortDate;
  final DashboardKpis kpis;
  final List<ActivityRow> rows;
  final int total;
}

/// `GET /admin/dashboard`. Throws `SettingsRequiredException` when the
/// resort time zone is not configured (HTTP 422 `SETTINGS_REQUIRED`).
abstract interface class DashboardRepository {
  Future<DashboardView> fetch();
}
