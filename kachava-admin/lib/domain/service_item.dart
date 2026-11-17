import 'catalog_values.dart';
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
      );

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
      };

  /// Editable JSON for the form (keeps the image URL for its preview).
  Map<String, dynamic> toDraftJson() =>
      {...toWriteJson(), 'id': id, 'image': image?.toDraftJson()};
}
