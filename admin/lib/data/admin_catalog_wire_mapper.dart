import '../domain/admin_concierge_folio_entities.dart';
import 'admin_wire_values.dart';

/// Maps folio wire items. Items without an id are skipped.
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
}
