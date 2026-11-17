import 'package:flutter/material.dart';

import '../../core/service_catalog_labels.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../domain/admin_service.dart';
import '../../domain/json_draft.dart';
import '../components/components.dart';
import 'draft_text_fields.dart';

/// On/off switch bound to [path] (a [FormField], so the form sees edits).
class DraftSwitch extends StatelessWidget {
  const DraftSwitch({
    super.key,
    required this.draft,
    required this.path,
    required this.label,
    this.tip,
  });

  final JsonDraft draft;
  final String path;
  final String label;
  final String? tip;

  @override
  Widget build(BuildContext context) => FormField<bool>(
        initialValue: draft.flag(path),
        builder: (field) => MergeSemantics(
          child: Semantics(
            container: true,
            identifier: 'svc-$path',
            child: Row(children: [
              Flexible(child: Text(label)),
              if (tip != null) InfoTooltip(tip!),
              const Spacer(),
              Switch(
                key: Key('svc-$path'),
                value: field.value ?? false,
                onChanged: (v) {
                  field.didChange(v);
                  draft.set(path, v);
                },
              ),
            ]),
          ),
        ),
      );
}

/// One wire value of a dropdown and its label.
typedef DraftOption = (String value, String label);

/// Dropdown bound to [path]. [noneLabel] adds an empty choice (`null`).
class DraftDropdown extends StatelessWidget {
  const DraftDropdown({
    super.key,
    required this.draft,
    required this.path,
    required this.label,
    required this.options,
    this.noneLabel,
    this.tip,
    this.onChanged,
    this.enabled = true,
  });

  final JsonDraft draft;
  final String path;
  final String label;
  final List<DraftOption> options;
  final String? noneLabel;
  final String? tip;
  final ValueChanged<String?>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final current = draft.get(path)?.toString();
    final known = options.any((o) => o.$1 == current);
    return DraftLabelled(
      label: label,
      tip: tip,
      child: Semantics(
        container: true,
        identifier: 'svc-$path',
        child: DropdownButtonFormField<String?>(
          key: Key('svc-$path'),
          initialValue: known ? current : null,
          isExpanded: true,
          decoration: const InputDecoration(isDense: true),
          items: [
            if (noneLabel != null)
              DropdownMenuItem(value: null, child: Text(noneLabel!)),
            for (final (value, text) in options)
              DropdownMenuItem(
                  value: value,
                  child: Text(text, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: enabled
              ? (v) {
                  // The callback sees the previous value still in the draft.
                  onChanged?.call(v);
                  draft.set(path, v);
                }
              : null,
        ),
      ),
    );
  }
}

/// MON..SUN filter chips stored as wire values in week order.
class DraftWeekdays extends StatelessWidget {
  const DraftWeekdays({
    super.key,
    required this.draft,
    required this.path,
    required this.label,
    required this.isEs,
  });

  final JsonDraft draft;
  final String path;
  final String label;
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    final labels = ServiceCatalogLabels(isEs);
    return FormField<Set<String>>(
      initialValue: draft.strings(path).toSet(),
      builder: (field) => DraftLabelled(
        label: label,
        child: Wrap(
          spacing: KachavaTokens.space1,
          runSpacing: KachavaTokens.space1,
          children: [
            for (final day in Weekday.values)
              FilterChip(
                key: Key('svc-$path-${day.wire}'),
                label: Text(labels.weekday(day)),
                selected: field.value!.contains(day.wire),
                onSelected: (on) {
                  final next = {...field.value!};
                  on ? next.add(day.wire) : next.remove(day.wire);
                  field.didChange(next);
                  draft.set(path, [
                    for (final d in Weekday.values)
                      if (next.contains(d.wire)) d.wire
                  ]);
                },
              ),
          ],
        ),
      ),
    );
  }
}
