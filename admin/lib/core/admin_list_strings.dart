/// EN/ES copy of the shared list, panel, form and upload components.
/// Every label is 1-3 words (clean-UI rule); explanations go in ⓘ tooltips.
class AdminListStrings {
  const AdminListStrings(this.isEs);

  final bool isEs;

  String _t(String en, String es) => isEs ? es : en;

  String get search => _t('Search', 'Buscar');
  String get clearSearch => _t('Clear search', 'Borrar búsqueda');
  String get filters => _t('Filters', 'Filtros');
  String get all => _t('All', 'Todos');
  String get clearAll => _t('Clear all', 'Borrar todo');
  String get clear => _t('Clear', 'Borrar');
  String get apply => _t('Apply', 'Aplicar');
  String get sort => _t('Sort', 'Ordenar');
  String get none => _t('None', 'Ninguno');
  String get ascending => _t('Ascending', 'Ascendente');
  String get descending => _t('Descending', 'Descendente');
  String get noResults => _t('No results', 'Sin resultados');
  String get clearFilters => _t('Clear filters', 'Quitar filtros');
  String get loadError => _t("Couldn't load", 'No se pudo cargar');
  String get retry => _t('Retry', 'Reintentar');
  String get rowsPerPage => _t('Rows per page', 'Filas por página');
  String get previousPage => _t('Previous page', 'Página anterior');
  String get nextPage => _t('Next page', 'Página siguiente');
  String get close => _t('Close', 'Cerrar');
  String get save => _t('Save', 'Guardar');
  String get cancel => _t('Cancel', 'Cancelar');
  String get required => _t('Required', 'Obligatorio');
  String get more => _t('More', 'Más');
  String get saveError => _t("Couldn't save", 'No se pudo guardar');
  String get discardChanges => _t('Discard changes?', '¿Descartar cambios?');
  String get discard => _t('Discard', 'Descartar');
  String get keepEditing => _t('Keep editing', 'Seguir editando');
  String get upload => _t('Upload', 'Subir');
  String get replace => _t('Replace', 'Cambiar');
  String get remove => _t('Remove', 'Quitar');
  String get loading => _t('Loading', 'Cargando');
  String get uploading => _t('Uploading', 'Subiendo');
  String get maxFileSize => _t('Max 5 MB', 'Máx. 5 MB');
  String get imageTypes => _t('JPG, PNG or WebP', 'JPG, PNG o WebP');
  String get uploadFailed => _t('Upload failed', 'Error al subir');

  String sortedAscending(String column) =>
      _t('$column, sorted ascending', '$column, orden ascendente');
  String sortedDescending(String column) =>
      _t('$column, sorted descending', '$column, orden descendente');
  String sortBy(String column) => _t('Sort by $column', 'Ordenar por $column');

  /// "1–25 of 1,132" / "1–25 de 1.132".
  String range(int start, int end, int total) =>
      '${count(start)}–${count(end)} ${_t('of', 'de')} ${count(total)}';

  /// Thousands separators: `1,132` (EN) / `1.132` (ES).
  String count(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer(value < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(isEs ? '.' : ',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
