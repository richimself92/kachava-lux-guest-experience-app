# Test Matrix: Command Center final verification (Phase 10)

## 1. Execution Summary
- Runner Command: `cd e2e && E2E_API_BASE_URL=http://localhost:3011/api/v1 E2E_ADMIN_EMAIL=admin@kachava.local npx playwright test --config <headless>` (backend :3011, admin :3002, portal :3000, emulators 8085/9199, fresh release builds).
- Results: Playwright 25 passed / 0 failed (8.7 min); admin `flutter test` 298; web `flutter test` 129; backend `npm test` 701 (53 suites); all `dart analyze` and `npm run typecheck` clean.
- Exit Code: 0 for Playwright (final full run), admin/web analyze+test, backend typecheck+test.
- Date: 2026-11-03. Legacy `admin-dashboard.e2e.spec.ts` (old Command Center screens) deleted; `guest-explore.e2e.spec.ts` added.

## 2. Test Case Matrix
| ID | Ref | Level | Objective | Steps | Expected Result | Automated Test | Status |
|---|---|---|---|---|---|---|---|
| TC-01 | P3 | E2E | Settings and Villas CRUD, search, filter, pages | 1. Save Settings. 2. Create/edit/deactivate villas. 3. Bulk 30, search, page, reload | 25 per page, data persists, no 4xx | `e2e/tests/admin-villas-settings.e2e.spec.ts::E2E-P3-01` | PASS |
| TC-02 | P3 mobile | E2E | Villas, detail sheet, Settings at 375 | 1. Menu, Villas. 2. Search the run. 3. Open row, Settings | Full-screen sheet, no overflow | `admin-villas-settings.e2e.spec.ts::E2E-P3-02` | PASS |
| TC-03 | P4 | E2E | One service per kind, cover upload, items, activation | 1. New service per kind. 2. Activate without cover. 3. Upload, rights, activate. 4. Add item | 422 first, then Active, signed cover, item active | `admin-services.e2e.spec.ts::E2E-S01` | PASS |
| TC-04 | P4 | E2E | Services search, filters, paging, reload | 1. Add 20 via API. 2. Search tag, next page. 3. Filter Section/Use. 4. Reload | 1-25 of 28, 26-28, exact filter counts | `admin-services.e2e.spec.ts::E2E-S02` | PASS |
| TC-05 | P4 mobile | E2E | Catalog at 375 | 1. Menu. 2. Services | Renders, no overflow | `admin-services.e2e.spec.ts::E2E-S03` | PASS |
| TC-06 | P5 | E2E | Provider, staff trip, status flow, cancel, filters | 1. Create provider. 2. Departure trip. 3. Send, Confirm, En route, Complete. 4. Cancel local trip | Pickup = flight - 3 h, 5-state history | `admin-transportation.e2e.spec.ts::E2E-P5-01` | PASS |
| TC-07 | P6-8 | E2E | Reservation, dashboard, messages, tasks, notifications | 1. New reservation, copy link, Folio, check in. 2. Dashboard row. 3. Guest writes, reply. 4. Task assign/start/complete. 5. Notification Open | KPIs move, row visible, unread 0, task COMPLETED | `admin-operations.e2e.spec.ts::E2E-P8-01` | PASS |
| TC-08 | P6-8 mobile | E2E | Menu lists every plan item at 375 | 1. Open Menu. 2. Read items | All items, no overflow | `admin-operations.e2e.spec.ts::E2E-P8-02` | PASS |
| TC-09 | P9 | E2E | Numbered journey, skip, order, My requests, Host (375) | 1. Home 1.1/1.2, Not now. 2. Order 2 waters. 3. Requests. 4. Host message | Plain status "Received", server holds data | `guest-portal-journey.e2e.spec.ts::numbered journey` | PASS |
| TC-10 | P9 | E2E | Desktop grid, ES toggle, expired link | 1. 1440, ES. 2. Servicios. 3. Unknown link | Spanish labels, "Ask your Resort Host" | `guest-portal-journey.e2e.spec.ts::desktop / expired` | PASS |
| TC-11 | Guest API | E2E | Guest-safe view, orders per service, cancel/change, trip cancel, chat photo | 1. Skip via PUT. 2. Two orders. 3. Change/cancel booking. 4. Cancel trip. 5. Upload photo | No internal keys, 422 once confirmed, photo signed | `guest-portal.e2e.spec.ts::E2E-G01..G05` | PASS |
| TC-12 | Phase A | E2E | Guest link reliability, 503, 401, remembered link | 1. Open link, soak polls. 2. Unknown/malformed. 3. 503, 401 | Server data only, Reconnecting, expired screen | `phase-a-guest-link.e2e.spec.ts::E2E-PA01..PA06` | PASS |
| TC-13 | Exploratory guest | E2E | Home, Services, order/booking/transfer forms, Requests, Host+photo at 1440 and 375 | 1. Open each screen. 2. Open each form. 3. Send photo | 0 console errors, 0 4xx/5xx, no overflow, no raw enum, no demo data | `guest-explore.e2e.spec.ts::every screen and form is clean` | PASS |
| TC-14 | Exploratory admin | E2E | 12 menu items x 1440/375 | 1. Open each item. 2. Read console, responses, semantics | 24 screens clean | `scratchpad/explore-final.mjs` (not committed) | PASS |

## 3. Defects
- Product (fixed, unit-tested): (1) Reservations villa picker loaded only the first 100 villas: now walks all pages (`reservations_screen_test.dart`). (2) Guest portal: a write made while a poll was in flight was not re-read until the next poll: `refresh(afterWrite:)` runs again (`portal_controller_test.dart`). (3) Journey step header read out only "Step 1 of 3": title now included (`home_journey_test.dart`).
- Specs (fixed): missing villa statuses, `tab` role for portal nav, stale panel clicked, completed filter not scoped to the run, 8-row dashboard and long villa menu (run names sort first), empty staff roster (spec creates one in the emulator), first key lost in Flutter inputs, click during panel re-flow, dangling cover objects (now uploaded to Storage).

## 4. Remaining
- Tasks: Assign shows "No staff available" until a roster exists (no Team screen yet).
- Dining and Experiences "Requests" tab still "coming soon" (queue not built).
- Typing in the portal Services search during the first catalog load can be discarded.
- Not tested: real phone, App Check (phase 11).

## 5. Evidence
`doc/kachava-command-center/evidence/final-admin-<screen>-<1440|375>.png`, `final-guest-<home|services|form-order|form-booking|wizard-transfer|requests|host>-<1440|375>.png`.
