import 'package:flutter/foundation.dart';

import '../core/admin_i18n.dart';

/// One-line, bilingual failure text for a mutation the server did not confirm.
typedef FailureText = String Function(bool isEs);

/// Failure texts for server-confirmed admin mutations (EN/ES via [AdminI18n]).
class AdminFailureText {
  const AdminFailureText._();

  static String mutation(bool isEs) => AdminI18n.tr(
      isEs,
      'Not saved: the server did not confirm. Please retry.',
      'No se guardó: el servidor no confirmó. Intenta de nuevo.');

  static String createStay(bool isEs) => AdminI18n.tr(
      isEs,
      'Stay not created: the server did not confirm. No link was generated.',
      'Estancia no creada: el servidor no confirmó. No se generó ningún link.');

  static String rotateToken(bool isEs) => AdminI18n.tr(
      isEs,
      'Link not rotated: the server did not confirm. The current link stays active.',
      'Link no rotado: el servidor no confirmó. El link actual sigue activo.');
}

/// Thrown inside an action when its owner was disposed mid-flight; the action
/// stops silently (no follow-up calls, no feedback).
class OwnerDisposedException implements Exception {
  const OwnerDisposedException();
}

/// No signed-in staff member is known, so the mutation cannot be attributed.
class NoSessionStaffException implements Exception {
  const NoSessionStaffException();
}

/// Runs [action] and reports any failure through [report] as one line.
///
/// Success feedback lives inside [action], after the awaited server call, so it
/// can only appear once the server has confirmed the mutation. Errors (e.g. a
/// malformed payload) are reported too, so none escapes as an unhandled async
/// error from a button callback; a disposed owner stops silently.
Future<void> runServerConfirmed(
  Future<void> Function() action, {
  required void Function(String message) report,
  required String failureMessage,
}) async {
  try {
    await action();
  } on OwnerDisposedException {
    return;
  } catch (error) {
    debugPrint('Admin mutation not confirmed: $error');
    report(failureMessage);
  }
}

/// Runs a best-effort [read]: any failure is logged and yields null, so a read
/// that follows a server-confirmed mutation never turns success into failure.
Future<T?> bestEffortRead<T>(Future<T> Function() read) async {
  try {
    return await read();
  } catch (error) {
    debugPrint('Admin best-effort read failed: $error');
    return null;
  }
}
