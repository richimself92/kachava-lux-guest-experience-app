/// Raised when the staff role may not use an admin resource (HTTP 403) or the
/// silent staff login itself is rejected. Unlike transient failures, retrying
/// will not help.
abstract interface class AdminAccessDenied implements Exception {}
