import 'theme/kachava_tokens.dart';

/// One status: short EN/ES label plus its DESIGN.md token tone.
class StatusTerm {
  const StatusTerm(this.en, this.es, this.tone);

  final String en;
  final String es;
  final StatusTone tone;
}

/// The single EN/ES status vocabulary (`ux-patterns.md` §5). Wire enums such
/// as `CHECKED_OUT` are looked up case- and separator-insensitively; unknown
/// values are humanized ("Waiting for parts"), never shown raw.
abstract final class StatusVocabulary {
  static const Map<String, StatusTerm> _terms = {
    // Stays.
    'PRE_ARRIVAL': StatusTerm('Pre-arrival', 'Por llegar', StatusTone.info),
    'ARRIVAL': StatusTerm('Arrival', 'Llegada', StatusTone.info),
    'IN_HOUSE': StatusTerm('In house', 'En estancia', StatusTone.success),
    'ACTIVE_STAY': StatusTerm('In house', 'En estancia', StatusTone.success),
    'DEPARTURE': StatusTerm('Departure', 'Salida', StatusTone.neutral),
    'DEPARTING_TODAY':
        StatusTerm('Departing today', 'Sale hoy', StatusTone.neutral),
    'CHECKED_OUT':
        StatusTerm('Checked out', 'Salida realizada', StatusTone.neutral),
    'OVERSTAY': StatusTerm('Overstay', 'Estancia vencida', StatusTone.error),
    'EXPIRED': StatusTerm('Expired', 'Expirado', StatusTone.neutral),
    // Villas.
    'AVAILABLE': StatusTerm('Available', 'Disponible', StatusTone.success),
    'OCCUPIED': StatusTerm('Occupied', 'Ocupada', StatusTone.neutral),
    'CLEANING': StatusTerm('Cleaning', 'En limpieza', StatusTone.info),
    'MAINTENANCE':
        StatusTerm('Maintenance', 'Mantenimiento', StatusTone.warning),
    'BLOCKED': StatusTerm('Blocked', 'Bloqueada', StatusTone.error),
    'CLEAN': StatusTerm('Clean', 'Limpia', StatusTone.success),
    'DIRTY': StatusTerm('Needs cleaning', 'Por limpiar', StatusTone.warning),
    'OK': StatusTerm('OK', 'OK', StatusTone.success),
    'ISSUE_REPORTED':
        StatusTerm('Issue reported', 'Incidencia', StatusTone.warning),
    'IN_MAINTENANCE':
        StatusTerm('In maintenance', 'En mantenimiento', StatusTone.warning),
    // Catalog.
    'DRAFT': StatusTerm('Draft', 'Borrador', StatusTone.neutral),
    'ACTIVE': StatusTerm('Active', 'Activo', StatusTone.success),
    'DISABLED': StatusTerm('Disabled', 'Desactivado', StatusTone.neutral),
    'INACTIVE': StatusTerm('Disabled', 'Desactivado', StatusTone.neutral),
    // Requests, trips and tasks (section queues use the guest's words).
    'RECEIVED': StatusTerm('Received', 'Recibida', StatusTone.info),
    'PREPARING': StatusTerm('Preparing', 'En preparación', StatusTone.info),
    'DONE': StatusTerm('Done', 'Lista', StatusTone.success),
    'REQUESTED': StatusTerm('Requested', 'Solicitado', StatusTone.info),
    'PENDING': StatusTerm('Pending', 'Pendiente', StatusTone.info),
    'ASSIGNED': StatusTerm('Assigned', 'Asignado', StatusTone.neutral),
    'SENT_TO_PROVIDER':
        StatusTerm('Sent to provider', 'Enviado al proveedor', StatusTone.info),
    'CONFIRMED': StatusTerm('Confirmed', 'Confirmado', StatusTone.success),
    'SCHEDULED': StatusTerm('Scheduled', 'Programado', StatusTone.info),
    'EN_ROUTE': StatusTerm('En route', 'En camino', StatusTone.info),
    'IN_PROGRESS': StatusTerm('In progress', 'En curso', StatusTone.info),
    'COMPLETED': StatusTerm('Completed', 'Completado', StatusTone.success),
    'CANCELLED': StatusTerm('Cancelled', 'Cancelado', StatusTone.neutral),
    'CANCELED': StatusTerm('Cancelled', 'Cancelado', StatusTone.neutral),
    'OVERDUE': StatusTerm('Overdue', 'Vencido', StatusTone.error),
    'NOT_REQUESTED':
        StatusTerm('Not requested', 'No solicitado', StatusTone.neutral),
    'STOCKED_IN_VILLA': StatusTerm('Stocked', 'Entregado', StatusTone.success),
    'ATTENDED': StatusTerm('Attended', 'Atendido', StatusTone.success),
    // Severity.
    'INFO': StatusTerm('Info', 'Info', StatusTone.neutral),
    'NORMAL': StatusTerm('Normal', 'Normal', StatusTone.neutral),
    'HIGH': StatusTerm('High', 'Alta', StatusTone.warning),
    'ACTION_NEEDED':
        StatusTerm('Action needed', 'Acción pendiente', StatusTone.warning),
    'URGENT': StatusTerm('Urgent', 'Urgente', StatusTone.error),
    // Payments.
    'PRE_AUTHORIZED':
        StatusTerm('Pre-authorized', 'Preautorizado', StatusTone.neutral),
    'SETTLED': StatusTerm('Settled', 'Liquidado', StatusTone.success),
  };

  /// `in-progress`, `In Progress` and `IN_PROGRESS` share one key.
  static String normalize(String raw) => raw
      .trim()
      .toUpperCase()
      .split(RegExp(r'[^A-Z0-9]+'))
      .where((w) => w.isNotEmpty)
      .join('_');

  static StatusTerm? lookup(String raw) => _terms[normalize(raw)];

  static String label(String raw, {required bool isEs}) {
    final term = lookup(raw);
    if (term != null) return isEs ? term.es : term.en;
    return humanize(raw);
  }

  /// Token tone, or `null` when the status is not in the vocabulary.
  static StatusTone? tone(String raw) => lookup(raw)?.tone;

  /// `WAITING_FOR_PARTS` -> `Waiting for parts`; mixed-case text is kept.
  static String humanize(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return '—';
    if (text != text.toUpperCase()) return text;
    final words = normalize(text).toLowerCase().split('_');
    final sentence = words.join(' ');
    return sentence.isEmpty
        ? text
        : sentence[0].toUpperCase() + sentence.substring(1);
  }
}
