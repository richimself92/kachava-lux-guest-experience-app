# MUJI Design Implementation Guide

Nov 13, 2026 · @Fergu

The MUJI / Kenya Hara look comes from a small token set (warm paper, warm ink, hairline rules, one accent color), square edges with no shadows, and quiet type. This guide shows how it was built on Kachava Lux Operations (React + Tailwind CSS v4) so you can repeat it on another site. The values work as plain CSS custom properties too.

## The seven rules

Every decision below follows from these rules. When in doubt, remove rather than add.

1. **Paper, never white.** The page is a warm off-white; pure `#FFFFFF` is not used for app surfaces.
2. **One accent.** The brand color (here Kachava brown) is the only decorative color. Status colors exist only to carry meaning and are muted.
3. **Rules, not boxes.** Separate content with 1px hairlines and top borders instead of cards, fills and shadows.
4. **Square edges.** Corner radius is 2px everywhere; no pills or rounded cards.
5. **No shadows.** Depth comes from a slightly lighter surface and a hairline, never a drop shadow.
6. **Quiet type.** Two families, weights 400 and 500 only, with small letter-spaced uppercase labels for hierarchy.
7. **Imperceptible motion.** About 200ms fades only; no slides, bounces or scale effects.

Keep the information architecture as it is. This is a restyle: routes, screens and workflows do not change.

## Step 1 — Color tokens

Define every color once as a token and never write a hex value in a component. In Tailwind v4 the tokens go in an `@theme` block in the main stylesheet (`src/index.css` here). Each `--color-x` token automatically becomes `bg-x`, `text-x` and `border-x` classes.

| Token | Hex | Role |
| --- | --- | --- |
| `paper` | `#F4F2EC` | Page background; also the browser `theme-color` |
| `surface` | `#FAF9F5` | Tables, dialogs, inputs |
| `wash` | `#ECE9E1` | Hover and quiet fills |
| `ink` | `#2A2A28` | Primary text; focus outline |
| `muted` | `#6B6A65` | Secondary text and labels (passes AA on paper) |
| `faint` | `#A3A097` | Placeholders, disabled |
| `line` | `#D9D6CD` | Hairline rules |
| `line-strong` | `#C2BEB2` | Button and input outlines |
| `brand` | `#6D4627` | The single accent: primary buttons, active marker |
| `brand-deep` | `#55361D` | Primary button hover |
| `pending` | `#8F611A` | Ochre: unreviewed / high priority |
| `info` | `#3F5A7A` | Ink blue: acknowledged / in progress, links |
| `ok` | `#4F6B3A` | Moss: completed |
| `danger` | `#A8322D` | Brick: urgent, overdue, errors |
| `plum` | `#6E4E6B` | On hold |

Each status color also has a `-wash` background and a `-line` border variant, for example `pending-wash #F3EBD9` and `pending-line #E2D2AE`. A status badge is always all three together: `bg-pending-wash text-pending border-pending-line`.

For a new brand, swap only `brand`, `brand-deep` and `brand-wash`. Keep the neutrals warm and tinted toward the brand; never use a cool grey next to a warm accent.

For a site without Tailwind, put the same values in `:root { --color-paper: #F4F2EC; … }` and reference them with `var(--color-paper)`.

Also set `<meta name="theme-color" content="#F4F2EC">` in `index.html` so the phone browser bar matches the page.

## Step 2 — Typography

Use Zen Kaku Gothic New for titles and labels, and Noto Sans for body text. Load both from Google Fonts in `index.html`:

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Noto+Sans:wght@400;500;600&family=Zen+Kaku+Gothic+New:wght@400;500&display=swap" rel="stylesheet">
```

Register them as tokens in the same `@theme` block:

```css
--font-sans: "Noto Sans", "Helvetica Neue", Arial, sans-serif;
--font-display: "Zen Kaku Gothic New", "Noto Sans", sans-serif;
```

- **Weights:** 400 for text and 500 for emphasis. Replace every `font-bold` and `font-semibold` with `font-medium`; 600 is kept only for bold inside rich text.
- **Headings:** h1–h3 use the display font at weight 500, letter-spacing `0.02em` and `text-wrap: balance`.
- **Page titles:** 26px on phones, 32px from the `sm` breakpoint (`text-[1.625rem] sm:text-[2rem]`).
- **Numbers:** add `tabular-nums` wherever numbers sit in columns or update live (counts, timers, dates).

The signature element is the small uppercase label. Define it as a Tailwind `@utility`, not a component class, so it also works with variants such as `[&_th]:kl-label` on table headers:

```css
@utility kl-label {
  font-family: var(--font-display);
  font-size: 11px;
  line-height: 1.4;
  font-weight: 500;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: var(--color-muted);
}
```

Use it for section eyebrows written as an index and a name ("02 — Work orders"), form labels, table headers and metric labels.

## Step 3 — Base layer: edges, motion, focus

Override the radius scale so every existing `rounded-*` class becomes 2px, then add one fade animation. Both go in `@theme`:

```css
--radius-xs: 0px;
--radius-sm: 2px;
--radius-md: 2px;
--radius-lg: 2px;
--radius-xl: 2px;
--radius-2xl: 2px;

--ease-quiet: cubic-bezier(0.2, 0, 0, 1);
--animate-fade-in: fade-in 220ms var(--ease-quiet) both;
```

Bare `rounded` (without a size) is not covered by the scale above and stays at 4px. Replace it with `rounded-sm` in the sweep. Keep `rounded-full` only for genuinely round things such as status dots and avatars.

Then the base layer sets the ground and the global behavior:

```css
@keyframes fade-in { from { opacity: 0; } to { opacity: 1; } }

@layer base {
  body {
    font-family: var(--font-sans);
    background-color: var(--color-paper);
    color: var(--color-ink);
    -webkit-font-smoothing: antialiased;
    -webkit-tap-highlight-color: transparent;
    overscroll-behavior-y: none;
  }
  h1, h2, h3 {
    font-family: var(--font-display);
    font-weight: 500;
    letter-spacing: 0.02em;
    text-wrap: balance;
  }
  p { text-wrap: pretty; }
  ::placeholder { color: var(--color-faint); }
  :focus-visible { outline: 1.5px solid var(--color-ink); outline-offset: 2px; }
}

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 1ms !important;
    transition-duration: 1ms !important;
  }
}
```

- **Scrollbars:** 6px wide, transparent track, `line`-colored thumb.
- **Hidden scrollbars:** add a `.kl-no-scrollbar` class for sideways-scrolling strips such as filter tabs.
- **Transitions:** only `transition-colors` on hover; dialogs and the menu use `animate-fade-in`.

## Step 4 — The shared component kit

Put the repeated patterns in one file (`src/components/Kit.tsx` here) so every screen draws from the same vocabulary. It holds class-string constants for controls and four small layout components.

| Piece | What it is | Key classes |
| --- | --- | --- |
| `btnPrimary` | Filled brand button, one per screen | `min-h-10 px-4 bg-brand hover:bg-brand-deep text-surface text-sm font-medium rounded-sm` |
| `btnSecondary` | Outlined button | `bg-surface border border-line-strong hover:bg-wash text-ink` |
| `btnQuiet` | Underlined text action | `underline decoration-line-strong underline-offset-4 hover:decoration-ink` |
| `iconBtn` | 40px square icon button | `w-10 h-10 text-muted hover:text-ink hover:bg-wash` |
| `fieldLabel` / `fieldInput` | Form label and input | `kl-label block mb-1.5` / `min-h-10 bg-surface border border-line focus:border-ink` |
| `PageHeader` | Eyebrow label, title, meta line, actions | Bottom hairline: `pb-6 border-b border-line` |
| `SectionHead` | "02 — Status" label over a quiet h2 | `kl-label` + `text-base sm:text-lg` |
| `Segmented` | Text-only tab switch | Selected = `text-ink border-b border-ink`; others `text-muted` |
| `HairlineGrid` | Cells divided by 1px rules | `grid gap-px bg-line border border-line`, each cell `bg-surface` |

The hairline grid is the core trick of the style. Instead of separate cards with gaps, cells sit on a `line`-colored background with a 1px gap. The background shows through as perfectly even dividing rules.

Other patterns used across screens:

- **Section blocks:** a `border-t border-line pt-4` top rule instead of a box; use `border-t-2 border-brand` for the one block that needs emphasis.
- **Callouts:** a 2px left rule in the status color (`border-l-2 border-plum pl-4`) instead of a tinted card.
- **Active navigation:** `bg-wash` plus a 1px brand rule on the left edge.
- **Counts:** plain tabular numbers in `muted`, or in `pending` when something needs attention, instead of colored pill badges.
- **Icons:** lucide icons at `strokeWidth={1.5}`, never inside filled circles.

## Step 5 — Sweep the existing code onto the tokens

On an existing site, first replace classes mechanically across every `.tsx`/`.ts` file (skip tests), then redesign screen by screen. A find-and-replace script makes the first pass fast and consistent.

| Old pattern | Replace with |
| --- | --- |
| Hard-coded hex classes, e.g. `text-[#202124]`, `bg-[#6D4627]`, `border-[#DADCE0]` | The nearest token: `text-ink`, `bg-brand`, `border-line` |
| `bg-white` | `bg-surface` |
| `text-white` | `text-surface` |
| `bg-black/40` (overlays) | `bg-ink/40` |
| `shadow`, `shadow-md`, `shadow-lg` … | Remove |
| `font-bold`, `font-semibold` | `font-medium` |
| Bare `rounded` | `rounded-sm` |
| Colored status pills | `bg-{status}-wash text-{status} border-{status}-line` |

- **Third-party brand marks stay untouched.** The Microsoft sign-in button keeps its official white button, `#8C8C8C` border and logo colors; skip any line that holds them.
- **Shared color lists:** also update colors defined in data, such as the rich-text editor's text-color palette and the status-to-class map in `labels.ts`.
- **Then redesign each screen** with the kit, using this order:
  1. Swap the title area for `PageHeader`.
  2. Replace card grids with `HairlineGrid`.
  3. Replace boxed sections with top rules.
  4. Replace pill tabs with `Segmented`.

After the sweep, search for any remaining `#` hex values, `shadow` and `bg-white` to confirm nothing was missed.

## Step 6 — Mobile

Every role must be able to do everything on a phone, so mobile layouts keep all actions, not a reduced set. Design for widths of 320, 360, 375, 390, 412 and 430px, phone landscape, and 768px tablets.

- **Viewport and safe areas:** use `<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">`, then pad edge elements with `env(safe-area-inset-*)`, for example `pt-[env(safe-area-inset-top)]` on the top bar and `pb-[calc(0.75rem+env(safe-area-inset-bottom))]` on sticky footers.
- **Heights:** use `dvh` instead of `vh` (`h-dvh`, `max-h-[92dvh]`) so the browser bar does not cut content off.
- **Tap targets:** at least 44px tall for primary controls (`min-h-11`) and 40px for secondary ones (`min-h-10`, `w-10 h-10`).
- **No iOS zoom on inputs:** keep form text at 16px on touch screens:

```css
@media (pointer: coarse) {
  input:not([type="checkbox"]):not([type="radio"]):not([type="range"]),
  select, textarea, [contenteditable="true"] { font-size: 16px !important; }
}
```

- **Tables become cards** below the breakpoint where they stop fitting (`xl` for work orders, `lg` for people). Cards sit in a hairline grid and keep the edit and delete actions as a bottom row.
- **Dialogs become sheets:** large forms open full-screen on phones (`h-dvh sm:h-auto`) with the action buttons in a sticky footer; small dialogs slide up from the bottom (`items-end sm:items-center`).
- **Side menu drawer:** make the drawer exactly as wide as its content (`w-[min(18rem,85vw)]`). A fixed-width wrapper around narrower content leaves an empty band beside the menu, which was the original bug on this site.
- **No sideways page scroll:** add `min-w-0` to flex children that hold selects or long text, and `overflow-x-hidden` on the main column. Strips that must scroll sideways (tabs) bleed to the screen edge with `-mx-4 px-4` and hide their scrollbar.
- **Short landscape screens:** let the whole sidebar scroll (`overflow-y-auto`) so the navigation never squeezes to zero height.

## Step 7 — Verify, and avoid the known pitfalls

Check each screen in the browser's device emulation before calling the work done.

- [ ] Every tab at 320, 360, 390, 412 and 768px, phone landscape (932×430), and 1440px desktop
- [ ] No sideways scroll: `document.documentElement.scrollWidth` equals the window width on every tab
- [ ] Every role (staff, supervisor, admin) can reach all of its actions on a phone
- [ ] Dialogs open as sheets on phones, and their footers sit above the home bar
- [ ] No leftover hex values, shadows or `bg-white` in components
- [ ] Type check, production build and unit tests pass

Problems met on this site, and their fixes:

| Symptom | Cause | Fix |
| --- | --- | --- |
| `[&_th]:kl-label` does nothing | The label was defined in `@layer components` | Define it with `@utility` |
| Some corners still look rounded | Bare `rounded` is outside the radius scale | Replace it with `rounded-sm` |
| Text in grid-cell buttons sits in the middle | Browsers center `<button>` content vertically | Add `flex flex-col justify-start` |
| A select pushes the row off-screen at 320px | A select keeps its natural width inside flex | Add `min-w-0` |
| The editor toolbar covers the sticky footer | Both are sticky; the toolbar has `z-10` | Give the footer `z-20` |
| Navigation disappears in landscape | The nav was the only flexible part of a fixed-height column | Make the whole sidebar scroll |
| Labels truncate in narrow metric tables | Two columns are too tight on phones | Use one column, with `whitespace-nowrap` on values |
