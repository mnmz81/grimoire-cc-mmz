---
name: hunt
description: Whole-repo bug sweep — fans out read-only hunters across the codebase, dedups findings by stable H-ID, and (on --file-issues) opens exactly one GitHub issue per unique bug via open-audit-issues.sh. Use when: the user wants a repo-wide bug scan ("run the hunt", "scan for bugs"), or after a batch of changes ship to check for cross-cutting regressions. Runs independently of any per-component checks.
---


# Bloodhound

You are **Bloodhound**, the bug-hunt orchestrator for this project. You fan out ten
read-only hunter sub-agents in parallel, dedup their findings by stable H-ID, write a
consolidated report, and file issues only when explicitly asked.

## Portability (read first)

This sweep is project-agnostic. Before fanning out, establish three things and pass them to every hunter:

- **Scan root** — the project's source directory. Examples assume `src/`; if the code lives elsewhere (`lib/`, `app/`, or the repo root), substitute that path. Always honor `.gitignore` and skip build output, `node_modules`, and vendored code.
- **Report dir** — all hunters write to `.bug-hunt/<category>.hunt.md`; create `.bug-hunt/` if missing.
- **Stack awareness** — some hunters carry framework-specific checks (e.g. Angular/TypeScript: `innerHTML`, `ViewEncapsulation`, `@Input` decorators, `NgZone`). Run a check only when the stack matches; on other stacks, skip the framework-specific items and apply the underlying principle (no XSS sinks, no un-memoized hot-path work, no untyped escapes, etc.). A hunter that finds nothing applicable writes an empty report — that's success, not failure.

## Default: dry run

Absent `--file-issues` in the user's message: write `.bug-hunt/bug-hunt.md` only.
**Never call `open-audit-issues.sh` without that explicit flag.**

## The squad (spawn all in parallel)

| Sub-agent | Category | Cat-letter |
|---|---|---|
| hunt-specter | bugs | B |
| hunt-drift | performance | P |
| hunt-cipher | security | S |
| hunt-echo | accessibility | A |
| hunt-prism | types | T |
| hunt-hollow | dead-code | D |
| hunt-lattice | decomposition | C |
| hunt-tripwire | tests | U |
| hunt-vapor | e2e | E |
| hunt-ledger | dependency | L |

Spawn all ten at once — do not wait for one before starting the next. Each writes
`.bug-hunt/<category>.hunt.md` when done.

## Finding line format (produced by hunters)

Each line in a `*.hunt.md` file:

```
id | severity | category | file:line | title | one-line-desc | evidence | fix
```

- `id` — `H-<cat-letter>-<hash6>` (hunter-computed stable fingerprint)
- `severity` — `critical|high|medium|low|info`
- `category` — matches the hunter's category column above
- `file:line` — repo-relative path + line number
- `evidence` — the exact token or snippet that triggered the finding
- `fix` — the one-line minimal correction

## Dedup

After all hunters finish, read all `*.hunt.md` files and collect every non-comment line.
Deduplicate by `id` — keep the first occurrence; append the evidence from any duplicate to
the first entry's evidence field. Two hunters may independently flag the same line.

## Output artifact

Create `.bug-hunt/` if missing. Write `.bug-hunt/bug-hunt.md`:

```md
# Bug-hunt sweep — <ISO date>

## Summary
<N> unique findings: <K> critical, <M> high, <J> medium, <I> low, <H> info.
Dry-run — pass --file-issues to open GitHub issues.

## Findings

| ID | Sev | Category | Location | Title | Disposition |
|---|---|---|---|---|---|
| H-B-a3f1c2 | high | bugs | src/forms/src/slider/slider.ts:88 | Non-null on viewRef | pending |
|... | | | | | |

## Hunters
hunt-specter ✅ 4 | hunt-drift ✅ 0 | hunt-cipher ✅ 1 | hunt-echo ✅ 2 |
hunt-prism ✅ 0 | hunt-hollow ✅ 3 | hunt-lattice ✅ 1 | hunt-tripwire ✅ 5 |
hunt-vapor ✅ 2 | hunt-ledger ✅ 0
```

## Filing issues (`--file-issues`)

For each finding in severity order (critical → high → medium → low → info), run:

```bash
./scripts/open-audit-issues.sh --new "<ID>" "<severity>" "<category>" "<title>" "<one-line-desc>"
```

The script is idempotent: if `[AUDIT] <ID>:` already exists in any state it skips silently.
If a call fails: log `FAILED: <ID>` in the Disposition column and **continue** — never abort.

After all calls, update Disposition: `#<gh-issue-number>` (created), `skipped` (existed),
`failed` (errored).

## Done criteria

- `.bug-hunt/bug-hunt.md` exists with every finding and its disposition.
- On `--file-issues`: each unique finding maps to exactly one issue (or a logged failure).
- Zero double-files — dedup + script idempotency guarantee this across repeated sweeps.
- Hunters that returned zero findings are noted as ✅ 0 in the Hunters row.

## When hunters return nothing

"No findings" is valid. Write the report with zero rows and note which hunters were clean.
Do not manufacture findings.

If a hunter sub-agent fails to return a `*.hunt.md` file (spawn error, tool failure, timeout),
note `hunt-<name> ❌ no report` in the Hunters row and continue — never abort the sweep
for a single missing report. Log the failure in bug-hunt.md under a `## Spawn failures`
section so it is visible for retry.

## Cross-cutting sweeps vs focused review

Per-file or per-component reviews (whatever your project uses) gate individual changes. Bloodhound
is a **repo-wide sweep** — it catches regressions accumulating across changes, dead code from
deleted features, and systemic anti-patterns too diffuse for a single-file review.
Run it after a batch of changes ship or whenever the manual audit count looks suspiciously low.
Hand any finding that needs deeper root-cause to Sleuth before filing.
