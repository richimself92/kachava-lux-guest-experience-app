import { BusinessRuleError } from '../../src/domain/domain-errors';
import { StayLifecycleStatus } from '../../src/domain/models/domain.models';
import { Villa } from '../../src/domain/models/resort-config.models';
import {
  assertBookableRange,
  isVillaInService,
  stayBlocksRange,
} from '../../src/domain/stays/villa-availability';
import { villaFixture } from '../support/stay-fixtures';

const RANGE = { checkIn: '2026-12-10', checkOut: '2026-12-14' };

function stay(checkInDate: string, checkOutDate: string, status: StayLifecycleStatus = 'PRE_ARRIVAL') {
  return { checkInDate, checkOutDate, status };
}

describe('stayBlocksRange (villa nights overlap)', () => {
  it.each([
    ['overlap at the start', '2026-12-08', '2026-12-11'],
    ['overlap in the middle', '2026-12-11', '2026-12-12'],
    ['overlap at the end', '2026-12-13', '2026-12-16'],
    ['enclosing stay', '2026-12-01', '2026-12-20'],
    ['identical nights', '2026-12-10', '2026-12-14'],
  ])('test_stayBlocksRange_%s_blocks', (_label, checkIn, checkOut) => {
    expect(stayBlocksRange(stay(checkIn, checkOut), RANGE)).toBe(true);
  });

  it('test_stayBlocksRange_departureOnTheArrivalDay_allowsSameDayTurnover', () => {
    expect(stayBlocksRange(stay('2026-12-07', '2026-12-10'), RANGE)).toBe(false);
  });

  it('test_stayBlocksRange_arrivalOnTheDepartureDay_allowsSameDayTurnover', () => {
    expect(stayBlocksRange(stay('2026-12-14', '2026-12-18'), RANGE)).toBe(false);
  });

  it.each(['CANCELLED', 'CHECKED_OUT', 'EXPIRED'] as StayLifecycleStatus[])(
    'test_stayBlocksRange_%sStay_isIgnored',
    (status) => {
      expect(stayBlocksRange(stay('2026-12-11', '2026-12-12', status), RANGE)).toBe(false);
    },
  );

  it('test_stayBlocksRange_overstayingGuestStillInHouse_blocksUntilCheckedOut', () => {
    // Departure was 2026-12-02 but the guest has not checked out (resort today is 12-05):
    // the villa is still occupied, whatever nights are asked for.
    const overstay = stay('2026-11-28', '2026-12-02', 'ACTIVE_STAY');
    expect(stayBlocksRange(overstay, RANGE, '2026-12-05')).toBe(true);
  });

  it('test_stayBlocksRange_inHouseGuestLeavingToday_allowsSameDayTurnover', () => {
    const leavingToday = stay('2026-12-06', '2026-12-10', 'ACTIVE_STAY');
    expect(stayBlocksRange(leavingToday, RANGE, '2026-12-10')).toBe(false);
  });

  it('test_stayBlocksRange_inHouseStay_blocks', () => {
    expect(stayBlocksRange(stay('2026-12-09', '2026-12-11', 'ACTIVE_STAY'), RANGE)).toBe(true);
  });
});

describe('assertBookableRange', () => {
  it('test_assertBookableRange_checkInToday_isAccepted', () => {
    expect(() => assertBookableRange(RANGE, '2026-12-10')).not.toThrow();
  });

  it('test_assertBookableRange_checkInBeforeToday_isRejected', () => {
    expect(() => assertBookableRange(RANGE, '2026-12-11')).toThrow(new BusinessRuleError('checkIn cannot be in the past'));
  });

  it('test_assertBookableRange_checkOutNotAfterCheckIn_isRejected', () => {
    expect(() => assertBookableRange({ checkIn: '2026-12-10', checkOut: '2026-12-10' }, '2026-12-01'))
      .toThrow(new BusinessRuleError('checkOut must be after checkIn'));
  });
});

describe('isVillaInService', () => {
  const villa = (overrides: Partial<Villa>) => villaFixture(overrides);

  it('test_isVillaInService_activeAvailableVilla_isInService', () => {
    expect(isVillaInService(villa({ operationalStatus: 'OCCUPIED' }))).toBe(true);
  });

  it.each([
    [{ isActive: false }],
    [{ operationalStatus: 'MAINTENANCE' as const }],
    [{ operationalStatus: 'BLOCKED' as const }],
    [{ maintenanceStatus: 'IN_MAINTENANCE' as const }],
  ])('test_isVillaInService_%o_isOutOfService', (overrides) => {
    expect(isVillaInService(villa(overrides))).toBe(false);
  });
});
