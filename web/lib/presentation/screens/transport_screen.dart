import 'package:flutter/material.dart';
import '../../application/sanctuary_controller.dart';
import '../../core/constants/screen_id.dart';
import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';

/// Screen 2: Private Aviation & Transfer (`transport`).
class TransportScreen extends StatefulWidget {
  const TransportScreen({super.key, required this.controller});

  final SanctuaryController controller;

  @override
  State<TransportScreen> createState() => _TransportScreenState();
}

class _TransportScreenState extends State<TransportScreen> {
  late final TextEditingController _dateCtrl;
  late final TextEditingController _airportCtrl;
  late final TextEditingController _airlineCtrl;
  late final TextEditingController _flightCtrl;
  late final TextEditingController _terminalCtrl;
  late final TextEditingController _landingCtrl;
  bool _isEditing = false;

  static String _cleanVal(String raw) {
    final v = raw.trim();
    return (v.isEmpty || v == 'Pending' || v == 'TBD') ? '' : v;
  }

  static bool _isPending(String raw) => _cleanVal(raw).isEmpty;

  @override
  void initState() {
    super.initState();
    final t = widget.controller.transport;
    _dateCtrl = TextEditingController(text: _cleanVal(t.arrivalDate));
    _airportCtrl = TextEditingController(text: _cleanVal(t.arrivalAirport));
    _airlineCtrl = TextEditingController(text: _cleanVal(t.airline));
    _flightCtrl = TextEditingController(text: _cleanVal(t.flightNumber));
    _terminalCtrl = TextEditingController(text: _cleanVal(t.terminalBay));
    _landingCtrl = TextEditingController(text: _cleanVal(t.estimatedLanding));
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _airportCtrl.dispose();
    _airlineCtrl.dispose();
    _flightCtrl.dispose();
    _terminalCtrl.dispose();
    _landingCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickArrivalDate() async {
    final stay = widget.controller.stay;
    final picked = await showDatePicker(
      context: context,
      initialDate: stay.checkInDateTime,
      firstDate: stay.checkInDateTime,
      lastDate: stay.checkOutDateTime,
    );
    if (!mounted || picked == null) return;
    final y = picked.year.toString();
    final m = picked.month.toString().padLeft(2, '0');
    final d = picked.day.toString().padLeft(2, '0');
    setState(() => _dateCtrl.text = '$y-$m-$d');
  }

  Future<void> _saveFlightUpdate() async {
    final current = widget.controller.transport;
    await widget.controller.updateFlightDetails(
      current.copyWith(
        arrivalDate: _dateCtrl.text.trim(),
        arrivalAirport: _airportCtrl.text.trim(),
        airline: _airlineCtrl.text.trim(),
        flightNumber: _flightCtrl.text.trim(),
        terminalBay: _terminalCtrl.text.trim(),
        estimatedLanding: _landingCtrl.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.controller.transport;
    final i18n = widget.controller.i18n;
    final noFlight = _isPending(t.flightNumber);
    return ListView(
      key: const Key('screen-transport'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 84),
      children: [
        Text(i18n.t('INCLUDED WITH YOUR STAY', 'INCLUIDO EN TU ESTANCIA'),
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: KachavaColors.secondary)),
        const SizedBox(height: 4),
        Text(
            i18n.t('Private Airport Transportation',
                'Transporte Privado de Aeropuerto'),
            style: const TextStyle(
                fontFamily: KachavaTheme.serifFamily,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: KachavaColors.primary)),
        const SizedBox(height: 12),
        if (noFlight) _buildPendingCard() else _buildConfirmationCard(),
        const SizedBox(height: 12),
        if (noFlight || _isEditing) _buildEditForm() else _buildActionButtons(),
        const SizedBox(height: 14),
        _buildChauffeurCard(),
      ],
    );
  }

  Widget _buildPendingCard() {
    final i18n = widget.controller.i18n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.flight_takeoff, color: KachavaColors.secondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                i18n.t(
                    'Pending Flight Details — Please enter your arrival flight below so HOST ADMIN can assign your chauffeur and meeting point.',
                    'Datos de Vuelo Pendientes — Ingresa tu vuelo de llegada abajo para que HOST ADMIN asigne tu chofer y punto de encuentro.'),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: KachavaColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationCard() {
    final t = widget.controller.transport;
    final i18n = widget.controller.i18n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    i18n.t('Transportation Registered ✓',
                        'Transporte Registrado ✓'),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: KachavaColors.confirmedGreen),
                  ),
                ),
                Text(
                  t.status.isEmpty
                      ? i18n.t('REGISTERED', 'REGISTRADO')
                      : t.status.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: KachavaColors.primary),
                ),
              ],
            ),
            const Divider(height: 16),
            if (t.arrivalDate.isNotEmpty)
              _buildInfoRow(Icons.event_outlined, t.arrivalDate),
            _buildInfoRow(Icons.location_on_outlined, t.arrivalAirport),
            _buildInfoRow(
                Icons.flight_land, '${t.airline} · ${t.flightNumber}'),
            _buildInfoRow(
                Icons.schedule, '${t.estimatedLanding} · ${t.terminalBay}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: KachavaColors.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: KachavaColors.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final i18n = widget.controller.i18n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          key: const Key('transport-edit-flight-btn'),
          style: ElevatedButton.styleFrom(
              backgroundColor: KachavaColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12)),
          onPressed: () => setState(() => _isEditing = true),
          icon: const Icon(Icons.edit_calendar, size: 17),
          label: Text(i18n.t('EDIT FLIGHT DETAILS', 'EDITAR DATOS DE VUELO')),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => widget.controller.navigateTo(ScreenId.concierge),
          icon: const Icon(Icons.support_agent, size: 17),
          label: Text(i18n.t('MESSAGE CONCIERGE HOST ADMIN',
              'MENSAJE A CONCIERGE HOST ADMIN')),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    final i18n = widget.controller.i18n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
                i18n.t('Arrival Flight & Transfer Details',
                    'Datos de Vuelo de Llegada y Traslado'),
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: KachavaColors.primary)),
            const SizedBox(height: 8),
            _buildDateField(i18n),
            const SizedBox(height: 8),
            _buildTextField(
                'transport-airport-input',
                _airportCtrl,
                i18n.t('Arrival Airport', 'Aeropuerto de Llegada'),
                i18n.t('e.g. Cancun International (CUN)',
                    'Ej. Aeropuerto Internacional de Cancún (CUN)')),
            const SizedBox(height: 8),
            _buildTextField(
                'transport-airline-input',
                _airlineCtrl,
                i18n.t('Airline', 'Aerolínea'),
                i18n.t('e.g. Aeroméxico, American Airlines',
                    'Ej. Aeroméxico, American Airlines')),
            const SizedBox(height: 8),
            _buildTextField(
                'transport-flight-number-input',
                _flightCtrl,
                i18n.t('Flight Number', 'Número de Vuelo'),
                i18n.t('e.g. AM 420', 'Ej. AM 420')),
            const SizedBox(height: 8),
            _buildTextField(
                'transport-terminal-input',
                _terminalCtrl,
                i18n.t('Terminal', 'Terminal'),
                i18n.t('e.g. Terminal 3', 'Ej. Terminal 3')),
            const SizedBox(height: 8),
            _buildTextField(
                'transport-landing-input',
                _landingCtrl,
                i18n.t('Estimated Arrival Time', 'Hora Estimada de Llegada'),
                i18n.t('e.g. 14:30', 'Ej. 14:30')),
            const SizedBox(height: 10),
            ElevatedButton(
              key: const Key('transport-save-flight-btn'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: KachavaColors.primary,
                  foregroundColor: Colors.white),
              onPressed: _saveFlightUpdate,
              child: Text(i18n.t(
                  'SAVE & SYNC WITH HOST ADMIN', 'GUARDAR Y SINCRONIZAR')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(dynamic i18n) {
    return TextField(
      key: const Key('transport-arrival-date-input'),
      controller: _dateCtrl,
      readOnly: true,
      onTap: _pickArrivalDate,
      decoration: InputDecoration(
        labelText: i18n.t('Arrival Date', 'Fecha de Llegada'),
        hintText: i18n.t('Select arrival date', 'Seleccionar fecha de llegada'),
        suffixIcon: const Icon(Icons.calendar_today, size: 16),
      ),
    );
  }

  Widget _buildTextField(
      String keyName, TextEditingController ctrl, String label, String hint) {
    return TextField(
      key: Key(keyName),
      controller: ctrl,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  Widget _buildChauffeurCard() {
    final t = widget.controller.transport;
    final i18n = widget.controller.i18n;
    final awaiting =
        t.assignedDriver.trim().isEmpty && t.meetingPoint.trim().isEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              i18n.t('CHAUFFEUR & MEETING POINT (HOST ADMIN)',
                  'CHOFER Y PUNTO DE ENCUENTRO (HOST ADMIN)'),
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: KachavaColors.secondary),
            ),
            const SizedBox(height: 6),
            if (awaiting)
              Text(
                i18n.t(
                  'Awaiting chauffeur & meeting point assignment by HOST ADMIN.',
                  'Pendiente de asignación de chofer y punto de encuentro por HOST ADMIN.',
                ),
                style: const TextStyle(fontSize: 12),
              )
            else ...[
              Text(
                  '${i18n.t("Chauffeur", "Chofer")}: ${t.assignedDriver.isEmpty ? "HOST ADMIN" : t.assignedDriver}',
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: KachavaColors.primary)),
              if (t.vehicleModel.isNotEmpty)
                Text('${i18n.t("Vehicle", "Vehículo")}: ${t.vehicleModel}',
                    style: const TextStyle(fontSize: 12)),
              Text(
                  '${i18n.t("Meeting Point", "Punto de Encuentro")}: ${t.meetingPoint.isEmpty ? t.terminalBay : t.meetingPoint}',
                  style: const TextStyle(fontSize: 12)),
              Text('${i18n.t("Status", "Estatus")}: ${t.status}',
                  style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: KachavaColors.confirmedGreen)),
            ],
          ],
        ),
      ),
    );
  }
}
