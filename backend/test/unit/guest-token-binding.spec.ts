import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { GuestTokenGuard } from '../../src/common/guards/guest-token.guard';
import { resolveThrottleTracker } from '../../src/common/throttling/throttle-tracker';
import { FirestoreStayRepository } from '../../src/infrastructure/repositories/firestore-stay.repository';
import { FakeFirestore } from '../support/fake-firestore';
import { stayFixture, TEST_GUEST_TOKEN as DEFAULT_DEMO_GUEST_UUID } from '../support/stay-fixtures';

const OTHER_UUID = '6f1c1c55-1b1f-4c1e-9f4a-0a0b0c0d0e0f';

function contextFor(req: Record<string, unknown>): ExecutionContext {
  return { switchToHttp: () => ({ getRequest: () => req }) } as unknown as ExecutionContext;
}

describe('Guest token binding between guard and throttle tracker (ADV-03)', () => {
  const repo = new FirestoreStayRepository(new FakeFirestore().asFirestore());
  const guard = new GuestTokenGuard(repo);

  beforeAll(() => repo.createStay(stayFixture()));

  it('test_guestTokenGuard_headerTokenDiffersFromRouteToken_throwsUnauthorized', async () => {
    const req = { method: 'GET', params: { guestUuid: OTHER_UUID }, headers: { 'x-guest-token': DEFAULT_DEMO_GUEST_UUID } };

    await expect(guard.canActivate(contextFor(req))).rejects.toThrow(UnauthorizedException);
  });

  it('test_guestTokenGuard_bearerDiffersFromRouteToken_throwsUnauthorized', async () => {
    const req = { method: 'GET', params: { guestUuid: OTHER_UUID }, headers: { authorization: `Bearer ${DEFAULT_DEMO_GUEST_UUID}` } };

    await expect(guard.canActivate(contextFor(req))).rejects.toThrow(UnauthorizedException);
  });

  it('test_guestTokenGuard_headerMatchesRouteIgnoringCase_isAllowed', async () => {
    const req = {
      method: 'GET',
      params: { guestUuid: DEFAULT_DEMO_GUEST_UUID },
      headers: { 'x-guest-token': DEFAULT_DEMO_GUEST_UUID.toUpperCase() },
    };

    await expect(guard.canActivate(contextFor(req))).resolves.toBe(true);
  });

  it('test_resolveThrottleTracker_keysByTheTokenTheGuardAuthenticates', () => {
    const rotatedRoute = { params: { guestUuid: OTHER_UUID }, headers: { 'x-guest-token': DEFAULT_DEMO_GUEST_UUID }, ip: '1.1.1.1' };
    const guestBearer = { params: {}, headers: { authorization: `Bearer ${DEFAULT_DEMO_GUEST_UUID.toUpperCase()}` }, ip: '1.1.1.1' };

    expect(resolveThrottleTracker(rotatedRoute)).toBe(`guest:${DEFAULT_DEMO_GUEST_UUID}`);
    expect(resolveThrottleTracker(guestBearer)).toBe(`guest:${DEFAULT_DEMO_GUEST_UUID}`);
  });
});
