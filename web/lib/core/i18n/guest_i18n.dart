import '../constants/screen_id.dart';

/// Supported languages in the Kachava Lux Guest Portal (Default: English `en`).
enum GuestLocale { en, es }

/// Bilingual translation helper (`EN | ES`) with clear, guest-friendly terms.
class GuestI18n {
  const GuestI18n(this.locale);

  final GuestLocale locale;

  bool get isEs => locale == GuestLocale.es;

  String t(String en, String es) => isEs ? es : en;

  static String tr(bool isEs, String en, String es) => isEs ? es : en;

  String get navSanctuary => isEs ? 'Inicio' : 'Sanctuary';
  String get navExperiences => isEs ? 'Experiencias' : 'Experiences';
  String get navConcierge => 'Concierge';
  String get navProfile => isEs ? 'Perfil' : 'Profile';

  String screenShortTitle(ScreenId screen) {
    if (!isEs) return screen.shortTitle;
    return _esShortTitles[screen] ?? screen.shortTitle;
  }

  String screenTitle(ScreenId screen) {
    if (!isEs) return screen.title;
    return _esTitles[screen] ?? screen.title;
  }

  String screenSubtitle(ScreenId screen) {
    if (!isEs) return screen.subtitle;
    return _esSubtitles[screen] ?? screen.subtitle;
  }

  String categoryLabel(String raw) =>
      isEs ? (_esCategories[raw] ?? _esOptions[raw] ?? raw) : raw;

  String optionLabel(String raw) =>
      isEs ? (_esOptions[raw] ?? _esContent[raw] ?? raw) : raw;

  String translateContent(String raw) =>
      isEs ? (_esContent[raw] ?? _esOptions[raw] ?? raw) : raw;

  static const Map<String, String> _esOptions = {
    'Goose Down': 'Pluma de Ganso',
    'Memory Foam': 'Espuma Viscoelástica',
    'Hypoallergenic Firm': 'Hipoalergénica Firme',
    'Copal & Amber': 'Copal y Ámbar',
    'Tierra Sagrada · Copal & Amber': 'Tierra Sagrada · Copal y Ámbar',
    'Orange Blossom': 'Flor de Azahar',
    'White Cedar': 'Cedro Blanco',
    'Fragrance-Free': 'Sin Fragancia',
    'Standard': 'Estándar',
    'Pescatarian': 'Pescetariana',
    'Pescatarian & Gluten-Sensitive': 'Pescetariana y Sin Gluten',
    'Vegetarian': 'Vegetariana',
    'Vegan': 'Vegana',
    'Gluten-Free': 'Sin Gluten',
    'Requested': 'Solicitado',
    'Assigned': 'Asignado',
    'In Progress': 'En Proceso',
    'Completed': 'Completado',
    'Thu, Nov 13': 'Jue, 13 Nov',
    'Fri, Nov 14 (Anniversary Night)': 'Vie, 14 Nov (Noche de Aniversario)',
    'Sat, Nov 15': 'Sáb, 15 Nov',
    'Evening Service (07:00 PM)': 'Servicio Nocturno (07:00 PM)',
    'On Request': 'A Solicitud',
  };

  static const Map<String, String> _esContent = {
    'INCLUDED': 'INCLUIDO',
    'Included with Stay': 'Incluido en Estancia',
    'FROM \$380': 'DESDE \$380',
    'FROM \$450': 'DESDE \$450',
    'FROM \$290': 'DESDE \$290',
    '3.5 Hours': '3.5 Horas',
    '90 Min': '90 Min',
    '5 Hours': '5 Horas',
    '18 Holes': '18 Hoyos',
    '3 Hours': '3 Horas',
    '4 Hours': '4 Horas',
    'Sacred Cavern': 'Caverna Sagrada',
    'Villa 102 Terrace & Cenote Deck': 'Terraza de Villa y Deck del Cenote',
    'Sian Ka\'an Reserve': 'Reserva Sian Ka\'an',
    'Championship Course': 'Campo de Campeonato',
    'Tulum Cliffside & Coba': 'Acantilado de Tulum y Cobá',
    'Cenote Dos Ojos Private Dive & Ritual':
        'Inmersión y Ritual Privado en Cenote Dos Ojos',
    'Private dawn access with Mayan copal blessing & dive.':
        'Acceso privado al amanecer con ceremonia de copal maya e inmersión.',
    'Sunrise Cenote Yoga & Mayan Hydrotherapy Circuit':
        'Yoga al Amanecer e Hidroterapia Maya',
    'Warmed Puebla obsidian stones, copal balm & sound bowls.':
        'Piedras tibias de obsidiana, bálsamo de copal y cuencos sonoros.',
    'Sian Ka\'an Biosphere Expedition':
        'Expedición a la Biósfera de Sian Ka\'an',
    'Drift ancient Mayan canals with a resident biologist.':
        'Flota por antiguos canales mayas con un biólogo residente.',
    'El Camaleón & PGA Riviera Maya Championship Golf':
        'Golf de Campeonato El Camaleón y PGA Riviera Maya',
    'Priority sunrise tee times with GPS cart & club rental.':
        'Salidas prioritarias al amanecer con carrito GPS y bastones Callaway.',
    'Tulum & Coba Archaeological Dawn Tour':
        'Tour Arqueológico al Amanecer en Tulum y Cobá',
    'Explore ancient Mayan temples prior to public opening.':
        'Explora templos mayas ancestrales antes de la apertura al público.',
    'Half-Day Guest Experience': 'Experiencia de Medio Día (4 Horas)',
    'Included with 4N+ Stay · \$0 Due (\$2,000 USD Value)':
        'Incluido en Estancia 4N+ · \$0 por Pagar (Valor \$2,000 USD)',
    '4-hour private cruise with champagne lunch & reef swim.':
        'Crucero privado de 4 horas con almuerzo, champagne y nado en arrecife.',
    'Extended Caribbean Experience': 'Travesía Extendida por el Caribe',
    '+\$1,000 USD Stay Upgrade (Valued at \$3,000 USD)':
        '+\$1,000 USD Mejora de Estancia (Valor \$3,000 USD)',
    '6 hours exploring isolated sandbars & golden sunset.':
        '6 horas explorando bancos de arena virgen y atardecer dorado.',
    'Private Full-Day Escape': 'Escapada Privada de Día Completo',
    '+\$2,000 USD Stay Upgrade (Valued at \$4,000 USD)':
        '+\$2,000 USD Mejora de Estancia (Valor \$4,000 USD)',
    '8-hour voyage to Isla Contoy or Cozumel Deep Wall.':
        'Travesía de 8 horas hacia Isla Contoy o el arrecife de Cozumel.',
    'Fuego y Mar Mayan Fire Tasting': 'Degustación Fuego y Mar a la Leña',
    'Recommended for Anniversary · 5-Course Coastal Fire':
        'Recomendado para Aniversario · 5 Tiempos de Fuego Costero',
    'Sommelier Cellar Pairing · Valle de Guadalupe Wines':
        'Maridaje de Cava · Vinos del Valle de Guadalupe',
    'Tierra Sagrada Heritage Menu': 'Menú Ancestral Tierra Sagrada',
    'Ancestral Underground Pib & Heirloom Masa':
        'Horno Subterráneo Pib y Maíz Criollo',
    'Ancestral Mezcal & Biodynamic Orange Wine Flight':
        'Degustación de Mezcal Ancestral y Vino Naranja Biodinámico',
    'Flora Silvestre Botanical Omakase': 'Omakase Botánico Flora Silvestre',
    '100% Plant-Forward Milpa & Cenote Harvest':
        '100% Basado en Plantas de la Milpa y el Cenote',
    'Biodynamic Pet-Nat & Botanical Elixir Pairing':
        'Maridaje de Pet-Nat Biodinámico y Elíxires Botánicos',
    '1. Yellowtail Aguachile & Smoked Lime':
        '1. Aguachile de Jurel y Lima Ahumada',
    '2. Wood-Fired Mayan Octopus & Recado Negro':
        '2. Pulpo Maya a la Leña y Recado Negro',
    '3. Coastal Omakase & Charred Avocado':
        '3. Omakase Costero y Aguacate Tatemado',
    '4. Grilled Catch of the Day with Saffron Emulsion':
        '4. Pesca del Día a las Brasas con Emulsión de Azafrán',
    '5. Chiapas Dark Cacao & Melipona Honey Ganache':
        '5. Ganache de Cacao de Chiapas y Miel Melipona',
    '1. Sikil Pak Pumpkin Seed Dip & Blue Tostadas':
        '1. Sikil Pak de Pepita de Calabaza y Tostadas Azules',
    '2. Squash Blossom & Black Truffle Velouté':
        '2. Velouté de Flor de Calabaza y Trufa Negra',
    '3. Underground Pit-Roasted Heritage Entrée':
        '3. Plato Fuerte Horneado en Pib Tradicional',
    '4. Charred Chayote & Wild Herb Salad':
        '4. Ensalada de Chayote Asado y Hierbas Silvestres',
    '5. Smoked Coconut & Corn Husk Custard':
        '5. Natilla de Coco Ahumado en Hoja de Maíz',
    '1. Smoked Coconut Ceviche & Finger Lime':
        '1. Ceviche de Coco Ahumado y Cítrico Caviar',
    '2. Charred Heirloom Carrot & Copal Oil':
        '2. Zanahoria Criolla Tatemada al Aceite de Copal',
    '3. Wild Mushroom Tamal in Banana Leaf':
        '3. Tamal de Hongos Silvestres en Hoja de Plátano',
    '4. Roasted Mamey Sapote & Cacao Nib Mole':
        '4. Mamey Asado con Mole de Cacao',
    '5. Passionfruit & Hibiscus Sorbet': '5. Sorbete de Maracuyá y Jamaica',
    'Endemic Tropical Fruit Harvest': 'Cosecha de Frutas Tropicales Endémicas',
    'Dragonfruit, golden passionfruit, wild papaya & mamey.':
        'Pitahaya, maracuyá dorado, papaya silvestre y mamey.',
    'Chilled Cold-Pressed Elixirs (Set of 4)':
        'Elíxires Prensados en Frío (Set de 4)',
    'Green jungle detox, golden turmeric, hibiscus & coconut.':
        'Jugo verde detox, cúrcuma dorada, jamaica y agua de coco.',
    'Casa Dragones Joven & Smoked Salt Kit':
        'Tequila Casa Dragones Joven y Sal Ahumada',
    'Small-batch sipping tequila, copal salt & stone copitas.':
        'Tequila artesanal de degustación, sal de copal y copitas de piedra.',
    'GF Sourdough & Melipona Honeycomb':
        'Pan de Masa Madre Sin Gluten y Miel Melipona',
    'Ancient grain loaf with raw stingless Melipona honey.':
        'Hogaza de granos ancestrales con miel virgen de abeja Melipona.',
    'Oaxacan Quesillo & Guacamole Board':
        'Tabla de Quesillo Oaxaqueño y Guacamole',
    'Stone-ground guacamole, chipotle salsa & blue tostadas.':
        'Guacamole en molcajete, salsa de chipotle y tostadas de maíz azul.',
    'Casa Madero Gran Reserva Red Blend': 'Vino Tinto Casa Madero Gran Reserva',
    'Blackberry, cassis, cedarwood & toasted cacao.':
        'Notas de zarzamora, cassis, cedro y cacao tostado.',
    'Organic Sun & Ocean Recovery Kit':
        'Kit Orgánico de Protección Solar y Aloe',
    'Reef-safe SPF 50 zinc, copal & aloe after-sun mist.':
        'Protector solar biodegradable FPS 50, bruma de copal y aloe.',
    'Extra Organic Pool & Bath Towels':
        'Toallas Orgánicas Extra de Alberca y Baño',
    'Private Airport Transportation Sync':
        'Coordinación de Transporte Privado de Aeropuerto',
    'Degustation 8:00 PM': 'Degustación 8:00 PM',
  };

  static const Map<String, String> _esCategories = {
    'All': 'Todas',
    'All Items': 'Todo',
    'Included': 'Incluido',
    'Yacht': 'Yate',
    'Wellness': 'Bienestar y Spa',
    'Adventure': 'Aventura',
    'Culture': 'Cultura',
    'Fresh Fruit & Botanicals': 'Frutas Frescas',
    'Chilled Elixirs': 'Jugos y Bebidas Frías',
    'Cellar Selection': 'Vinos y Licores',
    'GF Bakery': 'Panadería Sin Gluten',
    'Snacks': 'Snacks y Botanas',
    'Recovery': 'Hidratación y Bienestar',
    'CHILLED IN LARDER': 'En Refrigerador',
    'SUB-ZERO CHILLED': 'Cava Fría',
    'DRY BAR PRESENTATION': 'En Barra / Mesa',
  };

  static const Map<ScreenId, String> _esShortTitles = {
    ScreenId.home: 'Inicio',
    ScreenId.transport: 'Traslado',
    ScreenId.personalize: 'Preferencias',
    ScreenId.included: 'Beneficios',
    ScreenId.explore: 'Excursiones',
    ScreenId.yacht: 'Yate Privado',
    ScreenId.dining: 'Cena Privada',
    ScreenId.stockVilla: 'Minibar y Bebidas',
    ScreenId.concierge: 'Atención 24/7',
    ScreenId.midstay: 'Comentarios',
    ScreenId.departure: 'Resumen de Estancia',
    ScreenId.philosophy: 'El Resort',
    ScreenId.profile: 'Mi Perfil y Llave',
  };

  static const Map<ScreenId, String> _esTitles = {
    ScreenId.home: 'Inicio · Mi Villa',
    ScreenId.transport: '1. Registrar Vuelo y Transporte',
    ScreenId.personalize: '2. Confort, Aroma, Dieta y Alergias',
    ScreenId.stockVilla: '3. Pedir Bebidas y Minibar',
    ScreenId.explore: '4. Excursiones y Tours',
    ScreenId.yacht: '5. Reserva de Yate Privado',
    ScreenId.dining: '6. Cena con Chef Privado en Villa',
    ScreenId.concierge: '7. Chat 24/7 y Solicitudes a Concierge',
    ScreenId.midstay: '8. ¿Cómo va tu estancia?',
    ScreenId.departure: '9. Resumen de Estancia y Salida',
    ScreenId.profile: '10. Mi Perfil, Wi-Fi y Alergias',
    ScreenId.philosophy: '11. Arquitectura y Naturaleza del Resort',
    ScreenId.included: 'Beneficios Incluidos',
  };

  static const Map<ScreenId, String> _esSubtitles = {
    ScreenId.home: 'Resumen de tu villa, clima y acciones rápidas',
    ScreenId.transport: 'Vuelo, chofer asignado HOST ADMIN y terminal',
    ScreenId.personalize: 'Confort de Habitación, Aroma, Dieta y Alergias',
    ScreenId.included: 'Beneficios Incluidos, Yoga, Spa y Golf',
    ScreenId.explore: 'Cenotes, biósfera Sian Ka\'an y tours guiados',
    ScreenId.yacht: 'Galeon 470 Sky / 500 FLY y Equipo Marino',
    ScreenId.dining: 'Equipo Culinario: Fuego y Mar, Tierra Sagrada',
    ScreenId.stockVilla: 'Pedir Bebidas y Snacks para mi Villa',
    ScreenId.concierge: 'Atención 24/7 y Chat con HOST ADMIN',
    ScreenId.midstay: '¿Cómo va tu estancia? (Comentarios)',
    ScreenId.departure:
        'Fechas de estancia, experiencias solicitadas y resumen de minibar',
    ScreenId.philosophy:
        'Botánica endémica, piedra Chukum y reserva Sian Ka\'an',
    ScreenId.profile: 'Wi-Fi de la villa y alertas de alergias',
  };
}
