import '../domain/dashboard_view.dart';
import 'resort_time.dart';

/// EN/ES copy of the actionable "Today's activity" table.
class DashboardStrings {
  const DashboardStrings(this.isEs);

  final bool isEs;

  String t(String en, String es) => isEs ? es : en;

  String get next => t('Next', 'Siguiente');
  String get pending => t('Pending', 'Pendiente');
  String get checkIn => t('Check-in', 'Check-in');
  String get checkOut => t('Check-out', 'Check-out');
  String get back => t('Cancel', 'Cancelar');
  String confirmTitle(String action, String guest) => action == 'CHECK_IN'
      ? t('Check in $guest?', '¿Registrar entrada de $guest?')
      : t('Check out $guest?', '¿Registrar salida de $guest?');
  String get done => t('Stay updated', 'Estancia actualizada');
  String get failed => t("Couldn't update stay", 'No se pudo actualizar');

  String requests(int n) => n == 1
      ? t('1 request', '1 solicitud')
      : t('$n requests', '$n solicitudes');
  String messages(int n) =>
      n == 1 ? t('1 message', '1 mensaje') : t('$n messages', '$n mensajes');

  String transfer(String? state) => switch (state) {
        'DRIVER_CONFIRMED' => t('driver confirmed', 'chofer confirmado'),
        'NO_DRIVER' => t('transfer without driver', 'traslado sin chofer'),
        _ => t('no transfer', 'sin traslado'),
      };

  /// "✈ 14:10 · transfer without driver", "Massage · tomorrow 16:00", "—".
  String nextText(ActivityNext? next, String today, ResortTime? time) {
    if (next == null) return '—';
    if (next.kind == ActivityNext.booking) {
      final date = next.date ?? '';
      final day = date == today
          ? t('today', 'hoy')
          : date == _plusOne(today)
              ? t('tomorrow', 'mañana')
              : ResortTime.dayLabel(date, isEs: isEs);
      final title = next.title?.of(isEs: isEs) ?? '';
      return [title, '$day ${next.time ?? ''}'.trim()]
          .where((v) => v.isNotEmpty)
          .join(' · ');
    }
    final at = next.at;
    final clock =
        at == null ? null : ResortTime.hhmm(time?.wall(at) ?? at.toUtc());
    return [if (clock != null) '✈ $clock', transfer(next.transfer)].join(' · ');
  }

  static String _plusOne(String day) {
    final d = DateTime.tryParse('${day}T00:00:00Z');
    return d == null ? '' : ResortTime.isoDay(d.add(const Duration(days: 1)));
  }
}
