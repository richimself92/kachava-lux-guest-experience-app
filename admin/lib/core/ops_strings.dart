import '../domain/admin_task.dart';

/// EN/ES copy of Tasks, Notifications and the Messages inbox.
class OpsStrings {
  const OpsStrings(this.isEs);

  final bool isEs;

  String _t(String en, String es) => isEs ? es : en;

  // Tasks.
  String get tasks => _t('Tasks', 'Tareas');
  String get newTask => _t('New task', 'Nueva tarea');
  String get noTasks => _t('No tasks yet', 'Aún no hay tareas');
  String get title => _t('Title', 'Título');
  String get villaGuest => _t('Villa / Guest', 'Villa / Huésped');
  String get owner => _t('Owner', 'Responsable');
  String get priority => _t('Priority', 'Prioridad');
  String get due => _t('Due', 'Vence');
  String get status => _t('Status', 'Estado');
  String get category => _t('Category', 'Categoría');
  String get reservation => _t('Reservation', 'Reserva');
  String get overdue => _t('Overdue', 'Vencida');
  String get overdueOnly => _t('Overdue', 'Vencidas');
  String get yes => _t('Yes', 'Sí');
  String get assign => _t('Assign', 'Asignar');
  String get start => _t('Start', 'Iniciar');
  String get complete => _t('Complete', 'Completar');
  String get cancelTask => _t('Cancel task', 'Cancelar tarea');
  String get completionNote => _t('Completion note', 'Nota de cierre');
  String get reason => _t('Reason', 'Motivo');
  String get back => _t('Back', 'Volver');
  String get cancel => _t('Cancel', 'Cancelar');
  String get actions => _t('Actions', 'Acciones');
  String get actionFailed => _t("Couldn't update", 'No se pudo actualizar');
  String get created => _t('Task created', 'Tarea creada');
  String get noStaff => _t('No staff available', 'Sin personal disponible');
  String get completion => _t('Completion', 'Cierre');
  String get source => _t('Source', 'Origen');
  String get dueInfo => _t('Resort time (Settings time zone).',
      'Hora del resort (zona horaria de Ajustes).');
  String get overdueInfo =>
      _t('Open and past its due time.', 'Abierta y pasada su hora límite.');

  String actionFor(String next) => switch (next) {
        TaskValues.assigned => assign,
        TaskValues.inProgress => start,
        _ => complete,
      };

  String priorityLabel(String p) => switch (p) {
        'LOW' => _t('Low', 'Baja'),
        'NORMAL' => 'Normal',
        'HIGH' => _t('High', 'Alta'),
        'URGENT' => _t('Urgent', 'Urgente'),
        _ => p,
      };

  String sourceLabel(String type) => switch (type) {
        'PREFERENCE' => _t('Preference', 'Preferencia'),
        'ORDER' => _t('Order', 'Pedido'),
        'BOOKING' => _t('Booking', 'Reserva'),
        'TRIP' => _t('Trip', 'Viaje'),
        _ => _t('Manual', 'Manual'),
      };

  // Notifications.
  String get notifications => _t('Notifications', 'Notificaciones');
  String get markAllRead => _t('Mark all read', 'Marcar todo leído');
  String get noNotifications => _t('No notifications', 'Sin notificaciones');
  String get level => _t('Level', 'Nivel');
  String get message => _t('Message', 'Mensaje');
  String get time => _t('Time', 'Hora');
  String get read => _t('Read', 'Leída');
  String get unread => _t('Unread', 'Sin leer');
  String get open => _t('Open', 'Abrir');
  String get markRead => _t('Mark read', 'Marcar leída');
  String get allMarked => _t('All marked read', 'Todo marcado como leído');
  String get urgentArrived => _t('Urgent notification', 'Notificación urgente');
  String get mute => _t('Mute', 'Silenciar');
  String get bellLabelPrefix =>
      _t('Unread operational alerts', 'Alertas operativas sin leer');
  String get notificationsInfo => _t(
      'Sound plays only for new urgent notifications.',
      'El sonido suena solo con urgentes nuevas.');

  String levelLabel(String level) => switch (level) {
        'INFO' => 'Info',
        'ACTION' => _t('Action', 'Acción'),
        'URGENT' => _t('Urgent', 'Urgente'),
        _ => level,
      };

  String categoryLabel(String c) => switch (c) {
        'RESERVATION' => _t('Reservation', 'Reserva'),
        'ARRIVAL' => _t('Arrival', 'Llegada'),
        'CONCIERGE' => 'Resort Host',
        'BOOKING' => _t('Booking', 'Reserva de servicio'),
        'LARDER' => _t('Order', 'Pedido'),
        'TRANSFER' => _t('Trip', 'Traslado'),
        'TASK' => _t('Task', 'Tarea'),
        'MIDSTAY' => _t('Feedback', 'Comentario'),
        'CHECKOUT' => _t('Check-out', 'Salida'),
        'DIETARY' => _t('Dietary', 'Dieta'),
        _ => c,
      };

  // Messages inbox.
  String get messages => _t('Messages', 'Mensajes');
  String get noConversations => _t('No messages yet', 'Aún no hay mensajes');
  String get lastMessage => _t('Last message', 'Último mensaje');
  String get awaitingReply => _t('Awaiting reply', 'Sin responder');
  String get unreadOnly => _t('Unread', 'Sin leer');
  String get photo => _t('Photo', 'Foto');
  String get reply => _t('Reply', 'Responder');
  String get send => _t('Send', 'Enviar');
  String get sendFailed => _t("Couldn't send", 'No se pudo enviar');
  String get noMessages => _t('No messages', 'Sin mensajes');
  String get photoUnavailable => _t('Photo unavailable', 'Foto no disponible');
}
