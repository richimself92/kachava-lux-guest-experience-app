/// Admin workspaces. Ids are stable (keys `nav-tab-<id>` / `workspace-<id>`).
enum AdminWorkspaceTab {
  adminOverview(id: 'admin-overview', label: 'Dashboard', labelEs: 'Panel'),

  /// Every guest request of every section (orders, bookings, trips).
  adminRequests(
      id: 'admin-requests', label: 'Requests', labelEs: 'Solicitudes'),

  /// Guest conversations (chat).
  adminMessages(id: 'admin-messages', label: 'Messages', labelEs: 'Mensajes'),
  adminStays(id: 'admin-stays', label: 'Reservations', labelEs: 'Reservas'),
  adminGuests(id: 'admin-guests', label: 'Guests', labelEs: 'Huéspedes'),
  adminVillas(id: 'admin-villas', label: 'Villas', labelEs: 'Villas'),

  /// HOSPITALITY › Services: the service catalog (every section).
  adminServices(id: 'admin-services', label: 'Services', labelEs: 'Servicios'),

  /// Section views of the catalog (plus their request queues).
  adminSectionExperiences(
      id: 'admin-section-experiences',
      label: 'Experiences',
      labelEs: 'Experiencias'),
  adminSectionDining(
      id: 'admin-section-dining', label: 'Dining', labelEs: 'Gastronomía'),
  adminSectionWellness(
      id: 'admin-section-wellness', label: 'Wellness', labelEs: 'Bienestar'),

  /// HOSPITALITY › Transportation: trips, providers and transport services.
  adminTransportation(
      id: 'admin-transportation',
      label: 'Transportation',
      labelEs: 'Transporte'),

  /// OPERATIONS › Tasks and Notifications.
  adminTasks(id: 'admin-tasks', label: 'Tasks', labelEs: 'Tareas'),
  adminNotifications(
      id: 'admin-notifications',
      label: 'Notifications',
      labelEs: 'Notificaciones'),

  /// Opened from the top bar gear; not a menu item.
  adminSettings(id: 'admin-settings', label: 'Settings', labelEs: 'Ajustes');

  const AdminWorkspaceTab({
    required this.id,
    required this.label,
    required this.labelEs,
  });

  final String id;
  final String label;
  final String labelEs;
}
