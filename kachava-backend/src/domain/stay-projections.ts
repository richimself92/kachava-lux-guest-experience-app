import { MidStayFeedback, StayAggregate } from './models/domain.models';

/** Pure read projection: the mid-stay feedback of every given stay, deep-copied. */
export function collectMidStayFeedback(stays: StayAggregate[]): MidStayFeedback[] {
  return structuredClone(stays.flatMap((s) => s.midstayFeedback));
}
