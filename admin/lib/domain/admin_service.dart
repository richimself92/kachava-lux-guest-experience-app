import 'catalog_values.dart';
import 'json_read.dart';
import 'service_parts.dart';

export 'service_parts.dart';

/// One catalog service (`/admin/services`, ADR-009). Sections (Dining,
/// Experiences, Wellness, Transportation, In villa) are filtered views of
/// this single catalog. Nothing is preloaded: staff create every service.
class AdminService {
  const AdminService({
    this.id = '',
    this.kind = '',
    this.section = '',
    this.category,
    this.usageType = '',
    required this.name,
    this.shortDescription = const LocalizedText(),
    this.description = const LocalizedText(),
    this.tags = const [],
    this.order = 0,
    this.featured = false,
    this.cover,
    this.gallery = const [],
    this.pricing = const ServicePricing(),
    this.availability = const ServiceAvailability(),
    this.guestInfo = const ServiceGuestInfo(),
    this.guestForm = const ServiceGuestForm(),
    this.operation = const ServiceOperation(),
    this.kindDetails = const {},
    this.status = 'DISABLED',
    this.audit = const AuditInfo(),
  });

  factory AdminService.fromJson(Map<String, dynamic> json) {
    final kind = JsonRead.text(json, 'kind');
    final block = kindBlocks[kind];
    return AdminService(
      id: JsonRead.requireId(json),
      kind: kind,
      section: JsonRead.text(json, 'section'),
      category: JsonRead.textOrNull(json, 'category'),
      usageType: JsonRead.text(json, 'usageType'),
      name: LocalizedText.fromJson(json['name']),
      shortDescription: LocalizedText.fromJson(json['shortDescription']),
      description: LocalizedText.fromJson(json['description']),
      tags: JsonRead.strings(json, 'tags'),
      order: JsonRead.intOrNull(json, 'order') ?? 0,
      featured: JsonRead.flag(json, 'featured'),
      cover: CatalogImage.fromJson(json['cover']),
      gallery: [
        for (final raw in JsonRead.objects(json, 'gallery'))
          if (CatalogImage.fromJson(raw) case final image?) image
      ],
      pricing: ServicePricing.fromJson(JsonRead.object(json, 'pricing')),
      availability:
          ServiceAvailability.fromJson(JsonRead.object(json, 'availability')),
      guestInfo: ServiceGuestInfo.fromJson(JsonRead.object(json, 'guestInfo')),
      guestForm: ServiceGuestForm.fromJson(JsonRead.object(json, 'guestForm')),
      operation: ServiceOperation.fromJson(JsonRead.object(json, 'operation')),
      kindDetails: block == null ? const {} : JsonRead.object(json, block),
      status: JsonRead.textOrNull(json, 'status') ?? 'DISABLED',
      audit: AuditInfo.fromJson(json),
    );
  }

  static const int maxGalleryImages = 8;

  /// The type-specific block each `kind` carries (exactly one per service).
  static const Map<String, String> kindBlocks = {
    'BAR': 'bar',
    'BREAKFAST': 'dining',
    'SPECIAL_MENU': 'dining',
    'VILLA_STOCKING': 'stocking',
    'EXPERIENCE': 'experience',
    'WELLNESS': 'wellness',
    'PREFERENCE': 'preference',
    'TRANSPORT': 'transport',
  };

  final String id;

  /// Template, immutable after creation: `BAR | BREAKFAST | SPECIAL_MENU |
  /// VILLA_STOCKING | EXPERIENCE | WELLNESS | PREFERENCE | TRANSPORT`.
  final String kind;

  /// `IN_VILLA | DINING | EXPERIENCES | WELLNESS | TRANSPORTATION`.
  final String section;
  final String? category;

  /// Guest use: `ORDER | BOOKING | PREFERENCE | TRIP`.
  final String usageType;
  final LocalizedText name;
  final LocalizedText shortDescription;
  final LocalizedText description;
  final List<String> tags;
  final int order;
  final bool featured;
  final CatalogImage? cover;
  final List<CatalogImage> gallery;
  final ServicePricing pricing;
  final ServiceAvailability availability;
  final ServiceGuestInfo guestInfo;
  final ServiceGuestForm guestForm;
  final ServiceOperation operation;

  /// Content of the [kindBlock] (e.g. `{ageConfirmationRequired: true}`).
  final Map<String, dynamic> kindDetails;

  /// `ACTIVE | DISABLED`.
  final String status;
  final AuditInfo audit;

  /// Wire key of the type block for [kind] (`bar`, `dining`, ...).
  String? get kindBlock => kindBlocks[kind];

  /// Activation needs a cover and EN/ES name and short description.
  bool get canActivate =>
      cover != null && name.isComplete && shortDescription.isComplete;

  Map<String, dynamic> toWriteJson() => {
        'kind': kind,
        'section': section,
        'category': category,
        'usageType': usageType,
        'name': name.toJson(),
        'shortDescription': shortDescription.toJson(),
        'description': description.toJson(),
        'tags': tags,
        'order': order,
        'featured': featured,
        'cover': cover?.toJson(),
        'gallery': [for (final g in gallery) g.toJson()],
        'pricing': pricing.toJson(),
        'availability': availability.toJson(),
        'guestInfo': guestInfo.toJson(),
        'guestForm': guestForm.toJson(),
        'operation': operation.toJson(),
        if (kindBlock case final block?) block: kindDetails,
        'status': status,
      };
}

/// One item/option of a service (`/admin/services/:id/items`): a bar drink,
/// breakfast dish, product, preference option or vehicle. Fields are flat;
/// the ones that do not apply to the service kind stay `null`/empty.
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
    this.status = 'ACTIVE',
    this.audit = const AuditInfo(),
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) => ServiceItem(
        id: JsonRead.requireId(json),
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
        status: JsonRead.textOrNull(json, 'status') ?? 'ACTIVE',
        audit: AuditInfo.fromJson(json),
      );

  final String id;
  final LocalizedText name;
  final LocalizedText description;

  /// Grouping inside the service (bar category, course, product family).
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

  /// Transport vehicles only.
  final VehicleCapacity? capacity;
  final int order;

  /// `ACTIVE | DISABLED`.
  final String status;
  final AuditInfo audit;

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
        'status': status,
      };
}
