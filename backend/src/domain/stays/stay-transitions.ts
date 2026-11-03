import { BusinessRuleError } from '../domain-errors';
import { StayAggregate, StayLifecycleStatus } from '../models/domain.models';
import { isOpenStay } from './open-requests';

export const STAY_ACTIONS = ['CHECK_IN', 'CHECK_OUT', 'CANCEL'] as const;
export type StayAction = (typeof STAY_ACTIONS)[number];

const MOVES: Record<StayAction, { from: StayLifecycleStatus; to: StayLifecycleStatus }> = {
  CHECK_IN: { from: 'PRE_ARRIVAL', to: 'ACTIVE_STAY' },
  CHECK_OUT: { from: 'ACTIVE_STAY', to: 'CHECKED_OUT' },
  CANCEL: { from: 'PRE_ARRIVAL', to: 'CANCELLED' },
};

export interface StayTransitionCommand {
  action: StayAction;
  reason?: string;
}

export interface StayAdminPatch {
  resortHostName?: string;
  resortHostStaffId?: string;
  internalNotes?: string;
  language?: string | null;
  wifi?: { ssid?: string; password?: string };
}

/**
 * Staff status moves: check-in (pre-arrival → in-house), check-out (in-house → checked out) and
 * cancel (pre-arrival → cancelled, reason required). Returns a new stay; never mutates `stay`.
 */
export function transitionStay(
  stay: StayAggregate,
  command: StayTransitionCommand,
  actor: string,
  at: string,
): StayAggregate {
  const move = MOVES[command.action];
  if (stay.status !== move.from) {
    throw new BusinessRuleError(`Cannot ${command.action} a stay that is ${stay.status}`);
  }
  const reason = command.reason?.trim() ?? '';
  if (command.action === 'CANCEL' && !reason) {
    throw new BusinessRuleError('Cannot cancel the stay', ['reason is required']);
  }
  const next = structuredClone(stay);
  next.status = move.to;
  next.updatedAt = at;
  if (command.action === 'CANCEL') next.cancellationReason = reason;
  next.statusHistory = [
    ...(stay.statusHistory ?? []),
    { from: stay.status, to: move.to, at, by: actor, reason: command.action === 'CANCEL' ? reason : null },
  ];
  return next;
}

/** Resort Host, internal notes, guest language and the stay's Wi-Fi override (open stays only). */
export function applyStayAdminPatch(stay: StayAggregate, patch: StayAdminPatch, at: string): StayAggregate {
  if (!isOpenStay(stay)) throw new BusinessRuleError(`Stay is ${stay.status}; it can no longer be edited`);
  const next = structuredClone(stay);
  if (patch.resortHostName !== undefined || patch.resortHostStaffId !== undefined) {
    const name = patch.resortHostName?.trim() ?? next.hostInfo.name;
    next.hostInfo = {
      ...next.hostInfo,
      name,
      shortName: name,
      staffId: patch.resortHostStaffId?.trim() ?? next.hostInfo.staffId,
    };
  }
  if (patch.internalNotes !== undefined) next.internalNotes = patch.internalNotes.trim();
  if (patch.language !== undefined) next.guestProfile = { ...next.guestProfile, language: patch.language?.trim() || null };
  if (patch.wifi) {
    next.villaAccess = {
      ...next.villaAccess,
      wifiSsid: patch.wifi.ssid?.trim() || next.villaAccess.wifiSsid,
      wifiPasscode: patch.wifi.password?.trim() || next.villaAccess.wifiPasscode,
    };
  }
  next.updatedAt = at;
  return next;
}
