import 'admin_stay_entities.dart';

/// Villas known from server-confirmed stays.
///
/// Until the API exposes a villas endpoint, the live console only lists villas
/// that appear on real stays: no villa is invented locally.
class AdminVillaDirectory {
  const AdminVillaDirectory._();

  static const String _separator = ' — ';

  static List<AdminVillaInfo> fromStays(List<AdminStayRecord> stays) {
    final byId = <String, AdminVillaInfo>{};
    for (final stay in stays) {
      final key = stay.villaId.isNotEmpty ? stay.villaId : stay.villaName;
      byId.putIfAbsent(key, () => _villaOf(stay));
    }
    return byId.values.toList()
      ..sort((a, b) => a.villaName.compareTo(b.villaName));
  }

  static AdminVillaInfo _villaOf(AdminStayRecord stay) {
    final cut = stay.villaName.indexOf(_separator);
    return AdminVillaInfo(
      villaId: stay.villaId,
      villaName: cut < 0 ? stay.villaName : stay.villaName.substring(0, cut),
      suiteType:
          cut < 0 ? '' : stay.villaName.substring(cut + _separator.length),
      maxGuests: '',
    );
  }
}
