/// The 6 Administrative & Concierge Operational Workspace Tabs (FR-14 to FR-19).
enum AdminWorkspaceTab {
  adminOverview(
    id: 'admin-overview',
    label: '1. Live Summary & Alerts',
    shortLabel: '1. Summary',
    subtitle: 'Live Alerts, Arrivals & Command Center',
  ),
  adminStays(
    id: 'admin-stays',
    label: '2. Villas, Guests & Magic Links',
    shortLabel: '2. Villas',
    subtitle: 'Stays, Personalization, Magic Link & Aviation Transfers',
  ),
  adminLarder(
    id: 'admin-larder',
    label: '3. Pre-Arrival: Minibar & Pantry',
    shortLabel: '3. Minibar',
    subtitle: 'Villa Stocking & Larder Provisioning Queue',
  ),
  adminExperiences(
    id: 'admin-experiences',
    label: '4. Stay: Yacht, Dining & Tours',
    shortLabel: '4. Tours',
    subtitle: 'Yacht, Private Dining, Excursions & Privileges Reservations',
  ),
  adminConcierge(
    id: 'admin-concierge',
    label: '5. Stay: 24/7 Chat & Requests',
    shortLabel: '5. Chat',
    subtitle: '24/7 Concierge Dispatch, 4-Stage Lifecycle & Live Host Chat',
  ),
  adminFolio(
    id: 'admin-folio',
    label: '6. Stay Summary & Feedback',
    shortLabel: '6. Summary',
    subtitle: 'Stay Summary, Acquired Services & Guest Feedback',
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
