import '../domain/service_request.dart';

/// EN/ES copy of the section request queues (1-3 word labels).
class RequestStrings {
  const RequestStrings(this.isEs);

  final bool isEs;

  String t(String en, String es) => isEs ? es : en;

  String get requests => t('Requests', 'Solicitudes');
  String get requestsInfo => t('Guest bookings and orders of this section.',
      'Reservas y pedidos de huéspedes de esta sección.');
  String get noRequests => t('No requests yet', 'Aún no hay solicitudes');
  String get notConnected =>
      t('Requests not connected', 'Solicitudes sin conexión');

  // Columns, facts and filters.
  String get guestVilla => t('Guest · Villa', 'Huésped · Villa');
  String get guest => t('Guest', 'Huésped');
  String get villa => t('Villa', 'Villa');
  String get service => t('Service', 'Servicio');
  String get dateTime => t('Date / time', 'Fecha / hora');
  String get guestsQty => t('Guests / qty', 'Personas / cant.');
  String get guests => t('Guests', 'Personas');
  String get quantity => t('Quantity', 'Cantidad');
  String get items => t('Items', 'Artículos');
  String get total => t('Total', 'Total');
  String get status => t('Status', 'Estado');
  String get reason => t('Reason', 'Motivo');
  String get dates => t('Dates', 'Fechas');
  String get open => t('Open', 'Abiertas');
  String get today => t('Today', 'Hoy');
  String get tomorrow => t('Tomorrow', 'Mañana');
  String get next7Days => t('Next 7 days', 'Próximos 7 días');
  String get last7Days => t('Last 7 days', 'Últimos 7 días');
  String get order => t('Order', 'Pedido');
  String get booking => t('Booking', 'Reserva');

  // Actions.
  String action(RequestAction a) => switch (a) {
        RequestAction.confirm => t('Confirm', 'Confirmar'),
        RequestAction.start => t('Start', 'Iniciar'),
        RequestAction.complete => t('Complete', 'Completar'),
        RequestAction.cancel => t('Cancel request', 'Cancelar solicitud'),
      };
  String get back => t('Back', 'Volver');
  String get moved => t('Request updated', 'Solicitud actualizada');
  String get cancelled => t('Request cancelled', 'Solicitud cancelada');
  String get actionFailed =>
      t("Couldn't update request", 'No se pudo actualizar');
}
