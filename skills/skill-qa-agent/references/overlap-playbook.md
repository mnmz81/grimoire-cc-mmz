# Overlap Detection & Resolution Playbook

How to turn `similarity.py` candidate pairs into Tier-3 verdicts and actions.
Pure text similarity over-flags boilerplate and misses functional overlap, so
adjudicate every candidate — don't act on the score alone.

## Inputs

- `skill-index.json` (from `inventory.py`) — name, description, trigger phrases, declared responsibilities, tree, format, `counterpart`.
- `candidate-pairs.json` (from `similarity.py`) — pairs scoring ≥ threshold, each annotated `same_tree`, `is_declared_counterpart`, `needs_adjudication`.

Only pairs with `needs_adjudication: true` need Tier-3 classification. Declared counterparts (`is_declared_counterpart: true`) are skipped — expected overlap.

## Tier-3 classification

For each candidate pair, read both items and classify:

| Verdict | Meaning |
|---------|---------|
| `exact-duplicate` | Same intent, same job. One is redundant. |
| `partial-duplicate` | Overlapping core, each adds little unique. |
| `functional-overlap` | Different wording, same capability owned by both. |
| `competing-responsibility` | Both claim authority over the same decision/task. |
| `false-positive` | Shared vocabulary only; distinct jobs. Discard. |

## Decision tree → recommended action

```
Identical intent?
├─ yes → MERGE: keep the better-scoring shell, fold in the other's unique content, deprecate the loser (human approves).
└─ no
   ├─ Shared core + distinct edges?
   │   └─ SPLIT/REFACTOR: extract the shared core into a reference or script; keep each skill's distinct edge.
   ├─ One is stale / superseded?
   │   └─ DEPRECATE (recommend only; never auto-delete).
   ├─ Wrong owner (capability sits in the wrong skill)?
   │   └─ REASSIGN: move the capability + update the responsibility matrix.
   └─ Just shared vocabulary?
       └─ FALSE-POSITIVE: discard.
```

All resulting edits are **double-gated** like W2 (GATE 1 plan → snapshot → propose → GATE 2 apply).

## Cross-tree rule

The two trees evolve independently, so the highest-risk duplication is a SKILL.md and an `.mdc` rule owning the same capability with drifting content.

- **Declared** dual-tree ownership (`metadata.counterpart` ↔ body `counterpart:`) is allowed and exempt. Verify the two stay in sync; flag content drift.
- **Undeclared** cross-tree twins (`same_tree: false`, `is_declared_counterpart: false`, high score) → flag as **drift risk**. Recommend either declaring the counterpart link or merging.

## Responsibility matrix

Build a table: **capability → owning item(s) + tree(s)**.

- A capability with **2+ owners** (not a declared counterpart) = **governance finding**.
- A skill with **0 unique capabilities** (everything it owns is owned better elsewhere) = **deprecation candidate**.

Capabilities are derived from each item's `declared_responsibilities` + trigger phrases, deduped into canonical capability names by judgment.
