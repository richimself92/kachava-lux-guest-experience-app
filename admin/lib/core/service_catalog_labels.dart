import '../domain/admin_service.dart';

/// EN/ES labels of catalog enums, type-specific fields and prices. Raw wire
/// values (`VILLA_STOCKING`) are never shown.
class ServiceCatalogLabels {
  const ServiceCatalogLabels(this.isEs);

  final bool isEs;

  String _t(String en, String es) => isEs ? es : en;

  String section(ServiceSection s) => switch (s) {
        ServiceSection.inVilla => _t('In-villa', 'En villa'),
        ServiceSection.dining => _t('Dining', 'Gastronomía'),
        ServiceSection.experiences => _t('Experiences', 'Experiencias'),
        ServiceSection.wellness => _t('Wellness', 'Bienestar'),
        ServiceSection.transportation => _t('Transportation', 'Transporte'),
      };

  String kind(ServiceKind k) => switch (k) {
        ServiceKind.bar => 'Lux bar',
        ServiceKind.breakfast => _t('Breakfast', 'Desayuno'),
        ServiceKind.specialMenu => _t('Special menu', 'Menú especial'),
        ServiceKind.villaStocking => _t('Villa stocking', 'Abastecimiento'),
        ServiceKind.experience => _t('Experience', 'Experiencia'),
        ServiceKind.wellness => _t('Wellness', 'Bienestar'),
        ServiceKind.preference => _t('Preference', 'Preferencia'),
        ServiceKind.transport => _t('Transport', 'Transporte'),
      };

  String usage(UsageType u) => switch (u) {
        UsageType.order => _t('Order', 'Pedido'),
        UsageType.booking => _t('Booking', 'Reserva'),
        UsageType.preference => _t('Preference', 'Preferencia'),
        UsageType.trip => _t('Trip', 'Viaje'),
      };

  String pricingMode(PricingMode m) => switch (m) {
        PricingMode.included => _t('Included', 'Incluido'),
        PricingMode.fixed => _t('Fixed', 'Fijo'),
        PricingMode.perPerson => _t('Per person', 'Por persona'),
        PricingMode.perUnit => _t('Per unit', 'Por unidad'),
        PricingMode.perHour => _t('Per hour', 'Por hora'),
        PricingMode.onRequest => _t('On request', 'A consultar'),
      };

  String weekday(Weekday d) => switch (d) {
        Weekday.mon => _t('Mon', 'Lun'),
        Weekday.tue => _t('Tue', 'Mar'),
        Weekday.wed => _t('Wed', 'Mié'),
        Weekday.thu => _t('Thu', 'Jue'),
        Weekday.fri => _t('Fri', 'Vie'),
        Weekday.sat => _t('Sat', 'Sáb'),
        Weekday.sun => _t('Sun', 'Dom'),
      };

  String offeredWhen(OfferedWhen o) => switch (o) {
        OfferedWhen.beforeArrival => _t('Before arrival', 'Antes de llegar'),
        OfferedWhen.duringStay => _t('During stay', 'Durante la estancia'),
        OfferedWhen.both => _t('Both', 'Ambos'),
      };

  /// Departments of `operation.responsibleDepartment`.
  static const List<String> departments = [
    'CONCIERGE',
    'CULINARY',
    'MARINE',
    'TRANSPORT',
    'HOUSEKEEPING',
    'ENGINEERING',
    'WELLNESS',
  ];

  String department(String wire) => switch (wire) {
        'CONCIERGE' => 'Resort Host',
        'CULINARY' => _t('Culinary', 'Cocina'),
        'MARINE' => _t('Marine', 'Marina'),
        'TRANSPORT' => _t('Transport', 'Transporte'),
        'HOUSEKEEPING' => _t('Housekeeping', 'Limpieza'),
        'ENGINEERING' => _t('Engineering', 'Mantenimiento'),
        'WELLNESS' => _t('Wellness', 'Bienestar'),
        _ => wire,
      };

  /// Type-specific field label.
  String kindField(String key) => switch (key) {
        'ageConfirmationRequired' => _t('Age check', 'Verificar edad'),
        'pairingAvailable' => _t('Pairing', 'Maridaje'),
        'maxPerItem' => _t('Max per item', 'Máx. por ítem'),
        'orderDeadlineHoursBeforeCheckIn' => _t('Deadline (h)', 'Límite (h)'),
        'itinerary' => _t('Itinerary', 'Itinerario'),
        'meetingPoint' => _t('Meeting point', 'Punto de encuentro'),
        'languages' => _t('Languages', 'Idiomas'),
        'minAge' => _t('Min age', 'Edad mínima'),
        'location' => _t('Location', 'Lugar'),
        'healthQuestions' => _t('Health questions', 'Preguntas de salud'),
        'contraindications' => _t('Contraindications', 'Contraindicaciones'),
        'selection' => _t('Selection', 'Selección'),
        'changeDeadlineHours' => _t('Change until (h)', 'Cambio hasta (h)'),
        'airportCodes' => _t('Airports', 'Aeropuertos'),
        'priceBasis' => _t('Price basis', 'Base de precio'),
        'flightDetailsRequired' => _t('Flight required', 'Vuelo obligatorio'),
        _ => key,
      };

  /// ⓘ text for fields whose label needs it, else `null`.
  String? kindFieldTip(String key) => switch (key) {
        'ageConfirmationRequired' => _t('Guests confirm drinking age.',
            'El huésped confirma su mayoría de edad.'),
        'orderDeadlineHoursBeforeCheckIn' =>
          _t('Hours before check-in.', 'Horas antes del check-in.'),
        'languages' =>
          _t('ISO codes, e.g. en, es.', 'Códigos ISO, p. ej. en, es.'),
        'changeDeadlineHours' =>
          _t('Hours before arrival.', 'Horas antes de la llegada.'),
        'airportCodes' => _t('IATA codes set in Settings.',
            'Códigos IATA definidos en Ajustes.'),
        _ => null,
      };

  String option(String wire) => switch (wire) {
        'VILLA' => 'Villa',
        'SPA' => 'Spa',
        'BOTH' => _t('Both', 'Ambos'),
        'SINGLE' => _t('Single', 'Única'),
        'MULTIPLE' => _t('Multiple', 'Múltiple'),
        'PER_TRIP' => _t('Per trip', 'Por trayecto'),
        'PER_VEHICLE' => _t('Per vehicle', 'Por vehículo'),
        _ => wire,
      };

  /// `$1,234.50 USD`; `—` when unknown.
  String money(double? amount) {
    if (amount == null) return '—';
    final fixed = amount.toStringAsFixed(2);
    final dot = fixed.indexOf('.');
    final whole = fixed.substring(0, dot);
    final grouped = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) grouped.write(',');
      grouped.write(whole[i]);
    }
    return '\$$grouped${fixed.substring(dot)} USD';
  }

  /// Price column: "Included", "$40.00 USD / person", "Per item"...
  String price(AdminService service) {
    final p = service.pricing;
    if (!p.mode.hasAmount) return pricingMode(p.mode);
    if (p.amount == null) return _t('Per item', 'Por ítem');
    final suffix = switch (p.mode) {
      PricingMode.perPerson => _t(' / person', ' / persona'),
      PricingMode.perUnit => _t(' / unit', ' / unidad'),
      PricingMode.perHour => _t(' / hour', ' / hora'),
      _ => '',
    };
    return '${money(p.amount)}$suffix';
  }
}
