# PLAN — Pre-stocking catalog (171 products) + weight-priced proteins (owner-approved 2026-11-18)

Sources: doc/catalog/*.xlsx, doc/catalog/video_ejemplo.mp4 (illustrative only).
Guest sees ONLY the USD selling price (column G). SKU, net cost MXN and source URL are admin-only.
Proteins (PRE-104..PRE-124) are priced per oz (USD/oz from Protein_Portion_Pricing column F);
guest picks number of portions + oz per portion; server computes the total.

## API contract (shared by all workers)
CatalogItem (admin):
  sku: string|null (<=40 chars, unique within the service), netCostMXN: number|null (0..1e6, 2dp),
  sourceUrl: string|null (http(s) URL <=500), pricingUnit: 'ITEM'|'OZ' (default 'ITEM'),
  portionOzOptions: number[] (ints 1..64, 1..10 entries, sorted unique; default [6,8,10,12,14] when OZ, [] when ITEM).
  With pricingUnit OZ, priceUSD = USD per oz (required, > 0) and netCostMXN = MXN per oz;
  both may have up to 4 decimals for OZ items (ITEM items: 2 decimals).
CatalogItem (guest projection): pricingUnit, portionOzOptions added; sku, netCostMXN, sourceUrl NEVER sent.
Admin items list: GET /admin/services/:serviceId/items?page&pageSize&sort&q&category
  q = case-insensitive contains on name.en/name.es/sku; category = exact match.
  GET /admin/services/:serviceId/item-categories -> { categories: string[] } (distinct, catalog order).
Guest order line (PUT /stays/:guestUuid/orders/:serviceId): { itemId, quantity, ozPerPortion? }
  OZ item: ozPerPortion required and must be in portionOzOptions; quantity = portions (1..20).
  ITEM item: ozPerPortion must be absent. 422 otherwise.
Pricing (server): ITEM line = qty * priceUSD; OZ line = qty * ozPerPortion * priceUSD; round to cents.
Stored order line (LarderOrderItem) and request projections (admin + guest) add:
  pricingUnit, ozPerPortion (null for ITEM), unitPriceUSD, lineTotalUSD.
Import: npm run import:prestocking -- --project <id> --file ../doc/catalog/prestocking-2027.json [--dry-run]
  upsert by sku inside the single VILLA_STOCKING service; items without sku -> DISABLED; prints counts.

| # | Task | Owner | Owned files | Status |
|---|------|-------|-------------|--------|
| 0 | Excel -> JSON + ES translation | coordinator | doc/catalog/** | in progress |
| 1 | Backend model, pricing, projections, list filters, import script | backend worker | kachava-backend/** | in progress |
| 2 | Admin editor, table search/filter, request detail oz | admin worker | kachava-admin/** | in progress |
| 3 | Guest order form search/filter, protein row, cart, review | web worker | kachava-web/** | in progress |
| 4 | Local import + black-box, prod dry-run, deploy with OK | coordinator | — | pending |

demo-data: approved (local emulator demo seed only, for verification).

## Amendment 2 — Terms & conditions + substitutions (owner request 2026-11-19)
Service (admin, any kind): guestInfo.terms: LocalizedText {en, es} (multiline, <= 3000 chars each; "" = none).
  Guest projection includes guestInfo.terms.
VILLA_STOCKING service: stocking.askSubstitutions: boolean (default false).
Guest order PUT body adds (top level, next to `items`):
  substitutionsAllowed?: boolean  -> required (true/false) when stocking.askSubstitutions; else ignored.
  termsAccepted?: boolean         -> must be true when guestInfo.terms has text in en or es; else ignored.
  Violations -> 422 with a clear message.
Stored with the order and exposed on request projections (admin + guest), request level:
  substitutionsAllowed: boolean|null, termsAcceptedAt: ISO string|null.
Import file may carry an optional top-level `service` block:
  { "service": { "terms": {en, es}, "askSubstitutions": true }, "items": [...] } -> patches the VILLA_STOCKING service
  (counted in the summary as serviceUpdated: true/false; dry-run writes nothing).
Admin: service editor textarea "Terms & conditions" (EN/ES) in guest info; stocking switch "Ask guest about substitutions";
  request detail shows "Substitutions: allowed / not allowed" and "Terms accepted <date>".
Guest: service detail shows a "Terms & conditions" section; order review shows the terms text, a required
  substitution choice (two options) when asked, and a required "I accept the terms & conditions" checkbox;
  "My requests" detail shows the substitution choice.
