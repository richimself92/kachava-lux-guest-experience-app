import 'package:flutter/material.dart';

import '../../../core/resort_time.dart';
import '../../../core/theme/kachava_tokens.dart';
import '../../../core/transport_strings.dart';
import '../../../domain/admin_catalog_repositories.dart';
import '../../../domain/list_query.dart';
import '../../../domain/reservation.dart';
import '../../components/components.dart';

/// Searchable stay picker: types a guest name, lists upcoming or in-house
/// stays as "Guest · Villa" from `/admin/stays?q=`.
class StayPickerField extends StatelessWidget {
  const StayPickerField({
    super.key,
    required this.stays,
    required this.selected,
    required this.onSelected,
    required this.isEs,
    this.isRequired = true,
  });

  static const int maxOptions = 10;
  final StayListRepository stays;
  final ReservationRow? selected;

  /// `null` when the text no longer matches the picked stay.
  final ValueChanged<ReservationRow?> onSelected;
  final bool isEs;

  /// Optional pickers (e.g. a task's stay) accept no selection.
  final bool isRequired;

  static String display(ReservationRow s) => '${s.guestName} · ${s.villaName}';

  Future<Iterable<ReservationRow>> _search(TextEditingValue value) async {
    final text = value.text.trim();
    if (text.isEmpty) return const [];
    try {
      final page = await stays.list(ListQuery(q: text, pageSize: maxOptions));
      return page.items.where((s) => s.isOpen);
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = TransportStrings(isEs);
    return Padding(
      padding: const EdgeInsets.only(bottom: KachavaTokens.space4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AdminFieldLabel(s.stay,
            isRequired: isRequired, info: s.stayInfo, readByInput: true),
        const SizedBox(height: KachavaTokens.space1),
        Autocomplete<ReservationRow>(
          displayStringForOption: display,
          optionsBuilder: _search,
          onSelected: onSelected,
          fieldViewBuilder: (context, controller, focus, onSubmit) => Semantics(
            label: s.stay,
            child: TextFormField(
              key: const Key('trip-stay'),
              controller: controller,
              focusNode: focus,
              decoration: InputDecoration(
                  isDense: true,
                  errorMaxLines: 1,
                  hintText: s.guest,
                  prefixIcon: const Icon(Icons.search, size: 20)),
              onChanged: (text) {
                if (selected != null && text != display(selected!)) {
                  onSelected(null);
                }
              },
              validator: (_) =>
                  isRequired && selected == null ? s.pickStay : null,
            ),
          ),
        ),
      ]),
    );
  }
}

/// Resort wall time typed as `YYYY-MM-DD HH:mm` or picked with the
/// calendar button. [toWire] gives `YYYY-MM-DDTHH:mm`.
class TripDateTimeField extends StatelessWidget {
  const TripDateTimeField({
    super.key,
    required this.label,
    required this.controller,
    required this.fieldKey,
    required this.isEs,
    this.isRequired = false,
    this.info,
  });

  static final RegExp _format = RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$');

  final String label;
  final TextEditingController controller;
  final Key fieldKey;
  final bool isEs;
  final bool isRequired;
  final String? info;

  /// `null` for an empty field.
  static String? toWire(String text) {
    final value = text.trim();
    return value.isEmpty ? null : value.replaceFirst(' ', 'T');
  }

  static bool isValid(String text) {
    if (!_format.hasMatch(text)) return false;
    final parsed = DateTime.tryParse('${text.replaceFirst(' ', 'T')}:00Z');
    return parsed != null &&
        '${ResortTime.isoDay(parsed)} ${ResortTime.hhmm(parsed)}' == text;
  }

  String? _validate(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    return isValid(text) ? null : TransportStrings(isEs).dateTimeFormat;
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(now));
    if (time == null) return;
    final picked =
        DateTime.utc(date.year, date.month, date.day, time.hour, time.minute);
    controller.text = '${ResortTime.isoDay(picked)} ${ResortTime.hhmm(picked)}';
  }

  @override
  Widget build(BuildContext context) {
    final s = TransportStrings(isEs);
    return AdminTextFormField(
      label: label,
      info: info,
      isRequired: isRequired,
      controller: controller,
      fieldKey: fieldKey,
      hintText: s.dateTimeHint,
      validator: _validate,
      keyboardType: TextInputType.datetime,
      suffixIcon: Builder(
        builder: (context) => IconButton(
          tooltip: s.pickDateTime,
          icon: const Icon(Icons.calendar_today_outlined, size: 18),
          onPressed: () => _pick(context),
        ),
      ),
      isEs: isEs,
    );
  }
}
