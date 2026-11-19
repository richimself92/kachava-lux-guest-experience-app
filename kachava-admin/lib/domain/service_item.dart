import 'catalog_values.dart';
import 'item_pricing_rules.dart';
import 'json_read.dart';
import 'service_catalog_enums.dart';

/// Seats and bags of a transport vehicle item.
class VehicleCapacity {
  const VehicleCapacity({required this.passengers, required this.luggage});

  static VehicleCapacity? fromJson(Object? json) {
    if (json is! Map) return null;
    final map = Map<String, dynamic>.from(json);
    final passengers = JsonRead.intOrNull(map, 'passengers');
    if (passengers == null) return null;
    return VehicleCapacity(
        passengers: passengers,
        luggage: JsonRead.intOrNull(map, 'luggage') ?? 0);
  }

  final int passengers;
  final int luggage;

  Map<String, dynamic> toJson() =>
      {'passengers': passengers, 'luggage': luggage};
}

/// One item/option of a service (`/admin/services/:id/items`): a bar drink,
/// breakfast dish, product, preference option or vehicle. Each has its own
/// photo and price.
class ServiceItem {
  const ServiceItem({
    this.id = '',
    required this.name,
    this.description = const LocalizedText(),
    this.category,
    this.image,
    this.priceUSD,
    this.tags = const [],
    this.dietaryTags = const [],
    this.allergens = const [],
    this.origin,
    this.unit,
    this.storage,
    this.capacity,
    this.order = 0,
    this.status = CatalogStatus.disabled,
    this.sku,
    this.netCostMXN,
    this.sourceUrl,
    this.pricingUnit = PricingUnit.item,
    this.portionOzOptions = const [],
  });

  /// A server record: a missing `id` is a [FormatException].
  factory ServiceItem.fromJson(Map<String, dynamic> json) =>
      parse(json, requireId: true);

  /// Parses server JSON or an editor draft ([toDraftJson]).
  static ServiceItem parse(Map<String, dynamic> json,
          {bool requireId = false}) =>
      ServiceItem(
        id: requireId ? JsonRead.requireId(json) : JsonRead.text(json, 'id'),
        name: LocalizedText.fromJson(json['name']),
        description: LocalizedText.fromJson(json['description']),
        category: JsonRead.textOrNull(json, 'category'),
        image: CatalogImage.fromJson(json['image']),
        priceUSD: JsonRead.doubleOrNull(json, 'priceUSD'),
        tags: JsonRead.strings(json, 'tags'),
        dietaryTags: JsonRead.strings(json, 'dietaryTags'),
        allergens: JsonRead.strings(json, 'allergens'),
        origin: JsonRead.textOrNull(json, 'origin'),
        unit: JsonRead.textOrNull(json, 'unit'),
        storage: JsonRead.textOrNull(json, 'storage'),
        capacity: VehicleCapacity.fromJson(json['capacity']),
        order: JsonRead.intOrNull(json, 'order') ?? 0,
        status: CatalogStatus.parse(json['status']),
        sku: JsonRead.textOrNull(json, 'sku'),
        netCostMXN: JsonRead.doubleOrNull(json, 'netCostMXN'),
        sourceUrl: JsonRead.textOrNull(json, 'sourceUrl'),
        pricingUnit: PricingUnit.parse(json['pricingUnit']),
        portionOzOptions: _ints(json['portionOzOptions']),
      );

  static List<int> _ints(Object? raw) => raw is List
      ? [
          for (final e in raw)
            if (e is num) e.toInt() else if (int.tryParse('$e') case final v?) v
        ]
      : const [];

  final String id;
  final LocalizedText name;
  final LocalizedText description;
  final String? category;
  final CatalogImage? image;

  /// Own USD price; `null` means the service pricing applies.
  final double? priceUSD;
  final List<String> tags;
  final List<String> dietaryTags;
  final List<String> allergens;
  final String? origin;
  final String? unit;
  final String? storage;
  final VehicleCapacity? capacity;
  final int order;
  final CatalogStatus status;

  /// Admin-only stock code (unique within the service).
  final String? sku;

  /// Admin-only net cost in MXN (per oz when [pricingUnit] is OZ).
  final double? netCostMXN;

  /// Admin-only purchase link.
  final String? sourceUrl;

  /// With [PricingUnit.oz], [priceUSD] is USD per oz.
  final PricingUnit pricingUnit;

  /// Oz per portion the guest can pick (OZ items only).
  final List<int> portionOzOptions;

  bool get isPricedByOz => pricingUnit == PricingUnit.oz;

  /// Options sent to the server: defaults for OZ, none for ITEM.
  List<int> get _wireOzOptions => !isPricedByOz
      ? const []
      : portionOzOptions.isEmpty
          ? ItemPricingRules.defaultOzOptions
          : portionOzOptions;

  /// `POST` / `PATCH` body.
  Map<String, dynamic> toWriteJson() => {
        'name': name.toJson(),
        'description': description.toJson(),
        'category': category,
        'image': image?.toJson(),
        'priceUSD': priceUSD,
        'tags': tags,
        'dietaryTags': dietaryTags,
        'allergens': allergens,
        'origin': origin,
        'unit': unit,
        'storage': storage,
        'capacity': capacity?.toJson(),
        'order': order,
        'status': status.wire,
        'sku': sku,
        'netCostMXN': netCostMXN,
        'sourceUrl': sourceUrl,
        'pricingUnit': pricingUnit.wire,
        'portionOzOptions': _wireOzOptions,
      };

  /// Editable JSON for the form (keeps the image URL for its preview).
  Map<String, dynamic> toDraftJson() =>
      {...toWriteJson(), 'id': id, 'image': image?.toDraftJson()};
}
