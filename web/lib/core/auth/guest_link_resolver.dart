import '../storage/guest_id_store.dart';
import 'magic_link_parser.dart';

/// Decides which guest the portal opens as.
///
/// A valid `?guestId=` in the URL always wins and replaces the remembered one.
/// Without it, the remembered guest is used. A malformed URL id is never
/// saved and stays in place so the portal reports the broken link.
abstract final class GuestLinkResolver {
  static const String _param = 'guestId';

  static Uri resolve(Uri current, GuestIdStore store) {
    final fromUrl = current.queryParameters[_param]?.trim() ?? '';
    if (fromUrl.isNotEmpty) {
      if (MagicLinkParser.isValidUuid(fromUrl)) {
        store.save(fromUrl.toLowerCase());
      }
      return current;
    }
    final stored = store.read()?.trim() ?? '';
    if (!MagicLinkParser.isValidUuid(stored)) {
      if (stored.isNotEmpty) store.clear();
      return current;
    }
    return current.replace(queryParameters: {
      ...current.queryParameters,
      _param: stored.toLowerCase(),
    });
  }
}
