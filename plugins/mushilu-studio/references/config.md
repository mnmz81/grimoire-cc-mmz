# Studio configuration (`.studio/config.json`)

The Studio stages were written for one project (`@mushilu-san/ui`: Angular, zoneless, `--mui-*`
tokens, `src/` layout, `.mui-team/` artifacts). Those are the **seams that vary per project**.
Rather than hardcode them in fifteen skill bodies, a stage reads them from a single
`.studio/config.json` at the target repo root and falls back to the documented defaults when a
key (or the file) is absent. This is what lets the pipeline target a different stack without
editing the skills.

## Schema

```jsonc
{
  "scanRoot": "src",            // where component source lives (lib/, app/, packages/*/src…)
  "teamDir": ".mui-team",       // artifact blackboard dir (see artifacts.md)
  "stack": "angular",           // angular | react | vue | svelte | … — gates framework-specific checks
  "tokenPrefix": "--mui-",      // design-token namespace Palette enforces
  "coverageMin": 80,            // Marshal's minimum % line coverage
  "touchTargetPx": 44,          // Sentinel-A11y minimum interactive hit area
  "bundleGroups": {             // Gauge's per-entry-point KB budgets
    "primitives": 8, "forms": 12, "layout": 7, "navigation": 8,
    "feedback": 9, "data-display": 10, "mobile": 8, "overlays": 10
  },
  "ciVerify": "scripts/ci-verify.sh"   // target-repo CI-parity script Quartermaster runs (optional)
}
```

## Defaults (when a key is missing)

`scanRoot=src`, `teamDir=.mui-team`, `stack=angular`, `tokenPrefix=--mui-`, `coverageMin=80`,
`touchTargetPx=44`, `bundleGroups` as above, `ciVerify` unset (run `npm ci → lint → test →
build` directly and note no script was present).

## How stages apply it

- **Stack-specific checks degrade gracefully.** When `stack` ≠ `angular`, skip the
  framework-specific rule (`@Input` decorators, `NgZone`, `ViewEncapsulation`, signal APIs) and
  apply the underlying principle instead — no XSS sink, no un-memoized hot-path work, visible
  focus ring, ≥`touchTargetPx` targets, token discipline against `tokenPrefix`. The
  bug-hunt squad already states this rule in `bug-hunting/references/hunter-core.md`; the Studio
  follows the same convention so the two stay consistent.
- **Paths come from config, not literals.** Read `scanRoot`/`teamDir` rather than assuming
  `src/` and `.mui-team/`. The grep examples in each stage use `src/` only as an illustration.
- **Budgets and thresholds are data.** Gauge reads `bundleGroups`, Marshal reads `coverageMin`,
  Sentinel-A11y reads `touchTargetPx` — none are baked into the prose as the single legal value.

A project that ships no `.studio/config.json` behaves exactly as before (the defaults are the
original Mushilu-San-UI values), so this is backward-compatible.
