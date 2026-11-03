import 'package:flutter/material.dart';

import '../../application/portal_controller.dart';
import '../../core/theme/kachava_colors.dart';
import '../../data/guest_api.dart';
import '../../domain/catalog.dart';
import '../../domain/forms.dart';
import '../../domain/json_read.dart';
import '../common/widgets.dart';
import 'form_scaffold.dart';

/// ORDER: items by category with steppers, sticky total, Review → Order.
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

  String get _draftKey => 'section:${widget.service.section}';

  @override
  void initState() {
    super.initState();
    final existing = {
      for (final line in widget.controller.stay?.larderOrders ?? const [])
        if (line.serviceId == widget.service.id) line.itemId: line.quantity,
    };
    final draft =
        asJson(widget.controller.readDraft(_draftKey)?[widget.service.id]);
    _cart = OrderCart(widget.service, {
      ...existing,
      for (final e in draft.entries) e.key: asInt(e.value) ?? 0,
    });
  }

  void _saveAndExit() {
    widget.controller
        .saveDraft(_draftKey, {widget.service.id: _cart.quantities});
    Navigator.of(context).pop();
  }

  Future<void> _submit() async {
    final l10n = widget.controller.l10n;
    if (widget.service.ageConfirmationRequired && !_ageOk) {
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
    final totalLabel = l10n.itemsTotal(_cart.count, l10n.money(_cart.total));
    if (_page == 0) {
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
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        children: [
          if (widget.service.items.isEmpty) OneLineState(message: l10n.noItems),
          for (final MapEntry(key: category, value: items)
              in _cart.groups.entries) ...[
            if (category.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(category,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            for (final item in items) _itemRow(item),
          ],
        ],
      );
    }
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
          if (_cart.quantityOf(item.id) > 0)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                  '${_cart.quantityOf(item.id)} × ${l10n.text(item.name)}'),
              trailing: Text(_cart.unitPrice(item) == null
                  ? ''
                  : l10n.money(
                      _cart.unitPrice(item)! * _cart.quantityOf(item.id))),
            ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.total,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          trailing: Text(l10n.money(_cart.total),
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        if (widget.service.ageConfirmationRequired)
          CheckboxListTile(
            key: const Key('age-check'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _ageOk,
            onChanged: (v) => setState(() => _ageOk = v ?? false),
            title: Text(l10n.ageConfirm),
            subtitle: _showIssues && !_ageOk
                ? Text(l10n.issue(FormIssue.ageRequired),
                    style: const TextStyle(
                        color: KachavaColors.errorRed, fontSize: 14))
                : null,
          ),
      ],
    );
  }

  Widget _itemRow(CatalogItem item) {
    final l10n = widget.controller.l10n;
    final price = _cart.unitPrice(item);
    final name = l10n.text(item.name);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (item.image != null)
            SizedBox(
                width: 64,
                child: ServicePhoto(image: item.image, l10n: l10n, radius: 8)),
          if (item.image != null) const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                if (price != null)
                  Text(l10n.money(price),
                      style: const TextStyle(
                          fontSize: 14, color: KachavaColors.onSurfaceVariant)),
              ],
            ),
          ),
          QuantityStepper(
            key: Key('qty-${item.id}'),
            label: name,
            value: _cart.quantityOf(item.id),
            max: orderLineMax,
            onChanged: (v) => setState(() => _cart.set(item.id, v)),
          ),
        ],
      ),
    );
  }
}
