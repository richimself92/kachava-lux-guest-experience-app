import { ExecutionContext, ForbiddenException, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { GuestTokenGuard } from '../../src/common/guards/guest-token.guard';
import { StepUpVerifiedGuard } from '../../src/common/guards/step-up-verified.guard';
import { AdminAuthGuard } from '../../src/common/guards/admin-auth.guard';
import {
  FirebaseIdTokenVerifier,
  VerifiedFirebaseIdentity,
} from '../../src/common/services/firebase-id-token.verifier';
import { RolesGuard } from '../../src/common/guards/roles.guard';
import { SecurityTokenService } from '../../src/common/services/security-token.service';
import { buildAdminServiceStaff } from '../../src/common/config/admin-identity';
import { StaffMember } from '../../src/domain/models/domain.models';
import { FirestoreStaffRepository, STAFF_COLLECTION } from '../../src/infrastructure/repositories/firestore-staff.repository';
import { FirestoreStayRepository } from '../../src/infrastructure/repositories/firestore-stay.repository';
import { FakeFirestore } from '../support/fake-firestore';
import { stayFixture, TEST_GUEST_TOKEN } from '../support/stay-fixtures';

const COORDINATOR: StaffMember = {
  staffId: 'staff-coord', firebaseUid: 'uid-coord', fullName: 'Test Coordinator', shortName: 'Coord',
  role: 'Coordinator', department: 'CULINARY', rbacRole: 'DEPARTMENT_COORDINATOR',
  email: 'coord@test.local', phone: '', avatarUrl: '', isActive: true,
};

function createMockExecutionContext(req: Record<string, unknown>, handlerRoles?: string[]): ExecutionContext {
  return {
    switchToHttp: () => ({
      getRequest: () => req,
      getResponse: () => ({}),
      getNext: () => ({}),
    }),
    getHandler: () => (handlerRoles ? { roles: handlerRoles } : {}),
    getClass: () => ({}),
  } as unknown as ExecutionContext;
}

describe('Security & Authentication Guards (TDD Unit Suite)', () => {
  let stayRepository: FirestoreStayRepository;
  let staffRepository: FirestoreStaffRepository;
  let securityTokenService: SecurityTokenService;
  let guestTokenGuard: GuestTokenGuard;
  let stepUpGuard: StepUpVerifiedGuard;
  let adminAuthGuard: AdminAuthGuard;
  let firebaseVerify: jest.Mock<Promise<VerifiedFirebaseIdentity | null>, [string]>;

  beforeEach(async () => {
    const fake = new FakeFirestore();
    stayRepository = new FirestoreStayRepository(fake.asFirestore());
    await stayRepository.createStay(stayFixture());
    fake.store(STAFF_COLLECTION).set(COORDINATOR.staffId, { ...COORDINATOR });
    staffRepository = new FirestoreStaffRepository(fake.asFirestore());
    securityTokenService = new SecurityTokenService();
    guestTokenGuard = new GuestTokenGuard(stayRepository);
    stepUpGuard = new StepUpVerifiedGuard(securityTokenService);
    firebaseVerify = jest.fn().mockResolvedValue(null);
    adminAuthGuard = new AdminAuthGuard(staffRepository, securityTokenService, {
      verify: firebaseVerify,
    } as unknown as FirebaseIdTokenVerifier);
  });

  describe('GuestTokenGuard', () => {
    it('test_guestTokenGuard_validUuidV4ActiveStay_readsStoreOnEveryRequest', async () => {
      const req: Record<string, unknown> = {
        method: 'GET',
        params: { guestUuid: TEST_GUEST_TOKEN },
        headers: {},
      };
      const spy = jest.spyOn(stayRepository, 'findByGuestTokenUuid');
      const ctx = createMockExecutionContext(req);

      const allowedFirst = await guestTokenGuard.canActivate(ctx);
      const allowedSecond = await guestTokenGuard.canActivate(ctx);

      expect(allowedFirst).toBe(true);
      expect(allowedSecond).toBe(true);
      expect(spy).toHaveBeenCalledTimes(2);
      expect((req.stay as { villaName: string }).villaName).toContain('Test Villa');
    });

    it('test_guestTokenGuard_stayChangedAfterFirstRequest_nextRequestSeesFreshStateWithoutCacheClear', async () => {
      const uuid = TEST_GUEST_TOKEN;
      const req = (): Record<string, unknown> => ({ method: 'GET', params: { guestUuid: uuid }, headers: {} });
      await guestTokenGuard.canActivate(createMockExecutionContext(req()));
      const stay = await stayRepository.findByGuestTokenUuid(uuid);
      await stayRepository.updateStayStatus(stay!.stayId, 'CANCELLED');

      await expect(guestTokenGuard.canActivate(createMockExecutionContext(req()))).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('test_guestTokenGuard_tokenRotated_oldTokenRejectedImmediately', async () => {
      const uuid = TEST_GUEST_TOKEN;
      const req = (): Record<string, unknown> => ({ method: 'GET', params: { guestUuid: uuid }, headers: {} });
      await guestTokenGuard.canActivate(createMockExecutionContext(req()));
      const stay = await stayRepository.findByGuestTokenUuid(uuid);
      await stayRepository.updateStayToken(stay!.stayId, '33333333-3333-4333-8333-333333333333');

      await expect(guestTokenGuard.canActivate(createMockExecutionContext(req()))).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('test_guestTokenGuard_retiredDemoAliasUuid_isRejectedAsUnknownToken', async () => {
      const req: Record<string, unknown> = {
        method: 'GET',
        params: { guestUuid: 'f47ac10b-58cc-4372-a567-0e02b2c3d479' },
        headers: {},
      };

      await expect(guestTokenGuard.canActivate(createMockExecutionContext(req))).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('test_guestTokenGuard_storageFailure_propagatesInsteadOfUnauthorized', async () => {
      jest
        .spyOn(stayRepository, 'findByGuestTokenUuid')
        .mockRejectedValue(new Error('UNAVAILABLE: firestore down'));
      const req: Record<string, unknown> = {
        method: 'GET',
        params: { guestUuid: TEST_GUEST_TOKEN },
        headers: {},
      };

      const outcome = guestTokenGuard.canActivate(createMockExecutionContext(req));

      await expect(outcome).rejects.toThrow('UNAVAILABLE: firestore down');
      await expect(outcome).rejects.not.toBeInstanceOf(UnauthorizedException);
    });

    it('test_guestTokenGuard_malformedUuid_throwsUnauthorizedException', async () => {
      const req: Record<string, unknown> = {
        method: 'GET',
        params: { guestUuid: 'not-a-valid-uuid' },
        headers: {},
      };
      const ctx = createMockExecutionContext(req);

      await expect(guestTokenGuard.canActivate(ctx)).rejects.toThrow(UnauthorizedException);
    });

    it('test_guestTokenGuard_checkedOutStay_allowsGetWithinWindowAndRejectsPostWithForbidden', async () => {
      const stay = await stayRepository.findByGuestTokenUuid(TEST_GUEST_TOKEN);
      expect(stay).not.toBeNull();
      await stayRepository.settleFolio(stay!.stayId, {
        settledAt: new Date().toISOString(),
        status: 'CHECKED_OUT',
      });

      const getReq: Record<string, unknown> = {
        method: 'GET',
        params: { guestUuid: TEST_GUEST_TOKEN },
        headers: {},
      };
      expect(await guestTokenGuard.canActivate(createMockExecutionContext(getReq))).toBe(true);

      const postReq: Record<string, unknown> = {
        method: 'POST',
        params: { guestUuid: TEST_GUEST_TOKEN },
        headers: {},
      };
      await expect(guestTokenGuard.canActivate(createMockExecutionContext(postReq))).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('test_guestTokenGuard_expiredOrCancelledStay_throwsForbiddenException', async () => {
      const stay = await stayRepository.findByGuestTokenUuid(TEST_GUEST_TOKEN);
      await stayRepository.updateStayStatus(stay!.stayId, 'EXPIRED');

      const req: Record<string, unknown> = {
        method: 'GET',
        params: { guestUuid: TEST_GUEST_TOKEN },
        headers: {},
      };
      await expect(guestTokenGuard.canActivate(createMockExecutionContext(req))).rejects.toThrow(
        ForbiddenException,
      );
    });
  });

  describe('StepUpVerifiedGuard', () => {
    it('test_stepUpVerifiedGuard_validSignedToken_allowsHighValueMutation', () => {
      const stayId = 'stay-test-1';
      const token = securityTokenService.issueStepUpToken(stayId, TEST_GUEST_TOKEN);
      const req: Record<string, unknown> = {
        stay: { stayId, guestTokenUuid: TEST_GUEST_TOKEN },
        headers: { 'x-stepup-session': token },
      };

      expect(stepUpGuard.canActivate(createMockExecutionContext(req))).toBe(true);
    });

    it('test_stepUpVerifiedGuard_missingOrTamperedToken_throwsForbiddenException', () => {
      const req: Record<string, unknown> = {
        stay: { stayId: 'stay-test-1', guestTokenUuid: TEST_GUEST_TOKEN },
        headers: { 'x-stepup-session': 'tampered.token.signature' },
      };

      expect(() => stepUpGuard.canActivate(createMockExecutionContext(req))).toThrow(ForbiddenException);
    });
  });

  describe('AdminAuthGuard & RolesGuard', () => {
    it('test_adminAuthGuard_rejectsGuestUuidTokenOnAdminRoute', async () => {
      const req: Record<string, unknown> = {
        headers: { authorization: `Bearer ${TEST_GUEST_TOKEN}` },
      };

      await expect(adminAuthGuard.canActivate(createMockExecutionContext(req))).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('test_adminAuthGuard_missingToken_throwsUnauthorizedWithoutStaffFallback', async () => {
      const req: Record<string, unknown> = { headers: {} };

      await expect(adminAuthGuard.canActivate(createMockExecutionContext(req))).rejects.toThrow(
        UnauthorizedException,
      );
      expect(req.staff).toBeUndefined();
    });

    it('test_adminAuthGuard_unknownOrForgedToken_throwsUnauthorizedWithoutStaffFallback', async () => {
      const genuine = securityTokenService.issueStaffToken((await staffRepository.findByStaffId('staff-coord'))!);
      const [payload] = genuine.split('.');
      for (const token of ['host-admin-session', `${payload}.forged-signature`]) {
        const req: Record<string, unknown> = { headers: { authorization: `Bearer ${token}` } };

        await expect(adminAuthGuard.canActivate(createMockExecutionContext(req))).rejects.toThrow(
          UnauthorizedException,
        );
        expect(req.staff).toBeUndefined();
      }
    });

    it('test_adminAuthGuard_firebaseIdTokenOfKnownStaff_resolvesStaffByUid', async () => {
      firebaseVerify.mockResolvedValue({ uid: 'uid-coord' });
      const req: Record<string, unknown> = { headers: { authorization: 'Bearer firebase.id.token' } };

      expect(await adminAuthGuard.canActivate(createMockExecutionContext(req))).toBe(true);
      expect((req.staff as { staffId: string }).staffId).toBe('staff-coord');
      expect(firebaseVerify).toHaveBeenCalledWith('firebase.id.token');
    });

    it('test_adminAuthGuard_firebaseVerificationRejectsToken_throwsUnauthorizedWithoutStaffFallback', async () => {
      firebaseVerify.mockResolvedValue(null);
      const req: Record<string, unknown> = { headers: { authorization: 'Bearer firebase.id.token' } };

      await expect(adminAuthGuard.canActivate(createMockExecutionContext(req))).rejects.toThrow(
        UnauthorizedException,
      );
      expect(req.staff).toBeUndefined();
    });

    it('test_adminAuthGuard_firebaseIdentityNotOnStaffRoster_throwsUnauthorized', async () => {
      firebaseVerify.mockResolvedValue({ uid: 'uid_stranger', email: 'stranger@example.com' });
      const req: Record<string, unknown> = { headers: { authorization: 'Bearer firebase.id.token' } };

      await expect(adminAuthGuard.canActivate(createMockExecutionContext(req))).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('test_adminAuthGuard_firebaseInfrastructureFailure_propagatesInsteadOfUnauthorized', async () => {
      firebaseVerify.mockRejectedValue(new Error('UNAVAILABLE: cannot fetch Google public keys'));
      const req: Record<string, unknown> = { headers: { authorization: 'Bearer firebase.id.token' } };

      const outcome = adminAuthGuard.canActivate(createMockExecutionContext(req));

      await expect(outcome).rejects.toThrow('UNAVAILABLE: cannot fetch Google public keys');
      await expect(outcome).rejects.not.toBeInstanceOf(UnauthorizedException);
    });

    it('test_adminAuthGuard_envAdminToken_resolvesHostAdminWithoutStaffDocument', async () => {
      process.env.ADMIN_SERVICE_EMAIL = 'ops@test.local';
      const token = securityTokenService.issueStaffToken(buildAdminServiceStaff('ops@test.local'));
      const req: Record<string, unknown> = { headers: { authorization: `Bearer ${token}` } };

      expect(await adminAuthGuard.canActivate(createMockExecutionContext(req))).toBe(true);
      expect(req.staff).toMatchObject({ staffId: 'admin-service', rbacRole: 'HOST_ADMIN', email: 'ops@test.local' });
    });

    it('test_adminAuthGuard_envAdminTokenAfterEmailChange_isRejected', async () => {
      process.env.ADMIN_SERVICE_EMAIL = 'ops@test.local';
      const token = securityTokenService.issueStaffToken(buildAdminServiceStaff('ops@test.local'));
      process.env.ADMIN_SERVICE_EMAIL = 'other@test.local';
      const req: Record<string, unknown> = { headers: { authorization: `Bearer ${token}` } };

      await expect(adminAuthGuard.canActivate(createMockExecutionContext(req))).rejects.toThrow(UnauthorizedException);
      delete process.env.ADMIN_SERVICE_EMAIL;
    });

    it('test_adminAuthGuardAndRolesGuard_enforcesRbacRoles', async () => {
      const chef = await staffRepository.findByStaffId('staff-coord');
      expect(chef).not.toBeNull();
      const staffJwt = securityTokenService.issueStaffToken(chef!);
      const req: Record<string, unknown> = {
        headers: { authorization: `Bearer ${staffJwt}` },
      };

      expect(await adminAuthGuard.canActivate(createMockExecutionContext(req))).toBe(true);

      const reflector = {
        getAllAndOverride: jest.fn().mockReturnValue(['HOST_ADMIN']),
      } as unknown as Reflector;
      const rolesGuard = new RolesGuard(reflector);

      expect(() => rolesGuard.canActivate(createMockExecutionContext(req))).toThrow(ForbiddenException);
    });
  });
});
