import 'package:http/http.dart' as http;
import 'package:kachava_admin_dashboard/data/admin_api_client.dart';
import 'package:kachava_admin_dashboard/data/admin_session.dart';

/// An [AdminApiClient] whose staff session is already open, for tests that
/// exercise authenticated admin calls against a fake HTTP client.
AdminApiClient signedInApiClient(http.Client httpClient) => AdminApiClient(
    httpClient: httpClient, session: AdminSession(token: 'test-staff-token'));
