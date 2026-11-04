import 'package:flutter/material.dart';

import '../application/admin_shell_controller.dart';
import '../application/request_inbox_source.dart';
import '../application/notification_bell_controller.dart';
import '../application/resort_settings_controller.dart';
import '../core/admin_list_strings.dart';
import '../core/resort_time.dart';
import '../core/time_zone_catalog.dart';
import '../domain/admin_catalog_repositories.dart';
import '../domain/admin_enums.dart';
import '../domain/admin_notification.dart';
import '../domain/inbox_item.dart';
import '../domain/reservation.dart';
import '../domain/service_catalog_enums.dart';
import 'components/components.dart';
import 'operations/dashboard_screen.dart';
import 'operations/guests/guests_screen.dart';
import 'operations/messages/messages_workspace.dart';
import 'operations/notifications_screen.dart';
import 'operations/operations_scope.dart';
import 'operations/reservations/reservations_screen.dart';
import 'operations/tasks/tasks_screen.dart';
import 'requests/inbox_task_section.dart';
import 'requests/request_inbox_scope.dart';
import 'requests/requests_inbox_screen.dart';
import 'services/services_workspace.dart';
import 'workspaces/settings_workspace.dart';
import 'workspaces/transportation/transportation_screen.dart';
import 'workspaces/transportation/trips_tab.dart';
import 'workspaces/villas_workspace.dart';

/// Builds the active workspace and routes cross-screen "open" requests
/// (dashboard rows, notification targets, reservation trips).
class AdminWorkspaceSwitcher extends StatelessWidget {
  const AdminWorkspaceSwitcher({
    super.key,
    required this.controller,
    required this.bell,
    required this.resortSettings,
    required this.villas,
    required this.timeZones,
    required this.zoneResolver,
  });

  final AdminShellController controller;
  final NotificationBellController bell;
  final ResortSettingsController resortSettings;
  final VillaRepository villas;
  final TimeZoneCatalog timeZones;
  final ZoneOffsetResolver zoneResolver;

  bool get _isEs => controller.isEs;

  ResortTime get _resortTime => ResortTime(
      timeZone: resortSettings.settings?.timeZone, resolver: zoneResolver);

  void _go(AdminWorkspaceTab tab) => controller.selectTab(tab);

  void _refreshBell() => bell.refresh().catchError((Object error) {
        debugPrint('Bell refresh failed: $error');
      });

  /// "Open" of a notification: its record, or the stay it belongs to.
  void openTarget(NotificationTarget t) {
    final open = controller.openRecord;
    switch (t.type) {
      case 'TRIP':
        open(AdminWorkspaceTab.adminTransportation, t.id);
      case 'CONVERSATION':
        open(AdminWorkspaceTab.adminGuests, t.id,
            section: GuestsScreen.messagesSection);
      case 'TASK':
        open(AdminWorkspaceTab.adminTasks, t.id);
      case 'STAY':
        open(AdminWorkspaceTab.adminStays, t.id);
      default:
        final stayId = t.stayId;
        if (stayId != null) open(AdminWorkspaceTab.adminStays, stayId);
    }
  }

  /// Transportation searching the stay's guest, any date.
  void _openTrips(ReservationRow row) {
    final q = controller.listQueries;
    q.write(TripsTab.storeKey,
        q.read(TripsTab.storeKey).clearFilters().withSearch(row.guestName));
    _go(AdminWorkspaceTab.adminTransportation);
  }

  @override
  Widget build(BuildContext context) {
    final tab = controller.activeTab;
    final request = controller.peekOpenRequest(tab);
    return KeyedSubtree(
      key: ValueKey(request ?? tab),
      child: _workspace(context, tab, request),
    );
  }

  Widget _missing(AdminWorkspaceTab tab) => Align(
        alignment: Alignment.topLeft,
        child: AdminStateLine(
          key: Key('workspace-${tab.id}'),
          message: AdminListStrings(_isEs).loadError,
          isError: true,
        ),
      );

  Widget _workspace(
      BuildContext context, AdminWorkspaceTab tab, AdminOpenRequest? request) {
    final ops = OperationsScope.maybeOf(context);
    switch (tab) {
      case AdminWorkspaceTab.adminOverview:
        if (ops == null) return _missing(tab);
        return DashboardScreen(
          repository: ops.dashboard,
          isEs: _isEs,
          onOpenStay: (id) =>
              controller.openRecord(AdminWorkspaceTab.adminStays, id),
          onViewAll: () => _go(AdminWorkspaceTab.adminStays),
          onOpenSettings: () => _go(AdminWorkspaceTab.adminSettings),
          resortTime: _resortTime,
          onStayAction: (row, action) => ops.reservations
              .update(row.stayId, ReservationPatch(action: action)),
          onOpenRequests: (row) => _openRequestsOf(row.guestName),
          onOpenMessages: (row) => controller.openRecord(
              AdminWorkspaceTab.adminMessages, row.stayId),
        );
      case AdminWorkspaceTab.adminRequests:
        return _requests(context, ops, request);
      case AdminWorkspaceTab.adminMessages:
        if (ops == null) return _missing(tab);
        return MessagesWorkspace(
          key: const Key('workspace-admin-messages'),
          repository: ops.conversations,
          queries: controller.listQueries,
          resortTime: _resortTime,
          isEs: _isEs,
          openStayId: request?.id,
          onRead: () => _messagesRead(context),
          onOpenStay: (id) =>
              controller.openRecord(AdminWorkspaceTab.adminStays, id),
        );
      case AdminWorkspaceTab.adminStays:
        if (ops == null) return _missing(tab);
        return _reservations(context, ops, request);
      case AdminWorkspaceTab.adminGuests:
        if (ops == null) return _missing(tab);
        return GuestsScreen(
          guests: ops.guests,
          conversations: ops.conversations,
          queries: controller.listQueries,
          resortTime: _resortTime,
          isEs: _isEs,
          section: request?.section,
          openId: request?.id,
          onMessagesRead: _refreshBell,
        );
      case AdminWorkspaceTab.adminTasks:
        if (ops == null) return _missing(tab);
        return TasksScreen(
          tasks: ops.tasks,
          stays: ops.reservations,
          queries: controller.listQueries,
          staff: controller.staffDirectory,
          resortTime: _resortTime,
          isEs: _isEs,
          openId: request?.id,
          onOpenRequest: (task) => _openRequestsOf(task.guestName ?? ''),
        );
      case AdminWorkspaceTab.adminNotifications:
        if (ops == null) return _missing(tab);
        return NotificationsScreen(
          repository: ops.notifications,
          queries: controller.listQueries,
          resortTime: _resortTime,
          isEs: _isEs,
          onOpenTarget: openTarget,
          onReadChanged: _refreshBell,
        );
      default:
        return _catalog(tab, request);
    }
  }

  /// The Requests inbox searching one guest's open requests.
  void _openRequestsOf(String guestName) {
    controller.listQueries.write(RequestsInboxScreen.storeKey,
        RequestInboxSource.initialQuery.withSearch(guestName));
    _go(AdminWorkspaceTab.adminRequests);
  }

  void _messagesRead(BuildContext context) {
    _refreshBell();
    RequestInboxScope.maybeOf(context)?.watcher.check();
  }

  Widget _requests(
      BuildContext context, OperationsDeps? ops, AdminOpenRequest? request) {
    final scope = RequestInboxScope.maybeOf(context);
    final deps = scope?.deps;
    if (scope == null || deps == null) {
      return _missing(AdminWorkspaceTab.adminRequests);
    }
    final openId = request?.id;
    return RequestsInboxScreen(
      key: const Key('workspace-admin-requests'),
      deps: deps,
      watcher: scope.watcher,
      isEs: _isEs,
      queries: controller.listQueries,
      resortTime: _resortTime,
      initialItem: openId == null ? null : scope.watcher.itemFor(openId),
      taskSection: ops == null
          ? null
          : (item) => InboxTaskSection(
                key: ValueKey('task-${item.rowId}-${item.status}'),
                item: item,
                tasks: ops.tasks,
                staff: controller.staffDirectory,
                isEs: _isEs,
                resortTime: _resortTime,
                onOpenTask: (id) =>
                    controller.openRecord(AdminWorkspaceTab.adminTasks, id),
                onCreateTask: item is TripInboxItem
                    ? null
                    : (item) => deps.requests.ensureTask(item.id),
              ),
      onMessageGuest: (item) =>
          controller.openRecord(AdminWorkspaceTab.adminMessages, item.stayId),
    );
  }

  Widget _reservations(BuildContext context, OperationsDeps ops,
          AdminOpenRequest? request) =>
      ReservationsScreen(
        reservations: ops.reservations,
        guests: ops.guests,
        villas: villas,
        queries: controller.listQueries,
        staff: controller.staffDirectory,
        isEs: _isEs,
        today: _resortTime.dayOf(DateTime.now().toUtc()),
        openId: request?.id,
        onOpenTrips: _openTrips,
        onOpenTrip: (id) =>
            controller.openRecord(AdminWorkspaceTab.adminTransportation, id),
      );

  Widget _catalog(AdminWorkspaceTab tab, AdminOpenRequest? request) {
    switch (tab) {
      case AdminWorkspaceTab.adminVillas:
        return VillasWorkspace(
            repository: villas, queries: controller.listQueries, isEs: _isEs);
      case AdminWorkspaceTab.adminServices:
        return ServicesWorkspace(
            queryStore: controller.listQueries,
            staff: controller.staffDirectory,
            isEs: _isEs);
      case AdminWorkspaceTab.adminSectionExperiences:
        return _section(ServiceSection.experiences);
      case AdminWorkspaceTab.adminSectionDining:
        return _section(ServiceSection.dining);
      case AdminWorkspaceTab.adminSectionWellness:
        return _section(ServiceSection.wellness);
      case AdminWorkspaceTab.adminTransportation:
        return TransportationScreen(
          resortSettings: resortSettings,
          queries: controller.listQueries,
          isEs: _isEs,
          zoneResolver: zoneResolver,
          openTripId: request?.id,
          onOpenSettings: () => _go(AdminWorkspaceTab.adminSettings),
          onOpenServicesTab: () => _go(AdminWorkspaceTab.adminServices),
        );
      default:
        return SettingsWorkspace(
          settings: resortSettings,
          timeZones: timeZones,
          isEs: _isEs,
          staff: controller.staffRoster,
          onStaffChanged: controller.loadStaff,
          queries: controller.listQueries,
        );
    }
  }

  Widget _section(ServiceSection section) => ServiceSectionWorkspace(
        key: ValueKey(section),
        section: section,
        queryStore: controller.listQueries,
        staff: controller.staffDirectory,
        today: _resortTime.dayOf(DateTime.now().toUtc()),
        isEs: _isEs,
      );
}
