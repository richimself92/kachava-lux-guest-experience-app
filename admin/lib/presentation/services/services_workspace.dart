import 'package:flutter/material.dart';

import '../../application/list_query_store.dart';
import '../../core/service_catalog_labels.dart';
import '../../core/service_catalog_strings.dart';
import '../../core/theme/kachava_tokens.dart';
import '../../domain/admin_service.dart';
import '../../domain/staff_member.dart';
import '../components/components.dart';
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
/// by [section], plus a "Requests" tab (the request queues come later).
class ServiceSectionWorkspace extends StatelessWidget {
  const ServiceSectionWorkspace({
    super.key,
    required this.section,
    this.queryStore,
    this.staff = const [],
    this.isEs = false,
  });

  final ServiceSection section;
  final ListQueryStore? queryStore;
  final List<StaffMember> staff;
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
          tabs: [Tab(text: s.catalog), Tab(text: s.requests)],
        ),
        Expanded(
          child: TabBarView(children: [
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
            Align(
              alignment: Alignment.topLeft,
              child: AdminStateLine(
                  key: Key('requests-${section.wire.toLowerCase()}-empty'),
                  message: s.requestsSoon),
            ),
          ]),
        ),
      ]),
    );
  }
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
