import 'package:flutter/material.dart';

import '../../core/admin_list_strings.dart';
import '../../core/service_catalog_strings.dart';
import '../../domain/admin_catalog_repositories.dart';
import '../../domain/json_draft.dart';
import '../../domain/list_query.dart';
import '../../domain/paged_result.dart';
import '../../domain/transport_provider.dart';
import '../components/components.dart';
import 'draft_choice_fields.dart';

/// External provider of `operation.providerId`, picked from the active
/// transport providers (loaded once; one line + Retry on failure).
class ProviderPicker extends StatefulWidget {
  const ProviderPicker({
    super.key,
    required this.draft,
    required this.providers,
    required this.label,
    required this.isEs,
  });

  final JsonDraft draft;
  final TransportProviderRepository providers;
  final String label;
  final bool isEs;

  @override
  State<ProviderPicker> createState() => _ProviderPickerState();
}

class _ProviderPickerState extends State<ProviderPicker> {
  late Future<PagedResult<TransportProvider>> _load = _fetch();

  Future<PagedResult<TransportProvider>> _fetch() => widget.providers
      .list(const ListQuery(pageSize: 50).withFilter('isActive', 'true'));

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<PagedResult<TransportProvider>>(
        future: _load,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final s = AdminListStrings(widget.isEs);
            return AdminStateLine(
              key: const Key('svc-provider-error'),
              message: '${widget.label}: ${s.loadError}',
              actionLabel: s.retry,
              onAction: () => setState(() => _load = _fetch()),
              isError: true,
            );
          }
          final providers = snapshot.data?.items ?? const <TransportProvider>[];
          return DraftDropdown(
            key: ValueKey('provider-${providers.length}'),
            draft: widget.draft,
            path: 'operation.providerId',
            label: widget.label,
            noneLabel: ServiceCatalogStrings(widget.isEs).none,
            options: [for (final p in providers) (p.id, p.name)],
          );
        },
      );
}
