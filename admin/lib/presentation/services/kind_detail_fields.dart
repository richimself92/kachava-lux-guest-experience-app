import 'package:flutter/material.dart';

import '../../core/admin_list_strings.dart';
import '../../core/service_catalog_labels.dart';
import '../../core/service_catalog_strings.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../domain/admin_service.dart';
import '../../domain/json_draft.dart';
import '../../domain/service_kind_fields.dart';
import 'draft_choice_fields.dart';
import 'draft_list_fields.dart';
import 'draft_text_fields.dart';

/// The input of `<kind.detailField>.<key>` (a [kindFields] entry).
Widget kindDetailField(
    JsonDraft draft, ServiceKind kind, String key, bool isEs) {
  final spec = kindFields(kind).firstWhere((f) => f.key == key);
  return _field(draft, '${kind.detailField}.$key', spec,
      ServiceCatalogLabels(isEs), isEs);
}

Widget _field(JsonDraft draft, String path, KindFieldSpec spec,
    ServiceCatalogLabels labels, bool isEs) {
  final label = labels.kindField(spec.key);
  final tip = labels.kindFieldTip(spec.key);
  return switch (spec.type) {
    KindFieldType.flag =>
      DraftSwitch(draft: draft, path: path, label: label, tip: tip),
    KindFieldType.count => DraftIntField(
        draft: draft,
        path: path,
        label: label,
        tip: tip,
        min: spec.min,
        max: spec.max,
        isEs: isEs),
    KindFieldType.choice => DraftDropdown(
        draft: draft,
        path: path,
        label: label,
        tip: tip,
        noneLabel: spec.nullable ? ServiceCatalogStrings(isEs).none : null,
        options: [for (final o in spec.options) (o, labels.option(o))]),
    KindFieldType.localized => DraftLocalizedField(
        draft: draft, path: path, label: label, tip: tip, isEs: isEs),
    KindFieldType.codes => DraftCsvField(
        draft: draft,
        path: path,
        label: label,
        tip: tip,
        isEs: isEs,
        pattern: RegExp(spec.pattern),
        maxEntries: spec.maxEntries,
        transform: spec.pattern.contains('A-Z')
            ? (v) => v.toUpperCase()
            : (v) => v.toLowerCase()),
    KindFieldType.localizedList => DraftLocalizedListField(
        draft: draft, path: path, label: label, maxEntries: spec.maxEntries),
    KindFieldType.itinerary =>
      ItineraryField(draft: draft, path: path, label: label, isEs: isEs),
  };
}

/// Step-by-step itinerary: title EN/ES and duration per step (other step
/// keys, such as descriptions, are kept as they are).
class ItineraryField extends StatefulWidget {
  const ItineraryField({
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

  static const int maxSteps = 20;

  @override
  State<ItineraryField> createState() => _ItineraryFieldState();
}

class _ItineraryFieldState extends State<ItineraryField> {
  late final List<Map<String, dynamic>> _steps = [
    for (final s in (widget.draft.get(widget.path) as List? ?? const []))
      if (s is Map) Map<String, dynamic>.from(s)
  ];
  late final List<int> _ids = [for (var i = 0; i < _steps.length; i++) i];
  late int _next = _steps.length;

  void _write() => widget.draft.set(widget.path, _steps);

  void _add() => setState(() {
        _steps.add({
          'title': {'en': '', 'es': ''},
          'durationMinutes': null,
        });
        _ids.add(_next++);
        _write();
      });

  void _remove(int index) => setState(() {
        _steps.removeAt(index);
        _ids.removeAt(index);
        _write();
      });

  @override
  Widget build(BuildContext context) {
    final s = ServiceCatalogStrings(widget.isEs);
    return DraftLabelled(
      label: widget.label,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < _steps.length; i++)
          KeyedSubtree(key: ValueKey(_ids[i]), child: _step(i, s)),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('itinerary-add'),
            onPressed: _steps.length >= ItineraryField.maxSteps ? null : _add,
            icon: const Icon(Icons.add, size: 18),
            label: Text(s.t('Add step', 'Agregar paso')),
          ),
        ),
      ]),
    );
  }

  Widget _step(int i, ServiceCatalogStrings s) {
    final step = _steps[i];
    final title = Map<String, dynamic>.from(step['title'] as Map? ?? {});
    return Padding(
      padding: const EdgeInsets.only(bottom: KachavaTokens.space2),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${i + 1}.', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(width: KachavaTokens.space2),
        for (final lang in ['en', 'es']) ...[
          Expanded(
            flex: 3,
            child: TextFormField(
              key: Key('itinerary-${_ids[i]}-$lang'),
              initialValue: '${title[lang] ?? ''}',
              decoration:
                  InputDecoration(isDense: true, hintText: lang.toUpperCase()),
              onChanged: (v) {
                step['title'] = {...title, lang: v};
                title[lang] = v;
                _write();
              },
            ),
          ),
          const SizedBox(width: KachavaTokens.space2),
        ],
        Expanded(
          flex: 2,
          child: TextFormField(
            key: Key('itinerary-${_ids[i]}-minutes'),
            initialValue: '${step['durationMinutes'] ?? ''}',
            decoration: const InputDecoration(isDense: true, hintText: 'min'),
            keyboardType: TextInputType.number,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (v) {
              final n = int.tryParse((v ?? '').trim());
              if ((v ?? '').trim().isEmpty) return null;
              return n == null || n < 1 || n > 1440 ? s.range(1, 1440) : null;
            },
            onChanged: (v) {
              step['durationMinutes'] = int.tryParse(v.trim());
              _write();
            },
          ),
        ),
        IconButton(
          tooltip: AdminListStrings(widget.isEs).remove,
          icon: const Icon(Icons.close),
          onPressed: () => _remove(i),
        ),
      ]),
    );
  }
}
