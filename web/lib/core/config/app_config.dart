/// Compile-time environment configuration loaded via `--dart-define-from-file`.
abstract final class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3001/api/v1',
  );

  static const bool enableNetwork = bool.fromEnvironment(
    'ENABLE_NETWORK',
    defaultValue: true,
  );

  // Firebase (realtime signal listeners only, ADR-012). Missing values
  // disable realtime; the portal still works through REST.
  static const String firebaseApiKey =
      String.fromEnvironment('FIREBASE_API_KEY');
  static const String firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String firebaseProjectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String firebaseMessagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const String firestoreDatabaseId = String.fromEnvironment(
      'FIRESTORE_DATABASE_ID',
      defaultValue: '(default)');

  /// `host:port` of the Firestore emulator; empty in deployed builds.
  static const String firestoreEmulatorHost =
      String.fromEnvironment('FIRESTORE_EMULATOR_HOST');

  static bool get firebaseConfigured =>
      firebaseApiKey.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseProjectId.isNotEmpty;
}
