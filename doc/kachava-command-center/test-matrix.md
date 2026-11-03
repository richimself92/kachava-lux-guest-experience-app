# Test Matrix: Command Center integration QA (phases 3-5)

## 1. Execution Summary
- Runner Command: `cd e2e && npx playwright test --config <headless> <spec>` (backend :3011, admin :3002, emulators 8085/9199) + `explore.mjs` (1440/375).
- Results: villas-settings 2/2; services 3/3; transportation 1/1; admin `dart analyze` clean; backend 40 suites / 537 tests passed; admin `flutter test` 371 passed.
- Exit Code: 0 for all three specs (final runs), `npm run typecheck` 0, `npm test` 0, `dart analyze` 0, `flutter test` 0.
- Date: 2026-11-03. Production code unchanged: every failure was an outdated spec.

## 2. Test Case Matrix
| ID | Ref | Level | Objective | Steps | Expected Result | Automated Test | Status |
|---|---|---|---|---|---|---|---|
| TC-01 | P3 Settings/Villas | E2E | Configure settings; create, edit, deactivate villas; search, filter, page | 1. Open Settings, save. 2. Create/edit/deactivate villas. 3. Add 30 via API, search, page, reload | 25 per page, filters work, data persists, no 4xx, no console errors | `e2e/tests/admin-villas-settings.e2e.spec.ts::E2E-P3-01` | PASS |
| TC-02 | P3 mobile | E2E | Villas list, full-screen detail and Settings at 375 | 1. Open Menu, Villas. 2. Search, open row. 3. Open Settings | Full-screen sheet, no overflow, no 4xx | `admin-villas-settings.e2e.spec.ts::E2E-P3-02` | PASS |
| TC-03 | P4 Services | E2E | One service per kind with cover upload to the Storage emulator, items, activation | 1. New service per kind. 2. Activate without cover. 3. Upload cover, confirm rights, activate. 4. Add item | 422 "Cover required" first, then Active; signed cover URL; item active; upload 200, no CORS error | `admin-services.e2e.spec.ts::E2E-S01` | PASS |
| TC-04 | P4 Services | E2E | Search, filters, pagination, reload persistence, section view | 1. Add 20 via API. 2. Search tag, page 2. 3. Section/Use/Status filters. 4. Reload, open Experiences | 1-25 of 28, 26-28, filter counts exact, data persists | `admin-services.e2e.spec.ts::E2E-S02` | PASS |
| TC-05 | P4 mobile | E2E | Catalog at 375 | 1. Menu. 2. Services | Renders, no horizontal overflow | `admin-services.e2e.spec.ts::E2E-S03` | PASS |
| TC-06 | P5 Transport | E2E | Provider, staff trip, full status flow, filters, reload | 1. Create provider. 2. New departure trip. 3. Send, Confirm, En route, Complete. 4. Cancel second trip | Pickup = flight - 3 h, history has 5 states, persists | `admin-transportation.e2e.spec.ts::E2E-P5-01` | PASS |
| TC-07 | Exploratory | E2E | All 10 menu items at 1440 and 375: console, network, overflow, raw enums, demo data | 1. Load admin. 2. Open each item (Menu first at 375). 3. Capture screenshot, console, responses, semantics | 0 console errors, 0 responses >= 400, 0 overflow, 0 raw enums, no demo data | `scratchpad/explore.mjs` (not committed) | PASS |
| TC-08 | Upload/CORS | Integration | Browser image upload to Storage emulator | 1. Upload cover in TC-03. 2. Watch network | `POST :9199/upload/...` 200; no CORS change needed | `admin-services.e2e.spec.ts::E2E-S01` | PASS |

## 3. Defects (all outdated specs, none in product code)
- Transportation: `POST /villas` now requires operational/housekeeping/maintenance status; `POST /stays` returns `data.stay.stayId`; Providers/Trips are `tab` roles; stay suggestions are `button`, not `option`.
- Services: checkbox is the identifier node itself (`[flt-semantics-identifier][role=checkbox]`); first "New service" tap can be lost (retry until editor opens); the open search box is a textbox; section tab bar "Requests" is not the scrolling editor bar; at 375 the drawer item must be tapped with a stable locator.

## 4. Observations (not failures)
- Dining and Experiences "Requests" tab shows "Request queue coming soon" (planned later phase).
- Rows with a stale cover show a pale tile: the 404 comes from old objects missing in the emulator Storage (`e2e-transport-cover.jpg`), not from the app.
- Local DB holds RUN-tagged test records (`e2e*`, `P3*`, `P5*`) and one probe stay (`ZZ probe`) from QA runs; emulator data only.

## 5. Evidence
`doc/kachava-command-center/evidence/integration-<screen>-<1440|375>.png` for dashboard, reservations, villas, services, experiences, dining, transportation, wellness, tasks, settings.
