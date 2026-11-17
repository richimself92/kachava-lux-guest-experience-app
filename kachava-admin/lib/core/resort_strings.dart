/// EN/ES copy of the Settings and Villas screens. Labels are 1-3 words;
/// explanations live in ⓘ tooltips; inline errors are <= 5 words.
class ResortStrings {
  const ResortStrings(this.isEs);

  final bool isEs;

  String _t(String en, String es) => isEs ? es : en;

  // Shared.
  String get save => _t('Save', 'Guardar');
  String get notSet => _t('Not set', 'Sin configurar');
  String get name => _t('Name', 'Nombre');
  String get active => _t('Active', 'Activo');
  String get edit => _t('Edit', 'Editar');
  String get remove => _t('Remove', 'Quitar');
  String get cancel => _t('Cancel', 'Cancelar');
  String get more => _t('More', 'Más');
  String get actions => _t('Actions', 'Acciones');
  String get saveFailed => _t("Couldn't save", 'No se pudo guardar');
  String get wholeNumber => _t('Whole number', 'Número entero');
  String hoursRange(num min, num max) =>
      _t('$min to $max hours', 'De $min a $max horas');

  // Settings.
  String get settings => _t('Settings', 'Ajustes');
  String get settingsSaved => _t('Settings saved', 'Ajustes guardados');
  String get checkIn => _t('Check-in', 'Entrada');
  String get checkOut => _t('Check-out', 'Salida');
  String get pickTime => _t('Pick time', 'Elegir hora');
  String get timeFormat => _t('Use HH:mm', 'Usa HH:mm');
  String get timeZone => _t('Time zone', 'Zona horaria');
  String get pickListedZone => _t('Pick a listed zone', 'Elige una zona');
  String get alertLead => _t('Trip alert (h)', 'Alerta de viaje (h)');
  String get alertLeadInfo => _t(
      'Alert when a trip this many hours away is still unconfirmed.',
      'Alerta si un viaje a estas horas sigue sin confirmar.');
  String get airports => _t('Airports', 'Aeropuertos');
  String get noAirports => _t('No airports', 'Sin aeropuertos');
  String get addAirport => _t('Add airport', 'Agregar aeropuerto');
  String get editAirport => _t('Edit airport', 'Editar aeropuerto');
  String get code => _t('Code', 'Código');
  String get codeFormat => _t('3 capital letters', '3 letras mayúsculas');
  String get codeTaken => _t('Code already added', 'Código ya agregado');
  String get buffer => _t('Buffer (h)', 'Margen (h)');
  String get bufferInfo => _t('Hours before the flight the pickup leaves.',
      'Horas antes del vuelo en que sale el traslado.');
  String get inactive => _t('Inactive', 'Inactivo');
  String removeAirportQ(String code) => _t('Remove $code?', '¿Quitar $code?');
  String get setUpInSettings =>
      _t('Set up in Settings', 'Configurar en Ajustes');
  String get timeZoneMissing =>
      _t('Time zone not set', 'Zona horaria sin configurar');

  // Villas.
  String get villas => _t('Villas', 'Villas');
  String get newVilla => _t('New villa', 'Nueva villa');
  String get noVillas => _t('No villas yet', 'Aún no hay villas');
  String get villasInfo => _t('Inventory, status and housekeeping per villa.',
      'Inventario, estado y limpieza de cada villa.');
  String get category => _t('Category', 'Categoría');
  String get capacity => _t('Capacity', 'Capacidad');
  String get capacityInfo => _t('Maximum guests.', 'Máximo de huéspedes.');
  String capacityRange(int max) =>
      _t('1 to $max guests', 'De 1 a $max huéspedes');
  String get status => _t('Status', 'Estado');
  String get housekeeping => _t('Housekeeping', 'Limpieza');
  String get maintenance => _t('Maintenance', 'Mantenimiento');
  String get maintenanceNote => _t('Maintenance note', 'Nota de mantenimiento');
  String get currentGuest => _t('Current guest', 'Huésped actual');
  String get wifiNetwork => _t('Wi-Fi network', 'Red Wi-Fi');
  String get wifiPassword => _t('Wi-Fi password', 'Clave Wi-Fi');
  String get showPassword => _t('Show password', 'Mostrar clave');
  String get hidePassword => _t('Hide password', 'Ocultar clave');
  String get villaInactive => _t('Inactive', 'Inactiva');
  String get villaActiveFilter => _t('Active', 'Activa');
  String get yes => _t('Yes', 'Sí');
  String get no => _t('No', 'No');
  String get villaSaved => _t('Villa saved', 'Villa guardada');
  String get deactivate => _t('Deactivate', 'Desactivar');
  String get activate => _t('Activate', 'Activar');
  String get delete => _t('Delete', 'Eliminar');
  String deactivateQ(String name) =>
      _t('Deactivate $name?', '¿Desactivar $name?');
  String activateQ(String name) => _t('Activate $name?', '¿Activar $name?');
  String deleteQ(String name) => _t('Delete $name?', '¿Eliminar $name?');
  String get villaDeactivated => _t('Villa deactivated', 'Villa desactivada');
  String get villaActivated => _t('Villa activated', 'Villa activada');
  String get villaDeleted => _t('Villa deleted', 'Villa eliminada');
  String get hasStays =>
      _t('Has stays · Deactivate instead', 'Tiene estancias · Desactívala');
}
