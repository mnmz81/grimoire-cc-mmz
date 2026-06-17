---
name: ui-ux-design
description: "UI/UX design intelligence for web and mobile. Use when building or reviewing pages, components, dashboards, landing pages, forms, navigation, charts, or any visual interface. Covers accessibility, touch targets, performance, style selection, layout, typography, animation, forms, navigation patterns, and data visualization across React, Next.js, Vue, Svelte, Tailwind, shadcn/ui, React Native, Flutter, SwiftUI, and HTML/CSS."
allowed-tools: [Read, Grep, Glob, Bash, Edit, Write]
---

# UI/UX Design Intelligence

Comprehensive design guide for web and mobile. Apply whenever a task changes how a feature **looks, feels, moves, or is interacted with**.

## When to Apply

**Must use:**
- Designing new pages (Landing Page, Dashboard, Admin, SaaS, Mobile App)
- Creating or refactoring UI components (buttons, modals, forms, tables, charts)
- Choosing color schemes, typography systems, spacing, or layout systems
- Reviewing UI code for UX, accessibility, or visual consistency
- Implementing navigation structures, animations, or responsive behavior
- Making product-level design decisions (style, information hierarchy, brand expression)

**Skip:**
- Pure backend logic, API/database design, infrastructure, DevOps, non-visual scripts

---

## Rule Priority Order

| Priority | Category | Impact |
|----------|----------|--------|
| 1 | Accessibility | CRITICAL |
| 2 | Touch & Interaction | CRITICAL |
| 3 | Performance | HIGH |
| 4 | Style Selection | HIGH |
| 5 | Layout & Responsive | HIGH |
| 6 | Typography & Color | MEDIUM |
| 7 | Animation | MEDIUM |
| 8 | Forms & Feedback | MEDIUM |
| 9 | Navigation Patterns | HIGH |
| 10 | Charts & Data | LOW |

---

## Rule Conflicts & Priorities

When rules from different categories conflict, use this tie-breaker order:

**Accessibility beats everything.** If a performance optimization removes keyboard access or drops contrast below 4.5:1, the optimization loses. No exception.

**Reduced motion beats animation timing.** When `prefers-reduced-motion: reduce` is set, skip all transitions and animations regardless of the 150–300ms timing guidance.

**Touch target size beats visual density.** A 44×44pt tap target that looks large on a compact layout is always preferred over a smaller target that "fits" better. Expand hit areas with padding instead of shrinking the target.

**Platform idioms beat cross-platform consistency.** An iOS-style bottom sheet on Android is always wrong, even if it matches the web version. When building cross-platform, implement per-platform variants rather than forcing a single pattern.

**Content legibility beats layout compactness.** If meeting the 60–75 char line-length guideline requires a layout change, make the change. Readable text is non-negotiable.

**When performance and aesthetics conflict,** degrade the visual (reduce blur, simplify animation, drop shadow) before degrading performance (CLS, LCP, input latency).

---

## 1. Accessibility (CRITICAL)

*WCAG defines the floor for who can use your product. These rules exist because roughly 15–20% of users have a disability that affects how they interact with digital interfaces.*

- Minimum 4.5:1 contrast ratio for normal text — the WCAG AA threshold; below this, low-vision users cannot read the text
- Large text (≥18pt / ≥14pt bold) minimum 3:1 — larger glyphs are easier to resolve at lower contrast
- Visible focus rings on interactive elements (2–4px) — keyboard-only users have no other way to know where they are
- Descriptive alt text for meaningful images — screen readers skip or misread images without it
- `aria-label` for icon-only buttons — an icon alone has no accessible name
- Tab order matches visual order; full keyboard support — mismatched order disorients screen reader users
- Use `<label>` with `for` attribute on all inputs — associates label to control for click-targeting and screen readers
- Skip-to-main-content link for keyboard users — prevents forcing keyboard users to tab through every nav item on every page
- Sequential h1→h6, no level skips — heading hierarchy is the primary navigation mechanism for screen reader users
- Never convey information by color alone (add icon/text) — ~8% of men have color vision deficiency
- Support system text scaling; avoid truncation as text grows — users with low vision commonly set text to 200%+
- Respect `prefers-reduced-motion`; reduce/disable animations — vestibular disorders make motion-heavy UIs physically nauseating
- Meaningful `accessibilityLabel`/`accessibilityHint`; logical reading order for screen readers
- Provide cancel/back in modals and multi-step flows — trapping a screen reader user in a modal with no exit is a critical failure
- Preserve system and a11y keyboard shortcuts

## 2. Touch & Interaction (CRITICAL)

*Touch targets exist for human fingers, not pixel-perfect cursors. The rules below prevent the most common mobile usability failures.*

- Min 44×44pt (Apple HIG) / 48×48dp (Material) — derived from average adult fingertip contact area; smaller targets produce ~40% more mis-taps
- Minimum 8px gap between touch targets — adjacent targets without a gap get hit together
- Use click/tap for primary interactions; don't rely on hover alone — hover doesn't exist on touch screens
- Disable button during async ops; show spinner or progress — prevents duplicate submissions and signals system state
- `cursor: pointer` on clickable elements — communicates interactivity on desktop
- Avoid horizontal swipe on main content; prefer vertical scroll — horizontal swipes conflict with system navigation gestures
- `touch-action: manipulation` to reduce 300ms tap delay — eliminates the double-tap zoom delay on older browsers
- Don't block system gestures (Control Center, back swipe) — overriding system gestures breaks user expectations and may violate platform guidelines
- Visual feedback on press (ripple/highlight) — confirms the tap registered; absence feels broken
- Keep primary touch targets away from notch, Dynamic Island, gesture bar — these areas are intercepted by the OS
- Swipe actions must show clear affordance or hint — invisible swipe actions are never discovered by new users
- Use movement threshold before starting drag to avoid accidental drags

## 3. Performance (HIGH)

*Performance is a UX feature. A 1-second delay in page response causes ~7% drop in conversions; 3s causes ~53% of mobile users to abandon.*

- Use WebP/AVIF, responsive images (`srcset/sizes`), lazy load non-critical assets — images are typically 50–70% of page weight
- Declare `width`/`height` or `aspect-ratio` to prevent layout shift (CLS) — CLS is one of Core Web Vitals; unexpected shifts cause mis-taps
- `font-display: swap` to avoid invisible text (FOIT) — text is invisible until the font loads without this
- Preload only critical fonts — over-preloading blocks other critical resources
- Lazy load non-hero components via dynamic import / route-level splitting
- Load third-party scripts `async`/`defer`
- Avoid frequent layout reads/writes; batch DOM reads then writes — interleaving causes layout thrashing (forced reflows)
- Virtualize lists with 50+ items — rendering thousands of DOM nodes locks the main thread
- Keep per-frame work under ~16ms for 60fps
- Use skeleton screens / shimmer for >1s operations — perceived wait time is lower with a skeleton than a spinner
- Keep input latency under ~100ms for taps/scrolls — above 100ms users perceive lag as a system fault
- Debounce/throttle high-frequency events (scroll, resize, input)
- Offer degraded modes for slow networks

## 4. Style Selection (HIGH)

*Visual consistency is a trust signal. Inconsistency — mixed icon styles, mismatched radii, arbitrary shadows — reads as unfinished.*

- Match style to product type and industry — a medical app and a gaming app need different visual languages
- Use same style across all pages — inconsistency within a product erodes trust
- Use SVG icons (Heroicons, Lucide), not emojis — emojis render differently across OSes and look unprofessional in UI controls
- Choose color palette from product/industry context
- Shadows, blur, radius aligned with chosen style
- Respect platform idioms (iOS HIG vs Material) — users have deeply ingrained platform expectations
- Make hover/pressed/disabled states visually distinct — state changes must be perceivable without relying on memory
- Use consistent elevation/shadow scale for cards, sheets, modals
- Design light/dark variants together — designing one then adapting the other creates mismatched contrast and token drift
- Use one icon set/visual language across the product
- Each screen should have only one primary CTA; secondary actions visually subordinate — multiple CTAs of equal weight force decision paralysis
- Use blur to indicate background dismissal (modals, sheets), not as decoration

## 5. Layout & Responsive (HIGH)

*Mobile-first is not a trend — it's a constraint. Most web traffic is mobile; design for that context first, then expand.*

- `<meta name="viewport" content="width=device-width, initial-scale=1">` — never disable zoom; zoom is an accessibility feature for low-vision users
- Design mobile-first, then scale up
- Systematic breakpoints (375 / 768 / 1024 / 1440)
- Minimum 16px body text on mobile — below 16px, iOS auto-zooms input fields, breaking the layout
- Mobile 35–60 chars per line; desktop 60–75 chars — beyond 75 chars the eye loses the line on return
- No horizontal scroll on mobile
- 4pt/8dp incremental spacing system — consistent rhythm makes layouts feel intentional
- Consistent `max-width` on desktop (max-w-6xl / 7xl)
- Define layered z-index scale (e.g. 0 / 10 / 20 / 40 / 100 / 1000) — ad-hoc z-indexes create stacking conflicts that are hard to debug
- Fixed navbar/bottom bar must reserve safe padding for underlying content
- Prefer `min-h-dvh` over `100vh` on mobile — `100vh` doesn't account for the browser chrome on mobile
- Keep layout readable and operable in landscape mode
- Show core content first on mobile; fold or hide secondary content

## 6. Typography & Color (MEDIUM)

*Typography is the primary carrier of meaning. Color reinforces it — but never replaces it.*

- Line-height 1.5–1.75 for body text — below 1.5 lines feel cramped; above 1.75 lines lose connection
- Limit lines to 65–75 characters
- Match heading/body font personalities — a slab serif heading with a geometric sans body creates tension
- Consistent type scale (e.g. 12 14 16 18 24 32)
- Define semantic color tokens (primary, secondary, error, surface, on-surface) — not raw hex in components; tokens allow theming and auditing
- Dark mode uses desaturated/lighter tonal variants, not inverted colors — inverted colors produce harsh, high-saturation backgrounds
- Foreground/background pairs must meet 4.5:1 (AA) or 7:1 (AAA)
- Functional color (error red, success green) must include icon/text — color alone fails color-blind users
- Use tabular/monospaced figures for data columns, prices, timers — proportional figures shift column widths as values change
- Use font-weight to reinforce hierarchy: Bold headings (600–700), Regular body (400), Medium labels (500)

## 7. Animation (MEDIUM)

*Animation communicates cause and effect. Every animation should answer: "what just happened and why?"*

- 150–300ms for micro-interactions; complex transitions ≤400ms; avoid >500ms — humans perceive >500ms as a system pause, not a designed transition
- Animate `transform`/`opacity` only; never `width`/`height`/`top`/`left` — non-composited properties trigger layout and paint, dropping frames
- Show skeleton or progress indicator when loading exceeds 300ms
- Animate 1–2 key elements per view max — animating everything creates visual noise and dilutes meaning
- `ease-out` for entering, `ease-in` for exiting — mimics natural deceleration/acceleration
- Every animation must express cause-effect, not just decoration
- State changes (hover / active / expanded / collapsed) should animate smoothly, not snap
- Page/screen transitions must maintain spatial continuity — where did the content come from?
- Respect `prefers-reduced-motion`
- Prefer spring/physics-based curves for natural feel
- Exit animations shorter than enter (~60–70% of enter duration) — exits should feel quick; users want to move on
- Stagger list/grid item entrance by 30–50ms per item
- Animations must be interruptible
- Never block user input during animation
- Forward navigation animates left/up; backward animates right/down

## 8. Forms & Feedback (MEDIUM)

*Forms are where users give you data. Every friction point directly reduces completion rate.*

- Visible label per input (not placeholder-only) — placeholders disappear on focus, leaving users without context mid-entry
- Show error below the related field — proximity makes the association unambiguous
- Loading then success/error state on submit
- Mark required fields (asterisk)
- Helpful message and action for empty states
- Auto-dismiss toasts in 3–5s; use `aria-live="polite"` for screen reader announcement
- Confirm before destructive actions
- Validate on blur (not keystroke); show error only after user finishes input — keystroke validation feels accusatory
- Use semantic input types (`email`, `tel`, `number`) to trigger correct mobile keyboard
- Provide show/hide toggle for password fields
- Use `autocomplete` / `textContentType` for autofill support
- Error messages must state cause + how to fix — "invalid input" tells the user nothing actionable
- After submit error, auto-focus the first invalid field
- For multiple errors, show summary at top with anchor links to each field
- Mobile input height ≥44px
- Destructive actions use semantic danger color (red) and are visually separated

## 9. Navigation Patterns (HIGH)

*Navigation is the skeleton of the product. Users build a mental model from it; inconsistency or unpredictability destroys trust.*

- Bottom navigation max 5 items; use labels with icons — beyond 5 items, the hierarchy is too flat and labels are essential for discoverability
- Use drawer/sidebar for secondary navigation, not primary actions
- Back navigation must be predictable and consistent; preserve scroll/state
- All key screens must be reachable via deep link / URL
- Navigation items must have both icon and text label
- Current location must be visually highlighted in navigation
- Modals and sheets must offer a clear close/dismiss affordance
- Web: use breadcrumbs for 3+ level deep hierarchies
- Navigating back must restore previous scroll position, filter state, and input
- Support system gesture navigation (iOS swipe-back, Android predictive back)
- Large screens (≥1024px) prefer sidebar; small screens use bottom/top nav
- Don't mix Tab + Sidebar + Bottom Nav at the same hierarchy level
- Modals must not be used for primary navigation flows
- After page transition, move focus to main content region for screen reader users
- Dangerous actions (delete account, logout) must be visually and spatially separated from normal nav items

## 10. Charts & Data (LOW)

*Charts communicate trends and comparisons. A chart that requires the user to decode it has failed its purpose.*

- Match chart type to data type (trend → line, comparison → bar, proportion → pie/donut)
- Use accessible color palettes; avoid red/green-only pairs — ~8% of men are red-green color blind
- Provide table alternative for accessibility; charts alone are not screen-reader friendly
- Supplement color with patterns/shapes so data is distinguishable without color
- Always show legend near the chart
- Provide tooltips/data labels on hover (web) or tap (mobile)
- Label axes with units and readable scale
- Charts must reflow or simplify on small screens
- Show meaningful empty state when no data exists
- Chart entrance animations must respect `prefers-reduced-motion`
- For 1000+ data points, aggregate or sample; provide drill-down
- Avoid pie/donut for >5 categories; switch to bar chart — humans are poor at comparing arc lengths beyond 5 slices
- Data lines/bars vs background ≥3:1; data text labels ≥4.5:1
- Interactive chart elements must be keyboard-navigable
- Provide a text summary or `aria-label` describing the chart's key insight for screen readers

---

## Icons & Visual Elements

| Rule | Standard | Avoid |
|------|----------|-------|
| No Emoji as Icons | Vector icons (Lucide, Heroicons, react-native-vector-icons) | Emojis (🎨 🚀 ⚙️) for navigation/controls |
| Vector-Only Assets | SVG or platform vector icons | Raster PNG icons |
| Consistent Icon Sizing | Define tokens (icon-sm, icon-md=24pt, icon-lg) | Mixing arbitrary values |
| Stroke Consistency | Consistent stroke width within same visual layer | Mixing thick/thin strokes |
| Filled vs Outline Discipline | One icon style per hierarchy level | Mixing filled and outline at same level |
| Touch Target Minimum | Min 44×44pt interactive area | Small icons without expanded tap area |
| Icon Contrast | 4.5:1 for small elements, 3:1 minimum for larger UI glyphs | Low-contrast icons |

---

## Pre-Delivery Checklist

See `references/checklists.md` for the full pre-delivery checklist. Run before marking any UI task complete.
