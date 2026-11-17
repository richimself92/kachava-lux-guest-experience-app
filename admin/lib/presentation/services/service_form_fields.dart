import 'package:flutter/material.dart';

import '../../application/service_catalog_deps.dart';
import '../../core/service_catalog_labels.dart';
import '../../core/service_catalog_strings.dart';
import '../../domain/admin_service.dart';
import '../../domain/json_draft.dart';
import '../../domain/service_form_layout.dart';
import '../../domain/staff_member.dart';
import '../components/components.dart';
import 'availability_fields.dart';
import 'catalog_image_fields.dart';
import 'draft_choice_fields.dart';
import 'draft_list_fields.dart';
import 'draft_text_fields.dart';
import 'kind_detail_fields.dart';
import 'provider_picker.dart';

/// Widgets of the single service form: the common top, then each field of
/// [serviceFormLayout] by id (see [ServiceFormField]).
class ServiceFormFields {
  const ServiceFormFields({
    required this.draft,
    required this.deps,
    required this.isEs,
    required this.kinds,
    required this.isNew,
    required this.showSection,
    required this.staff,
    required this.items,
    required this.onKind,
    required this.onRebuild,
  });

  final JsonDraft draft;
  final ServiceCatalogDeps deps;
  final bool isEs;
  final List<ServiceKind> kinds;
  final bool isNew;
  final bool showSection;
  final List<StaffMember> staff;

  /// The inline items block (or its "save first" line).
  final Widget items;
  final ValueChanged<ServiceKind> onKind;
  final VoidCallback onRebuild;

  ServiceCatalogStrings get s => ServiceCatalogStrings(isEs);
  ServiceCatalogLabels get l => ServiceCatalogLabels(isEs);
  ServiceKind get kind => ServiceKind.parse(draft.get('kind'));
  PricingMode get mode => PricingMode.parse(draft.get('pricing.mode'));

  /// Every field of the kind: main ones, then the collapsed "More options".
  List<Widget> all() {
    final layout = serviceFormLayout(kind);
    final more = [for (final id in layout.more) ...field(id)];
    return [
      ...top(),
      for (final id in layout.main) ...field(id),
      AdminAdvancedSection(
          key: const Key('svc-more'), title: s.more, children: more),
    ];
  }

  /// Type (only when creating), name, short text and cover.
  List<Widget> top() => [
        if (isNew)
          DraftDropdown(
              draft: draft,
              path: 'kind',
              label: s.type,
              tip: s.kindTip,
              options: [for (final k in kinds) (k.wire, l.kind(k))],
              onChanged: (v) => onKind(ServiceKind.parse(v))),
        _localized('name', s.name, requireOne: true),
        _localized('shortDescription', s.shortText),
        CatalogImageField(
          id: 'cover',
          label: s.cover,
          folder: 'services',
          deps: deps,
          isEs: isEs,
          value: draft.get('cover') as Map<String, dynamic>?,
          onChanged: (v) => draft.set('cover', v),
        ),
      ];

  /// The widgets of one layout id (none when it does not apply here).
  List<Widget> field(String id) {
    final dot = id.indexOf('.');
    final head = dot < 0 ? id : id.substring(0, dot);
    final key = dot < 0 ? '' : id.substring(dot + 1);
    if (head == 'availability') return [availabilityField(draft, key, isEs)];
    if (head == kind.detailField) {
      return [kindDetailField(draft, kind, key, isEs)];
    }
    if (head == 'guestInfo') return [_info(key)];
    if (head == 'operation') return _operation(key);
    return _general(id);
  }

  List<Widget> _general(String id) => switch (id) {
        ServiceFormField.items => [items],
        ServiceFormField.pricing => _pricing(),
        ServiceFormField.provider => [
            ProviderPicker(
                draft: draft,
                providers: deps.providers,
                label: s.provider,
                isEs: isEs)
          ],
        ServiceFormField.responsible => _responsible(),
        ServiceFormField.gallery => [_gallery()],
        'section' => [if (showSection) _section()],
        _ => _meta(id),
      };

  List<Widget> _meta(String id) => switch (id) {
        'pricing.note' => [_localized('pricing.note', s.priceNote)],
        'description' => [_localized('description', s.description, lines: 3)],
        'category' => [
            DraftTextField(
                draft: draft,
                path: 'category',
                label: s.category,
                nullIfBlank: true)
          ],
        'tags' => [
            DraftCsvField(
                draft: draft,
                path: 'tags',
                label: s.tags,
                tip: s.tagsTip,
                isEs: isEs)
          ],
        'order' => [
            DraftIntField(
                draft: draft,
                path: 'order',
                label: s.order,
                isEs: isEs,
                max: 10000)
          ],
        'featured' => [
            DraftSwitch(draft: draft, path: 'featured', label: s.featured)
          ],
        _ => throw ArgumentError.value(id, 'id', 'Unknown service field'),
      };

  Widget _localized(String path, String label,
          {bool requireOne = false, int lines = 1}) =>
      DraftLocalizedField(
          draft: draft,
          path: path,
          label: label,
          isEs: isEs,
          requireOne: requireOne,
          maxLines: lines);

  List<Widget> _pricing() => [
        DraftDropdown(
            draft: draft,
            path: 'pricing.mode',
            label: s.pricing,
            options: [
              for (final m in PricingMode.values) (m.wire, l.pricingMode(m))
            ],
            onChanged: (v) {
              if (!PricingMode.parse(v).hasAmount) {
                draft.set('pricing.amount', null);
              }
              onRebuild();
            }),
        if (mode.hasAmount)
          DraftAmountField(
              draft: draft,
              path: 'pricing.amount',
              label: s.amount,
              tip: s.amountTip,
              isEs: isEs),
        if (mode != PricingMode.included)
          DraftSwitch(
              draft: draft,
              path: 'pricing.chargeToFolio',
              label: s.chargeToFolio),
      ];

  Widget _info(String key) {
    final label = switch (key) {
      'includes' => s.includes,
      'excludes' => s.excludes,
      'location' => s.location,
      'whatToBring' => s.whatToBring,
      'restrictions' => s.restrictions,
      _ => s.cancellation,
    };
    return _localized('guestInfo.$key', label, lines: 2);
  }

  List<Widget> _operation(String key) => [
        if (key == 'requiresConfirmation')
          DraftSwitch(
              draft: draft,
              path: 'operation.requiresConfirmation',
              label: s.needsConfirmation)
        else
          DraftTextField(
              draft: draft,
              path: 'operation.internalInstructions',
              label: s.internalNotes,
              tip: s.operationTip,
              maxLines: 3),
      ];

  List<Widget> _responsible() => [
        DraftDropdown(
            draft: draft,
            path: 'operation.responsibleDepartment',
            label: s.department,
            noneLabel: s.none,
            options: [
              for (final d in ServiceCatalogLabels.departments)
                (d, l.department(d))
            ]),
        if (staff.isNotEmpty)
          DraftDropdown(
              draft: draft,
              path: 'operation.responsibleStaffId',
              label: s.responsible,
              noneLabel: s.none,
              options: [for (final m in staff) (m.staffId, m.fullName)]),
      ];

  Widget _gallery() => CatalogGalleryField(
        deps: deps,
        isEs: isEs,
        initial: [
          for (final g in (draft.get('gallery') as List? ?? const []))
            if (g is Map) Map<String, dynamic>.from(g)
        ],
        onChanged: (v) => draft.set('gallery', v),
      );

  Widget _section() => DraftDropdown(
      draft: draft,
      path: 'section',
      label: s.section,
      options: [for (final x in ServiceSection.values) (x.wire, l.section(x))]);
}
