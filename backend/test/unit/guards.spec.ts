import { ExecutionContext, ForbiddenException, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { GuestTokenGuard } from '../../src/common/guards/guest-token.guard';
import { StepUpVerifiedGuard } from '../../src/common/guards/step-up-verified.guard';
import { AdminAuthGuard } from '../../src/common/guards/admin-auth.guard';
import { RolesGuard } from '../../src/common/guards/roles.guard';
import { SecurityTokenService } from '../../src/common/services/security-token.service';
import { InMemorySeededStayRepository } from '../../src/infrastructure/repositories/in-memory-stay.repository';
import { InMemorySeededStaffRepository } from '../../src/infrastructure/repositories/in-memory-staff.repository';

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
  let stayRepository: InMemorySeededStayRepository;
  let staffRepository: InMemorySeededStaffRepository;
  let securityTokenService: SecurityTokenService;
  let guestTokenGuard: GuestTokenGuard;
  let stepUpGuard: StepUpVerifiedGuard;
  let adminAuthGuard: AdminAuthGuard;

  beforeEach(() => {
    stayRepository = new InMemorySeededStayRepository();
    staffRepository = new InMemorySeededStaffRepository();
    securityTokenService = new SecurityTokenService();
    guestTokenGuard = new GuestTokenGuard(stayRepository);
    stepUpGuard = new StepUpVerifiedGuard(securityTokenService);
    adminAuthGuard = new AdminAuthGuard(staffRepository, securityTokenService);
  });

  describe('GuestTokenGuard', () => {
    it('test_guestTokenGuard_validUuidV4ActiveStay_allowsAccessAndCachesStay', async () => {
      const req: Record<string, unknown> = {
        method: 'GET',
        params: { guestUuid: '550e8400-e29b-41d4-a716-446655440000' },
        headers: {},
      };
      const spy = jest.spyOn(stayRepository, 'findByGuestTokenUuid');
      const ctx = createMockExecutionContext(req);

      const allowedFirst = await guestTokenGuard.canActivate(ctx);
      const allowedSecond = await guestTokenGuard.canActivate(ctx);

      expect(allowedFirst).toBe(true);
      expect(allowedSecond).toBe(true);
      expect(spy).toHaveBeenCalledTimes(1);
      expect((req.stay as { villaName: string }).villaName).toContain('Villa 102');
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
      const stay = await stayRepository.findByGuestTokenUuid('550e8400-e29b-41d4-a716-446655440000');
      expect(stay).not.toBeNull();
      await stayRepository.updateFolioAndStatus(
        stay!.stayId,
        { ...stay!.folioSummary, isCheckedOut: true, checkedOutAt: new Date().toISOString() },
        stay!.folioItems,
        'CHECKED_OUT',
      );
      guestTokenGuard.clearCache();

      const getReq: Record<string, unknown> = {
        method: 'GET',
        params: { guestUuid: '550e8400-e29b-41d4-a716-446655440000' },
        headers: {},
      };
      expect(await guestTokenGuard.canActivate(createMockExecutionContext(getReq))).toBe(true);

      const postReq: Record<string, unknown> = {
        method: 'POST',
        params: { guestUuid: '550e8400-e29b-41d4-a716-446655440000' },
        headers: {},
      };
      await expect(guestTokenGuard.canActivate(createMockExecutionContext(postReq))).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('test_guestTokenGuard_expiredOrCancelledStay_throwsForbiddenException', async () => {
      const stay = await stayRepository.findByGuestTokenUuid('550e8400-e29b-41d4-a716-446655440000');
      await stayRepository.updateFolioAndStatus(
        stay!.stayId,
        stay!.folioSummary,
        stay!.folioItems,
        'EXPIRED',
      );
      guestTokenGuard.clearCache();

      const req: Record<string, unknown> = {
        method: 'GET',
        params: { guestUuid: '550e8400-e29b-41d4-a716-446655440000' },
        headers: {},
      };
      await expect(guestTokenGuard.canActivate(createMockExecutionContext(req))).rejects.toThrow(
        ForbiddenException,
      );
    });
  });

  describe('StepUpVerifiedGuard', () => {
    it('test_stepUpVerifiedGuard_validSignedToken_allowsHighValueMutation', () => {
      const stayId = 'stay_2026_11_villa102_miller';
      const token = securityTokenService.issueStepUpToken(stayId, '550e8400-e29b-41d4-a716-446655440000');
      const req: Record<string, unknown> = {
        stay: { stayId, guestTokenUuid: '550e8400-e29b-41d4-a716-446655440000' },
        headers: { 'x-stepup-session': token },
      };

      expect(stepUpGuard.canActivate(createMockExecutionContext(req))).toBe(true);
    });

    it('test_stepUpVerifiedGuard_missingOrTamperedToken_throwsForbiddenException', () => {
      const req: Record<string, unknown> = {
        stay: { stayId: 'stay_2026_11_villa102_miller', guestTokenUuid: '550e8400-e29b-41d4-a716-446655440000' },
        headers: { 'x-stepup-session': 'tampered.token.signature' },
      };

      expect(() => stepUpGuard.canActivate(createMockExecutionContext(req))).toThrow(ForbiddenException);
    });
  });

  describe('AdminAuthGuard & RolesGuard', () => {
    it('test_adminAuthGuard_rejectsGuestUuidTokenOnAdminRoute', async () => {
      const req: Record<string, unknown> = {
        headers: { authorization: 'Bearer 550e8400-e29b-41d4-a716-446655440000' },
      };

      await expect(adminAuthGuard.canActivate(createMockExecutionContext(req))).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('test_adminAuthGuard_fallsBackToHostAdminForFrictionlessAccess', async () => {
      const noTokenReq: Record<string, unknown> = { headers: {} };
      expect(await adminAuthGuard.canActivate(createMockExecutionContext(noTokenReq))).toBe(true);
      expect((noTokenReq.staff as { fullName: string; rbacRole: string }).fullName).toBe('HOST ADMIN');
      expect((noTokenReq.staff as { fullName: string; rbacRole: string }).rbacRole).toBe('HOST_ADMIN');

      const fallbackTokenReq: Record<string, unknown> = {
        headers: { authorization: 'Bearer host-admin-session' },
      };
      expect(await adminAuthGuard.canActivate(createMockExecutionContext(fallbackTokenReq))).toBe(true);
      expect((fallbackTokenReq.staff as { fullName: string; shortName: string }).shortName).toBe('HOST ADMIN');
    });

    it('test_adminAuthGuardAndRolesGuard_enforcesRbacRoles', async () => {
      const chef = await staffRepository.findByStaffId('staff_mateo');
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
