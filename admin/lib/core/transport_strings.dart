/// EN/ES copy of the Transportation screen. Labels are 1-3 words;
/// explanations live in ⓘ tooltips; inline errors are <= 5 words.
class TransportStrings {
  const TransportStrings(this.isEs);

  final bool isEs;

  String _t(String en, String es) => isEs ? es : en;

  // Tabs.
  String get trips => _t('Trips', 'Viajes');
  String get providers => _t('Providers', 'Proveedores');
  String get services => _t('Services', 'Servicios');
  String get tripsInfo => _t(
      'Arrivals, departures and local trips. Times are resort time.',
      'Llegadas, salidas y viajes locales. Horas del resort.');
  String get providersInfo => _t('External drivers and transport companies.',
      'Choferes y empresas de transporte externas.');
  String get servicesLine =>
      _t('Managed in Services', 'Se gestionan en Servicios');
  String get openServices => _t('Open Services', 'Abrir Servicios');

  // Trips list.
  String get newTrip => _t('New trip', 'Nuevo viaje');
  String get noTrips => _t('No trips yet', 'Aún no hay viajes');
  String get pickup => _t('Pickup', 'Recogida');
  String get guestVilla => _t('Guest · Villa', 'Huésped · Villa');
  String get type => _t('Type', 'Tipo');
  String get flight => _t('Flight', 'Vuelo');
  String get providerDriver => _t('Provider / Driver', 'Proveedor / Chofer');
  String get status => _t('Status', 'Estado');
  String get dates => _t('Dates', 'Fechas');
  String get provider => _t('Provider', 'Proveedor');
  String get unconfirmed => _t('Unconfirmed', 'Sin confirmar');
  String get unconfirmedInfo => _t(
      'Pickup is close and the trip is not confirmed.',
      'La recogida es pronto y el viaje no está confirmado.');
  String get todayTomorrow => _t('Today + tomorrow', 'Hoy y mañana');
  String get today => _t('Today', 'Hoy');
  String get tomorrow => _t('Tomorrow', 'Mañana');
  String get next7Days => _t('Next 7 days', 'Próximos 7 días');
  String get last7Days => _t('Last 7 days', 'Últimos 7 días');
  String get timeZoneMissing =>
      _t('Time zone not set', 'Zona horaria sin configurar');
  String get alertLeadMissing =>
      _t('Trip alert not set', 'Alerta de viaje sin configurar');
  String get settingsMissing =>
      _t('Settings incomplete', 'Ajustes incompletos');
  String get setUpInSettings =>
      _t('Set up in Settings', 'Configurar en Ajustes');

  String typeLabel(String type) => switch (type) {
        'ARRIVAL' => _t('Arrival', 'Llegada'),
        'DEPARTURE' => _t('Departure', 'Salida'),
        'LOCAL' => _t('Local', 'Local'),
        _ => type,
      };

  // Detail.
  String get guest => _t('Guest', 'Huésped');
  String get villa => _t('Villa', 'Villa');
  String get airport => _t('Airport', 'Aeropuerto');
  String get route => _t('Route', 'Ruta');
  String get passengers => _t('Passengers', 'Pasajeros');
  String get luggage => _t('Luggage', 'Maletas');
  String get service => _t('Service', 'Servicio');
  String get vehicle => _t('Vehicle', 'Vehículo');
  String get driver => _t('Driver', 'Chofer');
  String get notes => _t('Staff notes', 'Notas internas');
  String get guestNotes => _t('Guest notes', 'Notas del huésped');
  String get createdBy => _t('Created by', 'Creado por');
  String get byGuest => _t('Guest', 'Huésped');
  String get byStaff => _t('Staff', 'Staff');
  String get history => _t('History', 'Historial');
  String get reason => _t('Reason', 'Motivo');
  String get roundTrip => _t('Round trip', 'Ida y vuelta');
  String get waitMinutes => _t('Wait (min)', 'Espera (min)');
  String get actions => _t('Actions', 'Acciones');

  // Status actions.
  String get sendToProvider => _t('Send to provider', 'Enviar al proveedor');
  String get confirm => _t('Confirm', 'Confirmar');
  String get enRoute => _t('En route', 'En camino');
  String get complete => _t('Complete', 'Completar');
  String get cancelTrip => _t('Cancel trip', 'Cancelar viaje');
  String get back => _t('Back', 'Volver');
  String get noActiveProviders =>
      _t('No active providers', 'Sin proveedores activos');
  String get driverName => _t('Driver name', 'Nombre del chofer');
  String get driverPhone => _t('Driver phone', 'Teléfono del chofer');
  String get vehicleDescription => _t('Vehicle', 'Vehículo');
  String get plate => _t('Plate', 'Placa');
  String get tripCancelled => _t('Trip cancelled', 'Viaje cancelado');
  String movedTo(String status) => _t('Trip · $status', 'Viaje · $status');
  String get actionFailed => _t("Couldn't update", 'No se pudo actualizar');

  /// Short step labels of the status stepper.
  String stepLabel(String status) => switch (status) {
        'REQUESTED' => _t('Requested', 'Solicitado'),
        'SENT_TO_PROVIDER' => _t('Sent', 'Enviado'),
        'CONFIRMED' => _t('Confirmed', 'Confirmado'),
        'EN_ROUTE' => _t('En route', 'En camino'),
        'COMPLETED' => _t('Completed', 'Completado'),
        _ => status,
      };

  /// The button that moves a trip to [next].
  String actionFor(String next) => switch (next) {
        'SENT_TO_PROVIDER' => sendToProvider,
        'CONFIRMED' => confirm,
        'EN_ROUTE' => enRoute,
        'COMPLETED' => complete,
        _ => next,
      };

  // New trip form.
  String get stay => _t('Guest stay', 'Estancia');
  String get stayInfo => _t('Search an upcoming or in-house guest.',
      'Busca un huésped por llegar o en estancia.');
  String get pickStay => _t('Pick a stay', 'Elige una estancia');
  String get noTransportServices =>
      _t('No transport services', 'Sin servicios de transporte');
  String get anyVehicle => _t('Any vehicle', 'Cualquier vehículo');
  String get airline => _t('Airline', 'Aerolínea');
  String get flightNumber => _t('Flight number', 'Número de vuelo');
  String get flightTime => _t('Flight time', 'Hora del vuelo');
  String get pickupInfoAirport => _t(
      'Resort time. Leave empty to use the suggested pickup.',
      'Hora del resort. Vacío usa la recogida sugerida.');
  String get pickupInfoLocal => _t('Resort time.', 'Hora del resort.');
  String get origin => _t('Origin', 'Origen');
  String get destination => _t('Destination', 'Destino');
  String get noAirports => _t('No airports', 'Sin aeropuertos');
  String get dateTimeFormat =>
      _t('Use YYYY-MM-DD HH:mm', 'Usa AAAA-MM-DD HH:mm');
  String get dateTimeHint => 'YYYY-MM-DD HH:mm';
  String get pickDateTime => _t('Pick date and time', 'Elegir fecha y hora');
  String get none => _t('None', 'Ninguno');
  String get atLeastOne => _t('At least 1', 'Mínimo 1');
  String get wholeNumber => _t('Whole number', 'Número entero');
  String overCapacity(int max) => _t('Max $max', 'Máx. $max');
  String tripCreated(String pickup) =>
      _t('Trip created · Pickup $pickup', 'Viaje creado · Recogida $pickup');

  // Providers.
  String get newProvider => _t('New provider', 'Nuevo proveedor');
  String get noProviders => _t('No providers yet', 'Aún no hay proveedores');
  String get name => _t('Name', 'Nombre');
  String get phone => _t('Phone', 'Teléfono');
  String get email => _t('Email', 'Email');
  String get active => _t('Active', 'Activo');
  String get inactive => _t('Inactive', 'Inactivo');
  String get yes => _t('Yes', 'Sí');
  String get no => _t('No', 'No');
  String get invalidEmail => _t('Invalid email', 'Email no válido');
  String get providerSaved => _t('Provider saved', 'Proveedor guardado');
  String get deactivate => _t('Deactivate', 'Desactivar');
  String get activate => _t('Activate', 'Activar');
  String deactivateQ(String name) =>
      _t('Deactivate $name?', '¿Desactivar $name?');
  String activateQ(String name) => _t('Activate $name?', '¿Activar $name?');
  String get providerDeactivated =>
      _t('Provider deactivated', 'Proveedor desactivado');
  String get providerActivated =>
      _t('Provider activated', 'Proveedor activado');
  String get saveFailed => _t("Couldn't save", 'No se pudo guardar');
  String get cancel => _t('Cancel', 'Cancelar');
}
