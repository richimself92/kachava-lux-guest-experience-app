import 'guest_id_store.dart';

/// Headless platforms (`flutter test`) keep the guest link in memory only.
GuestIdStore createPlatformGuestIdStore() => MemoryGuestIdStore();
