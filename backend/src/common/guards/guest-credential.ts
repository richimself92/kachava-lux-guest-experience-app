type HeaderValue = string | string[] | undefined;

export interface CredentialRequest {
  params?: Record<string, string | undefined>;
  headers?: Record<string, HeaderValue>;
}

export const UUID_V4_REGEX =
  /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function firstHeader(value: HeaderValue): string {
  return (Array.isArray(value) ? value[0] : value)?.trim() ?? '';
}

export function bearerToken(req: CredentialRequest): string {
  const authorization = firstHeader(req.headers?.authorization);
  return authorization.startsWith('Bearer ') ? authorization.slice(7).trim() : '';
}

/**
 * The guest credential a request presents, in the order the guard authenticates it:
 * `Authorization: Bearer`, then `X-Guest-Token`, then the `:guestUuid` route segment.
 * The throttle tracker keys by this same value, so the budget always belongs to the token
 * that is actually authenticated.
 */
export function presentedGuestToken(req: CredentialRequest): string {
  return (
    bearerToken(req) ||
    firstHeader(req.headers?.['x-guest-token']) ||
    req.params?.guestUuid?.trim() ||
    ''
  );
}

/** A header token may only accompany the same `:guestUuid` (case-insensitive). */
export function routeTokenMismatch(req: CredentialRequest): boolean {
  const routeToken = req.params?.guestUuid?.trim();
  if (!routeToken) return false;
  return presentedGuestToken(req).toLowerCase() !== routeToken.toLowerCase();
}
