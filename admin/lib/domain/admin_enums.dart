/// Admin workspaces. Ids are stable (keys `nav-tab-<id>` / `workspace-<id>`).
enum AdminWorkspaceTab {
  adminOverview(
    id: 'admin-overview',
    label: 'Dashboard',
    shortLabel: 'Dashboard',
    subtitle: 'Live Alerts, Arrivals & Command Center',
  ),
  adminStays(
    id: 'admin-stays',
    label: 'Reservations',
    shortLabel: 'Reservations',
    subtitle: 'Stays, Personalization, Magic Link & Aviation Transfers',
  ),
  adminVillas(
    id: 'admin-villas',
    label: 'Villas',
    shortLabel: 'Villas',
    subtitle: 'Villa inventory and status',
  ),
  adminLarder(
    id: 'admin-larder',
    label: 'Services',
    shortLabel: 'Services',
    subtitle: 'Villa Stocking & Larder Provisioning Queue',
  ),
  adminExperiences(
    id: 'admin-experiences',
    label: 'Experiences',
    shortLabel: 'Experiences',
    subtitle: 'Yacht, Private Dining, Excursions & Privileges Reservations',
  ),

  /// HOSPITALITY › Services: the service catalog (every section).
  adminServices(
    id: 'admin-services',
    label: 'Services',
    shortLabel: 'Services',
    subtitle: 'Service catalog',
  ),

  /// Section views of the catalog (plus their request queues).
  adminSectionExperiences(
    id: 'admin-section-experiences',
    label: 'Experiences',
    shortLabel: 'Experiences',
    subtitle: 'Experiences catalog',
  ),
  adminSectionDining(
    id: 'admin-section-dining',
    label: 'Dining',
    shortLabel: 'Dining',
    subtitle: 'Dining catalog',
  ),
  adminSectionWellness(
    id: 'admin-section-wellness',
    label: 'Wellness',
    shortLabel: 'Wellness',
    subtitle: 'Wellness catalog',
  ),

  /// HOSPITALITY › Transportation: trips, providers and transport services.
  adminTransportation(
    id: 'admin-transportation',
    label: 'Transportation',
    shortLabel: 'Transportation',
    subtitle: 'Trips and providers',
  ),
  adminConcierge(
    id: 'admin-concierge',
    label: 'Tasks',
    shortLabel: 'Tasks',
    subtitle: '24/7 Resort Host Dispatch, 4-Stage Lifecycle & Live Host Chat',
  ),
  adminFolio(
    id: 'admin-folio',
    label: 'Stay summary',
    shortLabel: 'Stay summary',
    subtitle: 'Stay Summary, Acquired Services & Guest Feedback',
  ),

  /// Opened from the top bar gear; not a menu item.
  adminSettings(
    id: 'admin-settings',
    label: 'Settings',
    shortLabel: 'Settings',
    subtitle: 'Resort settings',
  );

  const AdminWorkspaceTab({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.subtitle,
  });

  final String id;
  final String label;
  final String shortLabel;
  final String subtitle;
}

/// Role-Based Access Control (RBAC) roles enforced by AdminAuthGuard & RolesGuard.
enum StaffRole {
  hostAdmin('HOST_ADMIN'),
  conciergeStaff('CONCIERGE_STAFF'),
  departmentCoordinator('DEPARTMENT_COORDINATOR');

  const StaffRole(this.apiValue);
  final String apiValue;
}

/// Operational departments across the Kachava Lux Sanctuary.
enum StaffDepartment {
  concierge('CONCIERGE', 'Concierge & Butlery'),
  culinary('CULINARY', 'Culinary'),
  marine('MARINE', 'Marine & Yacht'),
  transport('TRANSPORT', 'Aviation & Transport'),
  housekeeping('HOUSEKEEPING', 'Housekeeping'),
  engineering('ENGINEERING', 'Engineering & HVAC'),
  wellness('WELLNESS', 'Wellness & Rituals');

  const StaffDepartment(this.apiValue, this.displayName);
  final String apiValue;
  final String displayName;
}

/// Severity classification for operational alerts.
enum AlertSeverity {
  urgent('URGENT'),
  high('HIGH'),
  normal('NORMAL');

  const AlertSeverity(this.label);
  final String label;
}

/// Category classification for operational alerts.
enum AlertCategory {
  concierge('CONCIERGE'),
  booking('BOOKING'),
  larder('LARDER'),
  transfer('TRANSFER'),
  midstay('MIDSTAY'),
  checkout('CHECKOUT'),
  dietary('DIETARY');

  const AlertCategory(this.label);
  final String label;
}

/// Guest stay lifecycle states.
enum StayLifecycleStatus {
  preArrival('PRE_ARRIVAL'),
  activeStay('ACTIVE_STAY'),
  checkedOut('CHECKED_OUT'),
  expired('EXPIRED');

  const StayLifecycleStatus(this.label);
  final String label;
}

/// 4-Stage Concierge Ticket Lifecycle.
enum ConciergeStage {
  requested(step: 1, label: 'Requested'),
  assigned(step: 2, label: 'Assigned'),
  inProgress(step: 3, label: 'In Progress'),
  completed(step: 4, label: 'Completed');

  const ConciergeStage({required this.step, required this.label});
  final int step;
  final String label;

  ConciergeStage get nextStage {
    switch (this) {
      case ConciergeStage.requested:
        return ConciergeStage.assigned;
      case ConciergeStage.assigned:
        return ConciergeStage.inProgress;
      case ConciergeStage.inProgress:
      case ConciergeStage.completed:
        return ConciergeStage.completed;
    }
  }
}
