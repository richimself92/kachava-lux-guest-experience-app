/// Compile-time environment configuration loaded via `--dart-define-from-file`.
abstract final class AppConfig {
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3001/api/v1',
  );

  static const String guestPortalUrl = String.fromEnvironment(
    'GUEST_PORTAL_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const bool enableNetwork = bool.fromEnvironment(
    'ENABLE_NETWORK',
    defaultValue: true,
  );
}
