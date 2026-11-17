import * as crypto from 'crypto';

/**
 * ADR-012: a change announcement. Clients only learn "topic X changed" on their channel and
 * re-fetch through the REST API, so the guest-safe projection (ADR-007) stays the only read path.
 */
export type RealtimeTopic =
  | 'stay'
  | 'messages'
  | 'requests'
  | 'bookings'
  | 'orders'
  | 'trips'
  | 'tasks'
  | 'notifications'
  | 'catalog'
  | 'settings'
  | 'villas'
  | 'staff'
  | 'providers';

/** `stay` reaches admin + that stay's channel; `global` admin + `global`; `admin-only` admin. */
export type RealtimeScope = 'stay' | 'global' | 'admin-only';

export interface RealtimeChange {
  scope: RealtimeScope;
  stayId?: string;
  topic: RealtimeTopic;
}

/** Signal document every guest and staff client may listen to. */
export const GLOBAL_CHANNEL = 'global';

/** Guest-visible resort configuration: announced on the `global` channel. */
export const GLOBAL_TOPICS: ReadonlySet<RealtimeTopic> = new Set<RealtimeTopic>(['catalog', 'settings', 'villas']);

/** What a guest client listens to: its own stay channel and the resort-wide one. */
export interface GuestRealtimeChannels {
  channel: string;
  global: typeof GLOBAL_CHANNEL;
}

export function guestRealtimeChannels(stayChannel: string): GuestRealtimeChannels {
  return { channel: stayChannel, global: GLOBAL_CHANNEL };
}

/** Unguessable per-stay signal document id; rotated with the guest token. */
export function newStayRealtimeChannelId(): string {
  return `s_${crypto.randomUUID()}`;
}
