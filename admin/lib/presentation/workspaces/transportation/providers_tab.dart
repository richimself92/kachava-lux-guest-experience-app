import 'package:flutter/material.dart';

import '../../../application/list_query_store.dart';
import '../../../application/paged_list_controller.dart';
import '../../../core/theme/kachava_tokens.dart';
import '../../../core/transport_strings.dart';
import '../../../domain/admin_catalog_repositories.dart';
import '../../../domain/list_query.dart';
import '../../../domain/transport_provider.dart';
import '../../components/components.dart';

/// Transport providers: name, phone, email, active; create, edit and
/// deactivate/activate from the side panel.
class ProvidersTab extends StatefulWidget {
  const ProvidersTab({
    super.key,
    required this.repository,
    required this.queries,
    required this.isEs,
  });

  static const String storeKey = 'transport-providers';
  static const ListQuery initialQuery = ListQuery(sort: ListSort('name'));

  final TransportProviderRepository repository;
  final ListQueryStore queries;
  final bool isEs;

  @override
  State<ProvidersTab> createState() => _ProvidersTabState();
}

class _ProvidersTabState extends State<ProvidersTab> {
  late final PagedListController<TransportProvider> _list = PagedListController(
    fetch: widget.repository.list,
    initialQuery: ProvidersTab.initialQuery,
    store: widget.queries,
    storeKey: ProvidersTab.storeKey,
  );

  TransportStrings get _s => TransportStrings(widget.isEs);

  @override
  void dispose() {
    _list.dispose();
    super.dispose();
  }

  Widget _activeChip(TransportProvider p) => p.isActive
      ? StatusChip(label: _s.active, tone: StatusTone.success)
      : StatusChip(label: _s.inactive, tone: StatusTone.neutral);

  String _dash(String value) => value.isEmpty ? '—' : value;

  @override
  Widget build(BuildContext context) {
    return AdminListScreen<TransportProvider>(
      entity: 'providers',
      title: _s.providers,
      info: _s.providersInfo,
      controller: _list,
      columns: [
        AdminTableColumn(
            label: _s.name, text: (p) => p.name, sortField: 'name', flex: 3),
        AdminTableColumn(label: _s.phone, text: (p) => _dash(p.phone)),
        AdminTableColumn(label: _s.email, text: (p) => _dash(p.email), flex: 3),
        AdminTableColumn(label: _s.active, cell: _activeChip, flex: 1),
      ],
      rowId: (p) => p.id,
      compactTitle: (p) => p.name,
      compactSubtitle: (p) =>
          [p.phone, p.email].where((v) => v.isNotEmpty).join(' · '),
      compactTrailing: _activeChip,
      filters: [
        AdminListFilter(key: 'isActive', label: _s.active, options: [
          AdminFilterOption('true', _s.yes),
          AdminFilterOption('false', _s.no),
        ]),
      ],
      emptyMessage: _s.noProviders,
      primaryActionLabel: _s.newProvider,
      detailBuilder: (context, provider, close) => ProviderDetailPanel(
        provider: provider,
        repository: widget.repository,
        onClose: close,
        onChanged: _list.load,
        isEs: widget.isEs,
      ),
      isEs: widget.isEs,
    );
  }
}

/// Create/edit one provider; ⋮ Deactivate/Activate with a one-line confirm.
class ProviderDetailPanel extends StatefulWidget {
  const ProviderDetailPanel({
    super.key,
    required this.provider,
    required this.repository,
    required this.onClose,
    required this.onChanged,
    required this.isEs,
  });

  /// `null` creates a new provider.
  final TransportProvider? provider;
  final TransportProviderRepository repository;
  final VoidCallback onClose;
  final VoidCallback onChanged;
  final bool isEs;

  @override
  State<ProviderDetailPanel> createState() => _ProviderDetailPanelState();
}

class _ProviderDetailPanelState extends State<ProviderDetailPanel> {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  late final TransportProvider? _p = widget.provider;
  late String _name = _p?.name ?? '';
  late String _phone = _p?.phone ?? '';
  late String _emailText = _p?.email ?? '';

  TransportStrings get _s => TransportStrings(widget.isEs);

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final draft = TransportProvider(
      id: _p?.id ?? '',
      name: _name.trim(),
      phone: _phone.trim(),
      email: _emailText.trim(),
      isActive: _p?.isActive ?? true,
    );
    if (_p == null) {
      await widget.repository.create(draft);
    } else {
      await widget.repository.update(draft);
    }
    widget.onChanged();
    showAdminToastOn(messenger, _s.providerSaved);
  }

  Future<void> _toggleActive() async {
    final p = _p!;
    final on = !p.isActive;
    final ok = await showConfirmDialog(context,
        title: on ? _s.activateQ(p.name) : _s.deactivateQ(p.name),
        confirmLabel: on ? _s.activate : _s.deactivate,
        cancelLabel: _s.cancel,
        destructive: !on);
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await widget.repository.update(TransportProvider(
          id: p.id,
          name: p.name,
          phone: p.phone,
          email: p.email,
          isActive: on));
      widget.onChanged();
      widget.onClose();
      showAdminToastOn(
          messenger, on ? _s.providerActivated : _s.providerDeactivated);
    } catch (_) {
      showAdminToastOn(messenger, _s.saveFailed,
          isError: true, isEs: widget.isEs);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    return AdminFormPanel(
      title: p?.name ?? _s.newProvider,
      onSave: _save,
      onClose: widget.onClose,
      isEs: widget.isEs,
      actions: [
        if (p != null)
          PopupMenuButton<String>(
            key: const Key('provider-actions'),
            tooltip: _s.actions,
            onSelected: (_) => _toggleActive(),
            itemBuilder: (_) => [
              PopupMenuItem(
                key: Key(p.isActive
                    ? 'provider-action-deactivate'
                    : 'provider-action-activate'),
                value: 'toggle',
                child: Text(p.isActive ? _s.deactivate : _s.activate),
              ),
            ],
          ),
      ],
      children: [
        if (p != null && !p.isActive)
          Padding(
            padding: const EdgeInsets.only(bottom: KachavaTokens.space4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: StatusChip(label: _s.inactive, tone: StatusTone.neutral),
            ),
          ),
        AdminTextFormField(
          label: _s.name,
          isRequired: true,
          initialValue: _name,
          fieldKey: const Key('provider-name'),
          validator: AdminValidators.maxLength(200, widget.isEs),
          onChanged: (v) => _name = v,
          isEs: widget.isEs,
        ),
        AdminTextFormField(
          label: _s.phone,
          initialValue: _phone,
          fieldKey: const Key('provider-phone'),
          keyboardType: TextInputType.phone,
          validator: AdminValidators.maxLength(200, widget.isEs),
          onChanged: (v) => _phone = v,
          isEs: widget.isEs,
        ),
        AdminTextFormField(
          label: _s.email,
          initialValue: _emailText,
          fieldKey: const Key('provider-email'),
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            final text = (v ?? '').trim();
            return text.isEmpty || _email.hasMatch(text)
                ? null
                : _s.invalidEmail;
          },
          onChanged: (v) => _emailText = v,
          isEs: widget.isEs,
        ),
      ],
    );
  }
}
