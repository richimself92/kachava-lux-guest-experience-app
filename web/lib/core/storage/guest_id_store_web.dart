import 'package:web/web.dart' as web;

import 'guest_id_store.dart';

/// `localStorage` implementation. Storage can be disabled (private mode,
/// blocked site data), so every access fails soft.
class LocalStorageGuestIdStore implements GuestIdStore {
  @override
  String? read() {
    try {
      return web.window.localStorage.getItem(guestIdStorageKey);
    } catch (_) {
      return null;
    }
  }

  @override
  void save(String guestId) {
    try {
      web.window.localStorage.setItem(guestIdStorageKey, guestId);
    } catch (_) {}
  }

  @override
  void clear() {
    try {
      web.window.localStorage.removeItem(guestIdStorageKey);
    } catch (_) {}
  }
}

GuestIdStore createPlatformGuestIdStore() => LocalStorageGuestIdStore();
