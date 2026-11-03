import 'package:flutter/material.dart';

import '../../application/portal_controller.dart';
import '../../data/guest_api.dart';
import '../../domain/catalog.dart';
import '../../domain/forms.dart';
import '../../domain/journey.dart';
import '../../domain/trip.dart';
import '../common/widgets.dart';
import 'form_scaffold.dart';
import 'trip_review.dart';

/// TRIP wizard: 1 When → 2 Flight (or Route) → 3 Group → 4 Review → Send.
/// 1.1 and 3.1 preset the type; drafts are saved per guest.
class TripWizard extends StatefulWidget {
  const TripWizard({
    super.key,
    required this.controller,
    required this.service,
    required this.title,
    this.presetType,
    this.core,
  });

  final PortalController controller;
  final CatalogService service;
  final String title;
  final TripType? presetType;

  /// Core journey task (1.1 / 3.1): offers "I arrange my own".
  final CoreTask? core;

  @override
  State<TripWizard> createState() => _TripWizardState();
}

class _TripWizardState extends State<TripWizard> {
  late TripDraft _d;
  int _page = 0;
  bool _busy = false;
  bool _showIssues = false;
  String? _error;
  late final TextEditingController _time,
      _airline,
      _flight,
      _terminal,
      _origin,
      _destination;

  String get _draftKey =>
      widget.core?.id ?? 'section:${widget.service.section}';
  bool get _airportService => widget.service.airportCodes.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final type = widget.presetType ??
        (_airportService ? TripType.arrival : TripType.local);
    final saved = widget.controller.readDraft(_draftKey);
    _d = saved == null ? TripDraft(type) : TripDraft.fromJson(type, saved);
    if (_d.airport == null && widget.service.airportCodes.length == 1) {
      _d.airport = widget.service.airportCodes.single;
    }
    if (saved == null) {
      _d.passengers = (widget.controller.stay?.guestsCount ?? 1).clamp(1, 100);
    }
    _time = TextEditingController(text: _d.time);
    _airline = TextEditingController(text: _d.airline);
    _flight = TextEditingController(text: _d.flightNumber);
    _terminal = TextEditingController(text: _d.terminal);
    _origin = TextEditingController(text: _d.origin);
    _destination = TextEditingController(text: _d.destination);
  }

  @override
  void dispose() {
    for (final c in [
      _time,
      _airline,
      _flight,
      _terminal,
      _origin,
      _destination
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _sync() {
    _d
      ..time = _time.text.trim()
      ..airline = _airline.text
      ..flightNumber = _flight.text
      ..terminal = _terminal.text
      ..origin = _origin.text
      ..destination = _destination.text;
  }

  void _changeType(TripType type) {
    _sync();
    final old = _d.toJson();
    setState(() => _d = TripDraft.fromJson(type, old));
  }

  Map<String, FormIssue> get _issues => validateTripPage(
      _d, _page, widget.service, widget.controller.clock.nowWall());

  void _next() {
    _sync();
    if (_issues.isNotEmpty) {
      setState(() => _showIssues = true);
      return;
    }
    setState(() {
      _showIssues = false;
      _page++;
    });
  }

  void _saveAndExit() {
    _sync();
    widget.controller.saveDraft(_draftKey, _d.toJson());
    Navigator.of(context).pop();
  }

  void _ownArrangement() {
    widget.controller.markOwnArrangement(widget.core!);
    Navigator.of(context).pop();
  }

  Future<void> _send() async {
    final l10n = widget.controller.l10n;
    final invalid = firstInvalidTripPage(
        _d, widget.service, widget.controller.clock.nowWall());
    if (invalid != null) {
      setState(() {
        _page = invalid;
        _showIssues = true;
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result =
        await widget.controller.createTrip(tripPayload(_d, widget.service));
    if (!mounted) return;
    switch (result) {
      case ApiOk():
        widget.controller.clearDraft(_draftKey);
        Navigator.of(context).pop();
        showPortalToast(context, l10n.tripSent);
      case ApiFailed():
        setState(() {
          _busy = false;
          _error = failureMessage(l10n, result);
        });
    }
  }

  String? _issue(String field) {
    if (!_showIssues) return null;
    final i = _issues[field];
    return i == null ? null : widget.controller.l10n.issue(i);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.controller.l10n;
    final review = _page == tripPageCount - 1;
    return FormScaffold(
      l10n: l10n,
      title: widget.title,
      page: _page,
      pages: tripPageCount,
      busy: _busy,
      error: _error,
      onRetry: _send,
      onBack: _page == 0 ? null : () => setState(() => _page--),
      info: _d.type.isAirport ? l10n.pickupInfo : null,
      primaryLabel: review ? l10n.send : l10n.nextPage,
      onPrimary: review ? _send : _next,
      secondaryLabel: l10n.saveExit,
      onSecondary: _saveAndExit,
      children: switch (_page) {
        0 => _when(),
        1 => _d.type.isAirport ? _flightPage() : _routePage(),
        2 => [
            TripGroup(
              l10n: widget.controller.l10n,
              draft: _d,
              service: widget.service,
              issueOf: _issue,
              update: setState,
            ),
          ],
        _ => [
            TripReview(
              l10n: widget.controller.l10n,
              draft: _d,
              service: widget.service,
              onEdit: () => setState(() => _page = 0),
            ),
          ],
      },
    );
  }

  List<Widget> _when() {
    final l10n = widget.controller.l10n;
    final today = widget.controller.clock.today();
    final types = [
      if (_airportService) ...[TripType.arrival, TripType.departure],
      TripType.local
    ];
    return [
      if (widget.presetType == null && types.length > 1)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SegmentedButton<TripType>(
            segments: [
              for (final t in types)
                ButtonSegment(
                  value: t,
                  label: Text(
                      switch (t) {
                        TripType.arrival => l10n.arrivalTrip,
                        TripType.departure => l10n.departureTrip,
                        TripType.local => l10n.localTrip,
                      },
                      maxLines: 2,
                      textAlign: TextAlign.center),
                ),
            ],
            selected: {_d.type},
            onSelectionChanged: (s) => _changeType(s.first),
          ),
        ),
      LabeledField(
        label: l10n.dateLabel,
        issue: _issue('day'),
        child: DateField(
          fieldKey: const Key('trip-date'),
          l10n: l10n,
          value: _d.day,
          first: today,
          last: today.add(const Duration(days: 365)),
          onChanged: (d) => setState(() => _d.day = d),
        ),
      ),
      LabeledField(
        label: l10n.timeLabel,
        issue: _issue('time'),
        child: TextField(
          key: const Key('trip-time'),
          controller: _time,
          keyboardType: TextInputType.datetime,
          decoration: const InputDecoration(hintText: 'HH:MM'),
        ),
      ),
      if (widget.core != null)
        TextButton(
          key: const Key('trip-own'),
          onPressed: _ownArrangement,
          child: Text(l10n.arrangeOwn),
        ),
    ];
  }

  List<Widget> _flightPage() {
    final l10n = widget.controller.l10n;
    return [
      LabeledField(
        label: l10n.airport,
        issue: _issue('airport'),
        child: DropdownButtonFormField<String>(
          key: const Key('trip-airport'),
          initialValue: _d.airport,
          items: [
            for (final code in widget.service.airportCodes)
              DropdownMenuItem(value: code, child: Text(code)),
          ],
          onChanged: (v) => setState(() => _d.airport = v),
        ),
      ),
      LabeledField(
        label: l10n.airline,
        issue: _issue('airline'),
        child: TextField(key: const Key('trip-airline'), controller: _airline),
      ),
      LabeledField(
        label: l10n.flightNo,
        issue: _issue('flightNumber'),
        child: TextField(
          key: const Key('trip-flight'),
          controller: _flight,
          textCapitalization: TextCapitalization.characters,
        ),
      ),
      LabeledField(
        label: l10n.terminalOpt,
        child:
            TextField(key: const Key('trip-terminal'), controller: _terminal),
      ),
    ];
  }

  List<Widget> _routePage() {
    final l10n = widget.controller.l10n;
    return [
      LabeledField(
        label: l10n.from,
        issue: _issue('origin'),
        child: TextField(key: const Key('trip-origin'), controller: _origin),
      ),
      LabeledField(
        label: l10n.to,
        issue: _issue('destination'),
        child: TextField(
            key: const Key('trip-destination'), controller: _destination),
      ),
    ];
  }
}
