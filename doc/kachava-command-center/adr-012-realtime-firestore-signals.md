# ADR-012 — Real-time updates via Firestore signal documents

Status: accepted (2026-11-03). Supersedes the first draft (SSE), rejected for cost.

## Context
Admin polled every 15 s and the guest portal every 30 s: chat and status changes took up to
45 s to show on the other side. The owner requires every change to appear on both sides at once,
**and** Cloud Run must scale to zero to save cost. Both polling and SSE keep instances busy
(an open SSE stream is a billed in-flight request), so neither is acceptable.
All data reads/writes stay brokered by the NestJS backend (ADR-007/008).

## Decision
- On every successful mutating request, a backend interceptor updates tiny **signal documents**
  in Firestore collection `realtime_signals` (`{at, topic, seq}`, no business data), in one batch:
  - admin channel `REALTIME_ADMIN_CHANNEL` (secret id, returned by the silent admin login as
    `data.realtime.adminChannel`) — every change;
  - per-stay channel `realtimeChannelId` (random, rotated with the guest token, returned in the
    guest stay view as `realtime.channel`) — changes affecting that stay;
  - `global` — catalog/settings/villas changes.
- Clients listen to their signal docs with the Firestore web SDK (`snapshots()`); on change they
  debounce 250 ms and re-fetch on-screen data through the REST API.
- **No periodic polling.** Clients refresh on load, on signal, after their own writes, when the tab
  becomes visible again, and from a manual **Refresh** button (admin top bar, guest app bar).
- `firestore.rules`: deny-all except `realtime_signals/{id}`: `allow get: if true` (no list, no write).
  Channel ids are unguessable; a signal only reveals "something changed at time T".

## Consequences
- Instant updates; Cloud Run runs only while handling real requests and scales to zero.
- Cost: one Firestore write per change per channel + one read per listening tab per change.
- Clients bundle the Firebase JS SDK (Firestore only, no Auth). App Check (phase 11) can later
  restrict signal reads to the real apps.
- Deploy needs owner approval: new `firestore.rules`, env `REALTIME_ADMIN_CHANNEL`, Firebase web
  config in both apps' build configs, optional TTL not needed (docs are updated in place).
