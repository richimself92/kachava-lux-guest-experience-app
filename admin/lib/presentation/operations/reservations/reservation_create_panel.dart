import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/stay_strings.dart';
import '../../../domain/admin_villa.dart';
import '../../../domain/reservation.dart';
import '../../components/components.dart';
import '../ops_fields.dart';

/// "+ New reservation": guest, villa, arrival and departure; guest count,
/// contact, language and occasion are folded under "Guest data".
class ReservationCreatePanel extends StatefulWidget {
  const ReservationCreatePanel({
    super.key,
    required this.repository,
    required this.villas,
    required this.onClose,
    required this.onCreated,
    required this.isEs,
  });

  final ReservationRepository repository;

  /// Active villas to pick from.
  final List<AdminVilla> villas;
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
      isEs: widget.isEs,
      children: [
        _text(_s.guest, 'reservation-guest', (v) => _guest = v, required: true),
        if (widget.villas.isEmpty)
          AdminStateLine(
              key: const Key('reservation-no-villas'), message: _s.noVillas),
        AdminDropdownFormField<String>(
          label: _s.villa,
          isRequired: true,
          fieldKey: const Key('reservation-villa'),
          choices: [for (final v in widget.villas) AdminChoice(v.id, v.name)],
          onChanged: (v) => _villaId = v,
          isEs: widget.isEs,
        ),
        _date(_s.checkInDate, _checkIn, 'reservation-check-in'),
        _date(
            _s.checkOutDate, _checkOut, 'reservation-check-out', _afterArrival),
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
