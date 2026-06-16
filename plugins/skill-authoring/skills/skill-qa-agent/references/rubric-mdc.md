# QA Rubric — Cursor Rules (.mdc format)

Same 10 dimensions, 0–10 each, **/100**, same bands as `rubric.md`
(🔴<60 🟠60–79 🟢80–89 🥇90+). Only the anatomy-specific dimensions differ;
the other eight inherit `rubric.md`'s anchors with the mdc notes below.

`.mdc` frontmatter carries `description` / `globs` / `alwaysApply` instead of a
SKILL.md-style triggering description. So **Triggering** and **Structure** are
judged differently. `.mdc` rules are first-class audit subjects.

## Tier split (mdc)

| # | Dimension | Pts | Tier-1 scripted portion (`lint_skill.py --format mdc`) | Tier-2 judged |
|---|-----------|-----|---------------------------------------------------------|---------------|
| 1 | Clarity | 10 | — | all 10 |
| 2 | Completeness | 10 | — | all 10 |
| 3 | Triggering | 10 | `description_length` (5) + `alwaysApply_discipline` (6) + `globs_valid` (4) → scaled | judged overlay |
| 4 | Structure & progressive disclosure | 10 | `line_count` (7, max 100) | remaining 3 |
| 5 | Maintainability | 10 | `broken_refs` (6) | remaining 4 |
| 6 | Reusability / generality | 10 | — | all 10 |
| 7 | Governance-consistency | 10 | `frontmatter_valid` (5) | remaining 5 |
| 8 | Robustness & error handling | 10 | — | all 10 |
| 9 | Documentation quality | 10 | — | all 10 |
| 10 | Non-redundancy | 10 | — | all 10 |

> Note: the mdc lint awards 33 scriptable points across these checks. The agent maps lint points into the dimensions above; where a single check (e.g. `alwaysApply_discipline`) is larger than the dimension's scripted budget, treat the check as a gate — a failed gate caps that dimension's score.

## 3. Triggering (mdc) — scoping precision

Judges `description` + `globs` scoping and `alwaysApply` correctness.

- **2:** `alwaysApply: true` on a rule that should be scoped (broad always-on rule polluting every prompt), OR globs so broad they match everything, OR a description that doesn't say when the rule applies.
- **5:** Reasonable description but scoping is loose — globs wider than needed, or always-on when a glob would do.
- **8:** Description states applicability; globs scoped to the right file set; `alwaysApply` only true for genuinely universal rules.
- **10:** Precisely scoped — fires exactly where intended, silent elsewhere. `alwaysApply: true` (if used) is clearly justified as universal; otherwise tight globs.

**alwaysApply discipline:** an always-on rule that should be scoped is a **governance finding**. `alwaysApply: true` AND `globs` set is contradictory (auto-fail the scripted check).

## 4. Structure & progressive disclosure (mdc) — rule length

Judges rule length and `alwaysApply` discipline. `.mdc` rules should be **short** (<100 lines) — they load into every applicable prompt.

- **2:** Bloated (>100 lines) always-on rule.
- **5:** Within length but rambling; mixes multiple concerns.
- **8:** Lean, single-concern, well under 100 lines.
- **10:** Minimal and sharp; every line earns its place in the prompt budget.

## Inherited dimensions

Dimensions 1, 2, 5, 6, 7, 8, 9, 10 use `rubric.md`'s anchors verbatim, with one note: for **Non-redundancy**, a declared `counterpart:` to a SKILL.md skill is *expected* overlap (not a violation) — see `overlap-playbook.md` cross-tree rule.
