/// Environment configuration resolved via `--dart-define` or `--dart-define-from-file`.
class AdminAppConfig {
  const AdminAppConfig._();

  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3001/api/v1/admin',
  );

  /// Required: no default. Validated at startup by `GuestPortalLink.configure`.
  static const String guestPortalUrl = String.fromEnvironment(
    'GUEST_PORTAL_URL',
  );
}
