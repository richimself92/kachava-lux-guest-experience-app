import 'package:flutter/material.dart';

import '../../application/service_catalog_deps.dart';
import '../../core/service_catalog_labels.dart';
import '../../core/service_catalog_strings.dart';
import '../../domain/admin_service.dart';
import '../../domain/staff_member.dart';
import '../../domain/json_draft.dart';
import '../components/components.dart';
import 'availability_fields.dart';
import 'catalog_image_fields.dart';
import 'draft_choice_fields.dart';
import 'draft_list_fields.dart';
import 'draft_text_fields.dart';
import 'provider_picker.dart';

/// Field lists of each editor tab. Only fields relevant to the kind and the
/// guest use are shown; optional ones are collapsed under "More".
class ServiceEditorTabs {
  const ServiceEditorTabs({
    required this.draft,
    required this.deps,
    required this.isEs,
    required this.kinds,
    required this.isNew,
    required this.showSection,
    required this.staff,
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
  final ValueChanged<ServiceKind> onKind;
  final VoidCallback onRebuild;

  ServiceCatalogStrings get s => ServiceCatalogStrings(isEs);
  ServiceCatalogLabels get l => ServiceCatalogLabels(isEs);
  ServiceKind get kind => ServiceKind.parse(draft.get('kind'));
  UsageType get usage => UsageType.parse(draft.get('usageType'));
  PricingMode get mode => PricingMode.parse(draft.get('pricing.mode'));

  List<Widget> general() => [
        DraftDropdown(
            draft: draft,
            path: 'kind',
            label: s.type,
            tip: s.kindTip,
            enabled: isNew,
            options: [for (final k in kinds) (k.wire, l.kind(k))],
            onChanged: (v) => onKind(ServiceKind.parse(v))),
        DraftLocalizedField(
            draft: draft,
            path: 'name',
            label: s.name,
            isEs: isEs,
            requireOne: true),
        DraftLocalizedField(
            draft: draft,
            path: 'shortDescription',
            label: s.shortText,
            isEs: isEs),
        if (showSection)
          DraftDropdown(
              draft: draft,
              path: 'section',
              label: s.section,
              options: [
                for (final x in ServiceSection.values) (x.wire, l.section(x))
              ]),
        DraftDropdown(
            draft: draft,
            path: 'usageType',
            label: s.use,
            options: [for (final u in UsageType.values) (u.wire, l.usage(u))],
            onChanged: (_) => onRebuild()),
        AdminAdvancedSection(
            key: const Key('svc-more-general'),
            title: s.more,
            children: [
              DraftLocalizedField(
                  draft: draft,
                  path: 'description',
                  label: s.description,
                  isEs: isEs,
                  maxLines: 3),
              DraftTextField(
                  draft: draft,
                  path: 'category',
                  label: s.category,
                  nullIfBlank: true),
              DraftCsvField(
                  draft: draft,
                  path: 'tags',
                  label: s.tags,
                  tip: s.tagsTip,
                  isEs: isEs),
              DraftIntField(
                  draft: draft,
                  path: 'order',
                  label: s.order,
                  isEs: isEs,
                  max: 10000),
              DraftSwitch(draft: draft, path: 'featured', label: s.featured),
            ]),
      ];

  List<Widget> images() => [
        CatalogImageField(
          id: 'cover',
          label: s.cover,
          folder: 'services',
          deps: deps,
          isEs: isEs,
          value: draft.get('cover') as Map<String, dynamic>?,
          onChanged: (v) => draft.set('cover', v),
        ),
        CatalogGalleryField(
          deps: deps,
          isEs: isEs,
          initial: [
            for (final g in (draft.get('gallery') as List? ?? const []))
              if (g is Map) Map<String, dynamic>.from(g)
          ],
          onChanged: (v) => draft.set('gallery', v),
        ),
      ];

  List<Widget> pricing() => [
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
        ...availabilityFields(draft, usage, isEs),
        AdminAdvancedSection(
            key: const Key('svc-more-pricing'),
            title: s.more,
            children: [
              DraftLocalizedField(
                  draft: draft,
                  path: 'pricing.note',
                  label: s.priceNote,
                  isEs: isEs),
              ...availabilityFields(draft, usage, isEs, advanced: true),
            ]),
      ];

  static const _dietKinds = {
    ServiceKind.bar,
    ServiceKind.breakfast,
    ServiceKind.specialMenu,
    ServiceKind.villaStocking,
    ServiceKind.experience,
  };

  List<Widget> guestForm() => [
        AdminFieldLabel(s.asks),
        for (final (key, label) in [
          ('date', s.askDate),
          ('time', s.askTime),
          ('guests', s.askGuests),
          ('notes', s.askNotes),
          if (_dietKinds.contains(kind)) ('dietary', s.askDietary),
          if (kind == ServiceKind.wellness || kind == ServiceKind.experience)
            ('health', s.askHealth),
        ])
          DraftSwitch(draft: draft, path: 'guestForm.$key', label: label),
        const SizedBox(height: 16),
        for (final (key, label) in [
          ('includes', s.includes),
          ('excludes', s.excludes),
          ('location', s.location),
        ])
          _info(key, label),
        AdminAdvancedSection(
            key: const Key('svc-more-guest'),
            title: s.more,
            children: [
              _info('whatToBring', s.whatToBring),
              _info('restrictions', s.restrictions),
              _info('cancellationPolicy', s.cancellation),
            ]),
      ];

  Widget _info(String key, String label) => DraftLocalizedField(
      draft: draft,
      path: 'guestInfo.$key',
      label: label,
      isEs: isEs,
      maxLines: 2);

  List<Widget> operation() => [
        ProviderPicker(
            draft: draft,
            providers: deps.providers,
            label: s.provider,
            isEs: isEs),
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
        DraftSwitch(
            draft: draft,
            path: 'operation.requiresConfirmation',
            label: s.needsConfirmation),
        DraftTextField(
            draft: draft,
            path: 'operation.internalInstructions',
            label: s.internalNotes,
            tip: s.operationTip,
            maxLines: 3),
      ];
}
