import { ClockPort } from '../../domain/ports/clock.port';

export class SystemClock implements ClockPort {
  now(): Date {
    return new Date();
  }
}
