import '../domain/admin_catalog_repositories.dart';
import '../domain/service_request.dart';
import '../domain/uploads.dart';

/// Ports the Services catalog screens need: the catalog itself, transport
/// providers (operation picker), the signed image upload chain and the
/// section request queues.
class ServiceCatalogDeps {
  const ServiceCatalogDeps({
    required this.services,
    required this.providers,
    required this.signer,
    required this.transport,
    required this.picker,
    this.requests,
  });

  final ServiceCatalogRepository services;
  final TransportProviderRepository providers;
  final UploadSigner signer;
  final SignedUploadTransport transport;
  final ImageFilePicker picker;

  /// Section request queues; `null` shows one error line in the tab.
  final ServiceRequestRepository? requests;
}
