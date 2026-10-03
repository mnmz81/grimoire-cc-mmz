# grimoire-cc-mmz

Personal Claude Code skills & agents, consolidated into a **domain-based plugin marketplace**. Install any domain at user scope and it's available in every project.

## Install

```
/plugin marketplace add mnmz81/grimoire-cc-mmz
/plugin install <domain>@grimoire-cc-mmz
/reload-plugins
```

Replace `<domain>` with any plugin below, e.g. `/plugin install debugging@grimoire-cc-mmz`.

## Domains

<!-- BEGIN GENERATED: readme-domains (scripts/generate-catalog.py) -->

| Plugin | What it covers |
| ------ | -------------- |
| `coding-style` | Coding-style and output discipline — Karpathy LLM-mistake guardrails (surgical changes, no overcomplication), laziest-senior-dev minimalism (ponytail: YAGNI, stdlib-first, shortest working diff), and caveman output compression. Skills: karpathy-guidelines, ponytail, caveman. |
| `debugging` | Debugging discipline plus whole-repo bug sweeps — systematic root-cause-first fixing (sleuth: investigate before editing, one hypothesis at a time, stop after three failed fixes) and a fan-out of read-only hunters (hunt + 10 hunter agents) that surface bugs across an entire codebase. Skills: sleuth, hunt. |
| `mushilu-studio` | End-to-end Mushilu-San-UI component pipeline — scope, spec, build, parallel review/audit, test, docs, and release — orchestrated as one workflow. |
| `repo-init` | Bootstrap a GitHub repository with enterprise-grade defaults — branch protection (no direct push to main, require PR + N approvals, dismiss stale reviews), required CI status checks, squash-merge linear history, secret scanning, Dependabot alerts, and auto-delete of merged branches. |
| `skill-authoring` | Audit, grade, and improve Claude Code skills and Cursor rules, and resolve overlap between them. |
| `triple-lens-review` | Three-lens code review — bugs, security, and performance — strongest on JavaScript/TypeScript/Python, applies to any language. |
| `ux-design` | UI/UX design intelligence for web and mobile — accessibility, layout, typography, components, and data visualization. |

<!-- END GENERATED: readme-domains -->

See [`INVENTORY.md`](./INVENTORY.md) for the full asset → domain mapping and provenance.

## Structure

```
.claude-plugin/
  marketplace.json          # catalog listing every domain plugin
plugins/
  <domain>/
    .claude-plugin/plugin.json
    skills/<skill>/SKILL.md  # auto-discovered
    agents/<agent>.md        # auto-discovered (mushilu-studio, debugging)
    references/*.md          # shared protocol/schema docs (not auto-loaded)
scripts/
  generate-catalog.py       # source of truth: regenerate marketplace.json + INVENTORY table
  collect.sh                # Phase 1 (historical): gather scattered skills/agents
  build-plugins.sh          # Phase 2 (historical, one-shot): reshape into domain plugins
  restructure-studio.sh     # R2/R3 (one-shot): consolidate Studio + split out sleuth
  collected.tsv             # provenance log
```

`skills/`, `agents/`, `commands/`, and `hooks/` inside a plugin are **auto-discovered** — nothing is listed individually in the manifests.

## Adding a new domain

1. Create `plugins/<domain>/` with a `.claude-plugin/plugin.json` (use kebab-case for the name):
   ```json
   {
     "name": "<domain>",
     "version": "1.0.0",
     "description": "<one line>",
     "author": { "name": "Moris Zakay", "url": "https://github.com/mnmz81" }
   }
   ```
2. Drop skills under `plugins/<domain>/skills/<skill>/` and agents under `plugins/<domain>/agents/`. Keep every asset a skill references **inside** its own plugin folder (reference it as `${CLAUDE_PLUGIN_ROOT}/...`) — plugins are copied to a cache on install, so any path pointing outside the plugin breaks.
3. Regenerate the catalog: `scripts/generate-catalog.py`. The per-plugin `plugin.json` is the **single source of truth** — the script derives `.claude-plugin/marketplace.json` and the INVENTORY domains table from it, so there is no second file to keep in sync by hand.
4. Validate: `claude plugin validate .` and `scripts/generate-catalog.py --check` (both run in CI).
5. Open a PR — `main` is protected and only merges via PR.
