import 'package:flutter/material.dart';

import '../../core/admin_i18n.dart';
import '../../core/theme/kachava_tokens.dart';

/// Top-bar "Refresh": re-reads the bell and every open screen (list,
/// detail, conversation) through the real-time fan-out. Shows a small
/// spinner until [onRefresh] completes; taps meanwhile are ignored.
class AdminRefreshButton extends StatefulWidget {
  const AdminRefreshButton({
    super.key,
    required this.onRefresh,
    required this.isEs,
  });

  final Future<void> Function() onRefresh;
  final bool isEs;

  @override
  State<AdminRefreshButton> createState() => _AdminRefreshButtonState();
}

class _AdminRefreshButtonState extends State<AdminRefreshButton> {
  bool _busy = false;

  Future<void> _refresh() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onRefresh();
    } catch (error) {
      // Each screen shows its own failure; the button only ends its spinner.
      debugPrint('Manual refresh failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
        key: const Key('admin-refresh-button'),
        tooltip: AdminI18n.tr(widget.isEs, 'Refresh', 'Actualizar'),
        style: IconButton.styleFrom(fixedSize: const Size(48, 48)),
        onPressed: _busy ? null : _refresh,
        icon: _busy
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: KachavaTokens.text),
              )
            : const Icon(Icons.refresh, color: KachavaTokens.text),
      );
}
