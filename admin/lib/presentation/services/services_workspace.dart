import 'package:flutter/material.dart';

import '../../application/list_query_store.dart';
import '../../core/request_strings.dart';
import '../../core/service_catalog_labels.dart';
import '../../core/service_catalog_strings.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../domain/admin_service.dart';
import '../../domain/service_request.dart';
import '../../domain/staff_member.dart';
import '../components/components.dart';
import 'request_queue_tab.dart';
import 'service_catalog_scope.dart';
import 'services_catalog_list.dart';

/// HOSPITALITY › Services: the whole catalog, every section.
class ServicesWorkspace extends StatelessWidget {
  const ServicesWorkspace({
    super.key,
    this.queryStore,
    this.staff = const [],
    this.isEs = false,
  });

  final ListQueryStore? queryStore;
  final List<StaffMember> staff;
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    final deps = ServiceCatalogScope.maybeOf(context);
    final s = ServiceCatalogStrings(isEs);
    return KeyedSubtree(
      key: const Key('workspace-admin-services'),
      child: deps == null
          ? _NotConnected(s)
          : ServicesCatalogList(
              deps: deps,
              title: s.services,
              queryStore: queryStore,
              staff: staff,
              isEs: isEs,
            ),
    );
  }
}

/// HOSPITALITY › Experiences / Dining / Wellness: the same catalog filtered
/// by [section], plus the section's "Requests" queue.
class ServiceSectionWorkspace extends StatelessWidget {
  const ServiceSectionWorkspace({
    super.key,
    required this.section,
    this.queryStore,
    this.staff = const [],
    this.today,
    this.isEs = false,
  });

  final ServiceSection section;
  final ListQueryStore? queryStore;
  final List<StaffMember> staff;

  /// Resort day for the queue's date presets (`null` without a zone).
  final String? today;
  final bool isEs;

  @override
  Widget build(BuildContext context) {
    final deps = ServiceCatalogScope.maybeOf(context);
    final s = ServiceCatalogStrings(isEs);
    final title = ServiceCatalogLabels(isEs).section(section);
    return DefaultTabController(
      key: Key('workspace-admin-section-${section.wire.toLowerCase()}'),
      length: 2,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: KachavaTokens.text,
          unselectedLabelColor: KachavaTokens.textSecondary,
          indicatorColor: KachavaTokens.text,
          dividerColor: KachavaTokens.border,
          tabs: [
            Tab(
                key: Key('section-tab-requests-${section.wire.toLowerCase()}'),
                text: s.requests),
            Tab(
                key: Key('section-tab-catalog-${section.wire.toLowerCase()}'),
                text: s.catalog),
          ],
        ),
        Expanded(
          child: TabBarView(children: [
            _requests(deps?.requests),
            if (deps == null)
              _NotConnected(s)
            else
              ServicesCatalogList(
                deps: deps,
                title: title,
                section: section,
                queryStore: queryStore,
                staff: staff,
                isEs: isEs,
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _requests(ServiceRequestRepository? repository) => repository == null
      ? Align(
          alignment: Alignment.topLeft,
          child: AdminStateLine(
              key: Key('requests-${section.wire.toLowerCase()}-not-connected'),
              message: RequestStrings(isEs).notConnected,
              isError: true),
        )
      : RequestQueueTab(
          section: section,
          repository: repository,
          queries: queryStore,
          today: today,
          isEs: isEs,
        );
}

class _NotConnected extends StatelessWidget {
  const _NotConnected(this.s);

  final ServiceCatalogStrings s;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topLeft,
        child: AdminStateLine(
            key: const Key('services-not-connected'),
            message: s.notConfigured,
            isError: true),
      );
}
