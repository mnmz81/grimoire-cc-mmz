# grimoire-cc-mmz

Personal Claude Code skills & agents, consolidated into a **domain-based plugin marketplace**. Install any domain at user scope and it's available in every project.

## Install

```
/plugin marketplace add mnmz81/grimoire-cc-mmz
/plugin install <domain>@grimoire-cc-mmz
/reload-plugins
```

Replace `<domain>` with any plugin below, e.g. `/plugin install bug-hunting@grimoire-cc-mmz`.

## Domains

| Plugin | What it covers |
| ------ | -------------- |
| `mushilu-studio` | The full Mushilu-San-UI component pipeline as one workflow: scope → spec → build → **parallel** review/audit → test → docs → release. Skills (compass, blueprint, conductor, foreman, marshal, prowler, scribe, quartermaster, curator, warden) + read-only review/audit **agents** the conductor fans out (palette, staff, sentinel-a11y, gauge). |
| `bug-hunting` | Whole-repo bug sweeps — the `hunt` orchestrator + 10 read-only `hunt-*` hunter agents (shared protocol in `references/hunter-core.md`). |
| `debugging` | Root-cause-first debugging discipline for any codebase (sleuth). |
| `ai-coding-discipline` | Guidelines that reduce common LLM coding mistakes (karpathy-guidelines). |
| `skill-authoring` | Audit, grade, and improve skills & rules (skill-qa-agent). |
| `ux-design` | UI/UX design intelligence for web and mobile (ui-ux-design). |
| `code-review` | Thorough JS/TS/Python code review — bugs, security, performance. |
| `my-caveman` | Caveman output compression — terse, telegraphic replies that cut tokens while keeping accuracy (modes: lite, full, ultra, wenyan). |

See [`INVENTORY.md`](./INVENTORY.md) for the full asset → domain mapping and provenance.

## Structure

```
.claude-plugin/
  marketplace.json          # catalog listing every domain plugin
plugins/
  <domain>/
    .claude-plugin/plugin.json
    skills/<skill>/SKILL.md  # auto-discovered
    agents/<agent>.md        # auto-discovered (mushilu-studio, bug-hunting)
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
