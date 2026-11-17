import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kachava_admin_dashboard/data/admin_api_client.dart';

void main() {
  late int logins;
  late Object? realtime;

  AdminApiClient client() => AdminApiClient(
        baseUrl: 'http://api.test/api/v1/admin',
        httpClient: MockClient((request) async {
          if (!request.url.path.endsWith('/auth/login')) {
            return http.Response('{}', 200);
          }
          logins++;
          return http.Response(
              jsonEncode({
                'data': {'token': 'tok-$logins', 'realtime': realtime}
              }),
              201);
        }),
      );

  setUp(() {
    logins = 0;
    realtime = {'adminChannel': 'admin-abc'};
  });

  test('the channel comes from the silent login', () async {
    final api = client();
    expect(await api.realtimeChannel(), 'admin-abc');
    expect(await api.realtimeChannel(), 'admin-abc');
    expect(logins, 1, reason: 'reuses the session');
  });

  test('no channel in the login: real time disabled (null)', () async {
    realtime = null;
    expect(await client().realtimeChannel(), isNull);
  });

  test('renew logs in again when the listener was refused', () async {
    final api = client();
    await api.realtimeChannel();
    realtime = {'adminChannel': 'admin-new'};
    expect(await api.realtimeChannel(renew: true), 'admin-new');
    expect(logins, 2);
  });

  test('renew keeps a session the API already renewed', () async {
    final api = client();
    await api.realtimeChannel();
    api.session.expire();
    await api.getJson('/x');
    final before = logins;
    await api.realtimeChannel(renew: true);
    expect(logins, before);
  });
}
