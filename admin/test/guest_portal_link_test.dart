import 'package:flutter_test/flutter_test.dart';
import 'package:kachava_admin_dashboard/core/guest_portal_link.dart';
import 'package:kachava_admin_dashboard/main.dart' as app;

void main() {
  group('GuestPortalLink fail-fast configuration', () {
    test('test_validate_base_url_empty_value_throws_config_exception', () {
      expect(() => GuestPortalLink.validateBaseUrl('  '),
          throwsA(isA<AdminConfigException>()));
    });

    test('test_validate_base_url_relative_value_throws_config_exception', () {
      expect(() => GuestPortalLink.validateBaseUrl('guest-portal.web.app'),
          throwsA(isA<AdminConfigException>()));
    });

    test('test_validate_base_url_absolute_https_strips_trailing_slash', () {
      expect(GuestPortalLink.validateBaseUrl('https://portal.example.com/'),
          'https://portal.example.com');
    });

    test('test_config_exception_message_names_missing_define', () {
      try {
        GuestPortalLink.validateBaseUrl('');
        fail('Expected AdminConfigException');
      } on AdminConfigException catch (e) {
        expect(e.toString(), contains('GUEST_PORTAL_URL'));
      }
    });

    test('test_for_token_builds_magic_link_from_configured_base', () {
      expect(GuestPortalLink.forToken('uuid-1'),
          'http://localhost:3000/?guestId=uuid-1');
    });

    test('test_main_without_guest_portal_define_fails_fast_before_run_app', () {
      expect(app.main, throwsA(isA<AdminConfigException>()));
    });
  });
}
