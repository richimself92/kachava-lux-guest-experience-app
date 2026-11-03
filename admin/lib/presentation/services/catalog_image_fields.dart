import 'package:flutter/material.dart';

import '../../application/service_catalog_deps.dart';
import '../../core/admin_list_strings.dart';
import '../../core/service_catalog_strings.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../domain/admin_service.dart';
import '../../domain/uploads.dart';
import '../components/components.dart';

typedef ImageJson = Map<String, dynamic>;

/// One catalog photo: upload (signed, JPEG/PNG/WebP <= 5 MB), alt EN/ES and
/// the "usage rights" confirmation (required once a photo is set). The value
/// is `{storagePath, url, alt{en,es}, usageRightsConfirmed}` or `null`.
class CatalogImageField extends StatefulWidget {
  const CatalogImageField({
    super.key,
    required this.id,
    required this.label,
    required this.folder,
    required this.deps,
    required this.value,
    required this.onChanged,
    required this.isEs,
    this.isRequired = false,
  });

  /// Key suffix (`upload-<id>`, `svc-<id>-alt-en`, `svc-<id>-rights`).
  final String id;
  final String label;
  final String folder;
  final ServiceCatalogDeps deps;
  final ImageJson? value;
  final ValueChanged<ImageJson?> onChanged;
  final bool isEs;
  final bool isRequired;

  @override
  State<CatalogImageField> createState() => _CatalogImageFieldState();
}

class _CatalogImageFieldState extends State<CatalogImageField> {
  late ImageJson? _value = widget.value == null ? null : {...widget.value!};

  ServiceCatalogStrings get _s => ServiceCatalogStrings(widget.isEs);

  void _uploaded(UploadedImage? image) {
    setState(() {
      _value = image == null
          ? null
          : {
              'storagePath': image.storagePath,
              'url': image.publicUrl,
              'alt': {..._alt},
              'usageRightsConfirmed': false,
            };
    });
    widget.onChanged(_value);
  }

  Map<String, dynamic> get _alt =>
      Map<String, dynamic>.from(_value?['alt'] as Map? ?? {'en': '', 'es': ''});

  void _update(String key, Object value) {
    _value = {..._value!, key: value};
    widget.onChanged(_value);
  }

  UploadedImage? get _initial {
    final v = widget.value;
    if (v == null || '${v['storagePath'] ?? ''}'.isEmpty) return null;
    return UploadedImage(
        storagePath: '${v['storagePath']}', publicUrl: '${v['url'] ?? ''}');
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminImageUploadField(
            id: widget.id,
            label: widget.label,
            folder: widget.folder,
            signer: widget.deps.signer,
            transport: widget.deps.transport,
            picker: widget.deps.picker,
            initialValue: _initial,
            isRequired: widget.isRequired,
            onChanged: _uploaded,
            isEs: widget.isEs,
          ),
          if (_value != null)
            KeyedSubtree(
              key: ValueKey('${_value!['storagePath']}'),
              child: _details(),
            ),
        ],
      );

  Widget _details() => Padding(
        padding: const EdgeInsets.only(bottom: KachavaTokens.space4),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            for (final lang in ['en', 'es']) ...[
              if (lang == 'es') const SizedBox(width: KachavaTokens.space2),
              Expanded(child: _altInput(lang)),
            ],
          ]),
          _rights(),
        ]),
      );

  Widget _altInput(String lang) => Semantics(
        container: true,
        identifier: 'svc-${widget.id}-alt-$lang',
        child: TextFormField(
          key: Key('svc-${widget.id}-alt-$lang'),
          initialValue: '${_alt[lang] ?? ''}',
          decoration: InputDecoration(
              isDense: true, hintText: lang == 'en' ? _s.altEn : _s.altEs),
          onChanged: (v) => _update('alt', {..._alt, lang: v}),
        ),
      );

  Widget _rights() => FormField<bool>(
        initialValue: _value?['usageRightsConfirmed'] == true,
        validator: (v) => v == true ? null : _s.confirmRights,
        builder: (field) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              container: true,
              identifier: 'svc-${widget.id}-rights',
              child: Row(children: [
                Checkbox(
                  key: Key('svc-${widget.id}-rights'),
                  value: field.value ?? false,
                  onChanged: (v) {
                    field.didChange(v ?? false);
                    _update('usageRightsConfirmed', v ?? false);
                  },
                ),
                Text(_s.usageRights),
                InfoTooltip(_s.usageRightsTip),
              ]),
            ),
            if (field.errorText != null)
              Text(field.errorText!,
                  style: const TextStyle(
                      fontSize: 12, color: KachavaTokens.error)),
          ],
        ),
      );
}

/// Up to [AdminService.maxGalleryImages] photos; empty slots are ignored.
class CatalogGalleryField extends StatefulWidget {
  const CatalogGalleryField({
    super.key,
    required this.deps,
    required this.initial,
    required this.onChanged,
    required this.isEs,
  });

  final ServiceCatalogDeps deps;
  final List<ImageJson> initial;
  final ValueChanged<List<ImageJson>> onChanged;
  final bool isEs;

  @override
  State<CatalogGalleryField> createState() => _CatalogGalleryFieldState();
}

class _CatalogGalleryFieldState extends State<CatalogGalleryField> {
  late final Map<int, ImageJson?> _slots = {
    for (var i = 0; i < widget.initial.length; i++) i: widget.initial[i]
  };
  late int _nextId = _slots.length;

  void _emit() => widget.onChanged([
        for (final v in _slots.values)
          if (v != null) v
      ]);

  @override
  Widget build(BuildContext context) {
    final s = ServiceCatalogStrings(widget.isEs);
    final full = _slots.length >= AdminService.maxGalleryImages;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        AdminFieldLabel(s.gallery),
        InfoTooltip(s.galleryTip),
      ]),
      for (final id in _slots.keys.toList())
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: CatalogImageField(
              key: ValueKey('gallery-$id'),
              id: 'gallery-$id',
              label: '${s.photo} ${_slots.keys.toList().indexOf(id) + 1}',
              folder: 'services',
              deps: widget.deps,
              value: _slots[id],
              isEs: widget.isEs,
              onChanged: (v) {
                _slots[id] = v;
                _emit();
              },
            ),
          ),
          IconButton(
            key: Key('gallery-$id-remove'),
            tooltip: AdminListStrings(widget.isEs).remove,
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() => _slots.remove(id));
              _emit();
            },
          ),
        ]),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: const Key('gallery-add'),
          onPressed:
              full ? null : () => setState(() => _slots[_nextId++] = null),
          icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
          label: Text(s.addPhoto),
        ),
      ),
    ]);
  }
}
