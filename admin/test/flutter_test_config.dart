import 'dart:async';

import 'package:kachava_admin_dashboard/core/guest_portal_link.dart';

/// Test harness: the guest portal base URL is a required build-time define,
/// so tests configure it explicitly instead of relying on a silent default.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GuestPortalLink.configure('http://localhost:3000');
  await testMain();
}
