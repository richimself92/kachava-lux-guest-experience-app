import { BusinessRuleError, SettingsRequiredError } from '../domain-errors';

/**
 * Time-zone arithmetic on the IANA zone configured in Settings (`timeZone`), with no library and
 * no code default: callers pass the configured zone, and a missing zone is SETTINGS_REQUIRED.
 * Instants are stored as UTC ISO strings (`toISOString()`), so they compare lexicographically.
 */
const LOCAL_DATE_TIME = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?::(\d{2}))?$/;
const OFFSET_DATE_TIME = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2}(\.\d{1,3})?)?(Z|[+-]\d{2}:\d{2})$/;
const MS_PER_MINUTE = 60_000;
const TIME_ZONE_SETTING = 'timeZone';

/** API date-time input: an instant with offset (`...Z`, `...-05:00`) or a resort wall time. */
export const DATE_TIME_INPUT_PATTERN =
  /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2}(\.\d{1,3})?)?(Z|[+-]\d{2}:\d{2})?$/;

interface WallTime {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
  second: number;
}

function parseWallTime(local: string): WallTime {
  const match = LOCAL_DATE_TIME.exec(local);
  if (!match) throw new BusinessRuleError(`${local} is not a valid local date-time (YYYY-MM-DDTHH:mm)`);
  const [year, month, day, hour, minute, second] = match.slice(1).map((part) => Number(part ?? 0));
  const probe = new Date(Date.UTC(year, month - 1, day, hour, minute, second));
  const valid = probe.getUTCMonth() === month - 1 && probe.getUTCDate() === day && hour < 24 && minute < 60;
  if (!valid) throw new BusinessRuleError(`${local} is not a valid local date-time`);
  return { year, month, day, hour, minute, second };
}

/** Minutes the zone is ahead of UTC at `utcMs` (negative west of Greenwich). */
function zoneOffsetMinutes(utcMs: number, timeZone: string): number {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone,
    hourCycle: 'h23',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  }).formatToParts(new Date(utcMs));
  const part = (type: Intl.DateTimeFormatPartTypes) => Number(parts.find((p) => p.type === type)?.value);
  const asUtc = Date.UTC(part('year'), part('month') - 1, part('day'), part('hour'), part('minute'), part('second'));
  return Math.round((asUtc - Math.floor(utcMs / 1000) * 1000) / MS_PER_MINUTE);
}

/** The instant at which the resort clock in `timeZone` shows `local` (YYYY-MM-DDTHH:mm[:ss]). */
export function zonedLocalToUtc(local: string, timeZone: string): Date {
  const w = parseWallTime(local);
  const naive = Date.UTC(w.year, w.month - 1, w.day, w.hour, w.minute, w.second);
  const firstGuess = naive - zoneOffsetMinutes(naive, timeZone) * MS_PER_MINUTE;
  // Second pass corrects the guess when the offset differs across a DST change.
  return new Date(naive - zoneOffsetMinutes(firstGuess, timeZone) * MS_PER_MINUTE);
}

/** Normalises API input to a UTC ISO instant; wall times need the configured resort zone. */
export function toInstantIso(value: string, timeZone: string | null): string {
  if (OFFSET_DATE_TIME.test(value)) {
    const instant = new Date(value);
    if (Number.isNaN(instant.getTime())) throw new BusinessRuleError(`${value} is not a valid date-time`);
    return instant.toISOString();
  }
  if (!LOCAL_DATE_TIME.test(value)) throw new BusinessRuleError(`${value} is not a valid date-time`);
  if (!timeZone) throw new SettingsRequiredError([TIME_ZONE_SETTING]);
  return zonedLocalToUtc(value, timeZone).toISOString();
}

function nextDay(isoDate: string): string {
  const [year, month, day] = isoDate.split('-').map(Number);
  return new Date(Date.UTC(year, month - 1, day + 1)).toISOString().slice(0, 10);
}

export interface DayRange {
  from?: string;
  to?: string;
}

export interface InstantWindow {
  fromIso?: string;
  toIsoExclusive?: string;
}

/** Inclusive resort calendar days (YYYY-MM-DD) as the half-open instant window they cover. */
export function zonedDayWindow(range: DayRange, timeZone: string | null): InstantWindow {
  if (!range.from && !range.to) return {};
  if (!timeZone) throw new SettingsRequiredError([TIME_ZONE_SETTING]);
  if (range.from && range.to && range.from > range.to) {
    throw new BusinessRuleError('from must not be after to');
  }
  const startOf = (date: string) => zonedLocalToUtc(`${date}T00:00`, timeZone).toISOString();
  return {
    ...(range.from ? { fromIso: startOf(range.from) } : {}),
    ...(range.to ? { toIsoExclusive: startOf(nextDay(range.to)) } : {}),
  };
}
