# Repository Optimization Report

**Audit:** {{audit_id}}

## Responsibility matrix

Capability → owning item(s) and tree(s). A capability with **2+ owners** is a
governance finding (unless a declared `counterpart`). A skill with **0 unique
capabilities** is a deprecation candidate.

| Capability | Owner(s) | Tree(s) | Finding |
|------------|----------|---------|---------|
{{matrix_rows}}

## Overlap groups

| Members | Verdict | Recommended action | Effort |
|---------|---------|--------------------|--------|
{{overlap_rows}}

Verdicts: exact-duplicate · partial-duplicate · functional-overlap · competing-responsibility · false-positive
Actions: merge · split · refactor · deprecate · reassign

## Governance violations

| Item | Rule | Severity |
|------|------|----------|
{{violation_rows}}

## Priority-ranked action plan (impact × effort)

**Quick wins** (high impact, low effort)
{{quick_wins}}

**Big bets** (high impact, high effort)
{{big_bets}}

**Fill-ins** (low impact, low effort)
{{fill_ins}}

**Thankless** (low impact, high effort — defer)
{{thankless}}
