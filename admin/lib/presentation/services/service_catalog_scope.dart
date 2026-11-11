import 'package:flutter/widgets.dart';

import '../../application/service_catalog_deps.dart';

/// Provides [ServiceCatalogDeps] to the Services, Experiences, Dining and
/// Wellness workspaces (wired once in `main.dart`, faked in tests).
class ServiceCatalogScope extends InheritedWidget {
  const ServiceCatalogScope({
    super.key,
    required this.deps,
    required super.child,
  });

  final ServiceCatalogDeps deps;

  /// `null` when no catalog is wired (the screens show one error line).
  static ServiceCatalogDeps? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ServiceCatalogScope>()?.deps;

  @override
  bool updateShouldNotify(ServiceCatalogScope oldWidget) =>
      oldWidget.deps != deps;
}
