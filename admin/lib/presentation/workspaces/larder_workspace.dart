import 'package:flutter/material.dart';
import '../../application/admin_dashboard_controller.dart';
import '../../core/admin_i18n.dart';
import '../../core/admin_theme.dart';
import '../../domain/admin_entities.dart';
import '../widgets/semantic_status_badge.dart';
import 'catalog_dialogs.dart';

/// Tab 4: `admin-larder` — Villa Stocking & Larder Provisioning Queue (FR-17).
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
      padding: const EdgeInsets.all(20),
      children: [
        AdminSectionHeader(
          eyebrow: AdminI18n.tr(
              isEs,
              'VILLA LARDER & PANTRY PROVISIONING · FR-17',
              'PEDIDOS DE MINIBAR Y DESPENSA · FR-17'),
          title: AdminI18n.larderTitle(isEs),
          trailing: ElevatedButton.icon(
            key: const Key('add-catalog-larder-btn'),
            style: ElevatedButton.styleFrom(
                backgroundColor: KachavaAdminColors.zapotePrimary,
                foregroundColor: Colors.white),
            onPressed: () => showAddLarderCatalogDialog(context, controller),
            icon: const Icon(Icons.add, size: 16),
            label: Text(AdminI18n.tr(
                isEs, '+ New Minibar Product', '+ Nuevo Producto de Minibar')),
          ),
        ),
        const SizedBox(height: 12),
        _buildLarderCatalogStrip(isEs),
        const SizedBox(height: 14),
        _buildFilterRow(isEs),
        const SizedBox(height: 16),
        if (orders.isEmpty)
          AdminEmptyStateBox(
            message: AdminI18n.tr(
              isEs,
              'No minibar or larder orders yet. When a guest orders items in "Stock My Villa", they will appear here live.',
              'Aún no hay pedidos de minibar o despensa. Cuando el huésped pida productos en su link, aparecerán aquí en vivo.',
            ),
          )
        else
          ...orders.map((order) => _buildLarderOrderCard(order, isEs)),
      ],
    );
  }

  Widget _buildLarderCatalogStrip(bool isEs) {
    final items = controller.larderCatalog;
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: KachavaAdminColors.surfacePaper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KachavaAdminColors.borderLimestone)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          AdminI18n.tr(isEs, 'LIVE MINIBAR & LARDER CATALOG (${items.length})',
              'CATÁLOGO DE MINIBAR Y DESPENSA EN VIVO (${items.length})'),
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: KachavaAdminColors.mutedBronze),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: items
              .map((item) => InputChip(
                    key: Key('catalog-larder-chip-${item.id}'),
                    label: Text(
                        '${item.name} (\$${item.price.toStringAsFixed(0)})',
                        style: const TextStyle(fontSize: 11)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () =>
                        controller.deleteLarderCatalogItem(item.id),
                  ))
              .toList(),
        ),
      ]),
    );
  }

  Widget _buildFilterRow(bool isEs) {
    return Wrap(spacing: 8, runSpacing: 8, children: [
      ..._statuses.map((status) => ChoiceChip(
            key: Key('larder-status-$status'),
            label: Text(AdminI18n.statusLabel(status, isEs)),
            selected: controller.larderStatusFilter == status,
            onSelected: (_) => controller.setLarderFilters(status: status),
          )),
    ]);
  }

  Widget _buildLarderOrderCard(AdminLarderOrder order, bool isEs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: KachavaAdminColors.surfacePaper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KachavaAdminColors.borderLimestone)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildOrderHeader(order),
        const SizedBox(height: 6),
        Text('${order.targetDeadline} · ${order.assignedStaffName}',
            style: const TextStyle(
                fontSize: 12, color: KachavaAdminColors.neutralMuted)),
        const SizedBox(height: 12),
        ...order.items.map((item) => _buildPlacementItemRow(item, isEs)),
        const SizedBox(height: 10),
        Text(
            '${AdminI18n.tr(isEs, "Complimentary Staples", "Cortesías Incluidas")}: ${order.complimentaryStaples.join(' · ')}',
            style: const TextStyle(
                fontSize: 11, color: KachavaAdminColors.neutralMuted)),
        const SizedBox(height: 14),
        _buildOrderActions(order, isEs),
      ]),
    );
  }

  Widget _buildOrderHeader(AdminLarderOrder order) {
    return SizedBox(
      width: double.infinity,
      child: Wrap(
          spacing: 10,
          runSpacing: 6,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('${order.villaName} · ${order.guestNames}',
                style: const TextStyle(
                    fontFamily: 'Libre Baskerville',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: KachavaAdminColors.obsidian)),
            Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SemanticStatusBadge(label: order.status),
                  Text('\$${order.totalUsd.toStringAsFixed(2)} USD',
                      style: const TextStyle(
                          fontFamily: 'Libre Baskerville',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: KachavaAdminColors.zapotePrimary)),
                ]),
          ]),
    );
  }

  Widget _buildOrderActions(AdminLarderOrder order, bool isEs) {
    return Wrap(spacing: 10, runSpacing: 8, children: [
      OutlinedButton(
        key: Key('assign-larder-${order.orderId}'),
        onPressed: () => controller.updateLarderOrderStatus(
            orderId: order.orderId, status: 'Assigned', staffId: 'staff_sofia'),
        child:
            Text(AdminI18n.tr(isEs, 'Assign HOST ADMIN', 'Asignar HOST ADMIN')),
      ),
      ElevatedButton.icon(
        key: Key('mark-stocked-${order.orderId}'),
        style: ElevatedButton.styleFrom(
            backgroundColor: KachavaAdminColors.zapotePrimary,
            foregroundColor: Colors.white),
        onPressed: () => controller.updateLarderOrderStatus(
            orderId: order.orderId,
            status: 'Stocked in Villa',
            staffId: order.assignedStaffId),
        icon: const Icon(Icons.check_circle_outline, size: 16),
        label:
            Text(AdminI18n.tr(isEs, 'Stocked in Villa', 'Abastecido en Villa')),
      ),
    ]);
  }

  Widget _buildPlacementItemRow(LarderOrderItem item, bool isEs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: KachavaAdminColors.surfaceContainer,
          borderRadius: BorderRadius.circular(10)),
      child: Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                  item.isStocked
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  size: 16,
                  color: KachavaAdminColors.zapotePrimary),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: KachavaAdminColors.canvasLow,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: KachavaAdminColors.borderWarm),
                ),
                child: Text(
                    AdminI18n.tr(
                      isEs,
                      'Qty: ${item.quantity}',
                      'Cantidad: ${item.quantity}',
                    ),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: KachavaAdminColors.zapotePrimary)),
              ),
              const SizedBox(width: 8),
              Flexible(
                  child: Text('${item.quantity}x ${item.name}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600))),
            ]),
            Text('\$${item.priceUsd.toStringAsFixed(0)} USD',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: KachavaAdminColors.zapotePrimary)),
          ]),
    );
  }
}
