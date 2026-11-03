# Test Matrix - Kachava Command Center (Phase D)

Phase D = admin design system, sectioned navigation, no-login silent auth. Tier 3.

## 1. Execution Summary
- Runner Command: `cd admin && dart analyze && flutter test`; `cd e2e && E2E_API_BASE_URL=http://localhost:3011/api/v1 npx playwright test --config <headless temp config>`
- Results: analyze 0 issues; flutter test 172 passed / 0 failed (after D5 review fixes; exit 0); Playwright 8 passed / 7 failed (see TC-13)
- Exit Code: dart analyze 0; flutter test "All tests passed!" (exit code not captured by shell pipe); Playwright 1
- Date: 2026-11-02

## 2. Test Case Matrix (Phase D)
Ref: spec Phase D (client mockup `doc/improvements/WhatsApp Image 2026-11-02 at 16.52.54.jpeg`).

| ID | Ref | Level | Objective | Steps | Expected | Automated Test | Status |
|----|-----|-------|-----------|-------|----------|----------------|--------|
| TC-01 | D-NAV | Unit | Nav model: sections and hidden items | 1. Build nav model 2. List sections/items 3. Check hidden entries | 3 sections (Guest Operations, Hospitality, Operations); hidden items absent | admin/test/admin_nav_model_test.dart | PASS |
| TC-02 | D-NAV | Unit | No numeric prefixes in labels | 1. Read all item labels 2. Match `^\d` | None start with digits | admin/test/admin_nav_model_test.dart | PASS |
| TC-03 | D-UX | Unit | Contrast tokens meet WCAG AA | 1. Load Kachava tokens 2. Compute ratios per pair | All >= required ratio | admin/test/kachava_tokens_contrast_test.dart | PASS |
| TC-04 | D-NAV | Widget | Sidebar (desktop) layout + selected style | 1. Pump 1440px shell 2. Find sidebar 3. Select item | Brand, Dashboard, labels, chevrons; selected = light gray + bold | admin/test/admin_sidebar_test.dart | PASS |
| TC-05 | D-NAV | Widget | Rail (tablet) and drawer (mobile) | 1. Pump tablet/375px 2. Open drawer 3. Tap item | Rail/drawer navigate; no overflow | admin/test/admin_sidebar_test.dart | PASS |
| TC-06 | D-NAV | Widget | Stay summary reachable with hidden items | 1. Open dashboard 2. Use Reservations/Go to section 3. Open stay summary | Summary reachable without a nav entry | admin/test/admin_dashboard_widget_test.dart | PASS |
| TC-07 | D-COPY | Widget | Clean-UI copy (no eyebrows/FR codes) | 1. Pump each workspace 2. Search text for "SANCTUARY COMMAND CENTER", "FR-" | Absent | admin/test/d2a_restyle_test.dart, d2b_restyle_test.dart | PASS |
| TC-08 | D-UX | Widget | Shared components + 320px no overflow | 1. Pump components 2. Pump 6 workspaces at 320px | No overflow errors | admin/test/admin_components_test.dart; admin_dashboard_widget_test.dart::test_compact_320px_viewport_renders_all_6_workspaces_without_overflow | PASS |
| TC-09 | D-AUTH | Unit | Silent auth: one login | 1. Start app 2. Issue 3 API calls 3. Count logins | Exactly 1 login, no sign-in screen | admin/test/silent_staff_auth_test.dart | PASS |
| TC-10 | D-AUTH | Unit | Concurrent calls share one login | 1. Fire N parallel calls cold 2. Count logins | 1 login shared | admin/test/silent_staff_auth_test.dart | PASS |
| TC-11 | D-AUTH | Unit | 401 retried exactly once | 1. Stub 401 then 200 2. Call 3. Stub 401,401 | Re-login + 1 retry; second 401 surfaces error | admin/test/silent_staff_auth_test.dart | PASS |
| TC-12 | D-AUTH | Widget | Staff 403 on roster still shows shell | 1. Stub roster 403 2. Pump app | Shell shown, not No-Access | admin/test/best_effort_reread_test.dart | PASS |
| TC-13 | D-E2E | E2E | Full Playwright suite (headless, API :3011) | 1. Run suite 2. Record per test | All pass | e2e/tests/*.e2e.spec.ts | FAIL (8/15) |
| TC-14 | D-VIS | E2E | Visual evidence desktop 1440 + mobile 375 drawer | 1. Open :3002 headless 2. Wait render 3. Screenshot (click hamburger) | Matches mockup | evidence/phase-d-admin-desktop-1440.png, phase-d-admin-mobile-375.png | PASS (truncation fixed in D5, re-shot) |

## 3. E2E Failures (7 of 15)
- E2E-A02 (admin-dashboard): `clickSemanticsByText` false; menu item is "Villa-110 - 110 - AVAILABLE" (spec/helper label mismatch with `displayLabel`).
- E2E-PA01, PA05: same villa-label click in `submitNewStayDialog` (e2e-helpers.ts:320). PA06: create-stay returned 400 (expected 201).
- Root cause A02/PA01/PA05: `AdminVillaInfo.displayLabel` = `villaName — suiteType` (Phase A, unchanged in D) and the :3011 in-memory data has numeric suiteTypes; not a Phase D regression. Follow-up: helper should match villa + AVAILABLE, not the full label.
- E2E-PA02: guest API returns 401 "reservation token not found" for unknown guestId; spec expects 404 (backend/spec drift, not admin UI).
- E2E-G01/G02: guest portal semantics lack "432Hz" / a step returned false; guest web, not Phase D admin.
- Visual defect (fixed in D5): brand truncated at 280px sidebar; sidebar now 300px, screenshots re-taken.
