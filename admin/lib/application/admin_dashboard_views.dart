import '../domain/admin_entities.dart';
import '../domain/admin_enums.dart';
import '../domain/admin_stay_entities.dart';
import 'admin_dashboard_controller.dart';
import 'inspector_selection.dart';

/// Read-only views derived from the dashboard state (counts and filters).
extension AdminDashboardViews on AdminDashboardController {
  int get unreadAlertsCount => alerts.where((a) => !a.isAcknowledged).length;
  int get openConciergeCount =>
      conciergeTickets.where((t) => t.stage != ConciergeStage.completed).length;
  int get pendingBookingsAndLarderCount =>
      bookings.where((b) => b.status == 'Requested').length +
      larderOrders.where((o) => o.status != 'Stocked in Villa').length;
  int get urgentSlaAlertsCount => alerts
      .where((a) => a.severity == AlertSeverity.urgent && !a.isAcknowledged)
      .length;
  List<OperationalAlert> get filteredAlerts => AdminFilterEngine.filterAlerts(
      alerts: alerts,
      query: searchQuery,
      villaFilter: villaFilter,
      urgentOnly: urgentOnly,
      categoryFilter: alertCategoryFilter);
  List<AdminStayRecord> get filteredStays => AdminFilterEngine.filterStays(
      stays: stays,
      query: searchQuery,
      villaFilter: villaFilter,
      lifecycleFilter: lifecycleFilter);
  List<AdminBookingRecord> get filteredBookings =>
      AdminFilterEngine.filterBookings(
          bookings: bookings,
          query: searchQuery,
          categoryFilter: experienceCategoryFilter);
  List<AdminLarderOrder> get filteredLarderOrders =>
      AdminFilterEngine.filterLarderOrders(
          orders: larderOrders,
          query: searchQuery,
          statusFilter: larderStatusFilter,
          zoneFilter: larderZoneFilter);
  List<AdminConciergeTicket> get filteredConciergeTickets =>
      AdminFilterEngine.filterConciergeTickets(
          tickets: conciergeTickets,
          query: searchQuery,
          stageFilter: conciergeStageFilter,
          departmentFilter: conciergeDepartmentFilter);
  double get folioIncidentalsTotalUsd => folioItems
      .where((i) => !i.isIncludedPrivilege)
      .fold(0.0, (sum, item) => sum + item.amountUsd);
  AdminStayRecord? activeStayForVilla(String villaLabel) =>
      AdminFilterEngine.findActiveStayForVilla(stays, villaLabel);
  bool isVillaOccupied(String villaLabel) =>
      activeStayForVilla(villaLabel) != null;
}
