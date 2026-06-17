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
| `component-design` | Scope and lock a UI component's contract before code — Studio pipeline (compass, blueprint, conductor, foreman). |
| `component-quality` | Quality gates — review, design tokens, a11y, bundle budget, unit + browser tests, docs (staff, palette, sentinel-a11y, gauge, marshal, prowler, scribe). |
| `bug-hunting` | Whole-repo bug sweeps + root-cause debugging (hunt, sleuth, and 10 `hunt-*` hunter agents). |
| `studio-ops` | Release engineering, safety-marker hooks, learnings log (quartermaster, warden, curator). |
| `code-intelligence` | Knowledge-graph codebase Q&A (graphify). |
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
    agents/<agent>.md        # auto-discovered (bug-hunting only)
scripts/
  collect.sh                # Phase 1: gather scattered skills/agents (lossless)
  build-plugins.sh          # Phase 2: reshape into domain plugins
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
2. Drop skills under `plugins/<domain>/skills/<skill>/` and agents under `plugins/<domain>/agents/`. Keep every asset a skill references **inside** its own plugin folder — plugins are copied to a cache on install, so any path pointing outside the plugin breaks.
3. Add a matching entry to `.claude-plugin/marketplace.json` `plugins[]`. Keep `version` **identical** in both the plugin manifest and the marketplace entry.
4. Validate: `claude plugin validate .`
5. Open a PR — `main` is protected and only merges via PR.
