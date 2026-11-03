import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/resort_settings_controller.dart';
import '../../core/admin_list_strings.dart';
import '../../core/resort_strings.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../core/time_zone_catalog.dart';
import '../../domain/admin_settings.dart';
import '../components/components.dart';
import 'settings_airports.dart';

/// Settings (top bar gear): check-in/out times, time zone, airports and the
/// trip alert lead time, in one form with one Save. Unset values show
/// "Not set"; nothing is pre-filled.
class SettingsWorkspace extends StatelessWidget {
  const SettingsWorkspace({
    super.key,
    required this.settings,
    required this.timeZones,
    required this.isEs,
  });

  final ResortSettingsController settings;
  final TimeZoneCatalog timeZones;
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => Container(
        key: const Key('workspace-admin-settings'),
        alignment: Alignment.topLeft,
        child: switch (settings.status) {
          ResortSettingsStatus.loading =>
            const LinearProgressIndicator(key: Key('settings-loading')),
          ResortSettingsStatus.error => AdminStateLine(
              key: const Key('settings-error'),
              message: AdminListStrings(isEs).loadError,
              actionLabel: AdminListStrings(isEs).retry,
              onAction: settings.load,
              isError: true,
            ),
          ResortSettingsStatus.ready => _SettingsForm(
              key: ObjectKey(settings.settings),
              initial: settings.settings!,
              controller: settings,
              zones: timeZones.zones(),
              isEs: isEs,
            ),
        },
      ),
    );
  }
}

class _SettingsForm extends StatefulWidget {
  const _SettingsForm({
    super.key,
    required this.initial,
    required this.controller,
    required this.zones,
    required this.isEs,
  });

  final AdminSettings initial;
  final ResortSettingsController controller;
  final List<String> zones;
  final bool isEs;

  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  static final RegExp _hhmm = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  final _formKey = GlobalKey<FormState>();
  late final _checkIn = TextEditingController(text: widget.initial.checkInTime);
  late final _checkOut =
      TextEditingController(text: widget.initial.checkOutTime);
  late final _alertLead = TextEditingController(
      text: widget.initial.transportAlertLeadHours?.toString());
  late final _zone = TextEditingController(text: widget.initial.timeZone);
  late List<AirportSetting> _airports = widget.initial.airports;
  String? _zoneError;
  bool _saving = false;

  ResortStrings get _s => ResortStrings(widget.isEs);

  /// The browser list, plus the saved zone if the browser lacks it.
  late final List<String> _zones = {
    ...widget.zones,
    if (widget.initial.timeZone case final z?) z,
  }.toList()
    ..sort();

  @override
  void dispose() {
    for (final c in [_checkIn, _checkOut, _alertLead, _zone]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validateTime(String? value) {
    final text = (value ?? '').trim();
    return text.isEmpty || _hhmm.hasMatch(text) ? null : _s.timeFormat;
  }

  String? _validateLead(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final hours = int.tryParse(text);
    return hours == null || hours < 1 || hours > 168
        ? _s.hoursRange(1, 168)
        : null;
  }

  /// `null` when empty (clears it); the typed text must be a listed zone.
  bool _zoneIsValid() {
    final text = _zone.text.trim();
    final ok = text.isEmpty || _zones.contains(text);
    setState(() => _zoneError = ok ? null : _s.pickListedZone);
    return ok;
  }

  AdminSettings _collect() {
    String? orNull(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    return AdminSettings(
      checkInTime: orNull(_checkIn),
      checkOutTime: orNull(_checkOut),
      timeZone: orNull(_zone),
      airports: _airports,
      transportAlertLeadHours: int.tryParse(_alertLead.text.trim()),
    );
  }

  Future<void> _save() async {
    final formOk = _formKey.currentState!.validate();
    if (!_zoneIsValid() || !formOk) return;
    setState(() => _saving = true);
    try {
      await widget.controller.save(_collect());
      if (mounted) showAdminToast(context, _s.settingsSaved);
    } catch (_) {
      if (!mounted) return;
      showAdminToast(context, _s.saveFailed,
          isError: true, onRetry: _save, isEs: widget.isEs);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickTime(TextEditingController target) async {
    final parts = target.text.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
          hour: int.tryParse(parts.first) ?? 12,
          minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!),
    );
    if (picked == null) return;
    String two(int v) => v.toString().padLeft(2, '0');
    target.text = '${two(picked.hour)}:${two(picked.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        key: const Key('settings-form'),
        padding: const EdgeInsets.all(KachavaTokens.space6),
        children: [
          _header(),
          const SizedBox(height: KachavaTokens.space4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _fields(),
                const SizedBox(height: KachavaTokens.space4),
                SettingsAirportsSection(
                  airports: _airports,
                  onChanged: (next) => setState(() => _airports = next),
                  isEs: widget.isEs,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() => Row(children: [
        Expanded(
          child: Text(_s.settings,
              style: Theme.of(context).textTheme.headlineSmall),
        ),
        FilledButton(
          key: const Key('settings-save'),
          onPressed: _saving ? null : _save,
          child: _saving
              ? Row(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: KachavaTokens.space2),
                  Text(_s.save),
                ])
              : Text(_s.save),
        ),
      ]);

  Widget _fields() => LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 600;
        Widget sized(double width, Widget child) =>
            SizedBox(width: wide ? width : constraints.maxWidth, child: child);
        return Wrap(spacing: KachavaTokens.space4, children: [
          sized(160, _timeField(_s.checkIn, _checkIn, 'settings-check-in')),
          sized(160, _timeField(_s.checkOut, _checkOut, 'settings-check-out')),
          sized(360, _zoneField(wide ? 360 : constraints.maxWidth)),
          sized(160, _leadField()),
        ]);
      });

  Widget _timeField(String label, TextEditingController c, String key) =>
      AdminTextFormField(
        label: label,
        controller: c,
        fieldKey: Key(key),
        hintText: _s.notSet,
        keyboardType: TextInputType.datetime,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
          LengthLimitingTextInputFormatter(5),
        ],
        validator: _validateTime,
        suffixIcon: IconButton(
          key: Key('$key-pick'),
          tooltip: _s.pickTime,
          icon: const Icon(Icons.schedule, size: 20),
          onPressed: () => _pickTime(c),
        ),
        isEs: widget.isEs,
      );

  Widget _leadField() => AdminTextFormField(
        label: _s.alertLead,
        info: _s.alertLeadInfo,
        controller: _alertLead,
        fieldKey: const Key('settings-alert-lead'),
        hintText: _s.notSet,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: _validateLead,
        isEs: widget.isEs,
      );

  /// Searchable IANA dropdown: typing filters the browser's zone list.
  Widget _zoneField(double width) => Padding(
        padding: const EdgeInsets.only(bottom: KachavaTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminFieldLabel(_s.timeZone),
            const SizedBox(height: KachavaTokens.space1),
            Semantics(
              label: _s.timeZone,
              child: DropdownMenu<String>(
                key: const Key('settings-time-zone'),
                controller: _zone,
                width: width,
                menuHeight: 320,
                enableFilter: true,
                requestFocusOnTap: true,
                hintText: _s.notSet,
                errorText: _zoneError,
                initialSelection: widget.initial.timeZone,
                inputDecorationTheme: const InputDecorationTheme(isDense: true),
                onSelected: (_) => setState(() => _zoneError = null),
                dropdownMenuEntries: [
                  for (final z in _zones)
                    DropdownMenuEntry<String>(value: z, label: z),
                ],
              ),
            ),
          ],
        ),
      );
}
