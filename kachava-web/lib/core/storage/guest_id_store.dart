import 'guest_id_store_stub.dart'
    if (dart.library.js_interop) 'guest_id_store_web.dart';

/// Browser storage key shared with the boot script in `web/index.html`.
const String guestIdStorageKey = 'kachava_guest_id';

/// Port for the guest link remembered on this device, so an installed app
/// reopens as the same guest without `?guestId=` in the URL.
abstract interface class GuestIdStore {
  String? read();
  void save(String guestId);
  void clear();
}

/// In-memory [GuestIdStore] for tests and non-browser platforms.
class MemoryGuestIdStore implements GuestIdStore {
  MemoryGuestIdStore([this._guestId]);

  String? _guestId;

  @override
  String? read() => _guestId;

  @override
  void save(String guestId) => _guestId = guestId;

  @override
  void clear() => _guestId = null;
}

/// Factory returning the platform-appropriate [GuestIdStore].
GuestIdStore createGuestIdStore() => createPlatformGuestIdStore();
