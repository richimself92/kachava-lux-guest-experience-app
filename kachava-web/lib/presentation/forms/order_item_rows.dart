import 'package:flutter/material.dart';

import '../../core/i18n/l10n.dart';
import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';
import '../../domain/catalog.dart';
import '../../domain/forms.dart';
import '../common/widgets.dart';

const _name = TextStyle(fontSize: 16, fontWeight: FontWeight.w500);
const _muted = TextStyle(
    fontSize: 14,
    color: KachavaColors.muted,
    fontFeatures: KachavaTheme.tabular);

/// Search field plus text-only category tabs ("All" first). The selected
/// tab is scrolled into view whenever it changes.
class OrderFilterBar extends StatefulWidget {
  const OrderFilterBar({
    super.key,
    required this.l10n,
    required this.categories,
    required this.category,
    required this.onQuery,
    required this.onCategory,
  });

  final L10n l10n;
  final List<String> categories;
  final String? category;
  final ValueChanged<String> onQuery;
  final ValueChanged<String?> onCategory;

  @override
  State<OrderFilterBar> createState() => _OrderFilterBarState();
}

class _OrderFilterBarState extends State<OrderFilterBar> {
  final _selectedKey = GlobalKey();
  final _chips = ScrollController();

  @override
  void initState() {
    super.initState();
    _revealSelected(Duration.zero);
  }

  @override
  void didUpdateWidget(OrderFilterBar old) {
    super.didUpdateWidget(old);
    if (old.category != widget.category) _revealSelected(KachavaTheme.motion);
  }

  /// Centers the selected tab in the chip bar only (never scrolls the page).
  void _revealSelected(Duration duration) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _selectedKey.currentContext?.findRenderObject();
      if (!mounted || box is! RenderBox || !_chips.hasClients) return;
      final pos = _chips.position;
      final left = box.localToGlobal(Offset.zero).dx -
          (pos.context.notificationContext?.findRenderObject() as RenderBox)
              .localToGlobal(Offset.zero)
              .dx +
          pos.pixels;
      final target = (left + box.size.width / 2 - pos.viewportDimension / 2)
          .clamp(pos.minScrollExtent, pos.maxScrollExtent);
      if (duration == Duration.zero) return _chips.jumpTo(target);
      _chips.animateTo(target, duration: duration, curve: KachavaTheme.ease);
    });
  }

  @override
  void dispose() {
    _chips.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('order-search'),
          onChanged: widget.onQuery,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: l10n.searchItems,
            prefixIcon: const Icon(Icons.search, color: KachavaColors.muted),
          ),
        ),
        if (widget.categories.length > 1)
          SingleChildScrollView(
            key: const Key('order-categories'),
            controller: _chips,
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _tab(l10n.all, null),
              for (final c in widget.categories) _tab(c, c),
            ]),
          ),
      ],
    );
  }

  Widget _tab(String label, String? value) {
    final selected = widget.category == value;
    final tab = SegmentTab(label, selected, () => widget.onCategory(value),
        key: Key('order-cat-${value ?? 'all'}'));
    return selected ? KeyedSubtree(key: _selectedKey, child: tab) : tab;
  }
}

/// ITEM row: photo, name, unit price and a quantity stepper.
class OrderItemRow extends StatelessWidget {
  const OrderItemRow({
    super.key,
    required this.l10n,
    required this.item,
    required this.price,
    required this.quantity,
    required this.onQuantity,
  });

  final L10n l10n;
  final CatalogItem item;
  final double? price;
  final int quantity;
  final ValueChanged<int> onQuantity;

  @override
  Widget build(BuildContext context) {
    final name = l10n.text(item.name);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (item.image != null) ...[
            SizedBox(
                width: 64,
                child: ServicePhoto(image: item.image, l10n: l10n, radius: 8)),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: _name),
                if (price != null) Text(l10n.money(price!), style: _muted),
              ],
            ),
          ),
          QuantityStepper(
            key: Key('qty-${item.id}'),
            label: name,
            value: quantity,
            max: orderLineMax,
            onChanged: onQuantity,
          ),
        ],
      ),
    );
  }
}

/// OZ row (proteins): price per oz, portions, oz per portion and the
/// estimated total. The server computes the final amount.
class OzItemRow extends StatelessWidget {
  const OzItemRow({
    super.key,
    required this.l10n,
    required this.item,
    required this.pricePerOz,
    required this.portions,
    required this.oz,
    required this.onPortions,
    required this.onOz,
  });

  final L10n l10n;
  final CatalogItem item;
  final double? pricePerOz;
  final int portions;
  final int oz;
  final ValueChanged<int> onPortions;
  final ValueChanged<int> onOz;

  @override
  Widget build(BuildContext context) {
    final price = pricePerOz;
    return Padding(
      key: Key('oz-row-${item.id}'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 8),
          _controls(),
          if (portions > 0 && price != null) _estimate(price),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(l10n.estimateNote,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 13, color: KachavaColors.muted)),
          ),
        ],
      ),
    );
  }

  Widget _estimate(double price) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(l10n.estimate(portions, oz, portions * oz * price),
            key: Key('oz-estimate-${item.id}'),
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                fontFeatures: KachavaTheme.tabular)),
      );

  Widget _header() => Row(
        children: [
          if (item.image != null) ...[
            SizedBox(
                width: 64, child: ServicePhoto(image: item.image, l10n: l10n)),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.text(item.name),
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: _name),
                if (pricePerOz != null)
                  Text(l10n.perOz(pricePerOz!), style: _muted),
              ],
            ),
          ),
        ],
      );

  Widget _controls() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KlLabel(l10n.portions),
            QuantityStepper(
              key: Key('qty-${item.id}'),
              label: l10n.text(item.name),
              value: portions,
              max: orderLineMax,
              onChanged: onPortions,
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(child: _ozSelector()),
      ],
    );
  }

  Widget _ozSelector() {
    final options =
        item.portionOzOptions.isEmpty ? [oz] : item.portionOzOptions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KlLabel(l10n.ozPerPortion),
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          key: Key('oz-${item.id}'),
          initialValue: options.contains(oz) ? oz : options.first,
          isExpanded: true,
          items: [
            for (final o in options)
              DropdownMenuItem(value: o, child: Text(l10n.ozOption(o))),
          ],
          onChanged: (v) => v == null ? null : onOz(v),
        ),
      ],
    );
  }
}
