import 'guest_i18n.dart';

/// EN/ES one-line feedback: connection status and mutation outcomes.
extension GuestFeedbackI18n on GuestI18n {
  String get loadingSanctuary =>
      t('Preparing your sanctuary…', 'Preparando tu santuario…');

  String get reconnecting => t('Reconnecting…', 'Reconectando…');

  String get mutationFailed => t(
        "Couldn't confirm. Try again.",
        'No se pudo confirmar. Inténtalo de nuevo.',
      );

  /// Never interpolates stay data: the prompt must not reveal the answer.
  String get stepUpPrompt => t(
        'To protect your folio, enter your villa number or last name.',
        'Para proteger tu cuenta, ingresa tu número de villa o apellido.',
      );

  String get stepUpHint =>
      t('Villa number or last name', 'Número de villa o apellido');

  String get stepUpFailed => t(
        "Couldn't verify. Check your villa number or last name.",
        'No se pudo verificar. Revisa tu número de villa o apellido.',
      );

  String get accessRestrictedTitle => t(
        'Access Restricted · Guest link required',
        'Acceso restringido · Se requiere el enlace de huésped',
      );

  String get accessLinkInvalid => t(
        'This guest link is invalid or has expired.',
        'Este enlace de huésped no es válido o ha expirado.',
      );

  /// The server rejected a link this device remembered (HTTP 401/404).
  String get accessLinkExpired => t(
        'Your link has expired. Ask your Resort Host for a new one.',
        'Tu enlace expiró, pide uno nuevo a tu Resort Host.',
      );

  String get installAppHint =>
      t('Keep your stay one tap away.', 'Ten tu estancia a un toque.');

  String get installAppAction => t('Install app', 'Instalar app');

  String get installIosGuide => t(
        'Tap Share → Add to Home Screen',
        'Toca Compartir → Agregar a pantalla de inicio',
      );

  String get dismissLabel => t('Dismiss', 'Cerrar');

  String get accessLinkMissing => t(
        'Open the invitation link your host sent you.',
        'Abre el enlace de invitación que te envió tu anfitrión.',
      );

  String get yachtEmptyState => t(
        'Yacht charters are not available yet.',
        'Los paseos en yate aún no están disponibles.',
      );

  String get diningEmptyState => t(
        'Private dining menus are not available yet.',
        'Los menús de cena privada aún no están disponibles.',
      );

  String get noConciergeRequests =>
      t('No requests yet.', 'Aún no tienes solicitudes.');

  String identityVerified(String villa) =>
      t('Identity verified for $villa.', 'Identidad verificada para $villa.');

  String get flightSynced => t(
        'Flight details updated & synced with HOST ADMIN.',
        'Datos de vuelo actualizados y sincronizados con HOST ADMIN.',
      );

  String personalizationSaved(String villa) => t(
        'Personalization saved for $villa.',
        'Preferencias guardadas para $villa.',
      );

  String experienceRequested(String slot) => t(
        'Experience requested for $slot · Pending approval by HOST ADMIN.',
        'Solicitud de experiencia enviada ($slot) · Pendiente de aprobación por HOST ADMIN.',
      );

  String larderStocked(String villaNumber, int count) => t(
        'Villa $villaNumber Larder stocked ($count items).',
        'Pedido de minibar confirmado para Villa $villaNumber ($count artículos).',
      );

  String get yachtRequested => t(
        'Yacht charter requested · Pending approval by HOST ADMIN',
        'Solicitud de yate enviada · Pendiente de aprobación por HOST ADMIN',
      );

  String get diningRequested => t(
        'Private dining requested · Pending approval by HOST ADMIN',
        'Solicitud de cena privada enviada · Pendiente de aprobación por HOST ADMIN',
      );

  String get conciergeDispatched => t(
        'Concierge request dispatched to HOST ADMIN.',
        'Solicitud enviada a Concierge HOST ADMIN.',
      );

  String get midStayShared => t(
        'Mid-stay check-in shared with your Resort Host.',
        'Comentarios enviados a tu anfitrión del resort.',
      );

  /// Guest-facing name of the resort team when the server names no person.
  String get resortHost => t('Resort Host', 'Anfitrión del resort');

  /// The person the server named, or [resortHost] when it named nobody.
  String hostLabel(String serverName) =>
      serverName.trim().isEmpty ? resortHost : serverName;

  String get requestedJustNow =>
      t('Requested just now', 'Solicitado hace un momento');

  String get sentJustNow => t('Just now', 'Hace un momento');

  String get submittedJustNow =>
      t('Submitted just now', 'Enviado hace un momento');

  String checkoutCompleted(String villaNumber) => t(
        'Express Check-Out completed. Safe travels from Villa $villaNumber.',
        'Salida Express completada. Buen viaje desde Villa $villaNumber.',
      );

  String get readOnlyArchive => t(
        'Stay Checked Out — Portal is in Read-Only Archive mode.',
        'Estancia Finalizada — El portal está en modo de solo lectura.',
      );
}
