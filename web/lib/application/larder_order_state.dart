import '../domain/entities/experience_entities.dart';
import '../domain/entities/larder_provisioning.dart';

/// The guest's larder order as the server reports it on its items.
class LarderOrderState {
  const LarderOrderState({
    required this.status,
    required this.isConfirmed,
    required this.submittedItems,
  });

  final String status;
  final bool isConfirmed;
  final List<LarderItem> submittedItems;

  /// `null` when the server reports no order on any item.
  static LarderOrderState? fromServerItems(List<LarderItem> items) {
    final status = items
            .where((i) => i.provisioningStatus.isNotEmpty)
            .firstOrNull
            ?.provisioningStatus ??
        '';
    if (status.isEmpty) return null;
    if (LarderProvisioning.isDelivered(status)) {
      return const LarderOrderState(
        status: LarderProvisioning.stockedLabel,
        isConfirmed: false,
        submittedItems: [],
      );
    }
    return LarderOrderState(
      status: status,
      isConfirmed: true,
      submittedItems: items.where((i) => i.quantity > 0).toList(),
    );
  }
}
