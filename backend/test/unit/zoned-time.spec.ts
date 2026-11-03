import { BusinessRuleError, SettingsRequiredError } from '../../src/domain/domain-errors';
import { toInstantIso, zonedDayWindow, zonedLocalToUtc } from '../../src/domain/time/zoned-time';

describe('zonedLocalToUtc (resort wall time -> instant)', () => {
  it('test_cancunWallTime_isUtcMinusFive', () => {
    expect(zonedLocalToUtc('2026-12-01T14:30', 'America/Cancun').toISOString()).toBe('2026-12-01T19:30:00.000Z');
  });

  it('test_dstZone_usesTheOffsetOfThatDate', () => {
    expect(zonedLocalToUtc('2026-07-01T09:00', 'America/New_York').toISOString()).toBe('2026-07-01T13:00:00.000Z');
    expect(zonedLocalToUtc('2026-12-01T09:00:30', 'America/New_York').toISOString()).toBe('2026-12-01T14:00:30.000Z');
  });

  it('test_midnightAcrossUtcDayBoundary', () => {
    expect(zonedLocalToUtc('2026-12-31T23:59', 'America/Cancun').toISOString()).toBe('2027-01-01T04:59:00.000Z');
  });

  it.each(['2026-02-30T10:00', '2026-13-01T10:00', 'tomorrow'])('test_invalidLocalDateTime_%s_isRejected', (value) => {
    expect(() => zonedLocalToUtc(value, 'America/Cancun')).toThrow(BusinessRuleError);
  });
});

describe('toInstantIso (API date-time input -> stored UTC ISO)', () => {
  it('test_explicitOffset_needsNoTimeZone', () => {
    expect(toInstantIso('2026-12-01T14:30:00-05:00', null)).toBe('2026-12-01T19:30:00.000Z');
    expect(toInstantIso('2026-12-01T19:30Z', null)).toBe('2026-12-01T19:30:00.000Z');
  });

  it('test_localWallTime_isReadInTheResortTimeZone', () => {
    expect(toInstantIso('2026-12-01T14:30', 'America/Cancun')).toBe('2026-12-01T19:30:00.000Z');
  });

  it('test_localWallTime_withoutTimeZone_requiresSettings', () => {
    expect(() => toInstantIso('2026-12-01T14:30', null)).toThrow(SettingsRequiredError);
    expect(() => toInstantIso('2026-12-01T14:30', null)).toThrow(/timeZone/);
  });

  it('test_garbage_isRejected', () => {
    expect(() => toInstantIso('2026-12-01 14:30', 'America/Cancun')).toThrow(BusinessRuleError);
  });
});

describe('zonedDayWindow (inclusive resort calendar days -> [from, toExclusive) instants)', () => {
  it('test_fromAndTo_coverWholeResortDays', () => {
    expect(zonedDayWindow({ from: '2026-12-01', to: '2026-12-02' }, 'America/Cancun')).toEqual({
      fromIso: '2026-12-01T05:00:00.000Z',
      toIsoExclusive: '2026-12-03T05:00:00.000Z',
    });
  });

  it('test_openEndedWindows', () => {
    expect(zonedDayWindow({ from: '2026-12-31' }, 'America/Cancun')).toEqual({ fromIso: '2026-12-31T05:00:00.000Z' });
    expect(zonedDayWindow({ to: '2026-12-31' }, 'America/Cancun')).toEqual({ toIsoExclusive: '2027-01-01T05:00:00.000Z' });
  });

  it('test_noDates_isNoWindowAndNeedsNoTimeZone', () => {
    expect(zonedDayWindow({}, null)).toEqual({});
  });

  it('test_dates_withoutTimeZone_requireSettings', () => {
    expect(() => zonedDayWindow({ from: '2026-12-01' }, null)).toThrow(SettingsRequiredError);
  });

  it('test_fromAfterTo_isRejected', () => {
    expect(() => zonedDayWindow({ from: '2026-12-05', to: '2026-12-01' }, 'America/Cancun')).toThrow(BusinessRuleError);
  });
});
