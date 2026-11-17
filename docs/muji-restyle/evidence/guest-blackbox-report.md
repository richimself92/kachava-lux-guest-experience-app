# Guest portal MUJI restyle - black-box re-run on rebuilt :3005 (2026-11-16)
Runner: python Playwright, bundled Chromium, real backend :3011 (emulator demo data), no stubs. Manifests: `run-5fc1d712-*.json`, `run-791fdd17-*.json` (e2e_recorder).
Evidence: guest-{home,services,requests,host}-{375,390,768,1280,1440,1920,932}.png (28), guest-journey-*-390.png, guest-valeria-*-390.png.

## Journeys (Isabella 390x844)
1. Home journey: PARTIAL. 1/2/3 steps render, 3.x Departure open; "Next:"/"Not now" NOT exercisable for Isabella: all During-stay items are done after my earlier orders, so no Next bar. Valeria's home still shows "Next: 2.2 Dining" + "Not now" (guest-valeria-home-390.png), not clicked.
2. Services: PASS. Search "massage" -> 1; Dining -> 3; All -> 20; photo cards, price/lead chips, detail sheet (guest-journey-service-detail-390.png).
3. Villa stocking order: placed in the previous run (not repeated, per instruction). This run only went to Review and Back, nothing submitted. Order still in Requests as "Received" (now 4 line items).
4. Requests detail sheet + All/Active/Done tabs: PASS ("Ask Host" shown).
5. Host chat: PASS. "Hola, prueba MUJI" still in thread (no new message sent).
6. EN->ES->EN: PASS (Inicio/Servicios/Solicitudes/Host and back).
Valeria quick pass: PASS (Villa Coral, 4 tabs render).

## Overflow
PASS on all 28 matrix screens (375, 390, 768, 1280, 1440, 1920, 932): scrollWidth == innerWidth.

## Console / network
0 console errors, 0 pageerrors, 0 responses >= 400.

## Visual rules
No violation seen: 0 white surfaces visible, paper background, brown accent, hairlines, no shadows or pills, square corners. Not verifiable on canvas: font families/weights, fades.
Fix confirmed: SegmentTab filters are inline now at 1440 (guest-services-1440.png) and 768+.

## Remaining oddities
- 375/390: category tabs wrap to 2 rows ("Wellness, Transport, When: Any" on row 2) (guest-services-375.png). Acceptable but not single-line.
- 932x430: header + bottom nav leave ~2 rows of content (guest-requests-932.png).
- Numbering mismatch: Home "2.1 Villa stocking" vs Requests "1.3 Villa stocking".
- New red dot on Host tab (unread badge, guest-home-390.png): no error, presumably unread host reply.
- Gate: check_evidence.py exit 1 only because "demo run but no `demo-data: approved` in PLAN.md/spec.md". Removed stale PNGs I could not regenerate (order-sent toast, Not-now shot).
