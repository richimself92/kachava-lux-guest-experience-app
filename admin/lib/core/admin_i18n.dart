import '../domain/admin_enums.dart';

/// Supported bilingual locales for the Admin Dashboard (English default & Español).
enum AdminLocale { en, es }

/// Bilingual lookup helper for all Admin Dashboard navigation, headers, filters, and dialogs.
class AdminI18n {
  const AdminI18n._();

  static bool currentIsEs = false;

  static const Map<String, String> _esStatusMap = {
    'All': 'Todos',
    'Pending': 'Pendiente',
    'Assigned': 'En Preparación',
    'Stocked in Villa': 'Entregado en Villa',
    'CHILLED IN LARDER': 'En Refrigerador',
    'SUB-ZERO CHILLED': 'Cava Fría',
    'DRY BAR PRESENTATION': 'En Barra / Mesa',
    'ACTIVE_STAY': 'En Estancia',
    'PRE_ARRIVAL': 'Por Llegar',
    'CHECKED_OUT': 'Salida / Villa Libre',
    'EXPIRED': 'Expirado',
    'Scheduled': 'Programado',
    'En Route': 'En Camino',
    'At Terminal Bay': 'En Terminal',
    'Completed': 'Completado',
    'Confirmed': 'Confirmado',
    'Cancelled': 'Cancelado',
    'CONFIRMED · ACKNOWLEDGED': 'Atendida',
    'ATTENDED BY HOST ADMIN': 'ATENDIDA POR HOST ADMIN',
    'URGENT': 'Urgente',
    'HIGH': 'Prioridad Alta',
    'NORMAL': 'Normal',
    'Requested': 'Recibido',
    'In Progress': 'En Proceso',
    'Yacht Charters': 'Yates',
    'Private Dining': 'Cenas Privadas',
    'Excursions': 'Excursiones',
    'Included Privileges': 'Beneficios Incluidos',
    'CONCIERGE': 'Solicitudes',
    'BOOKING': 'Reservas',
    'LARDER': 'Despensa',
    'TRANSFER': 'Traslados',
    'MIDSTAY': 'Comentarios',
    'CHECKOUT': 'Salida',
    'DIETARY': 'Alergias',
  };

  static const Map<String, String> _esTextMap = {
    'Villa 102 reported Air Conditioning issue (Photo attached)':
        'Villa 102 reportó falla de Aire Acondicionado (Foto adjunta)',
    'Master suite chiller reading 73°F instead of 66°F night target. Guest uploaded V4 signed maintenance photo.':
        'Clima de suite principal en 73°F en vez de 66°F nocturno. El huésped adjuntó foto de mantenimiento.',
    'Allergy Caution: Shellfish · Chef & Yacht Crew Briefing':
        'Alerta de Alergia: Mariscos · Aviso a Chef y Tripulación de Yate',
    'Severe shellfish allergy flagged for Fuego y Mar tasting menu and Galeon 470 Sky charter.':
        'Alergia severa a mariscos registrada para cena en Fuego y Mar y recorrido en yate Galeon 470 Sky.',
    'Mid-Stay Pulse (< 7 Min SLA): Pool Terrace Plunge Heat · 86°F':
        'Comentario de Estancia (< 7 Min SLA): Climatizar Alberca · 86°F',
    'Guest submitted "A Detail Could Be Tuned" requesting plunge pool warmed by 2°F for twilight swim.':
        'El huésped solicitó subir 2°F la temperatura de la alberca privada de su terraza para la tarde.',
    'Villa 102 Curated Larder Provisioning (\$128.00 USD)':
        'Pedido de Minibar y Despensa para Villa 102 (\$128.00 USD)',
    '3 curated items across Chilled in Larder, Sub-Zero Chilled, and Dry Bar Presentation awaiting stocking.':
        '3 productos seleccionados para Refrigerador, Cava Fría y Barra listos para entregar en la villa.',
    'Flight AA 1492 Arrival Dispatch · Terminal 3':
        'Llegada de Vuelo AA 1492 · Terminal 3',
    'Mercedes-Benz EQS SUV #04 staged at 71°F with chilled young coconuts for HOST ADMIN.':
        'Camioneta Mercedes-Benz EQS SUV #04 lista a 71°F con cocos fríos asignada a HOST ADMIN.',
    'Aviation Transfer Updated': 'Vuelo y Traslado Actualizado',
    'Stay Preferences Updated': 'Preferencias de Estancia Actualizadas',
    'Dietary & Allergy Update': 'Actualización de Dieta y Alergias',
    'Larder Stocking Order': 'Pedido de Minibar y Despensa',
    'New Booking': 'Nueva Reserva',
    'New Concierge Request': 'Nueva Solicitud de Concierge',
    'New Chat Message': 'Nuevo Mensaje de Chat',
    'Mid-Stay Check-In': 'Comentario de Estancia',
    'Express Checkout': 'Solicitud de Salida Express',
  };

  static const Map<String, String> _esPrefMap = {
    'Goose Down': 'Pluma de Ganso',
    'Plush Goose Down': 'Pluma de Ganso Suave',
    'Memory Foam': 'Memory Foam',
    'Organic Buckwheat & Memory Foam': 'Memory Foam y Trigo Sarraceno',
    'Hypoallergenic Firm': 'Firme Hipoalergénica',
    'Hypoallergenic Micro-Down': 'Micro-Pluma Hipoalergénica',
    'Copal & Amber': 'Copal y Ámbar',
    'Sacred Copal & Amber': 'Copal Sagrado y Ámbar',
    'Mayan Copal': 'Copal Maya',
    'Orange Blossom': 'Flor de Azahar',
    'White Cedar': 'Cedro Blanco',
    'Coastal Cedar & Sea Salt': 'Cedro Costero y Sal de Mar',
    'Yucatán White Jasmine': 'Jazmín Blanco de Yucatán',
    'Fragrance-Free': 'Sin Fragancia',
    'Standard': 'Estándar',
    'Pescatarian': 'Pescatariana',
    'Vegetarian': 'Vegetariana',
    'Vegan': 'Vegana',
    'Gluten-Free': 'Sin Gluten',
    'Gluten Sensitive': 'Sensible al Gluten',
    'Plant-Forward': 'Basada en Plantas',
    'Mediterranean': 'Mediterránea',
    'Evening Service (07:00 PM)': 'Servicio Nocturno (07:00 PM)',
    'On Request': 'A Solicitud',
    'Not selected': 'Sin seleccionar',
  };

  static const Map<String, String> _enFromEsPrefMap = {
    'Servicio Nocturno (07:00 PM)': 'Evening Service (07:00 PM)',
    'A Solicitud': 'On Request',
    'Sin seleccionar': 'Not selected',
    'Pluma de Ganso': 'Goose Down',
    'Pluma de Ganso Suave': 'Plush Goose Down',
    'Memory Foam y Trigo Sarraceno': 'Organic Buckwheat & Memory Foam',
    'Firme Hipoalergénica': 'Hypoallergenic Firm',
    'Micro-Pluma Hipoalergénica': 'Hypoallergenic Micro-Down',
    'Copal y Ámbar': 'Copal & Amber',
    'Copal Sagrado y Ámbar': 'Sacred Copal & Amber',
    'Copal Maya': 'Mayan Copal',
    'Flor de Azahar': 'Orange Blossom',
    'Cedro Blanco': 'White Cedar',
    'Cedro Costero y Sal de Mar': 'Coastal Cedar & Sea Salt',
    'Jazmín Blanco de Yucatán': 'Yucatán White Jasmine',
    'Sin Fragancia': 'Fragrance-Free',
    'Estándar': 'Standard',
    'Pescatariana': 'Pescatarian',
    'Vegetariana': 'Vegetarian',
    'Vegana': 'Vegan',
    'Sin Gluten': 'Gluten-Free',
    'Sensible al Gluten': 'Gluten Sensitive',
    'Basada en Plantas': 'Plant-Forward',
    'Mediterránea': 'Mediterranean',
  };

  static const Map<String, String> _esPhraseMap = {
    'Aviation Transfer Updated': 'Vuelo y Traslado Actualizado',
    'Stay Preferences Updated': 'Preferencias de Estancia Actualizadas',
    'Dietary & Allergy Update': 'Actualización de Dieta y Alergias',
    'Larder Stocking Order': 'Pedido de Minibar y Despensa',
    'New Booking': 'Nueva Reserva',
    'New Concierge Request': 'Nueva Solicitud de Concierge',
    'New Chat Message': 'Nuevo Mensaje de Chat',
    'Mid-Stay Check-In': 'Comentario de Estancia',
    'Express Checkout': 'Solicitud de Salida Express',
    'Pillow:': 'Almohada:',
    'Scent:': 'Aroma:',
    'Cleaning:': 'Limpieza:',
    'Diet:': 'Dieta:',
    'Allergies:': 'Alergias:',
    'Notes:': 'Notas:',
    'Flight ': 'Vuelo ',
    'landing at ': 'aterrizando a las ',
    'artisanal larder items requested': 'productos de minibar solicitados',
    'Scheduled for ': 'Programado para ',
  };

  static String tr(bool isEs, String en, String es) => isEs ? es : en;

  static String translatePref(String raw, bool isEs) {
    final clean = raw.trim();
    if (clean.isEmpty) {
      return isEs ? 'Sin seleccionar' : 'Not selected';
    }
    if (!isEs) {
      return _enFromEsPrefMap[clean] ?? clean;
    }
    return _esPrefMap[clean] ?? clean;
  }

  static String statusLabel(String raw, [bool? isEs]) {
    final useEs = isEs ?? currentIsEs;
    if (!useEs) return raw;
    return _esStatusMap[raw] ?? raw;
  }

  static String translateText(String text, [bool? isEs]) {
    final useEs = isEs ?? currentIsEs;
    if (!useEs) return text;
    final exact = _esTextMap[text];
    if (exact != null) return exact;
    var out = text;
    for (final e in _esPhraseMap.entries) {
      out = out.replaceAll(e.key, e.value);
    }
    for (final e in _esPrefMap.entries) {
      out = out.replaceAll(e.key, e.value);
    }
    return out;
  }

  static String tabLabel(AdminWorkspaceTab tab, bool isEs) {
    if (!isEs) return tab.label;
    switch (tab) {
      case AdminWorkspaceTab.adminOverview:
        return '1. Resumen y Alertas en Vivo';
      case AdminWorkspaceTab.adminStays:
        return '2. Villas, Huéspedes y Crear Link';
      case AdminWorkspaceTab.adminLarder:
        return '3. Pre-Llegada: Minibar y Despensa';
      case AdminWorkspaceTab.adminExperiences:
        return '4. Estancia: Yate, Cenas y Tours';
      case AdminWorkspaceTab.adminConcierge:
        return '5. Estancia: Chat 24/7 y Solicitudes';
      case AdminWorkspaceTab.adminFolio:
        return '6. Resumen de Estancia y Calificación';
    }
  }

  static String tabShortLabel(AdminWorkspaceTab tab, bool isEs) {
    if (!isEs) return tab.shortLabel;
    switch (tab) {
      case AdminWorkspaceTab.adminOverview:
        return '1. Resumen';
      case AdminWorkspaceTab.adminStays:
        return '2. Villas';
      case AdminWorkspaceTab.adminLarder:
        return '3. Despensa';
      case AdminWorkspaceTab.adminExperiences:
        return '4. Tours';
      case AdminWorkspaceTab.adminConcierge:
        return '5. Chat';
      case AdminWorkspaceTab.adminFolio:
        return '6. Resumen';
    }
  }

  static String searchHint(bool isEs) => tr(
        isEs,
        'Search guest, villa, flight, ticket...',
        'Buscar huésped, villa, vuelo, solicitud...',
      );

  static String allVillas(bool isEs) =>
      tr(isEs, 'All Villas', 'Todas las Villas');
  static String urgentOnly(bool isEs) =>
      tr(isEs, 'Urgent Only', 'Solo Urgentes');
  static String activeStay(bool isEs) => tr(isEs, 'Active Stay', 'En Estancia');
  static String preArrival(bool isEs) => tr(isEs, 'Pre-Arrival', 'Por Llegar');

  static String kpiResidencies(bool isEs) =>
      tr(isEs, 'Active Residencies', 'Villas Ocupadas');
  static String kpiConcierge(bool isEs) =>
      tr(isEs, 'Open Concierge Tickets', 'Solicitudes Abiertas');
  static String kpiBookings(bool isEs) =>
      tr(isEs, 'Pending Bookings & Larder', 'Reservas y Minibar Pendientes');
  static String kpiUrgent(bool isEs) =>
      tr(isEs, 'Urgent SLA Alerts', 'Alertas Urgentes');

  static String overviewTitle(bool isEs) => tr(
        isEs,
        'Live Alerts, Arrivals & Command Center',
        'Alertas en Vivo, Llegadas y Centro de Mando',
      );

  static String staysTitle(bool isEs) => tr(
        isEs,
        'Stays, Magic Links & Airport Transfers',
        'Control de Villas, Huéspedes, Links y Traslados',
      );

  static String experiencesTitle(bool isEs) => tr(
        isEs,
        'Yacht, Private Dining, Excursions & Privileges Reservations',
        'Reservas de Yate, Cena Privada, Excursiones y Privilegios',
      );

  static String larderTitle(bool isEs) => tr(
        isEs,
        'Villa Stocking & Larder Provisioning Queue',
        'Pedidos de Bebidas, Frutas y Despensa para Villas',
      );

  static String conciergeTitle(bool isEs) => tr(
        isEs,
        '24/7 Concierge Dispatch, 4-Stage Lifecycle & Live Host Chat',
        'Atención de Solicitudes, Mantenimiento y Chat en Vivo',
      );

  static String folioTitle(bool isEs) => tr(
        isEs,
        'Stay Summary, Acquired Services & Guest Feedback',
        'Resumen de Estancia, Servicios Adquiridos y Calificación',
      );
}
