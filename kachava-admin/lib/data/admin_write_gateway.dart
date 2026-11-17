/// Port: sends admin mutations to the server (`/api/v1/admin/*`) and
/// returns the decoded response. Implemented by `AdminApiClient`.
abstract interface class AdminWriteGateway {
  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body);
  Future<Map<String, dynamic>> patchJson(
      String path, Map<String, dynamic> body);
  Future<Map<String, dynamic>> deleteJson(String path);
  void dispose();
}
