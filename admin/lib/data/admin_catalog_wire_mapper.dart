import '../domain/admin_concierge_folio_entities.dart';
import 'admin_wire_values.dart';

/// Maps catalog and folio wire items. Items without an id are skipped.
class AdminCatalogWireMapper {
  const AdminCatalogWireMapper._();

  static const _t = WireValues.text;

  static FolioLineItem? folioItem(Map<String, dynamic> fi) {
    final id = WireValues.id(fi, const ['folioItemId', 'itemId']);
    if (id == null) return null;
    return FolioLineItem(
      itemId: id,
      title: _t([fi['title']]),
      categoryLabel: _t([fi['categoryLabel'], fi['category']]).isEmpty
          ? 'INCIDENTAL'
          : _t([fi['categoryLabel'], fi['category']]),
      amountUsd: WireValues.toDouble(fi['amountUsd'] ?? fi['chargedAmountUSD']),
      isIncludedPrivilege:
          fi['isIncludedPrivilege'] == true || fi['isComplimentary'] == true,
    );
  }

  static AdminExperienceCatalogItem? experience(Map<String, dynamic> m) {
    final id = WireValues.id(m, const ['id', 'experienceId']);
    if (id == null) return null;
    final price = WireValues.toDouble(m['basePriceUSD'] ?? m['price']),
        inc = m['isIncluded'] == true || price == 0;
    final category = _t([m['category']]);
    return AdminExperienceCatalogItem(
      id: id,
      title: _t([m['title'], m['name']]),
      category: category.isEmpty ? 'Excursions' : category,
      duration: _t([m['duration']]),
      location: _t([m['location']]),
      priceText: _t([m['priceText']]).isEmpty
          ? (inc ? 'Included' : '\$${price.toStringAsFixed(0)} USD')
          : _t([m['priceText']]),
      basePriceUSD: price,
      isIncluded: inc,
      description: _t([m['description']]),
    );
  }

  static AdminLarderCatalogItem? larderItem(Map<String, dynamic> m) {
    final id = WireValues.id(m, const ['id', 'itemId']);
    if (id == null) return null;
    final category = _t([m['category']]),
        storage = _t([m['storageType'], m['placementZone']]);
    return AdminLarderCatalogItem(
      id: id,
      name: _t([m['name'], m['title']]),
      origin: _t([m['origin']]),
      price:
          WireValues.toDouble(m['price'] ?? m['unitPriceUSD'] ?? m['priceUsd']),
      category: category.isEmpty ? 'Artisanal Spirits' : category,
      storageType: storage.isEmpty ? 'CHILLED IN LARDER' : storage,
      description: _t([m['description']]),
    );
  }
}
