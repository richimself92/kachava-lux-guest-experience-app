# ADR-008: Firestore as the Single Source of Truth for Stays

- **Status**: Accepted
- **Date**: 2026-11-02
- **Supersedes**: the startup-hydration part of [ADR-003](../adr/003-gcp-low-cost-cloudbuild-cloudrun-hosting.md) (`ensureHydrated()` in-memory working set)

## Context
Guest magic links intermittently failed or showed another guest's data in production.
Root causes found in `backend/`:
- Each Cloud Run instance (up to 2) loaded Firestore once and then served from process memory, so a stay
  created on instance A did not exist on instance B.
- Writes were fire-and-forget (`void work().catch(() => {})`) under CPU throttling, and a bulk
  `persistAllStays` could overwrite newer documents with stale memory.
- The guest token guard cached lookups for 60 s, and the per-IP throttler (120 req/min) was exhausted by
  normal polling behind the Cloud Run proxy.

## Decision
1. Every request reads Firestore directly; stays are found by `guestTokenUuid` with a `where` query.
2. Every write is awaited; failures propagate as 5xx, never as success.
3. Only the changed document (or subcollection document) is written; no whole-aggregate rewrites.
4. No cross-request caches in guards; lookups are request-scoped.
5. Admin "reset" operates on the store, is HOST_ADMIN-only, and is disabled (403) in production/Firestore mode.
6. The in-memory repository is a separate adapter selected only when `USE_FIRESTORE != true`
   (unit tests, local E2E). It is never a cache in front of Firestore and production never seeds demo data.
7. Storage shape: one `stays/{stayId}` document with embedded lists (the shape production already holds),
   updated inside a Firestore transaction to prevent lost updates. Legacy subcollection data is not read.
   Alerts and catalog repositories also read/write Firestore per request (no per-instance copies).
8. Express `trust proxy` is enabled and throttling is keyed by guest token / admin token, falling back to IP.
   Clients poll less: guest every 10 s, admin one `GET /admin/sync` every 5 s, never overlapping.

## Consequences
- Positive: consistent reads across instances; no lost writes; errors are visible.
- Negative: more Firestore reads per request (acceptable at boutique scale, < 50 concurrent users).
- Local development must use the in-memory adapter or the Firestore emulator. `run-local.sh` defaults to
  in-memory and requires an explicit opt-in for any non-emulator Firestore.
- Interim mitigation `maxScale=1` on Cloud Run is optional and requires owner approval.

## Verification
- Jest: two repository instances over one fake Firestore see each other's writes; a failing write raises;
  the guard has no stale cache; throttling is per token.
