---
name: hebrew-rtl-layout
description: >
  Make web UIs work right-to-left for Hebrew, Angular first — dir/lang on
  <html>, CSS logical properties instead of left/right, :dir(rtl) overrides in
  component styles, bidi isolation for numbers, emails, code and user content,
  which icons to mirror, Angular CDK/Material direction (Directionality, the
  Dir directive, dialogs and overlays), RTL scroll math, Hebrew fonts and
  typography, and how to verify. Use when building or fixing a Hebrew or RTL
  screen, when layout, icons, popovers or mixed Hebrew-English text land on
  the wrong side, or when converting an LTR stylesheet to RTL-ready CSS.
  Plurals, dates and currency formatting go to hebrew-i18n.
---

# Hebrew RTL Layout

Build direction-agnostic UI: one stylesheet that is correct in both
directions because it describes *start* and *end*, not *left* and *right*.
Then patch the few things that do not flip by themselves.

## 1. One source of truth for direction

Set `<html lang="he" dir="rtl">`. The attribute — not CSS `direction` —
drives the browser's bidi algorithm, logical properties, scrollbar side, form
controls and assistive technology. Never set direction only on `body` or a
wrapper `div`.

**Angular CDK reads it once.** The root `Directionality` service (from
`@angular/cdk/bidi`) takes its value from `body` or `html` `dir` when it is
created and never re-reads it. If the language can change without a page
reload, also bind direction on a root container with the CDK `Dir`
directive, which provides `Directionality` to everything beneath it and emits
on change:

```ts
import { Component, computed, inject } from '@angular/core';
import { Dir } from '@angular/cdk/bidi';
import { RouterOutlet } from '@angular/router';
import { LanguageService } from './language.service';

@Component({
  selector: 'app-root',
  imports: [Dir, RouterOutlet],
  template: `<div class="app-shell" [dir]="dir()"><router-outlet /></div>`,
})
export class AppComponent {
  private readonly language = inject(LanguageService);
  protected readonly dir = computed(() => (this.language.current() === 'he' ? 'rtl' : 'ltr'));
}
```

Keep updating `document.documentElement.dir` as well, for native controls and
anything outside the Angular tree.

In code, read direction from the injected service, never from the DOM:
`inject(Directionality).valueSignal()` (recent CDK) or `.value`.

## 2. Logical properties instead of physical ones

| Physical | Logical |
|----------|---------|
| `margin-left` / `margin-right` | `margin-inline-start` / `margin-inline-end` |
| `padding-left` / `padding-right` | `padding-inline-start` / `padding-inline-end` |
| `border-left` / `border-right` | `border-inline-start` / `border-inline-end` |
| `left` / `right` | `inset-inline-start` / `inset-inline-end` |
| `border-top-left-radius` | `border-start-start-radius` |
| `border-top-right-radius` | `border-start-end-radius` |
| `text-align: left` / `right` | `text-align: start` / `end` |
| `float: left` / `right` | `float: inline-start` / `inline-end` |
| `width` / `height` (when it follows text flow) | `inline-size` / `block-size` |

Flexbox and grid already follow `dir`: `flex-direction: row` and grid line 1
start on the right in RTL. Do **not** add `row-reverse` "for RTL" — it flips
the layout back to LTR order.

Enforce it with a linter rule that rejects physical properties (for example
`stylelint-use-logical`) so they do not creep back.

## 3. What does not flip — and how to patch it

These stay physical in RTL: `transform: translateX()` and slide-in keyframes,
`box-shadow` / `text-shadow` x-offsets, `linear-gradient(to right …)`,
`background-position`, `transform-origin`, SVG and canvas drawings, charts,
and `scrollLeft`.

Patch them with `:dir(rtl)`. It matches the *computed* direction (including
inherited and `dir="auto"`), so it works directly inside Angular component
styles without `:host-context`:

```css
.drawer { transform: translateX(-100%); }
.drawer:dir(rtl) { transform: translateX(100%); }

.card { box-shadow: 4px 4px 12px rgb(0 0 0 / 0.12); }
.card:dir(rtl) { box-shadow: -4px 4px 12px rgb(0 0 0 / 0.12); }
```

`:dir()` is Baseline since late 2023 (Chrome/Edge 120, Safari 16.4, Firefox
long before). For older targets, add a `[dir='rtl'] .drawer` fallback.

For charts, use the chart library's own reverse/RTL option — CSS cannot flip
an axis.

## 4. Bidirectional text

Hebrew letters are right-to-left, Latin letters left-to-right, digits are
weak and neutral characters (spaces, punctuation, `+`, `-`, `/`) take
direction from their neighbours. Trouble starts where they meet.

| Content | Do this |
|---------|---------|
| User content of unknown language (names, comments, search terms) | `<bdi>…</bdi>` — isolates it and auto-detects its direction |
| Known LTR value: phone with spaces or `+972`, email, URL, IBAN, code, file path | `<span dir="ltr">…</span>` (isolates and sets LTR) |
| Paragraphs of user-written text | `unicode-bidi: plaintext` — each paragraph picks its own base direction |
| `Intl` / Angular-pipe output (currency, dates) | Isolate (`<bdi>` or `unicode-bidi: isolate`) but do **not** force `dir="ltr"` — the string carries its own RTL marks and forcing LTR moves `₪` to the wrong side |
| English term inside Hebrew prose | `<span lang="en" dir="ltr">` — `lang` tells screen readers to switch voice |

Never use `unicode-bidi: bidi-override` or `<bdo>` on mixed content: they
disable the bidi algorithm and render Latin words letter-reversed.

`050-1234567` renders fine on its own; `+972 50 123 4567` reorders into
nonsense unless isolated. Check the real format before blaming bidi.

Set this once in the global stylesheet so technical content never inherits
RTL:

```css
code, pre, kbd, samp { direction: ltr; unicode-bidi: isolate; }
```

**Form fields:**

- Free text (`<textarea>`, name, search): `dir="auto"`. It follows the first
  strong character the user types; the placeholder does not affect it.
- Email and URL: `dir="ltr"` — most values are Latin, and `auto` would flip
  mid-typing for a Hebrew-script address. Accept that a Hebrew placeholder
  then aligns left, or style the placeholder separately.
- `type="tel"` is already LTR by default; leave `dir` off.
- Interpolated values in templates: `שלום, <bdi>{{ user.name }}</bdi>`.

## 5. Icons: mirror meaning, not everything

Mirror icons whose meaning follows reading direction:

- back / forward, previous / next, breadcrumb chevrons, carousel and
  pagination arrows
- "send" arrows, reply and indent/outdent icons, list-nesting arrows
- progress or stepper arrows that imply forward motion

Never mirror:

- logos, brand marks, and icons containing text
- checkmarks, close (×), plus, search magnifier, settings gear
- media controls (play points along the timeline, not the reading direction)
- clocks and refresh/rotate icons (clockwise is universal)
- real-world objects with a fixed orientation

```css
.icon-directional:dir(rtl) { transform: scaleX(-1); }
```

Use a horizontal flip, not `rotate(180deg)` — rotation also turns the icon
upside down. With `mat-icon` and Material Symbols, add the class to the
directional ones; nothing flips automatically.

## 6. Angular CDK and Material

- Material components (form fields, slider, tabs, paginator, sidenav, menu,
  select) take direction from the nearest `Directionality`. With §1 in place
  they mirror on their own.
- **Overlays render under `<body>`**, outside your `[dir]` container.
  Connected overlays (menu, select, autocomplete, tooltip) pick up direction
  from the trigger's injector. Global ones (dialog, bottom sheet, snack bar,
  custom `Overlay.create`) should receive it explicitly when direction can
  change at runtime:

  ```ts
  private readonly dir = inject(Directionality);

  open(): void {
    this.dialog.open(EditDialogComponent, { direction: this.dir.valueSignal() });
  }
  ```

  `OverlayConfig.direction` accepts a `Direction` or the `Directionality`
  instance itself.
- **Scrolling:** in RTL, `scrollLeft` is `0` at the start (right edge) and
  goes negative toward the end. Code like `el.scrollLeft += 300` or
  `Math.max(0, …)` breaks. Use `CdkScrollable`, whose
  `scrollTo({ start: … })` and `measureScrollOffset('start')` handle RTL, or
  `el.scrollBy({ left: isRtl ? -delta : delta })`.

## 7. Hebrew typography

```css
:root {
  --font-hebrew-sans: 'Heebo', 'Assistant', 'Rubik', 'Noto Sans Hebrew', 'Arial Hebrew', sans-serif;
  --font-hebrew-serif: 'Frank Ruhl Libre', 'David Libre', 'Noto Serif Hebrew', serif;
}
html:lang(he) body { font-family: var(--font-hebrew-sans); line-height: 1.6; }
```

- When self-hosting fonts, ship the `hebrew` subset; a Latin-only subset
  falls back to a system font for every Hebrew glyph. Monospace fonts often
  lack Hebrew — check the subset before using one for code with Hebrew
  comments.
- Hebrew needs more line height than Latin, and pointed text (nikud) needs
  more again — a tight line-height clips the vowel marks. Test pointed text in
  the actual font; some fonts ship letters without nikud glyphs.
- Hebrew has no letter case. `text-transform: uppercase` does nothing to
  Hebrew but still shouts Latin words in the same label — remove it from
  shared components in the Hebrew theme.
- Keep `letter-spacing: normal` on running text; tracking is a deliberate
  emphasis device in Hebrew, not a default.

## 8. Verify before shipping

1. Switch the app to `he` and look for anything that did not move — it is
   still using a physical property.
2. Paste one stress string into every text surface, input and table cell:
   `שלום John, הזמנה A-1043 ב־1,234.50 ₪, טל׳ +972 50-123-4567`
3. Open every dialog, menu, tooltip, snack bar and date picker.
4. Check sticky/fixed chrome, drawers, carousels, charts and anything
   animated horizontally.
5. Automate it: render key pages in both directions with Playwright and
   compare screenshots, so a reintroduced `margin-left` shows up in CI.
