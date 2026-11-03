import 'package:flutter/material.dart';

import '../../../application/list_query_store.dart';
import '../../../application/paged_list_controller.dart';
import '../../../core/admin_i18n.dart';
import '../../../core/stay_strings.dart';
import '../../../core/theme/kachava_tokens.dart';
import '../../../domain/guest_profile.dart';
import '../../../domain/list_query.dart';
import '../../../domain/reservation.dart';
import '../../components/components.dart';
import '../operations_scope.dart';
import '../ops_fields.dart';
import '../reservations/reservation_tabs.dart';

/// Guests tab: Guest, Villa, Dates, Language, Allergies, Open requests;
/// the profile (preferences, allergies, occasion, requests, notes) opens
/// in the side panel.
class GuestListTab extends StatefulWidget {
  const GuestListTab({
    super.key,
    required this.repository,
    required this.queries,
    required this.isEs,
    this.openId,
    this.onOpenChat,
  });

  static const String storeKey = 'guests';

  final GuestRepository repository;
  final ListQueryStore queries;
  final bool isEs;
  final String? openId;
  final ValueChanged<String>? onOpenChat;

  @override
  State<GuestListTab> createState() => _GuestListTabState();
}

class _GuestListTabState extends State<GuestListTab> {
  late final PagedListController<GuestRow> _list = PagedListController(
    fetch: widget.repository.list,
    initialQuery: const ListQuery(sort: ListSort('checkIn')),
    store: widget.queries,
    storeKey: GuestListTab.storeKey,
  );

  StayStrings get _s => StayStrings(widget.isEs);

  @override
  void dispose() {
    _list.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => OpenRecordLoader<GuestRow>(
        id: widget.openId,
        load: (id) async => (await widget.repository.get(id)).row,
        builder: (context, initial) => AdminListScreen<GuestRow>(
          entity: 'guests',
          title: _s.guestsTitle,
          controller: _list,
          columns: _columns(),
          rowId: (g) => g.stayId,
          compactTitle: (g) => g.guestName,
          compactSubtitle: (g) =>
              '${g.villaName} · ${_s.range(g.checkIn, g.checkOut)}',
          compactTrailing: _allergyCell,
          filters: [
            AdminListFilter(key: 'status', label: _s.status, options: [
              for (final v in StayValues.statuses)
                AdminFilterOption(v, AdminI18n.statusLabel(v, widget.isEs)),
            ]),
          ],
          emptyMessage: _s.noGuests,
          detailBuilder: (context, row, close) => GuestProfilePanel(
            row: row!,
            repository: widget.repository,
            onClose: close,
            onOpenChat: widget.onOpenChat,
            isEs: widget.isEs,
          ),
          initialDetail: initial,
          isEs: widget.isEs,
        ),
      );

  Widget _allergyCell(GuestRow g) => g.hasAllergies
      ? StatusChip(
          key: Key('guest-allergy-${g.stayId}'),
          label: _s.hasAllergies,
          tone: StatusTone.error)
      : const Text('—');

  List<AdminTableColumn<GuestRow>> _columns() => [
        AdminTableColumn(label: _s.guest, text: (g) => g.guestName, flex: 3),
        AdminTableColumn(label: _s.villa, text: (g) => g.villaName),
        AdminTableColumn(
            label: _s.dates,
            text: (g) => _s.range(g.checkIn, g.checkOut),
            sortField: 'checkIn',
            flex: 3),
        AdminTableColumn(
            label: _s.language,
            text: (g) => _s.languageLabel(g.language),
            flex: 1),
        AdminTableColumn(label: _s.allergies, cell: _allergyCell),
        AdminTableColumn(
            label: _s.openRequests,
            text: (g) => '${g.openRequests}',
            numeric: true,
            flex: 1),
      ];
}

/// Staff-only guest profile of one stay.
class GuestProfilePanel extends StatelessWidget {
  const GuestProfilePanel({
    super.key,
    required this.row,
    required this.repository,
    required this.onClose,
    required this.isEs,
    this.onOpenChat,
  });

  final GuestRow row;
  final GuestRepository repository;
  final VoidCallback onClose;
  final ValueChanged<String>? onOpenChat;
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    final s = StayStrings(isEs);
    return AdminDetailPanel(
      key: const Key('guest-profile'),
      title: row.guestName,
      onClose: onClose,
      isEs: isEs,
      body: LoadedTab<GuestProfile>(
        load: () => repository.get(row.stayId),
        isEs: isEs,
        builder: (context, profile) => ListView(
          padding: const EdgeInsets.all(KachavaTokens.space6),
          children: [
            FactRow(label: s.villa, value: profile.row.villaName),
            FactRow(
                label: s.dates,
                value: s.range(profile.row.checkIn, profile.row.checkOut)),
            FactRow(
                label: s.language,
                value: s.languageLabel(profile.row.language)),
            FactRow(label: s.email, value: profile.email),
            FactRow(label: s.phone, value: profile.phone),
            PanelHeading(s.preferences),
            ...GuestPreferencesView.items(profile, isEs),
            PanelHeading(s.requestHistory),
            if (profile.requestHistory.isEmpty)
              AdminStateLine(message: s.noRequests),
            for (final r in profile.requestHistory)
              Padding(
                padding: const EdgeInsets.only(bottom: KachavaTokens.space2),
                child: Row(children: [
                  Expanded(child: Text(r.title)),
                  StatusChip.fromStatus(r.status, isEs: isEs),
                ]),
              ),
            PanelHeading(s.internalNotes),
            Text(AdminI18n.orDash(profile.internalNotes)),
          ],
        ),
      ),
      footer: onOpenChat == null
          ? null
          : Row(children: [
              const Spacer(),
              FilledButton.icon(
                key: const Key('guest-open-chat'),
                onPressed: () => onOpenChat!(row.stayId),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: Text(s.openChat),
              ),
            ]),
    );
  }
}
