import 'package:flutter/material.dart';
import '../../application/admin_dashboard_controller.dart';
import '../../core/admin_i18n.dart';
import '../../core/admin_theme.dart';
import '../../domain/admin_stay_entities.dart';

const _dialogTitleStyle = TextStyle(
  fontFamily: 'Libre Baskerville',
  fontSize: 18,
  fontWeight: FontWeight.w700,
  color: KachavaAdminColors.obsidian,
);

/// Opens the modal dialog to register a new Sanctuary Villa.
Future<void> showNewVillaDialog(
        BuildContext context, AdminDashboardController controller) =>
    showDialog<void>(
        context: context,
        builder: (_) => _NewVillaDialog(controller: controller));

/// Opens the modal dialog to create a new Guest Stay & generate a Magic Link.
Future<void> showNewStayDialog(
        BuildContext context, AdminDashboardController controller,
        {String? initialVilla}) =>
    showDialog<void>(
        context: context,
        builder: (_) =>
            _NewStayDialog(controller: controller, initialVilla: initialVilla));

/// Opens the modal dialog to assign Chauffeur, Vehicle, Meeting Point, and Transfer Status.
Future<void> showAssignTransferDialog(BuildContext context,
        AdminDashboardController controller, AdminStayRecord stay) =>
    showDialog<void>(
        context: context,
        builder: (_) =>
            _AssignTransferDialog(controller: controller, stay: stay));

/// Opens the modal dialog to configure Villa Wi-Fi SSID and Passcode for a Stay.
Future<void> showConfigureWifiDialog(BuildContext context,
        AdminDashboardController controller, AdminStayRecord stay) =>
    showDialog<void>(
        context: context,
        builder: (_) =>
            _ConfigureWifiDialog(controller: controller, stay: stay));

class _NewVillaDialog extends StatefulWidget {
  const _NewVillaDialog({required this.controller});
  final AdminDashboardController controller;
  @override
  State<_NewVillaDialog> createState() => _NewVillaDialogState();
}

class _NewVillaDialogState extends State<_NewVillaDialog> {
  final _nameCtrl = TextEditingController(),
      _suiteCtrl = TextEditingController(),
      _guestsCtrl = TextEditingController();
  final _ssidCtrl = TextEditingController(),
      _passCtrl = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _suiteCtrl,
      _guestsCtrl,
      _ssidCtrl,
      _passCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim(), guests = _guestsCtrl.text.trim();
    if (name.isEmpty) return;
    widget.controller.createVilla(
        villaName: name,
        suiteType: _suiteCtrl.text.trim(),
        maxGuests: guests.isEmpty ? '2 Guests' : guests,
        wifiSsid: _ssidCtrl.text.trim(),
        wifiPasscode: _passCtrl.text.trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEs = widget.controller.isEs;
    return AlertDialog(
      backgroundColor: KachavaAdminColors.surfacePaper,
      title: Text(
          AdminI18n.tr(
              isEs, 'Register New Sanctuary Villa', 'Registrar Nueva Villa'),
          style: _dialogTitleStyle),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _field(
                const Key('new-villa-name-input'),
                _nameCtrl,
                AdminI18n.tr(
                    isEs, 'Villa Name / Number', 'Nombre / Número de Villa'),
                AdminI18n.tr(isEs, 'e.g. Villa 110', 'Ej. Villa 110')),
            const SizedBox(height: 10),
            _field(
                const Key('new-villa-suite-input'),
                _suiteCtrl,
                AdminI18n.tr(isEs, 'Suite / Category', 'Categoría / Suite'),
                AdminI18n.tr(
                    isEs, 'e.g. Mayan Sanctuary', 'Ej. Mayan Sanctuary')),
            const SizedBox(height: 10),
            _field(
                const Key('new-villa-guests-input'),
                _guestsCtrl,
                AdminI18n.tr(isEs, 'Capacity', 'Capacidad'),
                AdminI18n.tr(isEs, 'e.g. 4 Guests', 'Ej. 4 Huéspedes')),
            const SizedBox(height: 10),
            _wifiInputsRow(isEs, const Key('new-villa-wifi-ssid-input'),
                _ssidCtrl, const Key('new-villa-wifi-pass-input'), _passCtrl),
          ]),
        ),
      ),
      actions: _dialogActions(
          context,
          isEs,
          const Key('confirm-create-villa-btn'),
          AdminI18n.tr(isEs, 'Save Villa', 'Guardar Villa'),
          _submit),
    );
  }
}

class _NewStayDialog extends StatefulWidget {
  const _NewStayDialog({required this.controller, this.initialVilla});
  final AdminDashboardController controller;
  final String? initialVilla;
  @override
  State<_NewStayDialog> createState() => _NewStayDialogState();
}

class _NewStayDialogState extends State<_NewStayDialog> {
  late String _selectedVilla;
  final _guestCtrl = TextEditingController(),
      _checkInCtrl = TextEditingController();
  final _checkOutCtrl = TextEditingController(),
      _occasionCtrl = TextEditingController();
  final _ssidCtrl = TextEditingController(),
      _passCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final villas = widget.controller.villas;
    if (widget.initialVilla != null &&
        villas.any((v) => v.displayLabel == widget.initialVilla)) {
      _selectedVilla = widget.initialVilla!;
      return;
    }
    final free =
        villas.where((v) => !widget.controller.isVillaOccupied(v.displayLabel));
    _selectedVilla = free.isNotEmpty
        ? free.first.displayLabel
        : (villas.isNotEmpty
            ? villas.first.displayLabel
            : 'Villa 101 — Palm Sanctuary');
  }

  @override
  void dispose() {
    for (final c in [
      _guestCtrl,
      _checkInCtrl,
      _checkOutCtrl,
      _occasionCtrl,
      _ssidCtrl,
      _passCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: DateTime(now.year - 1),
        lastDate: DateTime(now.year + 3));
    if (picked == null || !mounted) return;
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    setState(() =>
        ctrl.text = '${m[picked.month - 1]} ${picked.day}, ${picked.year}');
  }

  Future<void> _submit() async {
    final guestNames = _guestCtrl.text.trim();
    if (guestNames.isEmpty) return;
    await widget.controller.createNewStay(
        villaName: _selectedVilla,
        guestNames: guestNames,
        checkInDate: _checkInCtrl.text.trim().isEmpty
            ? 'Nov 20, 2026'
            : _checkInCtrl.text.trim(),
        checkOutDate: _checkOutCtrl.text.trim().isEmpty
            ? 'Nov 25, 2026'
            : _checkOutCtrl.text.trim(),
        occasion: _occasionCtrl.text.trim(),
        wifiSsid: _ssidCtrl.text.trim(),
        wifiPasscode: _passCtrl.text.trim());
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEs = widget.controller.isEs,
        occ = widget.controller.activeStayForVilla(_selectedVilla);
    return AlertDialog(
      backgroundColor: KachavaAdminColors.surfacePaper,
      title: Text(
          AdminI18n.tr(isEs, 'New Guest Stay & Magic Link',
              'Nuevo Huésped y Crear Link'),
          style: _dialogTitleStyle),
      content: SizedBox(
          width: 460,
          child: SingleChildScrollView(child: _buildForm(isEs, occ))),
      actions: _dialogActions(
          context,
          isEs,
          const Key('confirm-create-stay-btn'),
          AdminI18n.tr(isEs, 'Create & Generate Link', 'Crear y Generar Link'),
          occ != null ? null : _submit),
    );
  }

  Widget _buildForm(bool isEs, AdminStayRecord? occ) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _buildVillaDropdown(isEs),
      if (occ != null) ...[
        const SizedBox(height: 10),
        _buildOccupiedWarning(occ.guestNames, isEs)
      ],
      const SizedBox(height: 10),
      _field(
          const Key('new-stay-guest-input'),
          _guestCtrl,
          AdminI18n.tr(isEs, 'Guest Name(s)', 'Nombre(s) del Huésped'),
          AdminI18n.tr(isEs, 'e.g. Marcus & Elena Sterling',
              'Ej. Marcus y Elena Sterling')),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
            child: _field(
                const Key('new-stay-checkin-input'),
                _checkInCtrl,
                AdminI18n.tr(isEs, 'Check-In Date', 'Fecha Check-In'),
                AdminI18n.tr(isEs, 'e.g. Nov 20, 2026', 'Ej. Nov 20, 2026'),
                suffixIcon: const Icon(Icons.calendar_today, size: 16),
                onTap: () => _pickDate(_checkInCtrl))),
        const SizedBox(width: 10),
        Expanded(
            child: _field(
                const Key('new-stay-checkout-input'),
                _checkOutCtrl,
                AdminI18n.tr(isEs, 'Check-Out Date', 'Fecha Check-Out'),
                AdminI18n.tr(isEs, 'e.g. Nov 25, 2026', 'Ej. Nov 25, 2026'),
                suffixIcon: const Icon(Icons.calendar_today, size: 16),
                onTap: () => _pickDate(_checkOutCtrl))),
      ]),
      const SizedBox(height: 10),
      _field(
          const Key('new-stay-occasion-input'),
          _occasionCtrl,
          AdminI18n.tr(isEs, 'Notes / Occasion', 'Motivo / Notas'),
          AdminI18n.tr(isEs, 'e.g. Honeymoon / Anniversary',
              'Ej. Aniversario / Luna de Miel')),
      const SizedBox(height: 10),
      _wifiInputsRow(isEs, const Key('new-stay-wifi-ssid-input'), _ssidCtrl,
          const Key('new-stay-wifi-pass-input'), _passCtrl),
    ]);
  }

  Widget _buildVillaDropdown(bool isEs) {
    return DropdownButtonFormField<String>(
      key: const Key('new-stay-villa-dropdown'),
      initialValue: _selectedVilla,
      isExpanded: true,
      decoration: InputDecoration(
          labelText: AdminI18n.tr(isEs, 'Select Villa', 'Seleccionar Villa'),
          border: const OutlineInputBorder()),
      items: widget.controller.villas.map((v) {
        final occ = widget.controller.activeStayForVilla(v.displayLabel);
        final text = occ != null
            ? '🔴 ${v.displayLabel} — ${AdminI18n.tr(isEs, "OCCUPIED", "OCUPADA")} (${occ.guestNames})'
            : '🟢 ${v.displayLabel} — ${AdminI18n.tr(isEs, "AVAILABLE", "LIBRE")}';
        return DropdownMenuItem(
            value: v.displayLabel,
            child: Text(text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12)));
      }).toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedVilla = val);
      },
    );
  }

  Widget _buildOccupiedWarning(String guestNames, bool isEs) {
    return Container(
      key: const Key('occupied-villa-warning'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: const Color(0xFFFFDAD6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFBA1A1A))),
      child: Text(
          AdminI18n.tr(
              isEs,
              '⚠️ Villa Occupied by $guestNames. Please Check-Out / Release this villa first, or select a FREE (🟢) villa.',
              '⚠️ Villa Ocupada por $guestNames. Primero pulsa "Dar Salida / Liberar Villa" en su tarjeta o elige una villa LIBRE (🟢).'),
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF93000A))),
    );
  }
}

class _ConfigureWifiDialog extends StatefulWidget {
  const _ConfigureWifiDialog({required this.controller, required this.stay});
  final AdminDashboardController controller;
  final AdminStayRecord stay;
  @override
  State<_ConfigureWifiDialog> createState() => _ConfigureWifiDialogState();
}

class _ConfigureWifiDialogState extends State<_ConfigureWifiDialog> {
  late final _ssidCtrl = TextEditingController(text: widget.stay.wifiSsid);
  late final _passCtrl = TextEditingController(text: widget.stay.wifiPasscode);

  @override
  void dispose() {
    _ssidCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ssid = _ssidCtrl.text.trim(), pass = _passCtrl.text.trim();
    if (ssid.isEmpty || pass.isEmpty) return;
    await widget.controller.updateStayWifi(
        stayId: widget.stay.stayId, wifiSsid: ssid, wifiPasscode: pass);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEs = widget.controller.isEs;
    return AlertDialog(
      backgroundColor: KachavaAdminColors.surfacePaper,
      title: Text(
          AdminI18n.tr(isEs, 'Configure Villa Wi-Fi Network',
              'Configurar Red Wi-Fi de la Villa'),
          style: _dialogTitleStyle),
      content: SizedBox(
        width: 400,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _field(
              const Key('wifi-ssid-input'),
              _ssidCtrl,
              AdminI18n.tr(isEs, 'Wi-Fi Network (SSID)', 'Red Wi-Fi (SSID)'),
              AdminI18n.tr(
                  isEs, 'e.g. Kachava_Villa_104', 'Ej. Kachava_Villa_104')),
          const SizedBox(height: 10),
          _field(
              const Key('wifi-pass-input'),
              _passCtrl,
              AdminI18n.tr(isEs, 'Wi-Fi Passcode', 'Contraseña Wi-Fi'),
              AdminI18n.tr(isEs, 'e.g. Santuario2026', 'Ej. Santuario2026')),
        ]),
      ),
      actions: _dialogActions(context, isEs, const Key('confirm-wifi-btn'),
          AdminI18n.tr(isEs, 'Save Wi-Fi', 'Guardar Wi-Fi'), _submit),
    );
  }
}

class _AssignTransferDialog extends StatefulWidget {
  const _AssignTransferDialog({required this.controller, required this.stay});
  final AdminDashboardController controller;
  final AdminStayRecord stay;
  @override
  State<_AssignTransferDialog> createState() => _AssignTransferDialogState();
}

class _AssignTransferDialogState extends State<_AssignTransferDialog> {
  static const _statuses = ['Confirmed', 'En Route', 'Completed'];
  final _driverCtrl = TextEditingController(),
      _meetingCtrl = TextEditingController();
  late String _status = _statuses.contains(widget.stay.transfer.transferStatus)
      ? widget.stay.transfer.transferStatus
      : 'Confirmed';

  @override
  void dispose() {
    _driverCtrl.dispose();
    _meetingCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await widget.controller.updateTransferDispatch(
        stayId: widget.stay.stayId,
        chauffeurId: widget.stay.transfer.assignedChauffeurId,
        transferStatus: _status,
        driverAndVehicle: _driverCtrl.text.trim(),
        meetingPoint: _meetingCtrl.text.trim());
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEs = widget.controller.isEs;
    return AlertDialog(
      backgroundColor: KachavaAdminColors.surfacePaper,
      title: Text(
          AdminI18n.tr(isEs, 'Assign Chauffeur & Meeting Point',
              'Asignar Chofer y Punto de Encuentro'),
          style: _dialogTitleStyle),
      content: SizedBox(
        width: 440,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _field(
              const Key('transfer-driver-input'),
              _driverCtrl,
              AdminI18n.tr(isEs, 'Chauffeur & Vehicle', 'Chofer y Vehículo'),
              AdminI18n.tr(isEs, 'e.g. Carlos · Escalade ESV #04',
                  'Ej. Carlos · Escalade ESV #04')),
          const SizedBox(height: 10),
          _field(
              const Key('transfer-meeting-point-input'),
              _meetingCtrl,
              AdminI18n.tr(isEs, 'Meeting Point / Notes', 'Punto de Encuentro'),
              AdminI18n.tr(isEs, 'e.g. Terminal 3 FBO · Gate 4',
                  'Ej. Terminal 3 FBO · Puerta 4')),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
              key: const Key('transfer-status-dropdown'),
              initialValue: _status,
              isExpanded: true,
              decoration: InputDecoration(
                  labelText: AdminI18n.tr(
                      isEs, 'Transfer Status', 'Estatus del Traslado'),
                  border: const OutlineInputBorder()),
              items: _statuses
                  .map((s) => DropdownMenuItem(
                      value: s, child: Text(AdminI18n.statusLabel(s, isEs))))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
              }),
        ]),
      ),
      actions: _dialogActions(
          context,
          isEs,
          const Key('confirm-assign-transfer-btn'),
          AdminI18n.tr(isEs, 'Save Assignment', 'Guardar Asignación'),
          _submit),
    );
  }
}

Widget _wifiInputsRow(bool isEs, Key ssidKey, TextEditingController ssidCtrl,
        Key passKey, TextEditingController passCtrl) =>
    Row(children: [
      Expanded(
          child: _field(
              ssidKey,
              ssidCtrl,
              AdminI18n.tr(isEs, 'Wi-Fi Network (SSID)', 'Red Wi-Fi (SSID)'),
              AdminI18n.tr(
                  isEs, 'e.g. Kachava_Villa_104', 'Ej. Kachava_Villa_104'))),
      const SizedBox(width: 10),
      Expanded(
          child: _field(
              passKey,
              passCtrl,
              AdminI18n.tr(isEs, 'Wi-Fi Passcode', 'Contraseña Wi-Fi'),
              AdminI18n.tr(isEs, 'e.g. Santuario2026', 'Ej. Santuario2026'))),
    ]);

List<Widget> _dialogActions(BuildContext context, bool isEs, Key btnKey,
        String label, VoidCallback? onPressed) =>
    [
      TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AdminI18n.tr(isEs, 'Cancel', 'Cancelar'))),
      ElevatedButton(
          key: btnKey,
          style: ElevatedButton.styleFrom(
              backgroundColor: KachavaAdminColors.zapotePrimary,
              foregroundColor: Colors.white),
          onPressed: onPressed,
          child: Text(label)),
    ];

Widget _field(
        Key fieldKey, TextEditingController ctrl, String label, String hint,
        {Widget? suffixIcon, VoidCallback? onTap}) =>
    TextField(
        key: fieldKey,
        controller: ctrl,
        onTap: onTap,
        decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            suffixIcon: suffixIcon,
            border: const OutlineInputBorder()));
