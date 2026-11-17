import '../domain/admin_service.dart';

/// EN/ES copy of the Services catalog screens. Labels are 1-3 words; the
/// explanations live in ⓘ tooltips ([tip]). Spanish is never machine-made.
class ServiceCatalogStrings {
  const ServiceCatalogStrings(this.isEs);

  final bool isEs;

  String t(String en, String es) => isEs ? es : en;

  // Screens and states.
  String get services => t('Services', 'Servicios');
  String get newService => t('New service', 'Nuevo servicio');
  String get noServices => t('No services yet', 'Aún no hay servicios');
  String get catalog => t('Catalog', 'Catálogo');
  String get requests => t('Requests', 'Solicitudes');
  String get notConfigured =>
      t('Catalog not connected', 'Catálogo sin conexión');
  String get servicesInfo => t('One catalog; sections are filtered views.',
      'Un solo catálogo; las secciones son vistas filtradas.');

  // Columns and filters.
  String get order => t('Order', 'Orden');
  String get name => t('Name', 'Nombre');
  String get section => t('Section', 'Sección');
  String get use => t('Use', 'Uso');
  String get price => t('Price', 'Precio');
  String get status => t('Status', 'Estado');
  String get photo => t('Photo', 'Foto');

  /// Title of the collapsed section with the rarely used fields.
  String get more => t('More options', 'Más opciones');

  // General fields.
  String get type => t('Type', 'Tipo');
  String get shortText => t('Short text', 'Texto corto');
  String get description => t('Description', 'Descripción');
  String get category => t('Category', 'Categoría');
  String get tags => t('Tags', 'Etiquetas');
  String get featured => t('Featured', 'Destacado');
  String get nameRequired => t('Name required', 'Nombre obligatorio');
  String get tagsTip => t('Separate with commas.', 'Separa con comas.');
  String get kindTip => t('Fixed after saving.', 'No cambia al guardar.');

  // Images.
  String get cover => t('Cover', 'Portada');
  String get gallery => t('Gallery', 'Galería');
  String get addPhoto => t('Add photo', 'Agregar foto');
  String get altEn => t('Alt EN', 'Alt EN');
  String get altEs => t('Alt ES', 'Alt ES');
  String get usageRights => t('Usage rights', 'Derechos de uso');
  String get usageRightsTip =>
      t('Kachava may use this photo.', 'Kachava puede usar esta foto.');
  String get confirmRights =>
      t('Confirm usage rights', 'Confirma los derechos');
  String get galleryTip => t('Up to 8 photos.', 'Hasta 8 fotos.');

  // Pricing and availability.
  String get pricing => t('Pricing', 'Precio');
  String get amount => t('Amount (USD)', 'Monto (USD)');
  String get chargeToFolio => t('Charge to folio', 'Cargar al folio');
  String get priceNote => t('Price note', 'Nota de precio');
  String get amountTip => t(
      'Empty when items carry the price.', 'Vacío si los ítems tienen precio.');
  String get days => t('Days', 'Días');
  String get timeSlots => t('Time slots', 'Horarios');
  String get blockedDates => t('Blocked dates', 'Fechas bloqueadas');
  String get leadTime => t('Lead time (h)', 'Anticipación (h)');
  String get cancelBy => t('Cancel by (h)', 'Cancelar hasta (h)');
  String get minGuests => t('Min guests', 'Mín. personas');
  String get maxGuests => t('Max guests', 'Máx. personas');
  String get duration => t('Duration (min)', 'Duración (min)');
  String get offered => t('Offered', 'Se ofrece');
  String get blockedTip =>
      t('YYYY-MM-DD, separated by commas.', 'AAAA-MM-DD, separadas por comas.');

  // Guest info.
  String get includes => t("What's included", 'Qué incluye');
  String get excludes => t('Excludes', 'No incluye');
  String get whatToBring => t('What to bring', 'Qué llevar');
  String get location => t('Location', 'Lugar');
  String get restrictions => t('Restrictions', 'Restricciones');
  String get cancellation => t('Cancellation', 'Cancelación');

  // Operation.
  String get provider => t('Provider', 'Proveedor');
  String get department => t('Department', 'Departamento');
  String get responsible => t('Responsible', 'Responsable');
  String get needsConfirmation =>
      t('Needs confirmation', 'Requiere confirmación');
  String get internalNotes => t('Internal notes', 'Notas internas');
  String get none => t('None', 'Ninguno');
  String get operationTip =>
      t('Staff only; guests never see it.', 'Solo staff; el huésped no lo ve.');

  // Items.
  /// Title of the inline items list of [kind].
  String itemsTitle(ServiceKind kind) => switch (kind) {
        ServiceKind.bar ||
        ServiceKind.villaStocking =>
          t('Products', 'Productos'),
        ServiceKind.breakfast || ServiceKind.specialMenu => t('Menus', 'Menús'),
        ServiceKind.transport => t('Vehicles', 'Vehículos'),
        _ => t('Options', 'Opciones'),
      };
  String get newItem => t('New item', 'Nuevo ítem');
  String get noItems => t('No items yet', 'Aún no hay ítems');
  String get saveFirst =>
      t('Save the service first', 'Guarda el servicio primero');
  String get itemPrice => t('Price (USD)', 'Precio (USD)');
  String get itemPriceTip =>
      t('Empty uses the service price.', 'Vacío usa el precio del servicio.');
  String get dietaryTags => t('Dietary tags', 'Etiquetas dietéticas');
  String get allergens => t('Allergens', 'Alérgenos');
  String get origin => t('Origin', 'Origen');
  String get unit => t('Unit', 'Unidad');
  String get storage => t('Storage', 'Almacenamiento');
  String get passengers => t('Passengers', 'Pasajeros');
  String get luggage => t('Luggage', 'Maletas');

  // Status actions and toasts.
  String get activate => t('Activate', 'Activar');
  String get deactivate => t('Deactivate', 'Desactivar');
  String confirmStatus(CatalogStatus next, {bool item = false}) {
    final noun = item ? t('item', 'ítem') : t('service', 'servicio');
    return next == CatalogStatus.active
        ? t('Activate this $noun?', '¿Activar este $noun?')
        : t('Deactivate this $noun?', '¿Desactivar este $noun?');
  }

  String get saved => t('Service saved', 'Servicio guardado');
  String get itemSaved => t('Item saved', 'Ítem guardado');
  String statusChanged(CatalogStatus now) => now == CatalogStatus.active
      ? t('Now active', 'Ahora activo')
      : t('Now deactivated', 'Ahora desactivado');

  // Inline validation (<= 5 words).
  String range(int min, int max) => t('Use $min–$max', 'Usa $min–$max');
  String get wholeNumber => t('Whole number', 'Número entero');
  String get invalidAmount => t('Invalid amount', 'Monto inválido');
  String get timeFormat => t('Use HH:mm', 'Usa HH:mm');
  String get endAfterStart => t('End after start', 'Fin después del inicio');
  String get dateFormat => t('Use YYYY-MM-DD', 'Usa AAAA-MM-DD');
  String get codesFormat => t('Invalid codes', 'Códigos inválidos');

  /// One 422 detail as a short label ("Cover required").
  String problem(String raw) {
    if (raw == 'cover image is required') {
      return t('Cover required', 'Portada obligatoria');
    }
    final match = RegExp(r'^(name|shortDescription)\.(en|es) is required$')
        .firstMatch(raw);
    if (match == null) return raw;
    final field = match.group(1) == 'name' ? name : shortText;
    final lang = match.group(2)!.toUpperCase();
    return t('$field $lang required', '$field $lang obligatorio');
  }

  String problems(List<String> raw) => raw.map(problem).join(' · ');
}
