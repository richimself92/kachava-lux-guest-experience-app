import 'package:flutter/material.dart';

import '../../application/portal_controller.dart';
import '../../core/theme/kachava_colors.dart';
import '../../data/guest_api.dart';
import '../../domain/catalog.dart';
import '../../domain/forms.dart';
import '../../domain/stay.dart';
import '../common/widgets.dart';
import 'form_scaffold.dart';

/// BOOKING: [option] → date → time slot → people → configured questions
/// → Review → "Book". Up to 4 fields share one page. With [changing] it
/// re-sends a REQUESTED booking: prefilled date, time and people only.
class BookingForm extends StatefulWidget {
  const BookingForm({
    super.key,
    required this.controller,
    required this.service,
    required this.title,
    this.changing,
  });

  final PortalController controller;
  final CatalogService service;
  final String title;
  final GuestBooking? changing;

  @override
  State<BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final BookingDraft _draft = BookingDraft();
  late final List<BookingFieldSpec> _fields = widget.changing == null
      ? bookingFields(widget.service)
      : changeableBookingFields(widget.service);
  late final List<List<int>> _fieldPages =
      paginateFields([for (var i = 0; i < _fields.length; i++) i]);
  late final bool _hasOptions =
      widget.changing == null && widget.service.items.isNotEmpty;
  String? _itemId;
  int _page = 0;
  bool _busy = false;
  bool _showIssues = false;
  String? _error;

  int get _pages => (_hasOptions ? 1 : 0) + _fieldPages.length + 1;
  bool get _isReview => _page == _pages - 1;
  bool get _isOptions => _hasOptions && _page == 0;
  List<int> get _pageFieldIdx => _fieldPages[_page - (_hasOptions ? 1 : 0)];

  @override
  void initState() {
    super.initState();
    final changing = widget.changing;
    if (changing != null) {
      prefillBookingDraft(_draft, changing);
      return;
    }
    final a = widget.service.availability;
    if (_fields.any((f) => f.field == BookingField.guests)) {
      final guests = widget.controller.stay?.guestsCount ?? 1;
      _draft.guests = guests.clamp(a.minGuests ?? 1, a.maxGuests ?? 50);
    }
  }

  Map<BookingField, FormIssue> _issuesFor(List<int> idx) => validateBooking(
      _draft,
      [for (final i in idx) _fields[i]],
      widget.service,
      widget.controller.clock.nowWall());

  void _next() {
    if (_isOptions && _itemId == null) {
      setState(() => _showIssues = true);
      return;
    }
    if (!_isOptions && _issuesFor(_pageFieldIdx).isNotEmpty) {
      setState(() => _showIssues = true);
      return;
    }
    setState(() {
      _showIssues = false;
      _page++;
    });
  }

  Future<void> _submit() async {
    final l10n = widget.controller.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    final changing = widget.changing;
    final result = changing == null
        ? await widget.controller.createBooking(
            bookingPayload(_draft, widget.service, itemId: _itemId))
        : await widget.controller
            .changeBooking(changing.id, bookingChangePayload(_draft, _fields));
    if (!mounted) return;
    switch (result) {
      case ApiOk():
        Navigator.of(context).pop();
        showPortalToast(
            context, changing == null ? l10n.bookingSent : l10n.requestChanged);
      case ApiFailed():
        setState(() {
          _busy = false;
          _error = failureMessage(l10n, result);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.controller.l10n;
    return FormScaffold(
      l10n: l10n,
      title: widget.title,
      page: _page,
      pages: _pages,
      busy: _busy,
      error: _error,
      onRetry: _submit,
      onBack: _page == 0 ? null : () => setState(() => _page--),
      primaryLabel: _isReview
          ? (widget.changing == null ? l10n.actionBook : l10n.change)
          : l10n.nextPage,
      onPrimary: _isReview ? _submit : _next,
      children: _isReview
          ? _review()
          : _isOptions
              ? _options()
              : [for (final i in _pageFieldIdx) _field(i)],
    );
  }

  List<Widget> _options() {
    final l10n = widget.controller.l10n;
    return [
      for (final item in widget.service.items)
        ChoiceCard(
          key: Key('option-${item.id}'),
          selected: _itemId == item.id,
          title: l10n.text(item.name),
          subtitle: item.priceUSD == null ? null : l10n.money(item.priceUSD!),
          leading: item.image == null
              ? null
              : ServicePhoto(image: item.image, l10n: l10n, radius: 8),
          onTap: () => setState(() => _itemId = item.id),
        ),
      if (_showIssues && _itemId == null)
        Text(l10n.issue(FormIssue.required),
            style:
                const TextStyle(color: KachavaColors.errorRed, fontSize: 14)),
    ];
  }

  Widget _field(int index) {
    final l10n = widget.controller.l10n;
    final spec = _fields[index];
    final issues =
        _showIssues ? _issuesFor([index]) : const <BookingField, FormIssue>{};
    final issue =
        issues[spec.field] == null ? null : l10n.issue(issues[spec.field]!);
    final today = widget.controller.clock.today();
    final checkOut = widget.controller.stay?.checkOut;
    switch (spec.field) {
      case BookingField.date:
        return LabeledField(
          label: l10n.dateLabel,
          issue: issue,
          child: DateField(
            fieldKey: const Key('booking-date'),
            l10n: l10n,
            value: _draft.day,
            first: today,
            last: checkOut ?? today.add(const Duration(days: 365)),
            onChanged: (d) => setState(() => _draft.day = d),
          ),
        );
      case BookingField.time:
        final slots = widget.service.availability.timeSlots;
        return LabeledField(
          label: l10n.timeLabel,
          issue: issue,
          child: slots.isEmpty
              ? TextFormField(
                  key: const Key('booking-time'),
                  initialValue: _draft.time,
                  decoration: const InputDecoration(hintText: 'HH:MM'),
                  onChanged: (v) => _draft.time = v.trim(),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in slots)
                      ChoiceChip(
                        key: Key('slot-${s.start}'),
                        label: Text(s.start),
                        selected: _draft.time == s.start,
                        onSelected: (_) =>
                            setState(() => _draft.time = s.start),
                      ),
                  ],
                ),
        );
      case BookingField.guests:
        final a = widget.service.availability;
        return LabeledField(
          label: l10n.people,
          issue: issue,
          child: QuantityStepper(
            key: const Key('booking-guests'),
            label: l10n.people,
            value: _draft.guests,
            min: a.minGuests ?? 1,
            max: a.maxGuests ?? 50,
            onChanged: (v) => setState(() => _draft.guests = v),
          ),
        );
      case BookingField.notes:
        return LabeledField(
          label: l10n.notes,
          child: TextFormField(
            key: const Key('booking-notes'),
            initialValue: _draft.notes,
            maxLines: 3,
            maxLength: 500,
            onChanged: (v) => _draft.notes = v,
          ),
        );
      case BookingField.dietary:
        return LabeledField(
          label: l10n.diet,
          child: TextFormField(
            initialValue: _draft.dietary,
            onChanged: (v) => _draft.dietary = v,
          ),
        );
      case BookingField.health:
        return LabeledField(
          label:
              spec.question == null ? l10n.health : l10n.text(spec.question!),
          child: TextFormField(
            initialValue: _draft.health[index] ?? '',
            onChanged: (v) => _draft.health[index] = v,
          ),
        );
    }
  }

  List<Widget> _review() {
    final l10n = widget.controller.l10n;
    final item = widget.service.items.where((i) => i.id == _itemId).firstOrNull;
    final line = [
      if (_draft.day != null) l10n.date(_draft.day!),
      if (_draft.time.isNotEmpty) _draft.time,
      if (_draft.guests > 0) l10n.guests(_draft.guests),
    ].join(' · ');
    return [
      Text(l10n.review, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Text(l10n.text(widget.service.name),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      if (item != null)
        Text(l10n.text(item.name), style: const TextStyle(fontSize: 16)),
      Text(line,
          key: const Key('booking-review-line'),
          style: const TextStyle(fontSize: 16)),
      if (_draft.notes.trim().isNotEmpty)
        Text(_draft.notes.trim(), style: const TextStyle(fontSize: 15)),
    ];
  }
}
