import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/resort_strings.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../domain/admin_settings.dart';
import '../components/components.dart';

/// Airports of Settings: a small table (code, name, buffer hours, active)
/// with add / edit / remove. Changes stay local until the screen is saved.
class SettingsAirportsSection extends StatelessWidget {
  const SettingsAirportsSection({
    super.key,
    required this.airports,
    required this.onChanged,
    required this.isEs,
  });

  final List<AirportSetting> airports;
  final ValueChanged<List<AirportSetting>> onChanged;
  final bool isEs;

  ResortStrings get _s => ResortStrings(isEs);

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('settings-airports'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_s.airports, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: KachavaTokens.space2),
        if (airports.isEmpty)
          AdminStateLine(
            key: const Key('settings-airports-empty'),
            message: _s.noAirports,
            actionLabel: _s.addAirport,
            onAction: () => _add(context),
          )
        else ...[
          _header(context),
          for (final a in airports) _row(context, a),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('settings-airport-add'),
              onPressed: () => _add(context),
              icon: const Icon(Icons.add, size: 18),
              label: Text(_s.addAirport),
            ),
          ),
        ],
      ],
    );
  }

  Widget _header(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
        color: KachavaTokens.textSecondary, fontWeight: FontWeight.w500);
    return _AirportGrid(
      code: Text(_s.code, style: style),
      name: Text(_s.name, style: style),
      buffer: Row(mainAxisSize: MainAxisSize.min, children: [
        Flexible(child: Text(_s.buffer, style: style)),
        InfoTooltip(_s.bufferInfo),
      ]),
      active: Text(_s.active, style: style),
      menu: const SizedBox.shrink(),
    );
  }

  Widget _row(BuildContext context, AirportSetting a) => _AirportGrid(
        key: Key('settings-airport-${a.code}'),
        code: Text(a.code, style: const TextStyle(fontWeight: FontWeight.w500)),
        name: TruncatedText(a.name),
        buffer: Text(_hours(a.departureBufferHours)),
        active: Switch(
          key: Key('settings-airport-${a.code}-active'),
          value: a.isActive,
          onChanged: (on) => _replace(a, a.copyWith(isActive: on)),
        ),
        menu: PopupMenuButton<String>(
          key: Key('settings-airport-${a.code}-menu'),
          tooltip: _s.actions,
          onSelected: (action) =>
              action == 'edit' ? _edit(context, a) : _remove(context, a),
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Text(_s.edit)),
            PopupMenuItem(value: 'remove', child: Text(_s.remove)),
          ],
        ),
      );

  String _hours(double? value) {
    if (value == null) return _s.notSet;
    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
    return '$text h';
  }

  Future<void> _add(BuildContext context) async {
    final added = await _openDialog(context, null);
    if (added != null) onChanged([...airports, added]);
  }

  Future<void> _edit(BuildContext context, AirportSetting current) async {
    final edited = await _openDialog(context, current);
    if (edited != null) _replace(current, edited);
  }

  Future<void> _remove(BuildContext context, AirportSetting a) async {
    final ok = await showConfirmDialog(context,
        title: _s.removeAirportQ(a.code),
        confirmLabel: _s.remove,
        cancelLabel: _s.cancel,
        destructive: true);
    if (!ok) return;
    onChanged([
      for (final x in airports)
        if (!identical(x, a)) x
    ]);
  }

  void _replace(AirportSetting old, AirportSetting next) =>
      onChanged([for (final x in airports) identical(x, old) ? next : x]);

  Future<AirportSetting?> _openDialog(
          BuildContext context, AirportSetting? current) =>
      showDialog<AirportSetting>(
        context: context,
        builder: (_) => _AirportDialog(
          current: current,
          takenCodes: {
            for (final a in airports)
              if (!identical(a, current)) a.code
          },
          isEs: isEs,
        ),
      );
}

/// Column widths shared by the header and the rows.
class _AirportGrid extends StatelessWidget {
  const _AirportGrid({
    super.key,
    required this.code,
    required this.name,
    required this.buffer,
    required this.active,
    required this.menu,
  });

  final Widget code;
  final Widget name;
  final Widget buffer;
  final Widget active;
  final Widget menu;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: KachavaTokens.border))),
      child: Row(children: [
        SizedBox(width: 64, child: code),
        Expanded(child: name),
        SizedBox(width: 108, child: buffer),
        SizedBox(width: 64, child: active),
        SizedBox(width: 48, child: menu),
      ]),
    );
  }
}

/// Add/edit one airport: code, name, buffer hours, active.
class _AirportDialog extends StatefulWidget {
  const _AirportDialog({
    required this.current,
    required this.takenCodes,
    required this.isEs,
  });

  final AirportSetting? current;
  final Set<String> takenCodes;
  final bool isEs;

  @override
  State<_AirportDialog> createState() => _AirportDialogState();
}

class _AirportDialogState extends State<_AirportDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _code = widget.current?.code ?? '';
  late String _name = widget.current?.name ?? '';
  late String _buffer = _format(widget.current?.departureBufferHours);
  late bool _active = widget.current?.isActive ?? true;

  ResortStrings get _s => ResortStrings(widget.isEs);

  static String _format(double? v) =>
      v == null ? '' : (v == v.roundToDouble() ? '${v.toInt()}' : '$v');

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(AirportSetting(
      code: _code.trim(),
      name: _name.trim(),
      departureBufferHours: double.parse(_buffer.trim()),
      isActive: _active,
    ));
  }

  String? _validateCode(String? value) {
    final code = (value ?? '').trim();
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(code)) return _s.codeFormat;
    return widget.takenCodes.contains(code) ? _s.codeTaken : null;
  }

  String? _validateBuffer(String? value) {
    final hours = double.tryParse((value ?? '').trim());
    return hours == null || hours < 0 || hours > 24
        ? _s.hoursRange(0, 24)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('airport-dialog'),
      title: Text(widget.current == null ? _s.addAirport : _s.editAirport),
      content: SizedBox(
        width: 360,
        child: Form(key: _formKey, child: _fields()),
      ),
      actions: [
        TextButton(
          key: const Key('airport-dialog-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_s.cancel),
        ),
        FilledButton(
          key: const Key('airport-dialog-save'),
          onPressed: _submit,
          child: Text(_s.save),
        ),
      ],
    );
  }

  Widget _fields() => Column(mainAxisSize: MainAxisSize.min, children: [
        AdminTextFormField(
          label: _s.code,
          isRequired: true,
          initialValue: _code,
          fieldKey: const Key('airport-code'),
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            LengthLimitingTextInputFormatter(3),
            _UpperCaseFormatter(),
          ],
          validator: _validateCode,
          onChanged: (v) => _code = v,
          isEs: widget.isEs,
        ),
        AdminTextFormField(
          label: _s.name,
          isRequired: true,
          initialValue: _name,
          fieldKey: const Key('airport-name'),
          validator: AdminValidators.maxLength(200, widget.isEs),
          onChanged: (v) => _name = v,
          isEs: widget.isEs,
        ),
        AdminTextFormField(
          label: _s.buffer,
          info: _s.bufferInfo,
          isRequired: true,
          initialValue: _buffer,
          fieldKey: const Key('airport-buffer'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: _validateBuffer,
          onChanged: (v) => _buffer = v,
          isEs: widget.isEs,
        ),
        SwitchListTile(
          key: const Key('airport-active'),
          contentPadding: EdgeInsets.zero,
          title: Text(_s.active),
          value: _active,
          onChanged: (v) => setState(() => _active = v),
        ),
      ]);
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
          TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
