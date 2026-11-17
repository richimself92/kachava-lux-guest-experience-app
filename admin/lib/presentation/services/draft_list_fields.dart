import 'package:flutter/material.dart';

import '../../core/service_catalog_strings.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../domain/json_draft.dart';
import 'draft_text_fields.dart';

List<String> _splitCsv(String raw) => [
      for (final part in raw.split(','))
        if (part.trim().isNotEmpty) part.trim()
    ];

/// Comma-separated values stored as a list (tags, codes, dates). Each entry
/// must match [pattern] when given; [transform] normalizes case.
class DraftCsvField extends StatelessWidget {
  const DraftCsvField({
    super.key,
    required this.draft,
    required this.path,
    required this.label,
    required this.isEs,
    this.tip,
    this.pattern,
    this.invalidText,
    this.maxEntries = 30,
    this.transform,
  });

  final JsonDraft draft;
  final String path;
  final String label;
  final bool isEs;
  final String? tip;
  final RegExp? pattern;
  final String? invalidText;
  final int maxEntries;
  final String Function(String value)? transform;

  List<String> _parse(String raw) =>
      [for (final v in _splitCsv(raw)) transform?.call(v) ?? v];

  String? _validate(String? raw) {
    final values = _parse(raw ?? '');
    final s = ServiceCatalogStrings(isEs);
    if (values.length > maxEntries) return s.range(0, maxEntries);
    final bad = pattern != null && values.any((v) => !pattern!.hasMatch(v));
    return bad ? invalidText ?? s.codesFormat : null;
  }

  @override
  Widget build(BuildContext context) => DraftLabelled(
        label: label,
        tip: tip,
        child: draftInput(draft, path,
            initial: draft.strings(path).join(', '),
            validator: _validate,
            onChanged: (v) => draft.set(path, _parse(v))),
      );
}

/// Time slots typed as `HH:mm-HH:mm, HH:mm-HH:mm` (resort time).
class DraftTimeSlotsField extends StatelessWidget {
  const DraftTimeSlotsField({
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

  static final RegExp _slot =
      RegExp(r'^(([01]\d|2[0-3]):[0-5]\d)\s*-\s*(([01]\d|2[0-3]):[0-5]\d)$');

  static List<Map<String, String>> parse(String raw) => [
        for (final part in _splitCsv(raw))
          if (_slot.firstMatch(part) case final m?)
            {'start': m.group(1)!, 'end': m.group(3)!}
      ];

  String _initial() {
    final raw = draft.get(path);
    if (raw is! List) return '';
    return raw
        .whereType<Map>()
        .map((slot) => '${slot['start']}-${slot['end']}')
        .join(', ');
  }

  String? _validate(String? raw) {
    final s = ServiceCatalogStrings(isEs);
    for (final part in _splitCsv(raw ?? '')) {
      final m = _slot.firstMatch(part);
      if (m == null) return s.timeFormat;
      if (m.group(1)!.compareTo(m.group(3)!) >= 0) return s.endAfterStart;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => DraftLabelled(
        label: label,
        tip: isEs
            ? 'HH:mm-HH:mm, separados por comas.'
            : 'HH:mm-HH:mm, comma separated.',
        child: draftInput(draft, path,
            initial: _initial(),
            hint: '07:00-11:00',
            validator: _validate,
            onChanged: (v) => draft.set(path, parse(v))),
      );
}

/// A list of `{en, es}` texts, one per line, EN and ES side by side (line
/// *n* of each column forms entry *n*).
class DraftLocalizedListField extends StatelessWidget {
  const DraftLocalizedListField({
    super.key,
    required this.draft,
    required this.path,
    required this.label,
    this.maxEntries = 20,
  });

  final JsonDraft draft;
  final String path;
  final String label;
  final int maxEntries;

  List<Map<String, dynamic>> get _entries => [
        for (final e in (draft.get(path) as List? ?? const []))
          if (e is Map) Map<String, dynamic>.from(e)
      ];

  void _write(String lang, String raw) {
    final lines = raw.split('\n').map((l) => l.trim()).toList();
    final entries = _entries;
    final count =
        [lines.length, entries.length].reduce((a, b) => a > b ? a : b);
    final next = <Map<String, dynamic>>[
      for (var i = 0; i < count && i < maxEntries; i++)
        {
          'en': i < entries.length ? '${entries[i]['en'] ?? ''}' : '',
          'es': i < entries.length ? '${entries[i]['es'] ?? ''}' : '',
          lang: i < lines.length ? lines[i] : '',
        }
    ];
    draft.set(path, [
      for (final e in next)
        if ('${e['en']}'.isNotEmpty || '${e['es']}'.isNotEmpty) e
    ]);
  }

  String _column(String lang) =>
      _entries.map((e) => '${e[lang] ?? ''}').join('\n');

  @override
  Widget build(BuildContext context) => DraftLabelled(
        label: label,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final lang in ['en', 'es']) ...[
            if (lang == 'es') const SizedBox(width: KachavaTokens.space2),
            Expanded(
              child: draftInput(draft, '$path.$lang',
                  initial: _column(lang),
                  hint: lang.toUpperCase(),
                  maxLines: 3,
                  onChanged: (v) => _write(lang, v)),
            ),
          ],
        ]),
      );
}
