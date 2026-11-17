export const CLOCK_PORT = Symbol('CLOCK_PORT');

/** "Now" for business rules (lead times, due flags); tests inject a fixed clock. */
export interface ClockPort {
  now(): Date;
}
