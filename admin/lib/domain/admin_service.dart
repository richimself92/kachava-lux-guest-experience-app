import 'catalog_values.dart';
import 'json_read.dart';
import 'service_parts.dart';

export 'service_parts.dart';

/// One catalog service (`/admin/services`). Sections (Dining, Experiences,
/// Wellness, Transportation...) are filtered views of this single catalog.
class AdminService {
  const AdminService({
    this.id = '',
    required this.name,
    this.shortDescription = const LocalizedText(),
    this.description = const LocalizedText(),
    this.section = '',
    this.type = '',
    this.tags = const [],
    this.sortOrder = 0,
    this.featured = false,
    this.cover,
    this.gallery = const [],
    this.usage = '',
    this.pricing = const ServicePricing(),
    this.availability = const ServiceAvailability(),
    this.guestInfo = const ServiceGuestInfo(),
    this.guestForm = const ServiceGuestForm(),
    this.operation = const ServiceOperation(),
    this.status = 'DISABLED',
    this.details = const {},
    this.audit = const AuditInfo(),
  });

  factory AdminService.fromJson(Map<String, dynamic> json) => AdminService(
        id: JsonRead.requireId(json),
        name: LocalizedText.fromJson(json['name']),
        shortDescription: LocalizedText.fromJson(json['shortDescription']),
        description: LocalizedText.fromJson(json['description']),
        section: JsonRead.text(json, 'section'),
        type: JsonRead.text(json, 'type'),
        tags: JsonRead.strings(json, 'tags'),
        sortOrder: JsonRead.intOrNull(json, 'sortOrder') ?? 0,
        featured: JsonRead.flag(json, 'featured'),
        cover: CatalogImage.fromJson(json['cover']),
        gallery: [
          for (final raw in JsonRead.objects(json, 'gallery'))
            if (CatalogImage.fromJson(raw) case final image?) image
        ],
        usage: JsonRead.text(json, 'usage'),
        pricing: ServicePricing.fromJson(JsonRead.object(json, 'pricing')),
        availability:
            ServiceAvailability.fromJson(JsonRead.object(json, 'availability')),
        guestInfo:
            ServiceGuestInfo.fromJson(JsonRead.object(json, 'guestInfo')),
        guestForm:
            ServiceGuestForm.fromJson(JsonRead.object(json, 'guestForm')),
        operation:
            ServiceOperation.fromJson(JsonRead.object(json, 'operation')),
        status: JsonRead.textOrNull(json, 'status') ?? 'DISABLED',
        details: JsonRead.object(json, 'details'),
        audit: AuditInfo.fromJson(json),
      );

  static const int maxGalleryImages = 8;

  final String id;
  final LocalizedText name;
  final LocalizedText shortDescription;
  final LocalizedText description;

  /// `DINING | EXPERIENCES | WELLNESS | TRANSPORTATION | VILLA_PROVISIONING |
  /// PREFERENCES`.
  final String section;

  /// Type-specific template, e.g. `LUX_BAR`, `BREAKFAST`, `SPECIAL_MENU`,
  /// `PROVISIONING`, `EXPERIENCE`, `WELLNESS`, `PREFERENCE`, `TRANSPORT`.
  final String type;
  final List<String> tags;
  final int sortOrder;
  final bool featured;
  final CatalogImage? cover;
  final List<CatalogImage> gallery;

  /// Guest use: `ORDER | BOOKING | PREFERENCE | TRIP`.
  final String usage;
  final ServicePricing pricing;
  final ServiceAvailability availability;
  final ServiceGuestInfo guestInfo;
  final ServiceGuestForm guestForm;
  final ServiceOperation operation;

  /// `ACTIVE | DISABLED`.
  final String status;

  /// Type-specific fields (`ageConfirmationRequired`, `itinerary`,
  /// `maxPerProduct`, `selection`, ...), passed through untouched.
  final Map<String, dynamic> details;
  final AuditInfo audit;

  /// Activation needs a cover and EN/ES name and short description.
  bool get canActivate =>
      cover != null && name.isComplete && shortDescription.isComplete;

  Map<String, dynamic> toWriteJson() => {
        'name': name.toJson(),
        'shortDescription': shortDescription.toJson(),
        'description': description.toJson(),
        'section': section,
        'type': type,
        'tags': tags,
        'sortOrder': sortOrder,
        'featured': featured,
        'cover': cover?.toJson(),
        'gallery': [for (final g in gallery) g.toJson()],
        'usage': usage,
        'pricing': pricing.toJson(),
        'availability': availability.toJson(),
        'guestInfo': guestInfo.toJson(),
        'guestForm': guestForm.toJson(),
        'operation': operation.toJson(),
        'status': status,
        'details': details,
      };
}

/// One item/option of a service (`/admin/services/:id/items`): a bar drink,
/// breakfast dish, product, preference option or vehicle.
class ServiceItem {
  const ServiceItem({
    this.id = '',
    required this.name,
    this.description = const LocalizedText(),
    this.image,
    this.price,
    this.category = '',
    this.tags = const [],
    this.isAvailable = true,
    this.sortOrder = 0,
    this.details = const {},
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) => ServiceItem(
        id: JsonRead.requireId(json),
        name: LocalizedText.fromJson(json['name']),
        description: LocalizedText.fromJson(json['description']),
        image: CatalogImage.fromJson(json['image']),
        price: JsonRead.doubleOrNull(json, 'price'),
        category: JsonRead.text(json, 'category'),
        tags: JsonRead.strings(json, 'tags'),
        isAvailable: JsonRead.flag(json, 'isAvailable', fallback: true),
        sortOrder: JsonRead.intOrNull(json, 'sortOrder') ?? 0,
        details: JsonRead.object(json, 'details'),
      );

  final String id;
  final LocalizedText name;
  final LocalizedText description;
  final CatalogImage? image;

  /// USD; `null` = included / not priced per item.
  final double? price;
  final String category;
  final List<String> tags;
  final bool isAvailable;
  final int sortOrder;

  /// Item-specific fields (origin, unit, allergens, passengers, luggage...).
  final Map<String, dynamic> details;

  Map<String, dynamic> toWriteJson() => {
        'name': name.toJson(),
        'description': description.toJson(),
        'image': image?.toJson(),
        'price': price,
        'category': category,
        'tags': tags,
        'isAvailable': isAvailable,
        'sortOrder': sortOrder,
        'details': details,
      };
}
