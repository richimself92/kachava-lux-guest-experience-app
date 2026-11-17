# ADR-013: MUJI visual layer for admin and guest portal

- Status: Accepted (owner, 2026-11-16)
- Source: `doc/MUJI Design Implementation Guide.md` (client, 2026-11-13), written for React + Tailwind.

## Context
Kachava asked to restyle both Flutter apps after the MUJI / Kenya Hara guide. It conflicted with
DESIGN.md v1.0 (white canvas, 4–12px radii, Roboto; guest portal with its own editorial fonts).
The owner decided MUJI wins and DESIGN.md was updated to v2.0. Information architecture,
workflows, copy and the guest's numbered journey do not change.

## Decision
Translate the guide's Tailwind tokens and kit into Flutter themes, one token file per app:

| Guide (Tailwind) | Flutter |
|---|---|
| `@theme` colors | `admin/lib/core/theme/kachava_tokens.dart`, `web/lib/core/theme/kachava_colors.dart` |
| status `-wash` / `-line` | `StatusTone` with text, wash and line colors |
| `--radius-*: 2px` | single `radius = 2`; round only for dots, avatars, step numbers |
| no shadows | every component theme at elevation 0, `surfaceTint` transparent |
| `kl-label` utility | `klLabel` TextStyle (11px, w500, 0.14em, uppercase by widget) |
| fonts from Google Fonts | bundled assets, subset to Latin (Zen Kaku ~31 KB/weight, Noto Sans ~167 KB) |
| `animate-fade-in` 220ms | `pageTransitionsTheme` fades, `Cubic(0.2,0,0,1)` |
| `HairlineGrid`, `PageHeader`, `SectionHead`, `Segmented` | widgets in `admin/lib/presentation/components/` |
| `@media (pointer: coarse)` 16px inputs | input text 16px on touch platforms |
| lucide icons | kept Material icons (one family, no filled circles) |

The two apps duplicate ~20 token values instead of sharing a package: they deploy separately
and do not share code today.

## Consequences
- Old status colors (Google-like) were replaced by muted ochre, ink blue, moss, brick and plum;
  token tests assert AA contrast of each status text on its wash.
- Nav count pills became tabular numbers; pill chips became square labels.
- Roboto, Libre Baskerville and Libre Franklin were removed from the bundles.
- Visual regressions are checked with screenshots at 375, 390, 768, 1440 and 932×430.
