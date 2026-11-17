import '../domain/inbox_item.dart';

/// EN/ES copy of the Requests inbox (plain words, 1-3 word labels).
class InboxStrings {
  const InboxStrings(this.isEs);

  final bool isEs;

  String t(String en, String es) => isEs ? es : en;

  String get title => t('Requests', 'Solicitudes');
  String get info => t(
      'Everything guests asked for: orders, bookings, preferences and trips. New first.',
      'Todo lo que pidieron los huéspedes: pedidos, reservas, preferencias y traslados. Nuevas primero.');
  String get empty => t('No requests', 'No hay solicitudes');
  String get notConnected =>
      t('Requests not connected', 'Solicitudes sin conexión');

  // Columns and filters.
  String get guestVilla => t('Guest · Villa', 'Huésped · Villa');
  String get asked => t('What was asked', 'Qué pidió');
  String get waiting => t('Waiting', 'Espera');
  String get status => t('Status', 'Estado');
  String get section => t('Section', 'Sección');
  String get type => t('Type', 'Tipo');
  String get open => t('Open', 'Abiertas');

  String statusFilter(String value) => switch (value) {
        'OPEN' => t('Open', 'Abiertas'),
        'NEW' => t('New', 'Nuevas'),
        'DONE' => t('Done', 'Hechas'),
        _ => t('Cancelled', 'Canceladas'),
      };

  String typeLabel(InboxType type) => switch (type) {
        InboxType.order => t('Order', 'Pedido'),
        InboxType.booking => t('Booking', 'Reserva'),
        InboxType.preference => t('Preference', 'Preferencia'),
        InboxType.trip => t('Trip', 'Traslado'),
      };

  String sectionLabel(String? wire) => switch (wire) {
        'IN_VILLA' => t('In villa', 'En la villa'),
        'DINING' => t('Dining', 'Gastronomía'),
        'WELLNESS' => t('Wellness', 'Bienestar'),
        'EXPERIENCES' => t('Experiences', 'Experiencias'),
        'TRANSPORTATION' => t('Transport', 'Transporte'),
        _ => '—',
      };

  /// Inbox chip: New / Confirmed / In progress / On the way / Done ...
  String stageStatus(String wire) => switch (wire) {
        'RECEIVED' || 'REQUESTED' => t('New', 'Nueva'),
        'CONFIRMED' => t('Confirmed', 'Confirmada'),
        'PREPARING' => t('In progress', 'En curso'),
        'SENT_TO_PROVIDER' => t('Sent to provider', 'Enviada al proveedor'),
        'EN_ROUTE' => t('On the way', 'En camino'),
        'DONE' || 'COMPLETED' => t('Done', 'Hecha'),
        'CANCELLED' => t('Cancelled', 'Cancelada'),
        _ => wire,
      };

  // Waiting time.
  String ago(Duration d) {
    final (n, unit) = d.inMinutes < 1
        ? (0, '')
        : d.inHours < 1
            ? (d.inMinutes, 'min')
            : d.inDays < 1
                ? (d.inHours, 'h')
                : (d.inDays, 'd');
    return n == 0 ? t('just now', 'ahora') : t('$n $unit ago', 'hace $n $unit');
  }

  // Detail facts.
  String get guest => t('Guest', 'Huésped');
  String get villa => t('Villa', 'Villa');
  String get askedAt => t('Asked', 'Pedido');
  String get items => t('Items', 'Artículos');
  String get total => t('Total', 'Total');
  String get choice => t('Choice', 'Opción elegida');
  String get date => t('Date', 'Fecha');
  String get time => t('Time', 'Hora');
  String get partySize => t('Party size', 'Personas');
  String get option => t('Option', 'Opción');
  String get notes => t('Guest notes', 'Notas del huésped');
  String get flight => t('Flight', 'Vuelo');
  String get pickup => t('Pickup', 'Recogida');
  String get passengers => t('Passengers', 'Pasajeros');
  String get luggage => t('Luggage', 'Maletas');
  String get driver => t('Driver', 'Chofer');
  String get vehicle => t('Vehicle', 'Vehículo');
  String get reason => t('Reason', 'Motivo');
  String get progress => t('Progress', 'Avance');

  // Actions.
  String step(InboxStepLabel label) => switch (label) {
        InboxStepLabel.confirm => t('Confirm', 'Confirmar'),
        InboxStepLabel.startPreparing =>
          t('Start preparing', 'Empezar a preparar'),
        InboxStepLabel.markDelivered => t('Mark delivered', 'Marcar entregado'),
        InboxStepLabel.markDone => t('Mark done', 'Marcar hecho'),
        InboxStepLabel.sendToProvider =>
          t('Send to provider', 'Enviar al proveedor'),
        InboxStepLabel.confirmDriver => t('Confirm driver', 'Confirmar chofer'),
        InboxStepLabel.onTheWay => t('On the way', 'En camino'),
        InboxStepLabel.completed => t('Completed', 'Completado'),
      };
  String get cancel => t('Cancel request', 'Cancelar solicitud');
  String get back => t('Back', 'Volver');
  String get assign => t('Assign to staff', 'Asignar a personal');
  String get assignInfo => t('Optional. Never needed to move the status.',
      'Opcional. No hace falta para cambiar el estado.');
  String get staffMember => t('Staff member', 'Persona');
  String get noTask => t('No task to assign', 'No hay tarea para asignar');
  String assignedTo(String name) => t('Assigned to $name', 'Asignada a $name');
  String get assigned => t('Assigned', 'Asignada');
  String get moved => t('Request updated', 'Solicitud actualizada');
  String get cancelled => t('Request cancelled', 'Solicitud cancelada');
  String get failed => t("Couldn't update request", 'No se pudo actualizar');
  String get openTask => t('Open task', 'Abrir tarea');
  String get createTask => t('Create task', 'Crear tarea');
  String get messageGuest => t('Message guest', 'Escribir al huésped');

  // Toasts.
  String newRequest(String villa, String what) =>
      t('New request · $villa · $what', 'Nueva solicitud · $villa · $what');
  String newMessage(String villa, String guest, String text) => t(
      'New message · $villa · $guest: $text',
      'Nuevo mensaje · $villa · $guest: $text');
  String get openAction => t('Open', 'Abrir');
  String get dismiss => t('Dismiss', 'Cerrar');
}
