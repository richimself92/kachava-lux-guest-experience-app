import 'package:flutter/material.dart';

import '../../application/service_catalog_deps.dart';
import '../../core/service_catalog_strings.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../data/catalog_rule_violation.dart';
import '../../domain/admin_service.dart';
import '../../domain/catalog_values.dart';
import '../../domain/json_draft.dart';
import '../components/components.dart';
import 'catalog_image_fields.dart';
import 'draft_list_fields.dart';
import 'draft_text_fields.dart';

/// Nested form of one item (bar drink, dish, product, option, vehicle).
/// Only the fields its service kind uses are shown.
class ServiceItemEditor extends StatefulWidget {
  const ServiceItemEditor({
    super.key,
    required this.deps,
    required this.serviceId,
    required this.kind,
    required this.onClose,
    required this.onSaved,
    this.item,
    this.isEs = false,
  });

  final ServiceCatalogDeps deps;
  final String serviceId;
  final ServiceKind kind;
  final ServiceItem? item;
  final VoidCallback onClose;
  final VoidCallback onSaved;
  final bool isEs;

  @override
  State<ServiceItemEditor> createState() => _ServiceItemEditorState();
}

class _ServiceItemEditorState extends State<ServiceItemEditor> {
  late ServiceItem? _saved = widget.item;
  late JsonDraft _draft = JsonDraft(
      (widget.item ?? const ServiceItem(name: LocalizedText())).toDraftJson());
  int _generation = 0;

  ServiceCatalogStrings get _s => ServiceCatalogStrings(widget.isEs);
  bool get _isNew => (_saved?.id ?? '').isEmpty;
  CatalogStatus get _status => _saved?.status ?? CatalogStatus.disabled;
  bool _uses(ItemField f) => widget.kind.itemFields.contains(f);

  Future<void> _write() async {
    final item = ServiceItem.parse(_draft.json);
    final repo = widget.deps.services;
    final saved = _isNew
        ? await repo.createItem(widget.serviceId, item)
        : await repo.updateItem(widget.serviceId,
            ServiceItem.parse({..._draft.json, 'id': _saved!.id}));
    widget.onSaved();
    if (!mounted) return;
    setState(() {
      _saved = saved;
      _draft = JsonDraft(saved.toDraftJson());
      _generation++;
    });
  }

  Future<void> _save() async {
    await _write();
    if (mounted) showAdminToast(context, _s.itemSaved);
  }

  Future<void> _toggleStatus() async {
    final next = _status.toggled;
    final previous = _draft.get('status');
    _draft.set('status', next.wire);
    try {
      await _write();
    } catch (_) {
      _draft.set('status', previous);
      rethrow;
    }
    if (mounted) showAdminToast(context, _s.statusChanged(next));
  }

  @override
  Widget build(BuildContext context) {
    final name = _saved?.name.of(isEs: widget.isEs) ?? '';
    return AdminFormPanel(
      key: const Key('item-editor'),
      title: _isNew || name.isEmpty ? _s.newItem : name,
      onSave: _save,
      onClose: widget.onClose,
      isEs: widget.isEs,
      failureMessage: (e) => switch (CatalogRuleViolation.tryParse(e)) {
        final v? => _s.problems(v.problems),
        null => null,
      },
      actions: [
        if (!_isNew)
          StatusChip.fromStatus(_status.wire,
              key: const Key('item-status'), isEs: widget.isEs),
      ],
      footerActions: [
        AdminFormAction(
          key: const Key('item-toggle-status'),
          label: _status == CatalogStatus.active ? _s.deactivate : _s.activate,
          confirmTitle: _s.confirmStatus(_status.toggled, item: true),
          destructive: _status == CatalogStatus.active,
          run: _toggleStatus,
        ),
      ],
      children: [
        KeyedSubtree(
          key: ValueKey('item-gen-$_generation'),
          child: Column(children: _fields()),
        ),
      ],
    );
  }

  List<Widget> _fields() {
    final isEs = widget.isEs;
    return [
      DraftLocalizedField(
          draft: _draft,
          path: 'name',
          label: _s.name,
          isEs: isEs,
          requireOne: true),
      CatalogImageField(
        id: 'item-image',
        label: _s.photo,
        folder: 'services/items',
        deps: widget.deps,
        isEs: isEs,
        value: _draft.get('image') as Map<String, dynamic>?,
        onChanged: (v) => _draft.set('image', v),
      ),
      DraftAmountField(
          draft: _draft,
          path: 'priceUSD',
          label: _s.itemPrice,
          tip: _s.itemPriceTip,
          isEs: isEs),
      if (_uses(ItemField.capacity)) _capacity(),
      if (_uses(ItemField.category))
        DraftTextField(
            draft: _draft,
            path: 'category',
            label: _s.category,
            nullIfBlank: true),
      for (final (field, path, label) in [
        (ItemField.dietaryTags, 'dietaryTags', _s.dietaryTags),
        (ItemField.allergens, 'allergens', _s.allergens),
        (ItemField.tags, 'tags', _s.tags),
      ])
        if (_uses(field))
          DraftCsvField(
              draft: _draft,
              path: path,
              label: label,
              tip: _s.tagsTip,
              isEs: isEs),
      for (final (field, path, label) in [
        (ItemField.origin, 'origin', _s.origin),
        (ItemField.unit, 'unit', _s.unit),
        (ItemField.storage, 'storage', _s.storage),
      ])
        if (_uses(field))
          DraftTextField(
              draft: _draft, path: path, label: label, nullIfBlank: true),
      AdminAdvancedSection(
          key: const Key('item-more'),
          title: _s.more,
          children: [
            DraftLocalizedField(
                draft: _draft,
                path: 'description',
                label: _s.description,
                isEs: isEs,
                maxLines: 2),
            DraftIntField(
                draft: _draft,
                path: 'order',
                label: _s.order,
                isEs: isEs,
                max: 10000),
          ]),
    ];
  }

  Widget _capacity() =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: DraftIntField(
              draft: _draft,
              path: 'capacity.passengers',
              label: _s.passengers,
              isEs: widget.isEs,
              min: 1,
              max: 60),
        ),
        const SizedBox(width: KachavaTokens.space2),
        Expanded(
          child: DraftIntField(
              draft: _draft,
              path: 'capacity.luggage',
              label: _s.luggage,
              isEs: widget.isEs,
              max: 100),
        ),
      ]);
}
