import 'catalog.dart';
import 'forms.dart' show FormIssue;
import 'json_read.dart';
import 'stay.dart';
import 'text_search.dart';

/// Max quantity (units or portions) per line accepted by `PUT /orders`.
const int orderLineMax = 20;

/// Rounds a USD amount to cents, like the server does.
double roundCents(double v) => (v * 100).roundToDouble() / 100;

/// ORDER cart: quantity per item, plus oz per portion for OZ items.
class OrderCart {
  OrderCart(this.service, [Map<String, int>? initial, Map<String, int>? oz])
      : quantities = {...?initial},
        _oz = {...?oz};

  /// Cart from the server's stored [lines], overridden by a saved [draft].
  /// Drafts are `{itemId: {qty, oz}}`; old `{itemId: qty}` drafts still load.
  /// A drafted [substitutions] choice wins over the stored one.
  factory OrderCart.restore(CatalogService service,
      {List<LarderOrderLine> lines = const [],
      Json draft = const {},
      bool? substitutions}) {
    final cart = OrderCart(service);
    for (final line in lines) {
      if (line.serviceId != service.id) continue;
      cart._seed(line.itemId, line.quantity, line.ozPerPortion);
      cart.substitutions ??= line.substitutionsAllowed;
    }
    if (substitutions != null) cart.substitutions = substitutions;
    for (final MapEntry(:key, :value) in draft.entries) {
      final entry = asJson(value);
      if (entry.isEmpty) {
        cart._seed(key, asInt(value) ?? 0, null);
      } else {
        cart._seed(key, asInt(entry['qty']) ?? 0, asInt(entry['oz']));
      }
    }
    return cart;
  }

  final CatalogService service;
  final Map<String, int> quantities;
  final Map<String, int> _oz;
  Map<String, (String, String)>? _folded;

  /// Guest's substitution answer; null until chosen.
  bool? substitutions;

  /// Set when the guest ticks "I accept the terms & conditions".
  bool termsAccepted = false;

  bool get hasTerms {
    final t = service.guestInfo.terms;
    return t.en.trim().isNotEmpty || t.es.trim().isNotEmpty;
  }

  /// Required review inputs still missing.
  Set<FormIssue> get issues => {
        if (service.askSubstitutions && substitutions == null)
          FormIssue.substitutionRequired,
        if (hasTerms && !termsAccepted) FormIssue.termsRequired,
      };

  /// Seeds one stored/drafted line; items no longer in the active catalog
  /// (disabled legacy items) are dropped so they never count or get sent.
  void _seed(String itemId, int qty, int? oz) {
    if (_item(itemId) == null) return;
    set(itemId, qty);
    if (oz != null) setOz(itemId, oz);
  }

  CatalogItem? _item(String id) =>
      service.items.where((i) => i.id == id).firstOrNull;

  int quantityOf(String itemId) => quantities[itemId] ?? 0;

  void set(String itemId, int quantity) {
    final q = quantity.clamp(0, orderLineMax);
    if (q == 0) {
      quantities.remove(itemId);
    } else {
      quantities[itemId] = q;
    }
  }

  /// Oz per portion for [item]: the guest's pick or the item default.
  int ozOf(CatalogItem item) => _oz[item.id] ?? item.defaultOz;

  /// Keeps only an oz the item offers.
  void setOz(String itemId, int oz) {
    final item = _item(itemId);
    if (item == null || !item.byWeight) return;
    if (item.portionOzOptions.isNotEmpty &&
        !item.portionOzOptions.contains(oz)) {
      return;
    }
    _oz[itemId] = oz;
  }

  /// USD per unit (ITEM) or per oz (OZ), full precision.
  double? unitPrice(CatalogItem item) =>
      item.priceUSD ?? service.pricing.amount;

  /// Line total rounded to cents; OZ = qty × oz × price per oz.
  double? lineTotal(CatalogItem item) {
    final price = unitPrice(item);
    if (price == null) return null;
    final qty = quantityOf(item.id);
    return roundCents(item.byWeight ? qty * ozOf(item) * price : qty * price);
  }

  int get count => quantities.values.fold(0, (a, b) => a + b);

  double get total => roundCents(
      service.items.fold(0.0, (sum, item) => sum + (lineTotal(item) ?? 0)));

  bool get isEmpty => count == 0;

  /// Item categories in catalog order.
  List<String> get categories => {
        for (final item in service.items)
          if ((item.category ?? '').isNotEmpty) item.category!,
      }.toList();

  /// Items grouped by item category, in catalog order.
  Map<String, List<CatalogItem>> get groups => groupsFor();

  /// [groups] narrowed to a name [query] (EN or ES, case- and
  /// accent-insensitive) and an exact [category].
  Map<String, List<CatalogItem>> groupsFor(
      {String query = '', String? category}) {
    final q = foldForSearch(query);
    final out = <String, List<CatalogItem>>{};
    for (final item in service.items) {
      final cat = item.category ?? '';
      if (category != null && cat != category) continue;
      if (q.isNotEmpty && !_matches(item, q)) continue;
      out.putIfAbsent(cat, () => []).add(item);
    }
    return out;
  }

  bool _matches(CatalogItem item, String q) {
    final folded = _folded ??= {
      for (final i in service.items)
        i.id: (foldForSearch(i.name.en), foldForSearch(i.name.es)),
    };
    final (en, es) = folded[item.id]!;
    return en.contains(q) || es.contains(q);
  }

  /// `{itemId: {qty, oz}}`; oz only for OZ items.
  Json toDraft() => {
        for (final MapEntry(:key, :value) in quantities.entries)
          key: {
            'qty': value,
            if (_item(key)?.byWeight ?? false) 'oz': ozOf(_item(key)!),
          },
      };

  Json toPayload() => {
        'serviceId': service.id,
        'items': [
          for (final item in service.items)
            if (quantityOf(item.id) > 0)
              {
                'itemId': item.id,
                'quantity': quantityOf(item.id),
                if (item.byWeight) 'ozPerPortion': ozOf(item),
              },
        ],
        if (service.askSubstitutions && substitutions != null)
          'substitutionsAllowed': substitutions,
        if (hasTerms && termsAccepted) 'termsAccepted': true,
      };
}
