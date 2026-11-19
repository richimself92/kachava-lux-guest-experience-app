# Black-box re-run: pre-stocking catalog + terms/substitutions (2026-11-19)
Playwright Chromium, real backend + emulator, no stubs. check_evidence.py: PASS (375/768/1280/1920, real data). Evidence in this dir.
| # | Journey | Result | Seen |
|---|---------|--------|------|
| 1 | Footer ignores legacy items | PASS | "0 items . $0 USD" before adding |
| 2 | Terms in service detail | PASS | "Terms & conditions" expands to the stocking text |
| 3 | NY steak 5x12 oz + 2 Almonds | PASS | $198.68 + $25.58, footer "7 items . $224.26 USD" |
| 4 | Review: terms, 2 radios, accept box; Order empty | PASS | terms shown; both radios unchecked; checkbox; "Choose an option" error inline; 0 PUTs sent |
| 5 | Submit with No + accept | FAIL (blocker) | UI PUT body is only {items:[...]}: no substitutionsAllowed/termsAccepted -> HTTP 422 "substitutionsAllowed is required". Order cannot be placed from the guest UI ("Check the details" + Retry). |
| 5b | Same with fields added via API (workaround) | PASS | PUT 200; lines substitutionsAllowed=false, termsAcceptedAt=2026-11-19T05:54:52Z; guest My requests detail: "Substitutions: not allowed", Ordered 00:54 |
| 6 | ES review | PASS | Spanish terms; "Sí, autorizo sustitutos comparables" / "No, por favor no sustituir artículos no dispo..." |
| 7 | Admin request detail/list | PASS | "Substitutions Not allowed", "Terms accepted Nov 19 . 00:54" (resort time; UTC is 05:54); detail "New York steak - 5 x 12 oz = 60 oz . $198.68"; list "2 x Almonds, 5 x 12 oz New York steak" (checked 375/768/1280/1920) |
| 8 | Admin editor Villa stocking | PASS | More options: Terms EN+ES filled, "Ask guest about substitutions" on; cancelled |
| 9 | Items table at 375 | PARTIAL FAIL | No badge wrapping (OK, 375 shows "Disabled" on one line, but SKU/name truncated to "P...", "Mine..."). Disabled NOT last: page 1 = PRE-001..005 active then 5 disabled legacy; page 2 starts at PRE-006 active. |
| 10 | Chip bar "Health" | PASS | Bar scrolls (Health x 954-1024 in view), only Health has aria-current; same for Protein |
Overflow: scrollWidth == innerWidth at all 4 widths (guest review, admin request detail, items table). Console/HTTP: only the deliberate-looking 422 above (it is the defect); 0 other errors/responses >=400.
## Defects
1. BLOCKER: kachava-web/lib/data/http_guest_api.dart:146 saveOrder sends only {'items': payload['items']}; it drops substitutionsAllowed and termsAccepted that OrderCart.toPayload() (order_cart.dart:164-178) builds. Backend rejects 422, so no guest can order villa stocking.
2. Admin items: disabled legacy items still sort among actives (positions 6-10), not last. Items table at 375 truncates SKU/name heavily.
Side effect: Valeria's stay now holds the API-placed order (workaround above). Isabella not used.
Verdict: REJECTED (journey 5 blocks ordering; 9 partial).

## Re-run after fix (2026-11-19)
- J5 from guest UI: PASS. PUT 200, body has substitutionsAllowed:false and termsAccepted:true; response lines carry substitutionsAllowed:false and termsAcceptedAt 2026-11-19T06:13:30Z; My requests shows "Substitutions: not allowed" (Ordered 01:13 resort time). Totals $198.68 + $25.58 = $224.26; no console/HTTP errors.
- J9: PASS. Page 1 is all active; the last page (18) ends with 1 active then the 5 disabled legacy items. Shot: admin-items-last-page-375x812.png.
- check_evidence.py: PASS. Verdict now: PASSED (defects 1 and 2 fixed; 375 SKU/name truncation remains cosmetic).
