# Governance Standards

The canonical conventions the **Governance-consistency** rubric dimension
checks, plus library-wide rules. `lint_skill.py` enforces the mechanical ones;
the agent judges the rest.

## Naming

- Skill directory name = `name` frontmatter value = kebab-case `^[a-z0-9]+(-[a-z0-9]+)*$`, ≤64 chars.
- `.mdc` filename (stem) is the rule's identity. Same kebab-case convention.
- IDs in the index: `skill:<name>` and `mdc:<name>`.

## Frontmatter

**Skills (SKILL.md)** — allowed top-level keys: `name`, `description`, `metadata`. Nothing else.
- `name`: required, kebab-case.
- `description`: required, **third person**, leads with capability then **"Use when…"** triggering conditions. States *what + when*, never the workflow/process (workflow leakage causes Claude to shortcut past the body). 40–700 chars, no `<`/`>`.
- `metadata`: optional map. Cross-tree linkage lives here as `metadata.counterpart: mdc:<name>` (keeps the top-level allowlist clean).

**Cursor rules (.mdc)** — allowed keys: `description`, `alwaysApply`, `globs`.
- `description`: required, says what the rule does and when it applies.
- `alwaysApply`: boolean. `true` only for genuinely universal rules. `true` together with `globs` is contradictory.
- `globs`: optional list of file patterns scoping the rule. Prefer scoped globs over `alwaysApply: true`.
- A `.mdc` declares its counterpart in the **body** as a `counterpart: skill:<name>` line (frontmatter is allowlisted).

## File layout

```
<skill>/
  SKILL.md          # <500 lines; router + principles + inline patterns <50 lines
  references/       # heavy docs (100+ lines), loaded on demand
  scripts/          # deterministic work; run as `python -m scripts.<name>`; stdlib-only
  assets/           # templates, skeletons, static files
```

- Heavy reference content (100+ lines) → `references/`, not inlined.
- Deterministic, repeatable work → a script, not prose instructions.
- `.mdc` rules are single-file and short (<100 lines).

## Line budgets

| Artifact | Target |
|----------|--------|
| SKILL.md body | <500 lines (hard), lean is better |
| `.mdc` rule | <100 lines |
| reference doc | unbounded but TOC'd |

## Cross-tree linkage (`counterpart`)

When a capability is intentionally owned in **both** trees (a SKILL.md and an `.mdc` rule), both files must declare the link:
- skill → `metadata.counterpart: mdc:<name>`
- mdc → body line `counterpart: skill:<name>`

Declared counterparts are **expected** overlap, exempt from the Non-redundancy penalty. **Undeclared** cross-tree twins are flagged as drift risk (see `overlap-playbook.md`).

## Voice & style

- Imperative instructions ("Run X", "Check Y").
- Explain *why*, don't enforce with ALL-CAPS MUSTS (yellow flag in the rubric).
- Lean: every line pulls weight. Verbosity is penalized.

## Snapshot / rollback (no git)

The library is **not under version control**. Before any write to a skill/rule, snapshot the original to `~/.claude/skill-qa/history/<name>/<timestamp>/`. These snapshots are the **only** rollback mechanism — mandatory, never skipped.
