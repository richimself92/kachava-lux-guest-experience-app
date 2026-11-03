import 'package:flutter/material.dart';
import '../../application/admin_dashboard_controller.dart';
import '../../core/admin_i18n.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../domain/admin_entities.dart';
import '../components/components.dart';
import '../widgets/semantic_status_badge.dart' show AdminEmptyStateBox;
import 'catalog_dialogs.dart';

/// `admin-larder` — shown as "Services": minibar & larder catalog and orders.
class LarderWorkspace extends StatelessWidget {
  const LarderWorkspace({super.key, required this.controller});
  final AdminDashboardController controller;

  static const _statuses = ['All', 'Pending', 'Assigned', 'Stocked in Villa'];

  @override
  Widget build(BuildContext context) {
    final orders = controller.filteredLarderOrders;
    final isEs = controller.isEs;
    return ListView(
      key: const Key('workspace-admin-larder'),
      padding: const EdgeInsets.all(KachavaTokens.space6),
      children: [
        PageHeader(
          title: AdminI18n.tr(isEs, 'Services', 'Servicios'),
          info: AdminI18n.tr(
            isEs,
            'Minibar and larder catalog plus guest orders, updated live.',
            'Catálogo de minibar y despensa y pedidos de huéspedes, en vivo.',
          ),
          actions: [
            ElevatedButton.icon(
              key: const Key('add-catalog-larder-btn'),
              onPressed: () => showAddLarderCatalogDialog(context, controller),
              icon: const Icon(Icons.add, size: 18),
              label: Text(AdminI18n.tr(isEs, 'New product', 'Nuevo producto')),
            ),
          ],
        ),
        const SizedBox(height: KachavaTokens.space4),
        _buildLarderCatalogStrip(context, isEs),
        const SizedBox(height: KachavaTokens.space4),
        _buildFilterRow(isEs),
        const SizedBox(height: KachavaTokens.space4),
        if (orders.isEmpty)
          AdminEmptyStateBox(
            message:
                AdminI18n.tr(isEs, 'No orders yet.', 'Aún no hay pedidos.'),
          )
        else
          ...orders.map((order) => _buildLarderOrderCard(context, order, isEs)),
      ],
    );
  }

  Widget _buildLarderCatalogStrip(BuildContext context, bool isEs) {
    final items = controller.larderCatalog;
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${AdminI18n.tr(isEs, 'Catalog', 'Catálogo')} (${items.length})',
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: KachavaTokens.space2),
      Wrap(
        spacing: KachavaTokens.space2,
        runSpacing: KachavaTokens.space2,
        children: items
            .map((item) => InputChip(
                  key: Key('catalog-larder-chip-${item.id}'),
                  label:
                      Text('${item.name} (\$${item.price.toStringAsFixed(0)})'),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => controller.deleteLarderCatalogItem(item.id),
                ))
            .toList(),
      ),
    ]);
  }

  Widget _buildFilterRow(bool isEs) {
    return Wrap(
        spacing: KachavaTokens.space2,
        runSpacing: KachavaTokens.space2,
        children: [
          ..._statuses.map((status) => ChoiceChip(
                key: Key('larder-status-$status'),
                label: Text(AdminI18n.statusLabel(status, isEs)),
                selected: controller.larderStatusFilter == status,
                onSelected: (_) => controller.setLarderFilters(status: status),
              )),
        ]);
  }

  Widget _buildLarderOrderCard(
      BuildContext context, AdminLarderOrder order, bool isEs) {
    final theme = Theme.of(context);
    final secondary = theme.textTheme.bodyMedium
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Container(
      margin: const EdgeInsets.only(bottom: KachavaTokens.space4),
      padding: const EdgeInsets.all(KachavaTokens.space4),
      decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(KachavaTokens.radiusLg)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildOrderHeader(context, order),
        const SizedBox(height: KachavaTokens.space1),
        Text(
            [
              order.targetDeadline,
              AdminI18n.staffLabel(order.assignedStaffName, isEs)
            ].where((p) => p.isNotEmpty).join(' · '),
            style: secondary),
        const SizedBox(height: KachavaTokens.space3),
        ...order.items
            .map((item) => _buildPlacementItemRow(context, item, isEs)),
        if (order.complimentaryStaples.isNotEmpty) ...[
          const SizedBox(height: KachavaTokens.space2),
          Text(
              '${AdminI18n.tr(isEs, "Complimentary Staples", "Cortesías Incluidas")}: ${order.complimentaryStaples.join(' · ')}',
              style: secondary),
        ],
        const SizedBox(height: KachavaTokens.space3),
        _buildOrderActions(order, isEs),
      ]),
    );
  }

  Widget _buildOrderHeader(BuildContext context, AdminLarderOrder order) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: double.infinity,
      child: Wrap(
          spacing: KachavaTokens.space3,
          runSpacing: KachavaTokens.space2,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
                '${AdminI18n.orDash(order.villaName)} · ${AdminI18n.orDash(order.guestNames)}',
                style: textTheme.titleMedium),
            Wrap(
                spacing: KachavaTokens.space3,
                runSpacing: KachavaTokens.space2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusChip.fromStatus(order.status),
                  Text('\$${order.totalUsd.toStringAsFixed(2)} USD',
                      style: textTheme.titleMedium),
                ]),
          ]),
    );
  }

  Widget _buildOrderActions(AdminLarderOrder order, bool isEs) {
    return Wrap(
        spacing: KachavaTokens.space2,
        runSpacing: KachavaTokens.space2,
        children: [
          OutlinedButton(
            key: Key('assign-larder-${order.orderId}'),
            onPressed: () => controller.updateLarderOrderStatus(
                orderId: order.orderId,
                status: 'Assigned',
                staffId: controller.activeStaff?.staffId ?? ''),
            child: Text(AdminI18n.tr(isEs, 'Assign to me', 'Asignarme')),
          ),
          ElevatedButton.icon(
            key: Key('mark-stocked-${order.orderId}'),
            onPressed: () => controller.updateLarderOrderStatus(
                orderId: order.orderId,
                status: 'Stocked in Villa',
                staffId: order.assignedStaffId),
            icon: const Icon(Icons.check, size: 18),
            label: Text(
                AdminI18n.tr(isEs, 'Stocked in Villa', 'Abastecido en Villa')),
          ),
        ]);
  }

  Widget _buildPlacementItemRow(
      BuildContext context, LarderOrderItem item, bool isEs) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KachavaTokens.space1),
      child: Row(children: [
        Icon(item.isStocked ? Icons.check_box : Icons.check_box_outline_blank,
            size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: KachavaTokens.space2),
        Expanded(
          child: Text(item.name, style: theme.textTheme.bodyMedium),
        ),
        Text(
            AdminI18n.tr(
                isEs, 'Qty: ${item.quantity}', 'Cantidad: ${item.quantity}'),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(width: KachavaTokens.space4),
        Text('\$${item.priceUsd.toStringAsFixed(0)} USD',
            style: theme.textTheme.bodyMedium),
      ]),
    );
  }
}
