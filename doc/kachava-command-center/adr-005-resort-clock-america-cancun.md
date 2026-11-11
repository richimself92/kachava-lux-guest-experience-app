# ADR-005: Resort Clock (America/Cancun) and ISO Stay Dates

- **Status**: Accepted
- **Date**: 2026-11-02

## Context
Stay dates were free-form strings with fake defaults (`admin.service.ts`, `stays_dialogs.dart`).
Dashboard statuses (Arrival, Departure, In-house, overstay) and KPIs depend on "today" at the resort,
not on the server (UTC on Cloud Run) or the browser time zone.

## Decision
- Stay `checkInDate` / `checkOutDate` are `YYYY-MM-DD` strings, validated on input; no default dates.
- "Today" comes from a `ResortClockPort` (`today(): string`, `now(): Date`) whose production adapter uses
  the IANA zone `America/Cancun` (UTC-5, no DST). Tests inject a fixed clock.
- Resort check-in / check-out hours live in admin-editable resort settings, not in code.
- Derivations (`deriveActivityStatus`, `computeDashboardKpis`) are pure functions taking the clock's date.
- Existing documents are normalised by a migration script that supports `--dry-run` and is only run
  against production with explicit owner approval.

## Consequences
- Positive: deterministic, testable status logic; the dashboard date matches the front desk.
- Negative: a one-off migration of legacy date strings is required.

## Verification
- Unit tests at day boundaries (23:59 / 00:00 America/Cancun) and invalid date rejection.
