import 'package:flutter/material.dart';

import '../../application/portal_controller.dart';
import '../../core/i18n/l10n.dart';
import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';
import '../../data/guest_api.dart';
import '../../domain/catalog.dart';
import '../../domain/forms.dart';
import '../../domain/json_read.dart';
import '../common/widgets.dart';
import 'form_scaffold.dart';
import 'order_consent.dart';
import 'order_item_rows.dart';

/// ORDER: search + category filter, items by category (OZ items by
/// portions × oz), sticky total, Review → Order.
class OrderForm extends StatefulWidget {
  const OrderForm({
    super.key,
    required this.controller,
    required this.service,
    required this.title,
  });

  final PortalController controller;
  final CatalogService service;
  final String title;

  @override
  State<OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  late final OrderCart _cart;
  int _page = 0;
  bool _ageOk = false;
  bool _busy = false;
  String? _error;
  bool _showIssues = false;
  String _query = '';
  String? _category;

  String get _draftKey => 'section:${widget.service.section}';

  String get _subsKey => '${widget.service.id}:substitutions';

  @override
  void initState() {
    super.initState();
    final draft = widget.controller.readDraft(_draftKey);
    final subs = draft?[_subsKey];
    _cart = OrderCart.restore(
      widget.service,
      lines: widget.controller.stay?.larderOrders ?? const [],
      draft: asJson(draft?[widget.service.id]),
      substitutions: subs is bool ? subs : null,
    );
  }

  void _saveAndExit() {
    widget.controller.saveDraft(_draftKey, {
      widget.service.id: _cart.toDraft(),
      if (_cart.substitutions != null) _subsKey: _cart.substitutions,
    });
    Navigator.of(context).pop();
  }

  Future<void> _submit() async {
    final l10n = widget.controller.l10n;
    final ageMissing = widget.service.ageConfirmationRequired && !_ageOk;
    if (ageMissing || _cart.issues.isNotEmpty) {
      setState(() => _showIssues = true);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.controller.saveOrder(_cart.toPayload());
    if (!mounted) return;
    switch (result) {
      case ApiOk():
        widget.controller.clearDraft(_draftKey);
        Navigator.of(context).pop();
        showPortalToast(context, l10n.orderSent);
      case ApiFailed():
        setState(() {
          _busy = false;
          _error = failureMessage(l10n, result);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.controller.l10n;
    return _page == 0 ? _pickPage(l10n) : _reviewPage(l10n);
  }

  Widget _pickPage(L10n l10n) {
    final totalLabel = l10n.itemsTotal(_cart.count, l10n.money(_cart.total));
    return FormScaffold(
      l10n: l10n,
      title: widget.title,
      page: 0,
      pages: 2,
      primaryLabel: l10n.review,
      onPrimary: _cart.isEmpty ? null : () => setState(() => _page = 1),
      secondaryLabel: l10n.saveExit,
      onSecondary: _saveAndExit,
      bottomTop: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Semantics(
          liveRegion: true,
          child: Text(totalLabel,
              key: const Key('order-total'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFeatures: KachavaTheme.tabular)),
        ),
      ),
      children: _pickList(l10n),
    );
  }

  Widget _reviewPage(L10n l10n) {
    return FormScaffold(
      l10n: l10n,
      title: widget.title,
      page: 1,
      pages: 2,
      busy: _busy,
      error: _error,
      onRetry: _submit,
      onBack: () => setState(() => _page = 0),
      primaryLabel: l10n.actionOrder,
      onPrimary: _submit,
      children: [
        Text(l10n.review, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final item in widget.service.items)
          if (_cart.quantityOf(item.id) > 0) _reviewLine(item),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.total,
              style: const TextStyle(fontWeight: FontWeight.w500)),
          trailing: Text(l10n.money(_cart.total),
              style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  fontFeatures: KachavaTheme.tabular)),
        ),
        if (widget.service.ageConfirmationRequired) _ageCheck(l10n),
        OrderConsent(
          l10n: l10n,
          cart: _cart,
          showIssues: _showIssues,
          onSubstitutions: (v) => setState(() => _cart.substitutions = v),
          onTerms: (v) => setState(() => _cart.termsAccepted = v),
        ),
      ],
    );
  }

  Widget _ageCheck(L10n l10n) => CheckboxListTile(
        key: const Key('age-check'),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: _ageOk,
        onChanged: (v) => setState(() => _ageOk = v ?? false),
        title: Text(l10n.ageConfirm),
        subtitle: _showIssues && !_ageOk
            ? Text(l10n.issue(FormIssue.ageRequired),
                style: const TextStyle(
                    color: KachavaColors.dangerText, fontSize: 14))
            : null,
      );

  List<Widget> _pickList(L10n l10n) {
    if (widget.service.items.isEmpty) {
      return [OneLineState(message: l10n.noItems)];
    }
    final groups = _cart.groupsFor(query: _query, category: _category);
    return [
      OrderFilterBar(
        l10n: l10n,
        categories: _cart.categories,
        category: _category,
        onQuery: (q) => setState(() => _query = q),
        onCategory: (c) => setState(() => _category = c),
      ),
      const SizedBox(height: 8),
      if (groups.isEmpty) OneLineState(message: l10n.noResults),
      for (final MapEntry(key: category, value: items) in groups.entries) ...[
        if (category.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child:
                Text(category, style: Theme.of(context).textTheme.titleMedium),
          ),
        for (final item in items) _itemRow(l10n, item),
      ],
    ];
  }

  Widget _itemRow(L10n l10n, CatalogItem item) {
    if (item.byWeight) {
      return OzItemRow(
        l10n: l10n,
        item: item,
        pricePerOz: _cart.unitPrice(item),
        portions: _cart.quantityOf(item.id),
        oz: _cart.ozOf(item),
        onPortions: (v) => setState(() => _cart.set(item.id, v)),
        onOz: (v) => setState(() => _cart.setOz(item.id, v)),
      );
    }
    return OrderItemRow(
      l10n: l10n,
      item: item,
      price: _cart.unitPrice(item),
      quantity: _cart.quantityOf(item.id),
      onQuantity: (v) => setState(() => _cart.set(item.id, v)),
    );
  }

  Widget _reviewLine(CatalogItem item) {
    final l10n = widget.controller.l10n;
    final total = _cart.lineTotal(item);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.orderLine(
          _cart.quantityOf(item.id), l10n.text(item.name),
          oz: item.byWeight ? _cart.ozOf(item) : null)),
      trailing: Text(total == null ? '' : l10n.money(total),
          style: const TextStyle(fontFeatures: KachavaTheme.tabular)),
    );
  }
}
