import 'package:flutter/material.dart';
import '../../application/sanctuary_controller.dart';
import '../../core/theme/kachava_colors.dart';
import '../../core/theme/kachava_theme.dart';
import '../../domain/entities/experience_entities.dart';

/// Screen 8: Villa Stocking & Artisanal Larder (`stock-villa`).
class StockVillaScreen extends StatefulWidget {
  const StockVillaScreen({super.key, required this.controller});

  final SanctuaryController controller;

  @override
  State<StockVillaScreen> createState() => _StockVillaScreenState();
}

class _StockVillaScreenState extends State<StockVillaScreen> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final items = widget.controller.larderItems;
        final totalAmount = widget.controller.larderTotalAmount;
        final totalCount = widget.controller.larderTotalCount;
        final i18n = widget.controller.i18n;
        final showBanner = widget.controller.isLarderOrderConfirmed ||
            widget.controller.larderOrderStatus.isNotEmpty;

        return Column(
          key: const Key('screen-stock-villa'),
          children: [
            if (showBanner)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: _buildConfirmedOrderBanner(items),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                children: [
                  Text(
                    i18n.t(
                      'HOST ADMIN PANTRY PREPARATION',
                      'PEDIDO DE MINIBAR Y BEBIDAS · HOST ADMIN',
                    ),
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: KachavaColors.secondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    i18n.t(
                      'Stock My Villa — Pantry & Drinks',
                      'Minibar, Bebidas y Snacks para tu Villa',
                    ),
                    style: const TextStyle(
                      fontFamily: KachavaTheme.serifFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: KachavaColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...items.map(_buildLarderItemCard),
                ],
              ),
            ),
            _buildStickyCartBar(totalAmount, totalCount),
          ],
        );
      },
    );
  }

  Widget _buildConfirmedOrderBanner(List<LarderItem> items) {
    final i18n = widget.controller.i18n;
    final rawStatus = widget.controller.larderOrderStatus.toLowerCase();
    final isDelivered =
        rawStatus.contains('stocked') || rawStatus.contains('delivered');
    final isAssigned =
        rawStatus.contains('assigned') || rawStatus.contains('progress');
    final statusLabel = isDelivered
        ? i18n.t('✅ Delivered to Villa', '✅ Entregado en Villa')
        : (isAssigned
            ? i18n.t('🛠️ In Preparation', '🛠️ En Preparación')
            : i18n.t('⏳ Order Sent · Pending', '⏳ Pedido Enviado · Pendiente'));
    final submitted = widget.controller.submittedLarderItems;
    final selected = submitted.isNotEmpty
        ? submitted
        : items.where((i) => i.quantity > 0).toList();
    return Container(
      key: const Key('larder-order-status-banner'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KachavaColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDelivered
              ? KachavaColors.confirmedGreen
              : KachavaColors.secondary,
          width: 1.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            statusLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDelivered
                  ? KachavaColors.confirmedGreen
                  : KachavaColors.primary,
            ),
          ),
          if (isDelivered && selected.isEmpty) ...[
            const SizedBox(height: 4),
            Text(
              i18n.t(
                '✅ Previous order delivered to your villa · You may place a new order anytime.',
                '✅ Pedido anterior entregado en tu villa · Puedes realizar un nuevo pedido cuando gustes.',
              ),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: KachavaColors.onSurface,
              ),
            ),
          ] else if (selected.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...selected.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${item.quantity}x ${i18n.translateContent(item.name)}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: KachavaColors.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLarderItemCard(LarderItem item) {
    final i18n = widget.controller.i18n;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    i18n.translateContent(item.name),
                    style: const TextStyle(
                      fontFamily: KachavaTheme.serifFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: KachavaColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${item.priceUsd} USD',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: KachavaColors.secondary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              i18n.translateContent(item.description),
              style: const TextStyle(fontSize: 13.5),
            ),
            const SizedBox(height: 8),
            _buildQuantityRow(item),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityRow(LarderItem item) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          key: Key('larder-dec-${item.id}'),
          tooltip: 'Decrease ${item.name} quantity',
          onPressed: () => widget.controller
              .updateLarderQuantity(item.id, item.quantity - 1),
          icon: const Icon(Icons.remove_circle_outline, size: 24),
        ),
        Text(
          '${item.quantity}',
          key: Key('larder-qty-${item.id}'),
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: KachavaColors.primary),
        ),
        IconButton(
          key: Key('larder-inc-${item.id}'),
          tooltip: 'Increase ${item.name} quantity',
          onPressed: () => widget.controller
              .updateLarderQuantity(item.id, item.quantity + 1),
          icon: const Icon(Icons.add_circle_outline, size: 24),
        ),
      ],
    );
  }

  Widget _buildStickyCartBar(int totalAmount, int totalCount) {
    final isEmpty = totalCount == 0;
    final i18n = widget.controller.i18n;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        color: KachavaColors.surfaceContainerLow,
        border: Border(
            top: BorderSide(color: KachavaColors.surfaceContainerHighest)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$$totalAmount.00 USD · $totalCount ${i18n.t("items", "artículos")}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: KachavaColors.primary),
                ),
                Text(
                  i18n.t('Complimentary Staples Included',
                      'Básicos de cortesía incluidos'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            key: const Key('confirm-villa-stocking-btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isEmpty ? KachavaColors.inputBorder : KachavaColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onPressed: isEmpty ? null : widget.controller.confirmVillaStocking,
            child: Text(
              i18n.t('Confirm Order', 'Confirmar Pedido'),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
