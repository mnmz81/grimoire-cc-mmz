# Detailed Report — {{item_id}}

**Format:** {{format}}  ·  **Score:** {{score}} / 100  ·  **Band:** {{band}}

## Per-dimension scores

| # | Dimension | Score | Pass 1 | Pass 2 | Δ | Notes |
|---|-----------|-------|--------|--------|---|-------|
| 1 | Clarity | {{d1}} | | | | |
| 2 | Completeness | {{d2}} | | | | |
| 3 | Triggering | {{d3}} | | | | |
| 4 | Structure & progressive disclosure | {{d4}} | | | | |
| 5 | Maintainability | {{d5}} | | | | |
| 6 | Reusability / generality | {{d6}} | | | | |
| 7 | Governance-consistency | {{d7}} | | | | |
| 8 | Robustness & error handling | {{d8}} | | | | |
| 9 | Documentation quality | {{d9}} | | | | |
| 10 | Non-redundancy | {{d10}} | | | | |

> ⚠ marks any dimension whose two grade passes differed by >2 (tiebreak applied).

## Tier 1 findings (machine lint)

| Check | Pass | Pts | Detail |
|-------|------|-----|--------|
{{tier1_rows}}

## Tier 2 reasoning

{{tier2_reasoning}}

## Strengths

{{strengths}}

## Weaknesses

{{weaknesses}}

## Improvement recommendations

{{recommendations}}

## Change manifest (if rewritten)

| Change | Target dimension | Expected Δ | Intent preserved? | Justification |
|--------|------------------|-----------|-------------------|---------------|
{{manifest_rows}}

**Before:** {{before_score}}  ·  **After:** {{after_score}}
