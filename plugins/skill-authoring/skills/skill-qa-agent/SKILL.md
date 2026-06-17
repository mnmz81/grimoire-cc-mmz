---
name: skill-qa-agent
description: Audit, grade, and improve Claude Code skills and Cursor .mdc rules, and find or resolve overlap between them. Use when reviewing a skill or rule for quality, grading a skill against a rubric, running a full library audit, gating a new skill before it ships, resolving redundancy or overlap between skills or rules, or improving an existing skill with a quality report.
metadata:
  counterpart: mdc:skill-qa
allowed-tools: [Read, Grep, Glob, Bash, Edit, Write, Task]
---

# Skill QA Agent

Audits, grades, and (with approval) improves the local skill/rule library
across two trees — Claude skills (`~/.claude/skills/*/SKILL.md`) and Cursor
rules (`~/.cursor/rules/*.mdc`). Scoring is anchored to a rubric so it is
low-variance and reproducible. Heavy logic lives in `scripts/`; grading
criteria live in `references/`.

## ⚠ Operating contract — read first, never bypass

1. **Always ask first.** Confirm scope and exact targets before any write. Never start an improvement, merge, split, deprecation, or reassignment on your own — not even drafting a proposal.
2. **Audits are read-only.** W1 audits and all three reports never edit a skill. They may run freely.
3. **Writes are double-gated.** Any change to a skill/rule needs two explicit approvals: **GATE 1** approve the plan/diff → apply → re-lint → **GATE 2** confirm the result. See W2.
4. **Snapshot before write.** Before touching any file, copy the original to `~/.claude/skill-qa/history/<name>/<timestamp>/`. No git — these snapshots are the only rollback. Mandatory, never skipped.
5. **Lint on edit.** Whenever you create or edit any skill/rule, immediately run `lint_skill.py` on it and report the JSON — the same Tier-1 gate W3 runs on new skills.

When an action is irreversible or risky, write the confirmation request in plain full sentences, not terse fragments.

## Tier model

| Tier | What | How |
|------|------|-----|
| 1 — Lint | Deterministic checks (~33 pts) | `python -m scripts.lint_skill --format <skill\|mdc> <path>` |
| 2 — Rubric | Judgment dimensions (~67 pts) | **You** read the file + `references/rubric.md` (or `rubric-mdc.md`) and grade **inline, twice** |
| 3 — Adjudicate | True overlap from candidate pairs | You read `candidate-pairs.json` + `references/overlap-playbook.md` and classify |

**Tier 2 double-grade:** grade each judgment dimension twice independently, average; if any dimension's passes differ by >2, do a third tiebreak pass and take the median. Record `double_grade_deltas`. Do not re-award points a Tier-1 check already failed.

**Tier 3 is interactive/agent-inline** for normal use. The headless scheduled audit (`install_schedule.py`) uses `scripts/score_judge.py` (calls `claude -p`) since no agent is in the loop.

## Scripts

All stdlib-only, cross-platform (Windows/macOS/Linux), run from this skill dir as `python -m scripts.<name>`. Use whichever of `python` / `python3` resolves to Python 3.10+ — try one, fall back to the other.

- `lint_skill.py --format {skill|mdc} <path>` → Tier 1 JSON.
- `inventory.py [--project-roots ...] [--changed-since-last-audit] [--out P]` → `skill-index.json`.
- `similarity.py --index <skill-index.json> [--threshold 0.30] [--out P]` → `candidate-pairs.json`.
- `score_judge.py` → headless Tier 2/3 via `claude -p` (scheduled audit only).
- `install_schedule.py [--time 03:00] [--day SUN] [--remove] [--dry-run]` → weekly audit job (Task Scheduler on Windows, crontab on macOS/Linux).

### Example — reading a lint result

`python -m scripts.lint_skill --format skill ~/.claude/skills/foo` →

```json
{"checks": [{"id": "broken_refs", "passed": false,
             "detail": "missing: references/rubric.md",
             "points_possible": 6, "points_awarded": 0}, "..."],
 "tier1_points_awarded": 27, "tier1_points_possible": 33}
```

Read it as: 27 of 33 scripted points; the lost 6 stay lost (never re-award a failed Tier-1 check in Tier 2, the scripted verdict stands); `detail` names the exact fix.

## References — read when you need them

- `references/rubric.md` — 10 dimensions, anchors, bands. Read before any Tier 2 grade of a skill.
- `references/rubric-mdc.md` — rubric variant for `.mdc` rules.
- `references/governance-standards.md` — naming, frontmatter, layout, snapshot rule.
- `references/overlap-playbook.md` — Tier 3 adjudication + merge/split decision tree.
- `references/report-templates.md` — the three report formats; skeletons in `assets/report-skeletons/`.

## Bands

🔴 Red <60 · 🟠 Amber 60–79 · 🟢 Green 80–89 · 🥇 Gold 90+. Improvement trigger = Red or Amber. Report bands, not false point precision.

## Failure modes — recover, don't guess

- Lint exits 1 or JSON `errors` is non-empty → the file didn't parse. Fix frontmatter first; don't Tier-2 grade an unparseable file (its Tier-1 score stands at 0).
- A tree is absent (e.g. no `~/.cursor/rules/`) → `inventory.py` silently skips it. State "tree absent" in the report so a zero-rule result isn't read as an empty library.
- No previous audit → trend reads "baseline (no prior audit)". Expected, not an error.
- `similarity.py` returns no pairs → still build the responsibility matrix from the index; functional overlap can hide below the text threshold.
- Snapshot copy fails → stop before any write. No rollback copy, no edit.

---

## W1 — Full audit cycle (read-only)

1. `python -m scripts.inventory --out <audit>/skill-index.json`.
2. For each item: `python -m scripts.lint_skill --format <fmt> <path>` → save to `<audit>/lint/<id>.json`.
3. Tier 2: read each item + the matching rubric, grade inline (double-grade protocol).
4. `python -m scripts.similarity --index <audit>/skill-index.json --out <audit>/candidate-pairs.json`.
5. Tier 3: adjudicate pairs where `needs_adjudication` is true; build the responsibility matrix.
6. Write `<audit>/summary.json`; compute trend via `utils.diff_summaries` against the previous audit's `summary.json`.
7. Emit the three reports into `<audit>/reports/` using the skeletons in `assets/`.

`<audit>` = `~/.claude/skill-qa/audits/<YYYY-MM-DD-HHMMSS>/`. This workflow writes only into that audit folder — never into a skill.

## W2 — Single-skill improvement (double-gated)

Triggered for Red/Amber skills, or on request. Never auto-started.

1. Lint + Tier 2 grade the target; produce its Detailed Skill Report.
2. **GATE 1** — present the skill, its score/band, and the planned changes. Wait for explicit approval. Do not edit yet.
3. **Snapshot** the original to `~/.claude/skill-qa/history/<name>/<timestamp>/`.
4. Write the improved version to a sibling `<name>-proposed/` (skills) or `<name>-proposed.mdc` (rules) — never overwrite in place yet.
5. Build the **change manifest**: each change → targeted rubric dimension, expected score delta, and an explicit "intent preserved? Y/N + justification" line.
6. Re-run Tier 1 + Tier 2 on the proposal; report old vs new scores.
7. **GATE 2** — present the diff + before/after scores. Wait for a second explicit approval.
8. On approval: replace the original, re-lint, and regenerate the `.mdc` counterpart if one is declared.

Gaming guard: a "target of 80" tempts padding (boilerplate error-handling sections, ALL-CAPS MUSTS). The diff + manifest + re-score makes gaming visible — call it out if you see it.

## W3 — New-skill gate

Before any new skill/rule enters the library: run Tier 1 + Tier 2, and `similarity.py` against the whole index. Block unless **Green or better** and the responsibility matrix shows **no competing owner**. This keeps the audit backlog from growing.

## W4 — Overlap resolution

For each confirmed overlap group, apply `overlap-playbook.md`:
- Identical intent → **merge** (keep the better-scoring shell).
- Shared core + distinct edges → **split** (extract shared part to a reference/script).
- Stale duplicate → recommend **deprecate** (human approves; never auto-delete).
- Wrong owner → **reassign** + update the matrix.

Cross-tree: a declared `counterpart` (skill ↔ mdc) is expected, not a violation. Undeclared cross-tree twins are drift risk — flag them.

All W4 edits are double-gated exactly like W2.

## Self-audit (dogfooding)

This agent is itself a first-class audit subject in **both** formats — `skill-qa-agent` (SKILL.md, via `rubric.md`) and `skill-qa.mdc` (via `rubric-mdc.md`). Both must score **Gold (90+)** before the automation phase ships. Re-audit after any change to this skill.

The `.mdc` source ships in this folder; deploy it by copying to `~/.cursor/rules/skill-qa.mdc` so `inventory.py` picks it up.
