# PLAN — MUJI restyle (owner-approved 2026-11-16)

Source: `MUJI Design Implementation Guide.md`; DESIGN.md v2.0; ADR `doc/kachava-command-center/adr-013-muji-restyle.md`.
Visual-only restyle of both Flutter apps. No route, workflow, copy, backend or API changes.

| # | Task | Owner | Owned files | Status |
|---|------|-------|-------------|--------|
| 0 | DESIGN.md v2.0, AGENTS.md, ADR-013, fonts subset | coordinator | DESIGN.md, AGENTS.md, doc/, assets/fonts | done |
| 1 | Admin tokens + theme + component kit + screens + tests | flutter-implementer (admin) | admin/** | in progress |
| 2 | Guest portal tokens + theme + screens + tests | flutter-implementer (web) | web/** | in progress |
| 3 | Screenshots 375/390/768/1440/932x430, Playwright once | coordinator | e2e/ (read), scratchpad | pending |

Contrast decisions (coordinator, 2026-11-16):
- Neutral status label = muted text on surface with a line border (5.14:1); muted on wash (4.47) is not used for text.
- lineStrong #C2BEB2 is the client's outline value (1.76:1 on surface); kept as specified. Inputs show an ink 1.5px focus border, so focus never depends on the outline. Recorded, not asserted as 3:1.

Verification data:
- demo-data: approved. The local Firestore emulator holds the owner-approved demo seed (`.local-data/demo`, the same data set approved for the 2026-11-04 demo). It is used only for the black-box runs; it ships nowhere.
