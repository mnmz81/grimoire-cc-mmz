# Pre-Delivery Checklist

Run before considering any UI/UX task complete. Every unchecked item is a regression risk.

## Visual Quality
- [ ] No emojis used as icons (SVG only)
- [ ] All icons from a consistent icon family and style
- [ ] Semantic theme tokens used consistently (no ad-hoc hardcoded colors)
- [ ] Pressed-state visuals do not shift layout bounds or cause jitter

## Interaction
- [ ] All tappable elements provide clear pressed feedback
- [ ] Touch targets meet minimum size (≥44×44pt iOS, ≥48×48dp Android)
- [ ] Micro-interaction timing 150–300ms with native easing
- [ ] Disabled states visually clear and non-interactive
- [ ] Screen reader focus order matches visual order; labels are descriptive
- [ ] No nested/conflicting gesture interactions

## Light/Dark Mode
- [ ] Primary text contrast ≥4.5:1 in both modes
- [ ] Secondary text contrast ≥3:1 in both modes
- [ ] Dividers/borders distinguishable in both modes
- [ ] Modal scrim opacity 40–60% black
- [ ] Both themes tested independently

## Layout
- [ ] Safe areas respected for headers, tab bars, and bottom CTA bars
- [ ] Scroll content not hidden behind fixed/sticky bars
- [ ] Verified on small phone, large phone, and tablet (portrait + landscape)
- [ ] 4/8dp spacing rhythm maintained
- [ ] Long-form text measure readable on larger devices

## Accessibility
- [ ] All meaningful images/icons have accessibility labels
- [ ] Form fields have labels, hints, and clear error messages
- [ ] Color is not the only indicator of meaning
- [ ] Reduced motion and dynamic text size supported without layout breakage
- [ ] Accessibility traits/roles/states (selected, disabled, expanded) announced correctly
- [ ] Keyboard navigation works fully; focus order is logical
- [ ] All interactive elements reachable and operable without a mouse
