# Angular CDK and Material in RTL

Load this when a Material or CDK component, overlay or scroll container misbehaves in RTL. Parent: `SKILL.md` §6.

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
