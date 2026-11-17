import 'package:flutter/material.dart';

import '../../application/service_catalog_deps.dart';
import '../../core/service_catalog_strings.dart';
import '../../data/catalog_rule_violation.dart';
import '../../domain/admin_service.dart';
import '../../domain/staff_member.dart';
import '../../domain/json_draft.dart';
import '../../domain/service_form_layout.dart';
import '../components/components.dart';
import 'service_form_fields.dart';
import 'service_item_editor.dart';
import 'service_items_section.dart';

/// Create/edit one service in the detail panel: ONE scrolling form per kind
/// (only what that kind needs; the rest under "More options"), with its
/// items inline. Usage and guest form derive from the kind on every save.
/// Saving keeps the panel open (items need a saved service); an item opens
/// its own form in the same panel. Activate/Deactivate confirm in one line
/// and show 422 problems inline.
class ServiceEditor extends StatefulWidget {
  const ServiceEditor({
    super.key,
    required this.deps,
    required this.onClose,
    required this.onSaved,
    this.service,
    this.section,
    this.staff = const [],
    this.isEs = false,
  });

  final ServiceCatalogDeps deps;
  final AdminService? service;

  /// Fixed section of a section view (Experiences, Dining, Wellness).
  final ServiceSection? section;
  final List<StaffMember> staff;
  final VoidCallback onClose;

  /// A write was confirmed by the server (refresh the list).
  final VoidCallback onSaved;
  final bool isEs;

  @override
  State<ServiceEditor> createState() => _ServiceEditorState();
}

class _ServiceEditorState extends State<ServiceEditor> {
  late AdminService? _saved = widget.service;
  late JsonDraft _draft = JsonDraft(widget.service?.toDraftJson() ??
      AdminService.emptyDraft(_kinds.first, section: widget.section));

  /// Bumped to rebuild every field from the draft.
  int _generation = 0;

  /// The item form shown instead of the service form (`null` item = new).
  ServiceItem? _item;
  bool _itemOpen = false;

  ServiceCatalogStrings get _s => ServiceCatalogStrings(widget.isEs);
  bool get _isNew => (_saved?.id ?? '').isEmpty;
  ServiceKind get _kind => ServiceKind.parse(_draft.get('kind'));
  List<ServiceKind> get _kinds => widget.section == null
      ? ServiceKind.values
      : ServiceKind.forSection(widget.section!);

  void _changeKind(ServiceKind next) {
    final old = _kind;
    if (next == old) return;
    _draft
      ..remove(old.detailField)
      ..set('kind', next.wire)
      ..set(next.detailField, <String, dynamic>{})
      ..set('usageType', next.defaultUsage.wire)
      ..set('pricing',
          AdminService.emptyDraft(next)['pricing'] as Map<String, dynamic>);
    if (widget.section == null) _draft.set('section', next.defaultSection.wire);
    setState(() => _generation++);
  }

  Future<void> _save() =>
      _write(AdminService.parse(withKindDefaults(_draft.json)));

  Future<void> _write(AdminService service) async {
    final repo = widget.deps.services;
    final result = _isNew
        ? await repo.create(service)
        : await repo.update(_withId(service));
    if (!mounted) return;
    setState(() {
      _saved = result;
      _draft = JsonDraft(result.toDraftJson());
      _generation++;
    });
    widget.onSaved();
  }

  AdminService _withId(AdminService s) =>
      AdminService.parse({...s.toDraftJson(), 'id': _saved!.id});

  CatalogStatus get _status => _saved?.status ?? CatalogStatus.disabled;

  Future<void> _toggleStatus() async {
    final next = _status.toggled;
    final previous = _draft.get('status');
    _draft.set('status', next.wire);
    try {
      await _save();
    } catch (_) {
      _draft.set('status', previous);
      rethrow;
    }
    if (mounted) showAdminToast(context, _s.statusChanged(next));
  }

  Future<void> _saveWithToast() async {
    await _save();
    if (mounted) showAdminToast(context, _s.saved);
  }

  String? _failure(Object error) {
    final violation = CatalogRuleViolation.tryParse(error);
    return violation == null ? null : _s.problems(violation.problems);
  }

  void _openItem(ServiceItem? item) => setState(() {
        _item = item;
        _itemOpen = true;
      });

  void _closeItem() => setState(() {
        _item = null;
        _itemOpen = false;
        _generation++;
      });

  @override
  Widget build(BuildContext context) {
    if (_itemOpen) return _itemEditor();
    final name = _saved?.name.of(isEs: widget.isEs) ?? '';
    return AdminFormPanel(
      key: const Key('service-editor'),
      title: _isNew ? _s.newService : (name.isEmpty ? _s.services : name),
      closeOnSave: false,
      onSave: _saveWithToast,
      onClose: widget.onClose,
      failureMessage: _failure,
      isEs: widget.isEs,
      actions: [
        if (!_isNew)
          StatusChip.fromStatus(_status.wire,
              key: const Key('service-status'), isEs: widget.isEs),
      ],
      footerActions: [
        AdminFormAction(
          key: const Key('service-toggle-status'),
          label: _status == CatalogStatus.active ? _s.deactivate : _s.activate,
          confirmTitle: _s.confirmStatus(_status.toggled),
          destructive: _status == CatalogStatus.active,
          run: _toggleStatus,
        ),
      ],
      children: [
        KeyedSubtree(
          key: ValueKey('gen-$_generation-${_kind.wire}'),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _fields().all()),
        ),
      ],
    );
  }

  ServiceFormFields _fields() => ServiceFormFields(
        draft: _draft,
        deps: widget.deps,
        isEs: widget.isEs,
        kinds: _kinds,
        isNew: _isNew,
        showSection: widget.section == null,
        staff: widget.staff,
        items: _items(),
        onKind: _changeKind,
        onRebuild: () => setState(() {}),
      );

  Widget _items() => _isNew
      ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ServiceItemsHeader(title: _s.itemsTitle(_kind)),
          AdminStateLine(
              key: const Key('items-save-first'), message: _s.saveFirst),
        ])
      : ServiceItemsSection(
          key: ValueKey('items-${_saved!.id}'),
          deps: widget.deps,
          serviceId: _saved!.id,
          kind: _kind,
          isEs: widget.isEs,
          onOpen: _openItem,
        );

  Widget _itemEditor() => ServiceItemEditor(
        key: ValueKey(_item?.id ?? 'new-item'),
        deps: widget.deps,
        serviceId: _saved!.id,
        kind: _kind,
        item: _item,
        isEs: widget.isEs,
        onClose: _closeItem,
        onSaved: () {},
      );
}
