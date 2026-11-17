import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/admin_list_strings.dart';
import '../../../core/resort_time.dart';
import '../../../core/theme/kachava_tokens.dart';
import '../../../core/transport_strings.dart';
import '../../../domain/admin_service.dart';
import '../../../domain/admin_settings.dart';
import '../../../domain/reservation.dart';
import '../../../domain/admin_trip.dart';
import '../../../domain/list_query.dart';
import '../../../domain/transport_provider.dart';
import '../../../domain/trip_repository.dart';
import '../../components/components.dart';
import 'trip_form_fields.dart';

part 'trip_create_fields.dart';

/// "+ New trip" by staff on behalf of a guest: stay, transport service and
/// vehicle, type-specific fields (airport + flight, or origin/destination),
/// passengers. Airport pickups may stay empty: the backend suggests one and
/// the toast shows it. Optional fields sit under "More".
class TripCreatePanel extends StatefulWidget {
  const TripCreatePanel({
    super.key,
    required this.repositories,
    required this.settings,
    required this.resortTime,
    required this.providers,
    required this.onClose,
    required this.onCreated,
    required this.isEs,
    this.onOpenSettings,
  });

  /// Backend maximum page: every transport service / vehicle at once.
  static const ListQuery servicesQuery = ListQuery(
      pageSize: 100,
      sort: ListSort('order'),
      filters: {'kind': 'TRANSPORT', 'status': 'ACTIVE'});
  static const ListQuery vehiclesQuery = ListQuery(
      pageSize: 100, sort: ListSort('order'), filters: {'status': 'ACTIVE'});

  final TransportRepositories repositories;
  final AdminSettings? settings;
  final ResortTime resortTime;
  final List<TransportProvider> providers;
  final VoidCallback onClose;
  final ValueChanged<AdminTrip> onCreated;
  final bool isEs;
  final VoidCallback? onOpenSettings;

  @override
  State<TripCreatePanel> createState() => _TripCreatePanelState();
}

class _TripCreatePanelState extends State<TripCreatePanel> {
  final _flightTime = TextEditingController();
  final _pickup = TextEditingController();
  List<AdminService> _services = const [];
  List<ServiceItem> _vehicles = const [];
  ReservationRow? _stay;
  String? _serviceId;
  String? _itemId;
  String _type = TripValues.types.first;
  late String? _airport = _airports.firstOrNull?.code;
  String _airline = '', _number = '', _origin = '', _destination = '';
  String _passengers = '1', _luggage = '0', _wait = '';
  String _guestNotes = '', _notes = '';
  String? _providerId;
  bool _roundTrip = false;

  /// `details` of a 422 SETTINGS_REQUIRED on save.
  List<String>? _missingSettings;

  TransportStrings get _s => TransportStrings(widget.isEs);
  bool get _isAirport => TripValues.isAirport(_type);
  List<AirportSetting> get _airports =>
      (widget.settings?.airports ?? const []).where((a) => a.isActive).toList();
  ServiceItem? get _vehicle =>
      _vehicles.where((v) => v.id == _itemId).firstOrNull;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _flightTime.dispose();
    _pickup.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    try {
      final page = await widget.repositories.services
          .list(TripCreatePanel.servicesQuery);
      if (!mounted) return;
      setState(() {
        _services = page.items;
        if (_services.length == 1) _selectService(_services.single.id);
      });
    } catch (_) {
      // The dropdown stays empty ("No transport services").
    }
  }

  void _selectService(String? id) {
    _serviceId = id;
    _itemId = null;
    _vehicles = const [];
    if (id != null) _loadVehicles(id);
  }

  Future<void> _loadVehicles(String serviceId) async {
    try {
      final page = await widget.repositories.services
          .listItems(serviceId, TripCreatePanel.vehiclesQuery);
      if (mounted && _serviceId == serviceId) {
        setState(() => _vehicles = page.items);
      }
    } catch (_) {
      // Vehicle stays optional.
    }
  }

  NewTripRequest _request() => NewTripRequest(
        stayId: _stay!.id,
        serviceId: _serviceId!,
        itemId: _itemId,
        type: _type,
        airportCode: _isAirport ? _airport : null,
        flight: _isAirport
            ? TripFlightInput(
                airline: _airline.trim(),
                number: _number.trim(),
                scheduledAt: TripDateTimeField.toWire(_flightTime.text)!)
            : null,
        pickupAt: TripDateTimeField.toWire(_pickup.text),
        origin: _isAirport ? null : _origin,
        destination: _isAirport ? null : _destination,
        roundTrip: _isAirport ? null : _roundTrip,
        waitMinutes: _isAirport ? null : int.tryParse(_wait.trim()),
        passengers: int.parse(_passengers.trim()),
        luggage: int.tryParse(_luggage.trim()),
        guestNotes: _guestNotes,
        notes: _notes,
        providerId: _providerId,
      );

  /// Throws on failure so the form stays open ("Couldn't save").
  Future<void> _save() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final trip = await widget.repositories.trips.create(_request());
      widget.onCreated(trip);
      showAdminToastOn(
          messenger,
          _s.tripCreated(
              widget.resortTime.label(trip.pickupAt, isEs: widget.isEs)));
    } on SettingsRequiredException catch (error) {
      if (mounted) setState(() => _missingSettings = error.details);
      // The inline link may be scrolled away: the toast carries it too.
      showAdminToastOn(messenger, _s.settingsMissing,
          isError: true,
          actionLabel: _s.setUpInSettings,
          onRetry: widget.onOpenSettings,
          isEs: widget.isEs);
      rethrow;
    }
  }

  String? _count(String? value, {required int min, int? max}) {
    final n = int.tryParse((value ?? '').trim());
    if (n == null) return _s.wholeNumber;
    if (n < min) return _s.atLeastOne;
    return max != null && n > max ? _s.overCapacity(max) : null;
  }

  @override
  Widget build(BuildContext context) {
    return AdminFormPanel(
      title: _s.newTrip,
      onSave: _save,
      onClose: widget.onClose,
      isEs: widget.isEs,
      children: [
        if (_missingSettings != null) _setupLink(_s.settingsMissing),
        StayPickerField(
          stays: widget.repositories.stays,
          selected: _stay,
          onSelected: (stay) => setState(() => _stay = stay),
          isEs: widget.isEs,
        ),
        ..._serviceFields(),
        AdminDropdownFormField<String>(
          label: _s.type,
          fieldKey: const Key('trip-type'),
          initialValue: _type,
          choices: [
            for (final t in TripValues.types) AdminChoice(t, _s.typeLabel(t)),
          ],
          onChanged: (v) => setState(() => _type = v ?? _type),
          isEs: widget.isEs,
        ),
        if (_isAirport) ..._airportFields() else ..._localFields(),
        ..._countFields(),
        AdminAdvancedSection(
          key: const Key('trip-more'),
          title: AdminListStrings(widget.isEs).more,
          children: _moreFields(),
        ),
      ],
    );
  }

  Widget _setupLink(String message) => Padding(
        padding: const EdgeInsets.only(bottom: KachavaTokens.space4),
        child: SettingsSetupLink(
          key: const Key('trip-form-settings-missing'),
          message: message,
          linkLabel: _s.setUpInSettings,
          onOpenSettings: widget.onOpenSettings ?? () {},
        ),
      );

  void _update(VoidCallback change) => setState(change);
}
