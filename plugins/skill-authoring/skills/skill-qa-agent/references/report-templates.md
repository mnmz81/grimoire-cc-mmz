# Report Templates

Three report formats. Literal fill-in skeletons live in
`assets/report-skeletons/`. This file defines the fields. All reports are
written into `~/.claude/skill-qa/audits/<YYYY-MM-DD-HHMMSS>/reports/`.

## 1. Executive Summary (`executive-summary.md`)

Audience: the library owner, at a glance. One file per audit.

- **Totals:** item count (skills / mdc split), average score.
- **Band distribution:** count per Red / Amber / Green / Gold.
- **Red/Amber list:** the skills needing attention, with score + band.
- **Overlap groups:** confirmed groups with recommended action.
- **Top-5 priority actions:** ranked by impact × effort.
- **Trend vs previous audit:** computed by `utils.diff_summaries` diffing this audit's `summary.json` against the previous one — avg score delta, band transitions, new/removed items, violation/overlap deltas. First run → "baseline (no prior audit)".

## 2. Detailed Skill Report (`detailed-skill-report.md`)

Audience: whoever fixes a specific skill. One section per skill (or one file per skill).

- **Header:** name, format, band + total score.
- **Per-dimension scores:** the 10 dimensions, each with the score, the two grade passes, and a ⚠ flag where the double-grade delta >2 (tiebreak applied).
- **Tier 1 findings:** the machine lint table (check id, pass/fail, points, detail) — verbatim from `lint_skill.py`.
- **Tier 2 reasoning:** why each judged dimension landed where it did.
- **Strengths / weaknesses.**
- **Improvement recommendations:** concrete, dimension-targeted.
- **If rewritten:** change manifest (each change → targeted dimension, expected delta, intent-preserved Y/N + justification) + before/after scores.

## 3. Repository Optimization Report (`repo-optimization-report.md`)

Audience: library-level decisions.

- **Responsibility matrix:** capability → owning skill(s)/rule(s) and tree(s). Any capability with **2+ owners** = governance finding. Any skill with **0 unique capabilities** = deprecation candidate.
- **Overlap groups:** each with members, Tier-3 verdict (exact-duplicate / partial-duplicate / functional-overlap / competing-responsibility / false-positive), recommended action (merge / split / refactor / deprecate / reassign), and effort estimate.
- **Governance violations:** table of rule, offending item, severity.
- **Priority-ranked action plan:** impact × effort quadrants (quick-wins / big-bets / fill-ins / thankless).

## summary.json (machine-readable, per audit)

Not a report — the data backbone for trends. Schema:

```json
{
  "audit_id": "2026-06-10-093000",
  "previous_audit_id": "2026-06-03-093000",
  "totals": {"items": 18, "skills": 11, "mdc": 7, "avg_score": 82.4},
  "bands": {"red": 1, "amber": 4, "green": 10, "gold": 3},
  "per_item": [
    {"id": "skill:foo", "format": "skill", "score": 86, "band": "green",
     "tier1_points": 31, "dimensions": {"Clarity": 8, "...": 0},
     "double_grade_deltas": {"Clarity": 1}}
  ],
  "overlap_groups": [
    {"members": ["skill:a", "skill:b"], "verdict": "partial-duplicate", "action": "refactor"}
  ],
  "governance_violations": [
    {"id": "mdc:bar", "rule": "alwaysApply discipline", "severity": "high"}
  ]
}
```
