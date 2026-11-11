# ADR-006: Operational Tasks as a First-Class Entity

- **Status**: Accepted
- **Date**: 2026-11-02

## Context
The functional spec (`doc/improvements/spec.md`) requires every request that needs execution to become an
operational task with villa, guest, category, owner, priority, due date, state and completion confirmation.
Today the status of a request is the only tracking unit, so one request cannot fan out to several jobs
(e.g. a transfer needs a provider booking and a welcome setup).

## Decision
- New Firestore collection `tasks`. A task references its origin (`sourceType`: REQUEST | TRIP | MANUAL,
  `sourceId`, `stayId`, `villaId`). One source may generate many tasks.
- States: `PENDING -> ASSIGNED -> IN_PROGRESS -> COMPLETED` (plus `CANCELLED`). Transitions are validated by
  a pure function `transitionTask(task, action, actor, now)`; illegal transitions raise.
- `overdue` is derived when reading (`dueAt < now && state != COMPLETED`), never stored.
- Completion stores who confirmed and when.
- Notifications reference tasks through `targetRef` so "Open record" navigates to them.

## Consequences
- Positive: request status (guest-facing) and execution (staff-facing) evolve independently.
- Negative: one more collection and endpoints; request and task states must be kept coherent by services.

## Verification
- Unit tests of `transitionTask` covering every legal and illegal transition and overdue derivation.
