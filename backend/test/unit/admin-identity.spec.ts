import {
  ADMIN_SERVICE_STAFF_ID,
  assertAdminIdentityConfigured,
  buildAdminServiceStaff,
  resolveAdminServiceEmail,
} from '../../src/common/config/admin-identity';

describe('admin identity from the environment', () => {
  it('test_resolveAdminServiceEmail_normalizesCase', () => {
    expect(resolveAdminServiceEmail({ ADMIN_SERVICE_EMAIL: ' Ops@Example.COM ' })).toBe('ops@example.com');
  });

  it('test_resolveAdminServiceEmail_missing_returnsNull', () => {
    expect(resolveAdminServiceEmail({})).toBeNull();
    expect(resolveAdminServiceEmail({ ADMIN_SERVICE_EMAIL: '  ' })).toBeNull();
  });

  it('test_assertAdminIdentityConfigured_productionWithoutEmail_failsClosed', () => {
    expect(() => assertAdminIdentityConfigured({ NODE_ENV: 'production' })).toThrow(/ADMIN_SERVICE_EMAIL/);
  });

  it('test_assertAdminIdentityConfigured_productionWithInvalidEmail_failsClosed', () => {
    expect(() =>
      assertAdminIdentityConfigured({ NODE_ENV: 'production', ADMIN_SERVICE_EMAIL: 'not-an-email' }),
    ).toThrow(/ADMIN_SERVICE_EMAIL/);
  });

  it('test_assertAdminIdentityConfigured_productionWithEmail_passes', () => {
    expect(() =>
      assertAdminIdentityConfigured({ NODE_ENV: 'production', ADMIN_SERVICE_EMAIL: 'ops@example.com' }),
    ).not.toThrow();
  });

  it('test_buildAdminServiceStaff_isActiveHostAdmin_withoutDatabase', () => {
    const staff = buildAdminServiceStaff('ops@example.com');

    expect(staff).toMatchObject({
      staffId: ADMIN_SERVICE_STAFF_ID,
      email: 'ops@example.com',
      rbacRole: 'HOST_ADMIN',
      isActive: true,
    });
  });
});
