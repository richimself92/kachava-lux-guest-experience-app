import '../../domain/catalog.dart';
import '../../domain/forms.dart';
import '../../domain/requests.dart';

enum Lang { en, es }

/// Every visible portal string, EN/ES. Labels are 1-3 words; explanations
/// live in tooltips. Catalog content comes from the admin, never from here.
class L10n {
  const L10n(this.lang);

  final Lang lang;
  bool get es => lang == Lang.es;
  String _t(String en, String esText) => es ? esText : en;

  /// Admin text in the current language; a missing Spanish text is never
  /// auto-translated.
  String text(LocalizedText value) {
    if (value.isEmpty) return '';
    if (!es) return value.en.isNotEmpty ? value.en : value.es;
    return value.es.isNotEmpty ? value.es : translationPending;
  }

  String get translationPending =>
      _t('Translation pending', 'Traducción pendiente');

  // Tabs & titles
  String get tabHome => _t('Home', 'Inicio');
  String get tabServices => _t('Services', 'Servicios');
  String get tabRequests => _t('Requests', 'Solicitudes');
  String get tabHost => _t('Host', 'Host');
  String get myRequests => _t('My requests', 'Mis solicitudes');
  String get resortHost => 'Resort Host';
  String get languageToggle => _t('Language', 'Idioma');

  // Access & loading
  String get accessTitle => _t('Guest access', 'Acceso de huésped');
  String get linkMissing => _t('Open the link from your Resort Host.',
      'Abre el enlace de tu Resort Host.');
  String get linkInvalid => _t('This link is not valid. Ask your Resort Host.',
      'Este enlace no es válido. Pide uno a tu Resort Host.');
  String get linkExpired => _t(
      'Your link has expired. Ask your Resort Host for a new one.',
      'Tu enlace expiró, pide uno nuevo a tu Resort Host.');
  String get loading => _t('Loading', 'Cargando');
  String get reconnecting => _t('Reconnecting…', 'Reconectando…');
  String get retry => _t('Retry', 'Reintentar');
  String get loadFailed => _t("Couldn't load", 'No se pudo cargar');
  String get installAppHint =>
      _t('Add Kachava to your phone', 'Agrega Kachava a tu teléfono');
  String get installAppAction => _t('Install app', 'Instalar app');
  String get installIosGuide => _t('Tap Share → Add to Home Screen',
      'Toca Compartir → Agregar a pantalla de inicio');
  String get dismiss => _t('Dismiss', 'Cerrar');

  // Home
  String get wifi => 'Wi-Fi';
  String get wifiCopied => _t('Wi-Fi password copied', 'Clave Wi-Fi copiada');
  String get copyFailed => _t("Couldn't copy", 'No se pudo copiar');
  String stepTitle(int step) => switch (step) {
        1 => _t('Before arrival', 'Antes de llegar'),
        2 => _t('During stay', 'Durante tu estancia'),
        _ => _t('Departure', 'Tu salida'),
      };
  String progress(int done, int total) =>
      _t('$done of $total', '$done de $total');
  String opens(DateTime? day) => day == null
      ? _t('Opens later', 'Abre después')
      : _t('Opens ${date(day)}', 'Abre ${date(day)}');
  String get lockedInfo => _t('You can do these tasks when this step opens.',
      'Podrás hacer estas tareas cuando abra este paso.');
  String get allSet => _t('All set ✓', 'Todo listo ✓');
  String next(String number, String name) =>
      _t('Next: $number $name', 'Siguiente: $number $name');
  String get notNow => _t('Not now', 'Ahora no');
  String get skipped => _t('Skipped', 'Omitida');
  String get draft => _t('Draft', 'Borrador');
  String get pending => _t('Pending', 'Pendiente');
  String get done => _t('Done', 'Lista');
  String seeAll(int n) => _t('See all $n', 'Ver todas ($n)');
  String get showLess => _t('Show less', 'Ver menos');
  String stepSemantics(int step, int done, int total, bool expanded) => _t(
      'Step $step of 3, $done of $total done, ${expanded ? 'expanded' : 'collapsed'}',
      'Paso $step de 3, $done de $total listas, ${expanded ? 'abierto' : 'cerrado'}');
  String get ownTransport => _t('Own transport', 'Transporte propio');
  String get arrangeOwn => _t('I arrange my own', 'Lo organizo yo');

  // Core tasks
  String get taskFlight => _t('Flight & transfer', 'Vuelo y traslado');
  String get taskPreferences => _t('Preferences', 'Preferencias');
  String get taskDeparture => _t('Departure transfer', 'Traslado de salida');
  String get taskRating => _t('Rate your stay', 'Califica tu estancia');

  String section(String key) => switch (key) {
        'IN_VILLA' => _t('In villa', 'En la villa'),
        'DINING' => _t('Dining', 'Gastronomía'),
        'EXPERIENCES' => _t('Experiences', 'Experiencias'),
        'WELLNESS' => _t('Wellness', 'Bienestar'),
        'TRANSPORTATION' => _t('Transport', 'Transporte'),
        _ => key,
      };

  // Services
  String get search => _t('Search', 'Buscar');
  String get all => _t('All', 'Todo');
  String get when => _t('When', 'Cuándo');
  String get whenAny => _t('Any', 'Cualquiera');
  String get whenBefore => _t('Before', 'Antes');
  String get whenDuring => _t('During', 'Durante');
  String servicesCount(int n) => _t('$n services', '$n servicios');
  String get noResults => _t('No results', 'Sin resultados');
  String get clear => _t('Clear', 'Limpiar');
  String get nothingYet => _t('Nothing yet', 'Nada aún');
  String get askHost => _t('Ask Host', 'Preguntar al Host');
  String showMore(int n) => _t('Show $n more', 'Ver $n más');
  String get more => _t('More', 'Más');
  String get close => _t('Close', 'Cerrar');
  String get includes => _t('Includes', 'Incluye');
  String get bring => _t('Bring', 'Llevar');
  String get meetingPoint => _t('Meeting point', 'Punto de encuentro');
  String get rules => _t('Rules', 'Reglas');
  String get actionOrder => _t('Order', 'Pedir');
  String get actionBook => _t('Book', 'Reservar');
  String get actionChoose => _t('Choose', 'Elegir');
  String get actionPlanTrip => _t('Plan trip', 'Planear viaje');
  String get unavailable => _t('Not available', 'No disponible');
  String get noItems => _t('No options yet', 'Sin opciones aún');
  String photoOf(int i, int n) => '$i/$n';

  String price(ServicePricing p, (double, double)? range) {
    String usd(double v) =>
        '\$${v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2)}';
    if (p.mode == PricingMode.included) return _t('Included ✓', 'Incluido ✓');
    if (p.mode == PricingMode.onRequest) return _t('On request', 'A consultar');
    final base = p.amount != null
        ? usd(p.amount!)
        : range == null
            ? null
            : range.$1 == range.$2
                ? usd(range.$1)
                : '${usd(range.$1)}-${usd(range.$2).substring(1)}';
    if (base == null) return _t('On request', 'A consultar');
    return switch (p.mode) {
      PricingMode.perPerson => _t('$base / person', '$base / persona'),
      PricingMode.perUnit => _t('$base / item', '$base / unidad'),
      PricingMode.perHour => _t('$base / hour', '$base / hora'),
      _ => '$base USD',
    };
  }

  String money(double v) =>
      '\$${v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2)} USD';

  String leadTime(int? hours) {
    if (hours == null || hours <= 0) return '';
    return _t('$hours h ahead', '$hours h antes');
  }

  // Forms
  String stepOf(int page, int pages) =>
      _t('Step $page of $pages', 'Paso $page de $pages');
  String get nextPage => _t('Next', 'Siguiente');
  String get back => _t('Back', 'Atrás');
  String get review => _t('Review', 'Revisar');
  String get edit => _t('Edit', 'Editar');
  String get saveExit => _t('Save & exit', 'Guardar y salir');
  String get sending => _t('Sending…', 'Enviando…');
  String get send => _t('Send', 'Enviar');
  String get save => _t('Save', 'Guardar');
  String get dateLabel => _t('Date', 'Fecha');
  String get timeLabel => _t('Time', 'Hora');
  String get people => _t('People', 'Personas');
  String get notes => _t('Notes', 'Notas');
  String get diet => _t('Diet', 'Dieta');
  String get allergies => _t('Allergies', 'Alergias');
  String get none => _t('None', 'Ninguna');
  String get health => _t('Health', 'Salud');
  String get pickDate => _t('Pick date', 'Elegir fecha');
  String get ageConfirm => _t('I am 18 or older', 'Tengo 18 años o más');
  String itemsTotal(int count, String total) =>
      _t('$count items · $total', '$count artículos · $total');
  String changeUntil(String when) =>
      _t('Change until $when', 'Cambia hasta $when');
  String get airport => _t('Airport', 'Aeropuerto');
  String get airline => _t('Airline', 'Aerolínea');
  String get flightNo => _t('Flight no.', 'N.º de vuelo');
  String get terminalOpt => _t('Terminal (optional)', 'Terminal (opcional)');
  String get from => _t('From', 'Desde');
  String get to => _t('To', 'Hasta');
  String get passengers => _t('Passengers', 'Pasajeros');
  String get bags => _t('Bags', 'Maletas');
  String get vehicle => _t('Vehicle', 'Vehículo');
  String get pageWhen => _t('When', 'Cuándo');
  String get pageFlight => _t('Flight', 'Vuelo');
  String get pageRoute => _t('Route', 'Ruta');
  String get pageGroup => _t('Group', 'Grupo');
  String get pickupInfo => _t(
      'The resort sets the pickup time from your flight.',
      'El resort fija la hora de recogida según tu vuelo.');
  String get dietInfo =>
      _t('Choose None if nothing applies.', 'Elige Ninguna si no aplica.');
  String get rating => _t('Rating', 'Calificación');
  String stars(int n) => _t('$n of 5 stars', '$n de 5 estrellas');
  String get rateInfo => _t('Optional. Goes only to your Resort Host.',
      'Opcional. Solo la ve tu Resort Host.');
  String seats(int n) => _t('$n seats', '$n plazas');
  String get sendTrip => send;
  String get pickupAt => _t('Pickup', 'Recogida');

  String issue(FormIssue i) => switch (i) {
        FormIssue.required => _t('Required', 'Obligatorio'),
        FormIssue.invalidTime => _t('Use HH:MM', 'Usa HH:MM'),
        FormIssue.pastTime => _t('Must be in the future', 'Debe ser futura'),
        FormIssue.tooSoon => _t('Too soon to book', 'Muy pronto'),
        FormIssue.dayUnavailable =>
          _t('Day not available', 'Día no disponible'),
        FormIssue.notServed =>
          _t('Airport not served', 'Aeropuerto no atendido'),
        FormIssue.overCapacity =>
          _t('Too many for vehicle', 'Excede el vehículo'),
        FormIssue.tooManyBags => _t('Too many bags', 'Demasiadas maletas'),
        FormIssue.tooFewGuests => _t('Too few people', 'Muy pocas personas'),
        FormIssue.tooManyGuests => _t('Too many people', 'Demasiadas personas'),
        FormIssue.ageRequired => _t('Confirm your age', 'Confirma tu edad'),
        FormIssue.emptyCart => _t('Add an item', 'Agrega un artículo'),
      };

  // Results
  String get orderSent => _t('Order sent', 'Pedido enviado');
  String get bookingSent => _t('Booking sent', 'Reserva enviada');
  String get choiceSaved => _t('Choice saved', 'Elección guardada');
  String get tripSent => _t('Trip sent', 'Viaje enviado');
  String get preferencesSaved =>
      _t('Preferences saved', 'Preferencias guardadas');
  String get ratingSent => _t('Thanks for rating', 'Gracias por calificar');
  String get messageSent => _t('Message sent', 'Mensaje enviado');
  String get sendFailed => _t("Couldn't send", 'No se pudo enviar');
  String get notConfigured => _t('Not available yet', 'Aún no disponible');
  String get checkDetails => _t('Check the details', 'Revisa los datos');

  // Requests
  String get chipActive => _t('Active', 'Activas');
  String get chipDone => _t('Done', 'Listas');
  String get noRequests => _t('No requests', 'Sin solicitudes');
  String get browseServices => _t('Browse services', 'Ver servicios');
  String guests(int n) => _t('$n guests', '$n personas');
  String get requestFallback => _t('Request', 'Solicitud');
  String get arrivalTrip => _t('Arrival transfer', 'Traslado de llegada');
  String get departureTrip => _t('Departure transfer', 'Traslado de salida');
  String get localTrip => _t('Local trip', 'Viaje local');
  String get total => 'Total';
  String get changeInfo => _t('To change or cancel, ask your Resort Host.',
      'Para cambiar o cancelar, pregunta a tu Resort Host.');
  String get change => _t('Change', 'Cambiar');

  String status(RequestStatus s) => switch (s) {
        RequestStatus.received => _t('Received', 'Recibida'),
        RequestStatus.confirmed => _t('Confirmed', 'Confirmada'),
        RequestStatus.preparing => _t('Preparing', 'En preparación'),
        RequestStatus.onTheWay => _t('On the way', 'En camino'),
        RequestStatus.done => _t('Done', 'Lista'),
        RequestStatus.cancelled => _t('Cancelled', 'Cancelada'),
      };

  // Host chat
  String get message => _t('Message', 'Mensaje');
  String get attachPhoto => _t('Attach photo', 'Adjuntar foto');
  String get removePhoto => _t('Remove photo', 'Quitar foto');
  String get photo => _t('Photo', 'Foto');
  String get noMessages => _t('No messages yet', 'Sin mensajes aún');
  String get you => _t('You', 'Tú');

  // Dates
  static const _monthsEn = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  static const _monthsEs = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic'
  ];

  /// "Nov 3" / "3 nov".
  String date(DateTime day) => es
      ? '${day.day} ${_monthsEs[day.month - 1]}'
      : '${_monthsEn[day.month - 1]} ${day.day}';

  /// "7 PM" / "19:00" style is kept as 24h HH:mm in both languages.
  String clock(DateTime wall) =>
      '${wall.hour.toString().padLeft(2, '0')}:${wall.minute.toString().padLeft(2, '0')}';
}
