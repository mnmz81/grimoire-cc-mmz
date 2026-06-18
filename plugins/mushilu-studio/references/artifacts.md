# Studio artifact contract (`.mui-team/`)

Every Studio stage coordinates through files under `.mui-team/` in the target repo — a
filesystem blackboard. This is the hand-off contract: a stage's only input is the artifact(s)
the previous stage wrote, so any stage can run (and be validated) standalone. The directory
name is configurable (`teamDir` in `.studio/config.json`, default `.mui-team`); see
[`config.md`](./config.md).

## Layout

```
.mui-team/
  briefs/<component>.brief.md         # Compass   — verdict, group, minimal API, open questions
  specs/<component>.spec.md           # Blueprint — locked contract: selector, signal API, a11y/test matrix, bundle headroom
  reports/<component>.build.md        # Foreman   — 9-step build status
  reports/<component>.style.md        # Palette   — token/contrast/motion verdict (agent)
  reports/<component>.a11y.md         # Sentinel-A11y — per-gate verdict; may say BLOCKING (agent)
  reports/<component>.review.md       # Staff     — blocking/should-fix/nit findings (agent)
  reports/<component>.size.md         # Gauge     — measured KB vs group budget (agent)
  reports/<component>.test.md         # Marshal   — vitest result + coverage
  reports/<component>.qa.md           # Prowler   — browser/Storybook QA + regression tests
  reports/<component>.pipeline.md     # Conductor — one-line status dashboard per stage
  release-readiness.md                # Quartermaster — gate checklist, ci-verify result, PR URL
  learnings.md                        # all stages append; Curator dedupes/graduates
  freeze                              # Warden marker — a dir path; edits outside it are denied
```

## Who writes / who reads

| Artifact | Writer | Readers |
| --- | --- | --- |
| `briefs/<c>.brief.md` | Compass | Blueprint |
| `specs/<c>.spec.md` | Blueprint | Foreman, Staff, Gauge |
| `reports/<c>.build.md` | Foreman | Conductor |
| `reports/<c>.{style,a11y,review,size}.md` | Palette / Sentinel-A11y / Staff / Gauge (agents) | Conductor (reconcile), Quartermaster (gate) |
| `reports/<c>.{test,qa}.md` | Marshal / Prowler | Conductor, Quartermaster |
| `reports/<c>.pipeline.md` | Conductor | the user (dashboard) |
| `release-readiness.md` | Quartermaster | the user |
| `learnings.md` | every reviewer + the hunt squad (append) | Curator |
| `freeze` | Warden | the project's PreToolUse freeze hook |

## Finding-line format (review/audit reports)

Review and audit reports use one finding per line so the dashboard and Quartermaster can parse
them without re-reading prose. This is the same shape the bug-hunt squad uses
(`bug-hunting/references/hunter-core.md`); keep them aligned:

```
<verdict> | <area>:<file>:<line> | <title> | <fix>
```

- `verdict` — `PASS | FAIL | WARN | BLOCK` (Sentinel-A11y `BLOCK` stops the line; Gauge over-budget stops it).
- Staff groups findings as `blocking | should-fix | nit`.

## Validation rule

A stage that finds its required input artifact missing must say so and route back to the owning
stage — it must never fabricate a downstream green. "No artifact yet" is a valid, explicit state.
