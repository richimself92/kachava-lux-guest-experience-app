import 'package:flutter/material.dart';

import '../../core/service_catalog_strings.dart';
import '../../domain/item_pricing_rules.dart';
import '../../domain/json_draft.dart';
import '../../domain/service_catalog_enums.dart';
import 'draft_text_fields.dart';

/// Price of one item plus, when enabled, the admin-only sourcing fields
/// (SKU, net cost MXN, source link) and the per-oz weight pricing switch.
/// OZ prices and net costs accept 4 decimals; ITEM amounts keep 2.
class ItemPricingFields extends StatefulWidget {
  const ItemPricingFields({
    super.key,
    required this.draft,
    required this.isEs,
    this.sourcing = false,
    this.weightPricing = false,
  });

  final JsonDraft draft;
  final bool isEs;
  final bool sourcing;
  final bool weightPricing;

  @override
  State<ItemPricingFields> createState() => _ItemPricingFieldsState();
}

class _ItemPricingFieldsState extends State<ItemPricingFields> {
  JsonDraft get _draft => widget.draft;
  ServiceCatalogStrings get _s => ServiceCatalogStrings(widget.isEs);
  bool get _byOz =>
      PricingUnit.parse(_draft.get('pricingUnit')) == PricingUnit.oz;
  int get _decimals => _byOz ? 4 : 2;

  void _setByOz(bool on) {
    setState(() {
      _draft.set('pricingUnit', (on ? PricingUnit.oz : PricingUnit.item).wire);
      final empty = _draft.strings('portionOzOptions').isEmpty;
      _draft.set(
          'portionOzOptions',
          !on
              ? const <int>[]
              : empty
                  ? ItemPricingRules.defaultOzOptions
                  : _draft.get('portionOzOptions'));
    });
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        if (widget.weightPricing) _weightSwitch(),
        DraftAmountField(
          key: ValueKey('price-$_decimals'),
          draft: _draft,
          path: 'priceUSD',
          label: _byOz ? _s.pricePerOz : _s.itemPrice,
          tip: _byOz ? null : _s.itemPriceTip,
          decimals: _decimals,
          isRequired: _byOz,
          isEs: widget.isEs,
        ),
        if (widget.weightPricing && _byOz) _ozOptions(),
        if (widget.sourcing) ..._sourcing(),
      ]);

  Widget _weightSwitch() => DraftLabelled(
        label: _s.byWeight,
        tip: _s.byWeightTip,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Semantics(
            identifier: 'svc-pricingUnit',
            child: Switch(
              key: const Key('svc-pricingUnit'),
              value: _byOz,
              onChanged: _setByOz,
            ),
          ),
        ),
      );

  Widget _ozOptions() {
    final current = _draft.strings('portionOzOptions');
    return DraftLabelled(
      label: _s.ozOptions,
      tip: _s.ozOptionsTip,
      isRequired: true,
      child: draftInput(_draft, 'portionOzOptions',
          initial: current.join(', '),
          keyboardType: TextInputType.number,
          validator: (raw) =>
              ItemPricingRules.parseOz(raw ?? '') == null ? _s.invalidOz : null,
          onChanged: (raw) => _draft.set('portionOzOptions',
              ItemPricingRules.parseOz(raw) ?? const <int>[])),
    );
  }

  List<Widget> _sourcing() => [
        DraftTextField(
          draft: _draft,
          path: 'sku',
          label: _s.sku,
          tip: _s.skuTip,
          nullIfBlank: true,
          validator: (raw) => ItemPricingRules.skuOk(raw)
              ? null
              : _s.maxChars(ItemPricingRules.maxSku),
        ),
        DraftAmountField(
          key: ValueKey('net-$_decimals'),
          draft: _draft,
          path: 'netCostMXN',
          label: _s.netCost,
          tip: _s.adminOnlyTip,
          decimals: _decimals,
          isEs: widget.isEs,
        ),
        DraftTextField(
          draft: _draft,
          path: 'sourceUrl',
          label: _s.sourceLink,
          tip: _s.adminOnlyTip,
          nullIfBlank: true,
          validator: (raw) =>
              ItemPricingRules.urlOk(raw) ? null : _s.invalidUrl,
        ),
      ];
}
