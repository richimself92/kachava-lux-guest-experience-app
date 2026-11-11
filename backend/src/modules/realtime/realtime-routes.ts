import { GLOBAL_TOPICS, RealtimeChange, RealtimeTopic } from '../../domain/realtime/realtime-signal';

/** `null` = the route mutates nothing another screen shows (auth, upload signing). */
type RouteRule = readonly [pattern: RegExp, topic: RealtimeTopic | null];

const API_PREFIX = /^\/?api\/v1\//;
const GUEST_PREFIX = /^stays\/:guestUuid(\/|$)/;
const ADMIN_PREFIX = /^admin\//;

/** Matched against the route template after `stays/:guestUuid/`; first match wins. */
const GUEST_RULES: readonly RouteRule[] = [
  [/^concierge-requests\/upload-url$/, null],
  [/^concierge-requests\/:requestId\/messages$/, 'messages'],
  [/^concierge-requests\b/, 'requests'],
  [/^bookings\b/, 'bookings'],
  [/^orders\b/, 'orders'],
  [/^trips\b/, 'trips'],
  [/^/, 'stay'],
];

/** Matched against the route template after `admin/`; first match wins. */
const ADMIN_RULES: readonly RouteRule[] = [
  [/^(auth|uploads)\//, null],
  [/^conversations\//, 'messages'],
  [/^notifications\b/, 'notifications'],
  [/^requests\b/, 'requests'],
  [/^tasks\b/, 'tasks'],
  [/^trips\b/, 'trips'],
  [/^stays\b/, 'stay'],
  [/^services\b/, 'catalog'],
  [/^settings\b/, 'settings'],
  [/^villas\b/, 'villas'],
  [/^staff\b/, 'staff'],
  [/^transport-providers\b/, 'providers'],
];

function firstMatch(rules: readonly RouteRule[], path: string): RealtimeTopic | null | undefined {
  const rule = rules.find(([pattern]) => pattern.test(path));
  return rule ? rule[1] : undefined;
}

/**
 * Topic of a mutating route template (e.g. `/api/v1/admin/tasks/:taskId`): a topic, `null` for
 * deliberately silent routes, `undefined` when no rule covers the route.
 */
export function routeTopic(routePath: string): RealtimeTopic | null | undefined {
  const path = routePath.replace(API_PREFIX, '');
  if (GUEST_PREFIX.test(path)) return firstMatch(GUEST_RULES, path.replace(GUEST_PREFIX, ''));
  if (ADMIN_PREFIX.test(path)) return firstMatch(ADMIN_RULES, path.replace(ADMIN_PREFIX, ''));
  return undefined;
}

export interface MutationContext {
  routePath: string;
  params: Record<string, string | undefined>;
  /** The stay authenticated by the guest token guard (guest routes only). */
  guestStayId?: string;
  responseData: unknown;
}

function stringField(value: unknown, key: string): string | undefined {
  if (value === null || typeof value !== 'object') return undefined;
  const field = (value as Record<string, unknown>)[key];
  return typeof field === 'string' && field ? field : undefined;
}

/** The guest's own stay, else `:stayId`, else `stayId` (or `stay.stayId`) of the response. */
function resolveStayId(ctx: MutationContext): string | undefined {
  const nestedStay = (ctx.responseData as { stay?: unknown } | null)?.stay;
  return (
    ctx.guestStayId ||
    ctx.params.stayId ||
    stringField(ctx.responseData, 'stayId') ||
    stringField(nestedStay, 'stayId')
  );
}

/** The change a successful mutating request announces, or `null` when it announces nothing. */
export function changeForMutation(ctx: MutationContext): RealtimeChange | null {
  const topic = routeTopic(ctx.routePath);
  if (!topic) return null;
  if (GLOBAL_TOPICS.has(topic)) return { scope: 'global', topic };
  const stayId = resolveStayId(ctx);
  return stayId ? { scope: 'stay', stayId, topic } : { scope: 'admin-only', topic };
}
