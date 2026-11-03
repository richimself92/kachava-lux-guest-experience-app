import '../domain/admin_catalog_repositories.dart';
import '../domain/uploads.dart';

/// Ports the Services catalog screens need: the catalog itself, transport
/// providers (operation picker) and the signed image upload chain.
class ServiceCatalogDeps {
  const ServiceCatalogDeps({
    required this.services,
    required this.providers,
    required this.signer,
    required this.transport,
    required this.picker,
  });

  final ServiceCatalogRepository services;
  final TransportProviderRepository providers;
  final UploadSigner signer;
  final SignedUploadTransport transport;
  final ImageFilePicker picker;
}
