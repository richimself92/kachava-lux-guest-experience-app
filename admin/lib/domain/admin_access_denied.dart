/// Raised when the signed-in staff role may not use an admin resource (HTTP
/// 403). Unlike transient failures, retrying will not help.
abstract interface class AdminAccessDenied implements Exception {}
