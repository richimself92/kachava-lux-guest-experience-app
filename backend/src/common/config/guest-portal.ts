/** Base URL of the guest portal used in magic links (deployment configuration). */
export function guestPortalBaseUrl(): string {
  return (process.env.GUEST_PORTAL_URL || 'http://localhost:3000').replace(/\/$/, '');
}

/** Prefix a guest token is appended to in order to form the magic link. */
export function magicLinkBase(): string {
  return `${guestPortalBaseUrl()}/?guestId=`;
}
