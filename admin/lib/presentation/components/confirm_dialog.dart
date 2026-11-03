import 'package:flutter/material.dart';

/// Shows a one-line confirmation ("Disable this villa?"); resolves `true`
/// only when confirmed. Focus starts on Cancel.
///
/// [destructive] paints the confirm button with the error color. [message]
/// is optional: the title alone is usually enough.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  String message = '',
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const Key('confirm-dialog'),
      title: Text(title),
      content: message.isEmpty ? null : Text(message),
      actions: [
        TextButton(
          key: const Key('confirm-dialog-cancel'),
          autofocus: true,
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          key: const Key('confirm-dialog-confirm'),
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError)
              : null,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
