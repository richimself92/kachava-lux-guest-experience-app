import '../../domain/entities/experience_entities.dart';
import '../../domain/entities/larder_provisioning.dart';

/// Maps the larder catalog and the stay's `larderOrders` onto larder items.
///
/// Field types are strict: a wrong type throws [TypeError], which the
/// repository reports as a transient (unparseable) answer.
abstract final class LarderWireMapper {
  static List<LarderItem> merge(
    Object? rawOrders,
    List<Map<String, dynamic>> catalog,
  ) {
    final base = catalog.map(_mapCatalogItem).toList();
    final orders = rawOrders is List
        ? rawOrders.whereType<Map<String, dynamic>>().toList()
        : const <Map<String, dynamic>>[];
    if (orders.isEmpty) return base;
    final status = _orderStatus(orders.first);
    final quantities = _quantitiesById(orders);
    return LarderProvisioning.isDelivered(status)
        ? _markDelivered(base, quantities)
        : _applyOpenOrder(base, quantities, status);
  }

  static String _orderStatus(Map<String, dynamic> order) =>
      (order['provisioningStatus'] ?? order['status'] ?? 'Pending').toString();

  static Map<String, int> _quantitiesById(List<Map<String, dynamic>> orders) {
    final quantities = <String, int>{};
    for (final o in orders) {
      final id =
          (o['catalogItemId'] ?? o['itemId'] ?? o['id'] ?? '').toString();
      if (id.isNotEmpty) {
        quantities[id] = ((o['quantity'] ?? 0) as num).toInt();
      }
    }
    return quantities;
  }

  /// A delivered order marks its items (or, if none match, the first item)
  /// as stocked so the guest sees the delivery status.
  static List<LarderItem> _markDelivered(
      List<LarderItem> base, Map<String, int> quantities) {
    bool ordered(LarderItem i) => (quantities[i.id] ?? 0) > 0;
    final matchedAny = base.any(ordered);
    return [
      for (final (index, item) in base.indexed)
        item.copyWith(
          quantity: 0,
          isConfirmed: false,
          provisioningStatus: ordered(item) || (!matchedAny && index == 0)
              ? LarderProvisioning.stockedLabel
              : '',
        ),
    ];
  }

  static List<LarderItem> _applyOpenOrder(
      List<LarderItem> base, Map<String, int> quantities, String status) {
    return base.map((item) {
      final qty = quantities[item.id] ?? 0;
      return item.copyWith(
        quantity: qty,
        isConfirmed: qty > 0,
        provisioningStatus: qty > 0 ? status : '',
      );
    }).toList();
  }

  static LarderItem _mapCatalogItem(Map<String, dynamic> c) => LarderItem(
        id: (c['id'] ?? c['itemId'] ?? '').toString(),
        name: (c['name'] ?? c['title'] ?? '').toString(),
        origin: (c['origin'] ?? c['subtitle'] ?? '').toString(),
        description: (c['description'] ?? '').toString(),
        priceUsd: ((c['price'] ?? c['priceUSD'] ?? c['priceUsd'] ?? 0) as num)
            .round(),
        category: (c['category'] ?? '').toString(),
        quantity: 0,
        tag: (c['tag'] ?? '').toString(),
        storageType: (c['storageType'] ?? '').toString(),
        dietaryBadge: (c['dietary'] ?? c['dietaryBadge']) as String?,
      );
}
