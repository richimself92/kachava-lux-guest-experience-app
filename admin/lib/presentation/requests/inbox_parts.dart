import 'package:flutter/material.dart';

import '../../core/inbox_strings.dart';
import '../../core/resort_time.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../core/transport_strings.dart';
import '../../domain/inbox_item.dart';
import '../../domain/service_request.dart';
import '../components/components.dart';

/// Chip tone of an inbox status: New = warning (urgent once overdue),
/// confirmed / in progress = info, done = success, cancelled = neutral.
StatusTone inboxTone(InboxItem item, {bool overdue = false}) {
  if (overdue) return StatusTone.error;
  return switch (item.stage) {
    InboxStage.fresh => StatusTone.warning,
    InboxStage.active => StatusTone.info,
    InboxStage.closed =>
      item.status == 'CANCELLED' ? StatusTone.neutral : StatusTone.success,
  };
}

/// The inbox status chip (`inbox-chip-<tone>` for tests).
class InboxStatusChip extends StatelessWidget {
  const InboxStatusChip(
      {super.key,
      required this.item,
      required this.isEs,
      this.overdue = false});

  final InboxItem item;
  final bool isEs;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final tone = inboxTone(item, overdue: overdue);
    return KeyedSubtree(
      key: Key('inbox-chip-${tone.name}'),
      child: StatusChip(
          label: InboxStrings(isEs).stageStatus(item.status), tone: tone),
    );
  }
}

IconData inboxIcon(InboxType type) => switch (type) {
      InboxType.order => Icons.shopping_basket_outlined,
      InboxType.booking => Icons.event_available_outlined,
      InboxType.preference => Icons.tune,
      InboxType.trip => Icons.airport_shuttle_outlined,
    };

/// "Lux bar" / "Arrival" — what the request is about.
String inboxTitle(InboxItem item, bool isEs) => switch (item) {
      RequestInboxItem(:final request) => request.serviceName.of(isEs: isEs),
      TripInboxItem(:final trip) => TransportStrings(isEs).typeLabel(trip.type),
    };

String _lines(ServiceRequest r, bool isEs) => [
      for (final l in r.lines) '${l.quantity} × ${l.name.of(isEs: isEs)}'
    ].join(', ');

/// One line of what was asked: "2 × Mineral water, 1 × Artisan bread",
/// "Pillow menu: Goose down", "Arrival · Nov 6 · 14:10".
String inboxSummary(InboxItem item, bool isEs, ResortTime? time) {
  final title = inboxTitle(item, isEs);
  switch (item) {
    case RequestInboxItem(:final request):
      final lines = _lines(request, isEs);
      return switch (item.type) {
        InboxType.order => lines.isEmpty ? title : lines,
        InboxType.preference => request.lines.isEmpty
            ? title
            : '$title: ${request.lines.map((l) => l.name.of(isEs: isEs)).join(', ')}',
        _ => '$title · ${_when(request, isEs)}',
      };
    case TripInboxItem(:final trip):
      final pickup = time?.label(trip.pickupAt, isEs: isEs) ?? '—';
      return '$title · $pickup';
  }
}

String _when(ServiceRequest r, bool isEs) {
  final day = ResortTime.dayLabel(r.day, isEs: isEs);
  return r.time.isEmpty ? day : '$day · ${r.time}';
}

/// "Guest · Villa" with the type icon and section; bold with an accent
/// stripe while [unread].
class InboxGuestCell extends StatelessWidget {
  const InboxGuestCell({
    super.key,
    required this.item,
    required this.unread,
    required this.isEs,
  });

  final InboxItem item;
  final bool unread;
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme.bodyMedium;
    final s = InboxStrings(isEs);
    return Container(
      key: unread ? Key('inbox-unread-${item.rowId}') : null,
      padding: const EdgeInsets.only(left: KachavaTokens.space2),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
              width: 3,
              color: unread ? KachavaTokens.primary : Colors.transparent),
        ),
      ),
      child: Row(children: [
        Icon(inboxIcon(item.type),
            size: 18, color: KachavaTokens.textSecondary),
        const SizedBox(width: KachavaTokens.space2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TruncatedText('${item.guestName} · ${item.villaName}',
                  style: text?.copyWith(
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w400)),
              TruncatedText(
                  '${s.typeLabel(item.type)} · ${s.sectionLabel(item.section)}',
                  style: text?.copyWith(
                      fontSize: 12, color: KachavaTokens.textSecondary)),
            ],
          ),
        ),
      ]),
    );
  }
}
