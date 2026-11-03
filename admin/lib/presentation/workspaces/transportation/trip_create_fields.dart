part of 'trip_create_panel.dart';

/// Field builders of [TripCreatePanel] (type-specific groups and "More").
extension _TripCreateFields on _TripCreatePanelState {
  List<Widget> _serviceFields() => [
        if (_services.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: KachavaTokens.space4),
            child: Text(_s.noTransportServices,
                key: const Key('trip-no-services')),
          ),
        AdminDropdownFormField<String>(
          key: ValueKey('service-${_services.length}'),
          label: _s.service,
          isRequired: true,
          fieldKey: const Key('trip-service'),
          initialValue: _serviceId,
          choices: [
            for (final s in _services)
              AdminChoice(s.id, s.name.of(isEs: widget.isEs)),
          ],
          onChanged: (v) => _update(() => _selectService(v)),
          isEs: widget.isEs,
        ),
        AdminDropdownFormField<String?>(
          key: ValueKey('vehicle-$_serviceId-${_vehicles.length}'),
          label: _s.vehicle,
          fieldKey: const Key('trip-vehicle'),
          initialValue: _itemId,
          choices: [
            AdminChoice<String?>(null, _s.anyVehicle),
            for (final v in _vehicles)
              AdminChoice<String?>(v.id, _vehicleLabel(v)),
          ],
          onChanged: (v) => _update(() => _itemId = v),
          isEs: widget.isEs,
        ),
      ];

  String _vehicleLabel(ServiceItem v) => [
        v.name.of(isEs: widget.isEs),
        if (v.capacity case final c?)
          '${c.passengers} ${_s.passengers.toLowerCase()}',
      ].join(' · ');

  List<Widget> _airportFields() => [
        if (_airports.isEmpty)
          _setupLink(_s.noAirports)
        else
          AdminDropdownFormField<String>(
            label: _s.airport,
            isRequired: true,
            fieldKey: const Key('trip-airport'),
            initialValue: _airport,
            choices: [
              for (final a in _airports)
                AdminChoice(a.code, '${a.code} · ${a.name}'),
            ],
            onChanged: (v) => _airport = v,
            isEs: widget.isEs,
          ),
        _text(_s.airline, 'trip-airline', _airline, (v) => _airline = v,
            required: true),
        _text(
            _s.flightNumber, 'trip-flight-number', _number, (v) => _number = v,
            required: true),
        TripDateTimeField(
          label: _s.flightTime,
          controller: _flightTime,
          fieldKey: const Key('trip-flight-time'),
          isRequired: true,
          info: _s.pickupInfoLocal,
          isEs: widget.isEs,
        ),
        TripDateTimeField(
          label: _s.pickup,
          controller: _pickup,
          fieldKey: const Key('trip-pickup'),
          info: _s.pickupInfoAirport,
          isEs: widget.isEs,
        ),
      ];

  List<Widget> _localFields() => [
        _text(_s.origin, 'trip-origin', _origin, (v) => _origin = v,
            required: true),
        _text(_s.destination, 'trip-destination', _destination,
            (v) => _destination = v,
            required: true),
        TripDateTimeField(
          label: _s.pickup,
          controller: _pickup,
          fieldKey: const Key('trip-pickup'),
          isRequired: true,
          info: _s.pickupInfoLocal,
          isEs: widget.isEs,
        ),
      ];

  List<Widget> _countFields() => [
        _text(_s.passengers, 'trip-passengers', _passengers,
            (v) => _passengers = v,
            required: true,
            digits: true,
            validator: (v) =>
                _count(v, min: 1, max: _vehicle?.capacity?.passengers)),
        _text(_s.luggage, 'trip-luggage', _luggage, (v) => _luggage = v,
            digits: true,
            validator: (v) => (v ?? '').trim().isEmpty
                ? null
                : _count(v, min: 0, max: _vehicle?.capacity?.luggage)),
      ];

  List<Widget> _moreFields() => [
        AdminDropdownFormField<String?>(
          label: _s.provider,
          fieldKey: const Key('trip-provider'),
          initialValue: _providerId,
          choices: [
            AdminChoice<String?>(null, _s.none),
            for (final p in widget.providers.where((p) => p.isActive))
              AdminChoice<String?>(p.id, p.name),
          ],
          onChanged: (v) => _providerId = v,
          isEs: widget.isEs,
        ),
        if (!_isAirport) ...[
          SwitchListTile(
            key: const Key('trip-round-trip'),
            contentPadding: EdgeInsets.zero,
            title: Text(_s.roundTrip),
            value: _roundTrip,
            onChanged: (v) => _update(() => _roundTrip = v),
          ),
          _text(_s.waitMinutes, 'trip-wait', _wait, (v) => _wait = v,
              digits: true),
        ],
        _text(_s.guestNotes, 'trip-guest-notes', _guestNotes,
            (v) => _guestNotes = v,
            lines: 2),
        _text(_s.notes, 'trip-notes', _notes, (v) => _notes = v, lines: 2),
      ];

  Widget _text(String label, String key, String initial,
          ValueChanged<String> onChanged,
          {bool required = false,
          bool digits = false,
          int lines = 1,
          FormFieldValidator<String>? validator}) =>
      AdminTextFormField(
        label: label,
        isRequired: required,
        initialValue: initial,
        fieldKey: Key(key),
        maxLines: lines,
        keyboardType: digits ? TextInputType.number : null,
        inputFormatters:
            digits ? [FilteringTextInputFormatter.digitsOnly] : null,
        validator: validator ??
            AdminValidators.maxLength(lines > 1 ? 2000 : 200, widget.isEs),
        onChanged: onChanged,
        isEs: widget.isEs,
      );
}
