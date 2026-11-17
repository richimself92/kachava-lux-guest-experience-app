import 'catalog_values.dart';
import 'json_read.dart';

/// External transport provider (`/admin/transport-providers`).
class TransportProvider {
  const TransportProvider({
    this.id = '',
    required this.name,
    this.phone = '',
    this.email = '',
    this.isActive = true,
    this.audit = const AuditInfo(),
  });

  factory TransportProvider.fromJson(Map<String, dynamic> json) =>
      TransportProvider(
        id: JsonRead.requireId(json),
        name: JsonRead.text(json, 'name'),
        phone: JsonRead.text(json, 'phone'),
        email: JsonRead.text(json, 'email'),
        isActive: JsonRead.flag(json, 'isActive', fallback: true),
        audit: AuditInfo.fromJson(json),
      );

  final String id;
  final String name;
  final String phone;
  final String email;
  final bool isActive;
  final AuditInfo audit;

  Map<String, dynamic> toWriteJson() => {
        'name': name,
        'phone': phone,
        'email': email,
        'isActive': isActive,
      };
}
