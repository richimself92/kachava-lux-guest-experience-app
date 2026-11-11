import 'package:flutter/material.dart';

import '../../core/i18n/l10n.dart';
import '../../core/theme/kachava_colors.dart';
import '../../domain/requests.dart';
import '../common/labels.dart';
import '../common/widgets.dart';

/// One row of My requests: what was asked, when, the plain status word and,
/// once a trip is confirmed, the driver.
class RequestCard extends StatelessWidget {
  const RequestCard({
    super.key,
    required this.l10n,
    required this.request,
    required this.title,
    required this.onTap,
  });

  final L10n l10n;
  final GuestRequest request;
  final String title;
  final VoidCallback onTap;

  static const _secondary =
      TextStyle(fontSize: 14, color: KachavaColors.onSurfaceVariant);

  List<String> _details() {
    final r = request;
    final trip = r.trip;
    return [
      requestWhat(l10n, r),
      requestWhen(l10n, r),
      if (trip != null && showsDriver(r)) driverSummary(l10n, trip),
      requestReason(l10n, r),
    ].where((s) => s.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final r = request;
    final details = _details();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        label: [title, l10n.status(r.status), ...details].join(', '),
        excludeSemantics: true,
        child: InkWell(
          key: Key('request-${r.id}'),
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _body(details)),
                const SizedBox(width: 8),
                Flexible(child: StatusChip(status: r.status, l10n: l10n)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(List<String> details) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          for (final line in details)
            Text(line,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _secondary),
          const SizedBox(height: 6),
          StatusTrack(status: request.status),
        ],
      );
}
