import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/stay_strings.dart';
import '../../../domain/admin_catalog_repositories.dart';
import '../../../domain/reservation.dart';
import '../../components/components.dart';
import '../ops_fields.dart';
import 'available_villa_field.dart';

/// "+ New reservation": guest, arrival, departure, then a villa free on
/// those nights; guest count, contact, language and occasion are folded
/// under "Guest data". Server refusals (409 taken, 422 rule) show inline.
class ReservationCreatePanel extends StatefulWidget {
  const ReservationCreatePanel({
    super.key,
    required this.repository,
    required this.villas,
    required this.onClose,
    required this.onCreated,
    required this.isEs,
    this.today,
  });

  final ReservationRepository repository;

  /// Source of the villas available for the chosen nights.
  final VillaRepository villas;

  /// Resort day `YYYY-MM-DD`: the earliest arrival (`null`: no bound).
  final String? today;
  final VoidCallback onClose;

  /// Runs with the new stay id once the server confirmed it.
  final ValueChanged<String> onCreated;
  final bool isEs;

  @override
  State<ReservationCreatePanel> createState() => _ReservationCreatePanelState();
}

class _ReservationCreatePanelState extends State<ReservationCreatePanel> {
  final TextEditingController _checkIn = TextEditingController();
  final TextEditingController _checkOut = TextEditingController();
  String _guest = '';
  String? _villaId;
  String _guests = '';
  String _email = '';
  String _phone = '';
  String? _language;
  String _occasion = '';

  StayStrings get _s => StayStrings(widget.isEs);

  @override
  void initState() {
    super.initState();
    _checkIn.addListener(_datesChanged);
    _checkOut.addListener(_datesChanged);
  }

  @override
  void dispose() {
    _checkIn.dispose();
    _checkOut.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final id = await widget.repository.create(NewReservation(
      guestName: _guest,
      villaId: _villaId!,
      checkIn: _checkIn.text.trim(),
      checkOut: _checkOut.text.trim(),
      guestsCount: int.tryParse(_guests.trim()),
      email: _email,
      phone: _phone,
      language: _language,
      occasion: _occasion,
    ));
    widget.onCreated(id);
    showAdminToastOn(messenger, _s.created);
  }

  void _datesChanged() => setState(() {});

  /// The nights to book once both dates are valid and bookable.
  StayRange? get _range {
    final checkIn = _checkIn.text.trim();
    final checkOut = _checkOut.text.trim();
    if (!IsoDateField.isValid(checkIn) || !IsoDateField.isValid(checkOut)) {
      return null;
    }
    if (_notBeforeToday(checkIn) != null || checkOut.compareTo(checkIn) <= 0) {
      return null;
    }
    return (checkIn: checkIn, checkOut: checkOut);
  }

  String? _notBeforeToday(String? value) {
    final today = widget.today;
    if (today == null) return null;
    return (value ?? '').compareTo(today) < 0 ? _s.notBeforeToday : null;
  }

  String? _failure(Object error) => switch (error) {
        VillaUnavailableException() => _s.villaTaken,
        ReservationRejectedException(:final reason) when reason.isNotEmpty =>
          reason,
        _ => null,
      };

  String? _afterArrival(String? value) {
    final from = _checkIn.text.trim();
    if (!IsoDateField.isValid(from)) return null;
    return (value ?? '').compareTo(from) > 0 ? null : _s.checkOutAfterIn;
  }

  Widget _date(String label, TextEditingController c, String key,
          [FormFieldValidator<String>? extra]) =>
      IsoDateField(
        label: label,
        controller: c,
        fieldKey: Key(key),
        formatMessage: _s.dateFormat,
        pickLabel: _s.pickDate,
        isRequired: true,
        validator: extra,
        firstDay: widget.today,
        isEs: widget.isEs,
      );

  Widget _text(String label, String key, ValueChanged<String> onChanged,
          {bool required = false, TextInputType? type}) =>
      AdminTextFormField(
        label: label,
        isRequired: required,
        fieldKey: Key(key),
        keyboardType: type,
        inputFormatters: type == TextInputType.number
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        validator: AdminValidators.all([
          if (required) AdminValidators.required(widget.isEs),
          AdminValidators.maxLength(200, widget.isEs),
        ]),
        onChanged: onChanged,
        isEs: widget.isEs,
      );

  @override
  Widget build(BuildContext context) {
    return AdminFormPanel(
      key: const Key('reservation-create'),
      title: _s.newReservation,
      onSave: _save,
      onClose: widget.onClose,
      failureMessage: _failure,
      isEs: widget.isEs,
      children: [
        _text(_s.guest, 'reservation-guest', (v) => _guest = v, required: true),
        _date(
            _s.checkInDate, _checkIn, 'reservation-check-in', _notBeforeToday),
        _date(
            _s.checkOutDate, _checkOut, 'reservation-check-out', _afterArrival),
        AvailableVillaField(
          repository: widget.villas,
          range: _range,
          onChanged: (v) => _villaId = v,
          isEs: widget.isEs,
        ),
        AdminAdvancedSection(
          key: const Key('reservation-guest-data'),
          title: _s.guestData,
          children: [
            _text(_s.guests, 'reservation-guests', (v) => _guests = v,
                type: TextInputType.number),
            _text(_s.email, 'reservation-email', (v) => _email = v),
            _text(_s.phone, 'reservation-phone', (v) => _phone = v),
            AdminDropdownFormField<String>(
              label: _s.language,
              fieldKey: const Key('reservation-language'),
              choices: [
                AdminChoice('en', _s.english),
                AdminChoice('es', _s.spanish),
              ],
              onChanged: (v) => _language = v,
              isEs: widget.isEs,
            ),
            _text(_s.occasion, 'reservation-occasion', (v) => _occasion = v),
          ],
        ),
      ],
    );
  }
}
