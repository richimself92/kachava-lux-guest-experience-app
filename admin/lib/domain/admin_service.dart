import 'catalog_values.dart';
import 'json_read.dart';
import 'service_catalog_enums.dart';
import 'service_parts.dart';

export 'service_catalog_enums.dart';
export 'service_item.dart';
export 'service_parts.dart';

/// One catalog service (`/admin/services`, backend `AdminServiceView`).
/// Sections (Dining, Experiences, Wellness...) are filtered views of this
/// single catalog. Nothing is preloaded: staff create every service.
class AdminService {
  const AdminService({
    this.id = '',
    required this.kind,
    required this.section,
    required this.usageType,
    this.category,
    this.name = const LocalizedText(),
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
    this.details = const {},
    this.status = CatalogStatus.disabled,
    this.audit = const AuditInfo(),
  });

  /// A server record: a missing `id` is a [FormatException].
  factory AdminService.fromJson(Map<String, dynamic> json) =>
      parse(json, requireId: true);

  /// Parses server JSON or an editor draft ([toDraftJson]).
  static AdminService parse(Map<String, dynamic> json,
      {bool requireId = false}) {
    final kind = ServiceKind.parse(json['kind']);
    return AdminService(
      id: requireId ? JsonRead.requireId(json) : JsonRead.text(json, 'id'),
      kind: kind,
      section: ServiceSection.parse(json['section']),
      usageType: UsageType.parse(json['usageType']),
      category: JsonRead.textOrNull(json, 'category'),
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
      details: JsonRead.object(json, kind.detailField),
      status: CatalogStatus.parse(json['status']),
      audit: AuditInfo.fromJson(json),
    );
  }

  /// Editor draft of a new service: blank texts, no prices, disabled.
  static Map<String, dynamic> emptyDraft(ServiceKind kind,
          {ServiceSection? section}) =>
      AdminService(
        kind: kind,
        section: section ?? kind.defaultSection,
        usageType: kind.defaultUsage,
      ).toDraftJson();

  static const int maxGalleryImages = 8;

  final String id;
  final ServiceKind kind;
  final ServiceSection section;
  final UsageType usageType;
  final String? category;
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

  /// The type-specific block named [ServiceKind.detailField]
  /// (`ageConfirmationRequired`, `itinerary`, `maxPerItem`...).
  final Map<String, dynamic> details;
  final CatalogStatus status;
  final AuditInfo audit;

  /// Activation needs a cover and EN+ES name and short description.
  bool get canActivate =>
      cover != null && name.isComplete && shortDescription.isComplete;

  /// `POST /admin/services` body.
  Map<String, dynamic> toCreateJson() => {
        'kind': kind.wire,
        ...toPatchJson(),
      };

  /// `PATCH /admin/services/:id` body (the kind is immutable).
  Map<String, dynamic> toPatchJson() => {
        'section': section.wire,
        'usageType': usageType.wire,
        'category': (category ?? '').trim().isEmpty ? null : category!.trim(),
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
        kind.detailField: details,
        'status': status.wire,
      };

  /// Editable JSON for the form (keeps image URLs for previews).
  Map<String, dynamic> toDraftJson() => {
        ...toCreateJson(),
        'id': id,
        'cover': cover?.toDraftJson(),
        'gallery': [for (final g in gallery) g.toDraftJson()],
      };
}
