/// Environment configuration resolved via `--dart-define` or `--dart-define-from-file`.
class AdminAppConfig {
  const AdminAppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3001/api/v1/admin',
  );

  /// Rostered staff email the app silently signs in with (no login screen).
  static const String adminStaffEmail = String.fromEnvironment(
    'ADMIN_STAFF_EMAIL',
    defaultValue: 'eduardo.rivera@kachavalux.com',
  );

  /// Firebase web config for the real-time signal listener (ADR-012).
  /// Any of the first five empty disables real time (no crash).
  static const String firebaseApiKey =
      String.fromEnvironment('FIREBASE_API_KEY');
  static const String firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String firebaseProjectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String firebaseMessagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const String firestoreDatabaseId =
      String.fromEnvironment('FIRESTORE_DATABASE_ID');

  /// `host:port` of the Firestore emulator (local only); empty in cloud.
  static const String firestoreEmulatorHost =
      String.fromEnvironment('FIRESTORE_EMULATOR_HOST');

  static bool get realtimeConfigured => [
        firebaseApiKey,
        firebaseAppId,
        firebaseProjectId,
        firebaseMessagingSenderId,
        firestoreDatabaseId,
      ].every((v) => v.isNotEmpty);
}
