import { SettingsRequiredError } from '../../src/domain/domain-errors';
import { resortDate } from '../../src/domain/time/zoned-time';

describe('resortDate (the resort calendar day of an instant)', () => {
  it('test_lateEveningUtc_isStillTheSameDayAtTheResort', () => {
    expect(resortDate(new Date('2026-12-11T03:00:00.000Z'), 'America/Cancun')).toBe('2026-12-10');
    expect(resortDate(new Date('2026-12-11T05:00:00.000Z'), 'America/Cancun')).toBe('2026-12-11');
  });

  it('test_missingTimeZone_isSettingsRequired', () => {
    expect(() => resortDate(new Date(), null)).toThrow(SettingsRequiredError);
  });
});
