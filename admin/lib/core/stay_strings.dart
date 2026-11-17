import '../domain/reservation.dart';
import 'resort_time.dart';

/// EN/ES copy of Dashboard, Reservations and Guests (1-3 word labels;
/// explanations only in ⓘ tooltips).
class StayStrings {
  const StayStrings(this.isEs);

  final bool isEs;

  String _t(String en, String es) => isEs ? es : en;

  // Dashboard.
  String get overview => _t('Overview', 'Resumen');
  String get today => _t('Today', 'Hoy');
  String get occupiedVillas => _t('Occupied villas', 'Villas ocupadas');
  String get availableVillas => _t('Available villas', 'Villas disponibles');
  String get occupancy => _t('Occupancy', 'Ocupación');
  String get arrivals => _t('Arrivals', 'Llegadas');
  String get departures => _t('Departures', 'Salidas');
  String get openRequests => _t('Open requests', 'Solicitudes abiertas');
  String get occupiedInfo => _t('Active villas with a guest in house.',
      'Villas activas con huésped en estancia.');
  String get availableInfo => _t('Active villas − occupied − out of service.',
      'Villas activas − ocupadas − fuera de servicio.');
  String get occupancyInfo =>
      _t('Occupied ÷ active villas.', 'Ocupadas ÷ villas activas.');
  String get arrivalsInfo =>
      _t('Stays checking in today.', 'Estancias con llegada hoy.');
  String get departuresInfo =>
      _t('Stays checking out today.', 'Estancias con salida hoy.');
  String get openRequestsInfo => _t('Open orders, bookings, trips and tasks.',
      'Pedidos, reservas, viajes y tareas sin completar.');
  String get todaysActivity => _t("Today's activity", 'Actividad de hoy');
  String get noActivity => _t('No activity today', 'Sin actividad hoy');
  String get viewAll => _t('View all', 'Ver todo');
  String get timeZoneMissing =>
      _t('Time zone not set', 'Zona horaria sin configurar');
  String get setUpInSettings => _t('Set up in Settings', 'Configurar');
  String get inHouse => _t('In-house', 'En estancia');
  String get arrival => _t('Arrival', 'Llegada');
  String get departure => _t('Departure', 'Salida');
  String get inHouseOverdue =>
      _t('In-house · overdue', 'En estancia · vencida');

  // Reservations.
  String get reservations => _t('Reservations', 'Reservas');
  String get newReservation => _t('New reservation', 'Nueva reserva');
  String get noReservations => _t('No reservations yet', 'Aún no hay reservas');
  String get guest => _t('Guest', 'Huésped');
  String get villa => _t('Villa', 'Villa');
  String get status => _t('Status', 'Estado');
  String get resortHost => 'Resort Host';
  String get dates => _t('Dates', 'Fechas');
  String get checkInDate => _t('Arrival', 'Llegada');
  String get checkOutDate => _t('Departure', 'Salida');
  String get guests => _t('Guests', 'Huéspedes');
  String get language => _t('Language', 'Idioma');
  String get occasion => _t('Occasion', 'Ocasión');
  String get email => 'Email';
  String get phone => _t('Phone', 'Teléfono');
  String get guestData => _t('Guest data', 'Datos del huésped');
  String get english => _t('English', 'Inglés');
  String get spanish => _t('Spanish', 'Español');
  String get summary => _t('Summary', 'Resumen');
  String get preferences => _t('Preferences', 'Preferencias');
  String get trips => _t('Trips', 'Traslados');
  String get folio => 'Folio';
  String get guestLink => _t('Guest link', 'Link del huésped');
  String get copy => _t('Copy', 'Copiar');
  String get linkCopied => _t('Link copied', 'Link copiado');
  String get wifiName => _t('Wi-Fi name', 'Red Wi-Fi');
  String get wifiPassword => _t('Wi-Fi password', 'Clave Wi-Fi');
  String get show => _t('Show', 'Mostrar');
  String get hide => _t('Hide', 'Ocultar');
  String get internalNotes => _t('Internal notes', 'Notas internas');
  String get notesInfo => _t('Staff only; never shown to the guest.',
      'Solo personal; el huésped no las ve.');
  String get save => _t('Save', 'Guardar');
  String get saved => _t('Saved', 'Guardado');
  String get checkIn => _t('Check in', 'Registrar llegada');
  String get checkOut => _t('Check out', 'Registrar salida');
  String get cancelReservation => _t('Cancel reservation', 'Cancelar reserva');
  String get reason => _t('Reason', 'Motivo');
  String get back => _t('Back', 'Volver');
  String get cancel => _t('Cancel', 'Cancelar');
  String get actions => _t('Actions', 'Acciones');
  String get actionFailed => _t("Couldn't update", 'No se pudo actualizar');
  String get loadFailed => _t("Couldn't load", 'No se pudo cargar');
  String get retry => _t('Retry', 'Reintentar');
  String get created => _t('Reservation created', 'Reserva creada');
  String get checkOutAfterIn =>
      _t('After arrival date', 'Posterior a la llegada');
  String get dateFormat => _t('Use YYYY-MM-DD', 'Usa AAAA-MM-DD');
  String get pickDate => _t('Pick date', 'Elegir fecha');
  String get pickDatesFirst =>
      _t('Pick arrival and departure first', 'Elige llegada y salida primero');
  String get noVillasForDates => _t('No villas available for these dates',
      'No hay villas disponibles para estas fechas');
  String get notBeforeToday => _t('Not before today', 'No antes de hoy');
  String get villaTaken => _t('Villa already booked for these dates',
      'Villa ya reservada en esas fechas');
  String get noPreferences => _t('No preferences yet', 'Sin preferencias');
  String get allergies => _t('Allergies', 'Alergias');
  String get noTrips => _t('No trips', 'Sin traslados');
  String get openTransportation =>
      _t('Open Transportation', 'Abrir Transporte');
  String get stayServices => _t('Services', 'Servicios');
  String get noServices => _t('No services yet', 'Sin servicios');
  String get rating => _t('Rating', 'Calificación');
  String get noRating => _t('No rating yet', 'Sin calificación');
  String get charges => _t('Charges', 'Cargos');
  String get total => 'Total';
  String get payments => _t('Payments', 'Pagos');
  String get noPms => _t('No PMS integration', 'Sin integración PMS');
  String get included => _t('Included', 'Incluido');
  String get history => _t('History', 'Historial');
  String get unassigned => _t('Unassigned', 'Sin asignar');
  String get notSet => '—';

  String confirmMove(String action, String guest) => switch (action) {
        StayValues.checkIn =>
          _t('Check in $guest?', '¿Registrar llegada de $guest?'),
        StayValues.checkOut =>
          _t('Check out $guest?', '¿Registrar salida de $guest?'),
        _ => _t('Cancel this reservation?', '¿Cancelar esta reserva?'),
      };

  String actionLabel(String action) => switch (action) {
        StayValues.checkIn => checkIn,
        StayValues.checkOut => checkOut,
        _ => cancelReservation,
      };

  String languageLabel(String? code) => switch (code) {
        'en' => english,
        'es' => spanish,
        null || '' => notSet,
        _ => code.toUpperCase(),
      };

  /// "Nov 3 – Nov 7".
  String range(String? from, String? to) {
    String day(String? d) =>
        d == null ? notSet : ResortTime.dayLabel(d, isEs: isEs);
    return '${day(from)} – ${day(to)}';
  }

  String nights(int n) => isEs
      ? '$n ${n == 1 ? 'noche' : 'noches'}'
      : '$n ${n == 1 ? 'night' : 'nights'}';

  /// `$1,234.50 USD`; `null` is "—".
  String money(double? usd) {
    if (usd == null) return notSet;
    final fixed = usd.toStringAsFixed(2);
    final parts = fixed.split('.');
    final digits = parts.first.replaceFirst('-', '');
    final grouped = digits.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => isEs ? '.' : ',');
    final sign = usd < 0 ? '-' : '';
    return '$sign\$$grouped${isEs ? ',' : '.'}${parts.last} USD';
  }

  // Guests.
  String get guestsTitle => _t('Guests', 'Huéspedes');
  String get messages => _t('Messages', 'Mensajes');
  String get noGuests => _t('No guests yet', 'Aún no hay huéspedes');
  String get hasAllergies => _t('Allergies', 'Alergias');
  String get requests => _t('Requests', 'Solicitudes');
  String get requestHistory => _t('Requests', 'Solicitudes');
  String get noRequests => _t('No requests yet', 'Sin solicitudes');
  String get openChat => _t('Open chat', 'Abrir chat');
  String preferenceLabel(String key) => switch (key) {
        'pillow' => _t('Pillow', 'Almohada'),
        'scent' => _t('Scent', 'Aroma'),
        'dietary' => _t('Diet', 'Dieta'),
        'temperature' => _t('Temperature', 'Temperatura'),
        'lighting' => _t('Lighting', 'Iluminación'),
        'housekeeping' => _t('Housekeeping', 'Limpieza'),
        'communication' => _t('Contact', 'Contacto'),
        'interests' => _t('Interests', 'Intereses'),
        _ => _t('Choice', 'Elección'),
      };
}
