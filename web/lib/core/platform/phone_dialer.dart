import 'phone_dialer_stub.dart'
    if (dart.library.js_interop) 'phone_dialer_web.dart';

/// `tel:` URI for a phone typed by staff: keeps a leading `+` and digits.
Uri telUri(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  final normalized = digits.startsWith('+')
      ? '+${digits.substring(1).replaceAll('+', '')}'
      : digits.replaceAll('+', '');
  return Uri(scheme: 'tel', path: normalized);
}

/// Opens the phone dialer (browser `tel:` link); a no-op on headless platforms.
void dialPhone(String phone) => platformOpenUri(telUri(phone));
