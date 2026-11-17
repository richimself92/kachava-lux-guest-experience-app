# Guest portal UX: guided numbered journey (`web/`)
Owner decision (2026-11-02, binding): keep numbered steps. Source: [`plan.md`](plan.md) "Portal del huésped". Own brand look (Libre Baskerville / Libre Franklin, palette in `web/lib/core/theme/`); root `DESIGN.md` is admin-only. Minimal text: labels 1-3 words, explanations only in ⓘ. Nothing hardcoded: content comes from the catalog, Settings and the stay.

## 1. Information architecture
- **Tabs (4, bottom, no "all screens" drawer):** Home (journey) · Services · Requests (title "My requests") · Host (title "Resort Host": chat + real photo). Dot only for a real unread message or a request needing action.
- **Journey** = one pure function `buildJourney(stay, catalog, requests, skips, resortToday)`. Home rows, screen titles and Requests references read its output, so numbers cannot disagree.
- **Steps (fixed):** 1 Before arrival · 2 During stay · 3 Departure. **Core tasks (fixed slots):** 1.1 Flight & transfer (TRIP wizard, incl. "I arrange my own") · 1.2 Preferences (wizard: diet & allergies with explicit "None", then one page per active PREFERENCE service) · 3.1 Departure transfer · 3.2 Rate stay (optional). A core task shows only if its config exists (airports in Settings, active transport service): no dead rows.
- **Catalog tasks:** one task per *section* (a section with one service is named after it), from ACTIVE services by `offeredWhen`: before → Step 1, during → Step 2, both → Steps 1 and 2 (done state shared). PREFERENCE services live inside 1.2.
- **Numbering `step.task`:** core slots first, then catalog tasks by admin section order, then name; computed on read, never stored. Core numbers never move; a new section appends at its admin position; a disabled one vanishes and only rows after it shift; its past requests stay in Requests (snapshot name). An open task keeps its number until closed; the journey refreshes on Home focus, never mid-form.

## 2. Home journey
- Top strip: villa, dates, Wi-Fi (tap = reveal + real clipboard copy). No hero, no stat cards, no sentence subtitles.
- **Open step by resort date** (`America/Cancun`, adr-005): before check-in → Step 1; from check-in → Step 2; Step 3 from check-out minus max(departure-transfer lead time, 1 day). If the open step has nothing pending, open the next with pending tasks; none left → "All set ✓". Accordion: one step open, others collapsed; every header is a button (`aria-expanded`), never dead text (`SPECIFICATION.md` §137). A future step reads "Opens Nov 3" and expands to a read-only preview (rows disabled, ⓘ says why).
- **Progress per step:** "2 of 4" + bar. States by shape + word, never color alone: pending (number in ring) · in progress (half ring, "Draft": wizard/cart started, saved per guest) · done (✓ + one-line summary, e.g. "AA 1482 · Nov 3"). Staff progress lives in Requests, not here.
- **Next** (sticky primary above the tab bar): "Next: 1.3 Villa stocking" opens the first pending task of the open step, then of the next opened step; hidden when done. **Not now** (text button, 48px) skips a pending task; skipped tasks leave the count ("2 of 3"), sink as "Skipped" and stay tappable (stored on the stay: backend `skippedTaskIds`).
- **10+ services in a step:** rows are sections, not services ("Dining 6"); at most 5 rows (`journeyMaxRows`), then "See all 7" expands inline. A row opens Services filtered to that section, titled "2.1 Dining"; Back returns to the same open step.

## 3. Services tab (large catalogs)
- Top: search (300 ms debounce; name, one line, tags in the current language) + section chips (All · each section; selected = filled + ✓) + "When" chip (Any / Before / During). "All" = section blocks: header + 3 cards + "See all N"; one section = 12 cards + "Show 12 more" (no infinite scroll). Grid: 1 column <640px, 2 at 640-1023, 3 from 1024 (max 960). Live region "12 services"; none → "No results" + "Clear".
- **Card** (whole card is the target): 16:9 photo (box reserved, lazy, alt EN/ES), name (serif), one line (ellipsis), price chip ("Included ✓" · "$45 / person" · "On request"), lead time ("24 h ahead"). No paragraphs.
- **Detail sheet** (bottom sheet on mobile, 480px side panel on desktop; Esc/swipe closes, focus returns to the card): swipe gallery (cover + up to 8, "3/6", arrow keys), price + lead time, 3-line summary + "More", collapsed accordions Includes / Bring / Meeting point / Rules, sticky primary by usage type: Order · Book · Choose · Plan trip. A disabled primary says why in one line.
- **Forms:** up to 4 fields = one page; more = wizard, max 3 fields per page, "Step 2 of 4" + bar, Back keeps data, draft autosaved, "Save & exit".
  - ORDER: items grouped by item category (photo, price, 48px steppers), sticky total "2 items · $38 USD", Review (notes, age check if configured) → "Order". PREFERENCE: choice cards with photo (radio/checkbox), "Save", "Change until Nov 2, 6 PM".
  - BOOKING: date → available time slot → people (min/max) → configured questions → Review → "Book".
  - TRIP (arrival / departure / local; 1.1 and 3.1 preset the type): 1 When (date, time) → 2 Flight (airport from Settings, airline, flight no., terminal optional) → 3 Group (passengers, bags, vehicle cards with photo/price) → 4 Review → "Send". Departure shows the computed pickup time.

## 4. Requests
- One list, newest first, chips All · Active · Done. Row: name, "Nov 4 · 7 PM · 2 guests", status chip (word + icon) and a 4-dot track. Statuses: Received → Confirmed → Preparing (orders, preferences, bookings) / On the way (trips) → Done; plus Cancelled. Never raw enums.
- Tap = sheet: timeline with times, snapshot of name/price/items. While Received: "Change" (prefilled, re-sent) and "Cancel" (one-line confirm "Cancel Lux bar order?", focus on Cancel). After Confirmed: "Ask Host" (chat with the request attached).

## 5. Feedback and states
- Loading: skeletons in the final layout (reserved image boxes, no layout shift), never spinner-only; buttons show "Sending…" and disable. Error: one line + "Retry" in place, form data kept; only 401/403/404 say "Link expired, ask your Resort Host"; 5xx/timeouts keep last data + "Reconnecting".
- Empty (one line + one action): Services "Nothing yet" + "Ask Host"; Requests "No requests" + "Browse services"; Journey "All set ✓".
- Success only after the server confirms (awaited write), never optimistic or fake (today's "copied" toasts copy nothing). Toast: one line, 4 s (errors 8 s + Retry), above the tab bar, `aria-live="polite"`, e.g. "Order sent". Missing ES = "Translation pending", never auto-translated.

## 6. Accessibility and mobile
- Text >= 14px everywhere (tabs too; no uppercase micro-labels), body 16. Text on cream: swap `secondary` (3.5:1) and `mutedMetadata` (4.3:1) for `tertiary` (5.4:1) or `onSurfaceVariant` (8.5:1); `secondary` stays decorative.
- Targets >= 48px (rows, chips, steppers, tabs, EN|ES); primary action sticky in the thumb zone; no horizontal scroll at 320px; safe-area insets. Focus ring 2px `primary`, 2px offset; sheets trap focus; labels like "Step 2 of 3, 1 of 5 done, expanded"; reduced motion disables accordion animation.
- Language: first visit from `navigator.language` (es* → ES, else EN), remembered in localStorage; EN|ES toggle always in the header.

## 7. Wireframes (390px; ✓ done · ◐ in progress · o pending)
```
HOME (step 1 open)                       STEP 2 OPEN (10+ services)
+------------------------------------+   +------------------------------------+
| Villa 3 · Nov 3-8 · Wi-Fi          |   | v 2 During stay      [#---] 1 of 5 |
| v 1 Before arrival   [##--] 2 of 4 |   | o 2.1 Dining                   6 > |
| ✓ 1.1 Flight & transfer            |   | o 2.2 Experiences             12 > |
| ✓ 1.2 Preferences                  |   | ✓ 2.3 Wellness  Spa Nov 5        > |
| o 1.3 Villa stocking               |   | o 2.4 Transport                3 > |
| ◐ 1.4 Wellness               Draft |   | o 2.5 Villa comfort            4 > |
| > 2 During stay        Opens Nov 3 |   |   See all 7  v                     |
| > 3 Departure          Opens Nov 7 |   | > 3 Departure          Opens Nov 7 |
| [   Next: 1.3 Villa stocking >   ] |   | [       Next: 2.1 Dining >       ] |
|              Not now               |   |              Not now               |
| Home   Services  Requests  Host    |   | Home   Services  Requests  Host    |
+------------------------------------+   +------------------------------------+

SERVICES                                 DETAIL SHEET
+------------------------------------+   +------------------------------------+
| [ Search ]                   EN|ES |   | ----                           [X] |
| (All)(Dining)(Wellness)(Trips) >   |   | [ gallery 16:9 ]               3/6 |
| When: Any v                        |   |          < o o * o o o >           |
| Dining                 See all 6 > |   | Lux bar                            |
| +--------------------------------+ |   | [$12-45 / item] [2 h ahead]    (i) |
| | [ photo 16:9 ]                 | |   | Cocktails by the pool.        More |
| | Lux bar                        | |   | v Includes                         |
| | Cocktails by the pool          | |   | > Meeting point                    |
| | $12-45 USD           2 h ahead | |   | > Rules                            |
| +--------------------------------+ |   | [             Order              ] |
| Wellness               See all 4 > |   +------------------------------------+
| Home   Services  Requests  Host    |
+------------------------------------+

TRIP WIZARD, page 2 of 4                 TRIP WIZARD, review
+------------------------------------+   +------------------------------------+
| < 1.1 Flight & transfer            |   | < 1.1 Flight & transfer            |
| Step 2 of 4  [#######-------]      |   | Step 4 of 4  [##############]      |
| Airport        [ CUN       v ]     |   | Review                        Edit |
| Airline        [             ]     |   | Nov 3 · 14:30 · CUN                |
| Flight no.     [ AA 1482     ]     |   | AA 1482 · 3 guests · 4 bags        |
| Terminal (opt) [             ]     |   | SUV (6 seats)              $85 USD |
| [              Next              ] |   | [              Send              ] |
|            Save & exit             |   |            Save & exit             |
+------------------------------------+   +------------------------------------+
```
