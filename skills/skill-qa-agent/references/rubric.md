# QA Rubric — Skills (SKILL.md format)

10 dimensions, 0–10 each, summed to **/100**. Grade against the written
anchors below, not vibes. For `.mdc` rules use `rubric-mdc.md` instead.

## Bands

| Band | Range | Meaning |
|------|-------|---------|
| 🔴 Red | < 60 | Broken or misleading. Fix before use. |
| 🟠 Amber | 60–79 | Works but weak. Improvement queued. |
| 🟢 Green | 80–89 | Solid. Shippable. |
| 🥇 Gold | 90+ | Exemplary. The standard others copy. |

Improvement trigger = **Red or Amber** (not "79 vs 80"). Report the band, not false point precision.

## Tier split

Roughly a third of the score is **script-computable** (Tier 1, `lint_skill.py`) and never varies run-to-run. The rest is **agent judgment** (Tier 2), graded inline against these anchors.

| # | Dimension | Pts | Tier-1 scripted portion | Tier-2 judged |
|---|-----------|-----|--------------------------|---------------|
| 1 | Clarity | 10 | — | all 10 |
| 2 | Completeness | 10 | `toc_present` (6) | remaining 4 |
| 3 | Triggering | 10 | `description_length` (5) | remaining 5 |
| 4 | Structure & progressive disclosure | 10 | `line_count` (5) + `references_used` (3) | remaining 2 |
| 5 | Maintainability | 10 | `broken_refs` (6) | remaining 4 |
| 6 | Reusability / generality | 10 | — | all 10 |
| 7 | Governance-consistency | 10 | `frontmatter_valid` (4) + `name_kebab` (4) | remaining 2 |
| 8 | Robustness & error handling | 10 | — | all 10 |
| 9 | Documentation quality | 10 | — | all 10 |
| 10 | Non-redundancy | 10 | — | all 10 (fed by similarity + Tier 3) |

**Scriptable budget ≈ 33 pts** (6+5+5+3+6+4+4). The lint JSON awards those points per check; the agent fills the rest. When a Tier-1 check fails, the agent must not silently re-award its points in Tier 2 — the scripted verdict stands.

## Double-grade protocol (variance control)

For every judgment dimension, grade **twice** independently. Average the two. If any dimension's two passes differ by **>2 points**, do a **third tiebreak pass** for that dimension and use the median. Record the per-dimension deltas in the report (`double_grade_deltas`). This catches the upward drift that happens when the agent grades its own rewrites.

## Cross-cutting anchor notes (apply to every dimension)

- **ALL-CAPS MUSTS and rigid templates are a yellow flag, not robustness.** Reward explained reasoning over enforcement language. A skill that says "do X because Y" beats one that says "YOU MUST ALWAYS X".
- **Verbosity is penalized, not rewarded.** A 9/10 skill is complete *and* lean — every line pulls weight.
- **Overfit examples cap Reusability at 5.** Fiddly instructions tied to one scenario don't generalize.

---

## 1. Clarity (10) — judgment

Unambiguous instructions, imperative voice, no contradictions.

- **2:** Vague or contradictory. Reader can't tell what to do.
- **5:** Mostly followable but has ambiguous steps or undefined terms.
- **8:** Clear, imperative, consistent. Minor wording could tighten.
- **10:** Every instruction unambiguous; a new reader executes correctly first try.

## 2. Completeness (10) — `toc_present` (6) + judgment (4)

Covers happy path + edge cases + failure modes.

- **2:** Happy path only; no edge cases, no headings/TOC.
- **5:** Happy path + some edges; gaps in failure handling.
- **8:** Happy path, edges, and failure modes; well-sectioned.
- **10:** Comprehensive without padding — anticipates what the reader will hit.

## 3. Triggering (10) — `description_length` (5) + judgment (5)

Description states **what + when**, "pushy" enough to fire, no triggering info buried in the body.

- **2:** Description summarizes the *workflow* (causes Claude to shortcut past the body) or is too vague to ever fire.
- **5:** States what but weak on when; some triggers only discoverable in body.
- **8:** Clear what + when, third person, "Use when…" with concrete contexts.
- **10:** Precise triggering with symptoms/contexts; fires when it should, stays quiet when it shouldn't. No workflow leakage into the description.

## 4. Structure & progressive disclosure (10) — `line_count` (5) + `references_used` (3) + judgment (2)

<500-line SKILL.md, heavy content in `references/` with TOC, deterministic work in `scripts/`.

- **2:** Monolithic; everything inline; no layering.
- **5:** Some structure but heavy reference content inlined, or scripts that should exist don't.
- **8:** Good layering; references and scripts used appropriately.
- **10:** Exemplary progressive disclosure — metadata → body → bundled resources, each at the right level.

## 5. Maintainability (10) — `broken_refs` (6) + judgment (4)

No hardcoded one-off paths, no overfit examples, lean — every line pulls weight; all references resolve.

- **2:** Broken links, hardcoded user-specific paths, dead weight.
- **5:** Resolves but brittle — some hardcoded values or stale sections.
- **8:** Clean, modular, all refs valid.
- **10:** Trivially maintainable; future edits are localized.

## 6. Reusability / generality (10) — judgment

Works beyond the original examples; explains *why*, not rigid MUSTs.

- **2:** Hardwired to one scenario; can't generalize.
- **5:** Works for the examples given; fiddly/overfit instructions cap here.
- **8:** Generalizes well; reasoning explained.
- **10:** Principles transfer broadly; a reader applies it to unforeseen cases.

## 7. Governance-consistency (10) — `frontmatter_valid` (4) + `name_kebab` (4) + judgment (2)

Naming, frontmatter, file layout per `governance-standards.md`.

- **2:** Invalid frontmatter or non-conforming name.
- **5:** Valid but deviates from layout/voice conventions.
- **8:** Conforms to governance standards.
- **10:** Textbook conformance; could be the reference example.

## 8. Robustness & error handling (10) — judgment

Anticipates bad input, tool failures, ambiguity.

- **2:** Assumes the happy path only; no recovery guidance.
- **5:** Mentions some failures but no recovery path.
- **8:** Anticipates common failures with recovery steps.
- **10:** Thorough failure-mode coverage with graceful, explained recovery — without bloating into boilerplate "error handling" sections.

## 9. Documentation quality (10) — judgment

Examples with input/output, rationale explained.

- **2:** No examples; assertions without rationale.
- **5:** Some examples but missing input/output or the "why".
- **8:** Good examples with I/O and rationale.
- **10:** Examples that teach; rationale makes the reader internalize the approach.

## 10. Non-redundancy (10) — judgment, fed by similarity + Tier 3

Unique responsibility per the responsibility matrix; no leakage into neighbors' jobs.

- **2:** Duplicates another skill's job (per matrix); competing owner.
- **5:** Overlaps a neighbor on some capability.
- **8:** Mostly unique; minor, declared overlap (e.g. a `counterpart` mdc).
- **10:** Clear sole owner of its capability; no leakage.
