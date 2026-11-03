/// Provisioning vocabulary shared by the larder wire mapping and UI state.
abstract final class LarderProvisioning {
  static const String stockedLabel = 'Stocked in Villa';

  static bool isDelivered(String status) {
    final lower = status.toLowerCase();
    return lower.contains('stocked') || lower.contains('delivered');
  }
}
