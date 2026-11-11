import 'package:web/web.dart' as web;

/// Hands a `tel:` link to the browser, which opens the phone dialer.
void platformOpenUri(Uri uri) {
  web.window.location.href = uri.toString();
}
