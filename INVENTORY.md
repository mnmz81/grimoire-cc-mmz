# INVENTORY

Phase 1 collected 21 skills + 36 agents (lossless). Phase 2 grouped the **shippable** assets — 21 skills + the 10 valid generated hunter agents — into domain plugins under `plugins/`. The 26 `team/agents/*.agent.md` files are non-standard Studio *build sources* (not valid Claude Code agents) and were **dropped from the plugins**; they remain in git history.

> **Current layout is the generated "Domains → plugins" table at the bottom** (run `scripts/generate-catalog.py`). A later restructure consolidated the three split Studio plugins (`component-design`, `component-quality`, `studio-ops`) into one workflow-aligned **`mushilu-studio`** plugin, moved the read-only review/audit stages (palette, staff, sentinel-a11y, gauge) into its `agents/`, and split `sleuth` into its own **`debugging`** plugin. The **Came-from / Now-at** provenance table below is **historical** — its "Now at" column records the original Phase-2 grouping, not the post-restructure paths.

| Type | Name | Domain | Came-from | Now at |
| ---- | ---- | ------ | --------- | ------ |
| agent | `blueprint.agent.md` | — (dropped: non-standard Studio build source) | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/team/agents/blueprint.agent.md` | — (not shipped; in git history) |
| agent | `compass.agent.md` | — (dropped: non-standard Studio build source) | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/team/agents/compass.agent.md` | — (not shipped; in git history) |
| agent | `conductor.agent.md` | — (dropped: non-standard Studio build source) | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/team/agents/conductor.agent.md` | — (not shipped; in git history) |
| agent | `curator.agent.md` | — (dropped: non-standard Studio build source) | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/team/agents/curator.agent.md` | — (not shipped; in git history) |
| agent | `foreman.agent.md` | — (dropped: non-standard Studio build source) | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/team/agents/foreman.agent.md` | — (not shipped; in git history) |
| agent | `gauge.agent.md` | — (dropped: non-standard Studio build source) | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/team/agents/gauge.agent.md` | — (not shipped; in git history) |
| agent | `hunt-cipher.agent.md` | — (dropped: non-standard Studio build source) | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/team/agents/hunt-cipher.agent.md` | — (not shipped; in git history) |
| agent | `hunt-cipher.md` | `bug-hunting` | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/.claude/agents/hunt-cipher.md` | `plugins/bug-hunting/agents/hunt-cipher.md` |
| agent | `hunt-drift.agent.md` | — (dropped: non-standard Studio build source) | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/team/agents/hunt-drift.agent.md` | — (not shipped; in git history) |
| agent | `hunt-drift.md` | `bug-hunting` | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/.claude/agents/hunt-drift.md` | `plugins/bug-hunting/agents/hunt-drift.md` |
| agent | `hunt-echo.agent.md` | — (dropped: non-standard Studio build source) | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/team/agents/hunt-echo.agent.md` | — (not shipped; in git history) |
| agent | `hunt-echo.md` | `bug-hunting` | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/.claude/agents/hunt-echo.md` | `plugins/bug-hunting/agents/hunt-echo.md` |
| agent | `hunt-hollow.agent.md` | — (dropped: non-standard Studio build source) | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/team/agents/hunt-hollow.agent.md` | — (not shipped; in git history) |
| agent | `hunt-hollow.md` | `bug-hunting` | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/.claude/agents/hunt-hollow.md` | `plugins/bug-hunting/agents/hunt-hollow.md` |
| agent | `hunt-lattice.agent.md` | — (dropped: non-standard Studio build source) | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/team/agents/hunt-lattice.agent.md` | — (not shipped; in git history) |
| agent | `hunt-lattice.md` | `bug-hunting` | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/.claude/agents/hunt-lattice.md` | `plugins/bug-hunting/agents/hunt-lattice.md` |
| agent | `hunt-ledger.agent.md` | — (dropped: non-standard Studio build source) | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/team/agents/hunt-ledger.agent.md` | — (not shipped; in git history) |
| agent | `hunt-ledger.md` | `bug-hunting` | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/.claude/agents/hunt-ledger.md` | `plugins/bug-hunting/agents/hunt-ledger.md` |
| agent | `hunt-prism.agent.md` | — (dropped: non-standard Studio build source) | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/team/agents/hunt-prism.agent.md` | — (not shipped; in git history) |
| agent | `hunt-prism.md` | `bug-hunting` | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/.claude/agents/hunt-prism.md` | `plugins/bug-hunting/agents/hunt-prism.md` |
| agent | `hunt-specter.agent.md` | — (dropped: non-standard Studio build source) | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/team/agents/hunt-specter.agent.md` | — (not shipped; in git history) |
| agent | `hunt-specter.md` | `bug-hunting` | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/.claude/agents/hunt-specter.md` | `plugins/bug-hunting/agents/hunt-specter.md` |
| agent | `hunt-tripwire.agent.md` | — (dropped: non-standard Studio build source) | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/team/agents/hunt-tripwire.agent.md` | — (not shipped; in git history) |
| agent | `hunt-tripwire.md` | `bug-hunting` | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/.claude/agents/hunt-tripwire.md` | `plugins/bug-hunting/agents/hunt-tripwire.md` |
| agent | `hunt-vapor.agent.md` | — (dropped: non-standard Studio build source) | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/team/agents/hunt-vapor.agent.md` | — (not shipped; in git history) |
| agent | `hunt-vapor.md` | `bug-hunting` | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/.claude/agents/hunt-vapor.md` | `plugins/bug-hunting/agents/hunt-vapor.md` |
| agent | `hunt.agent.md` | — (dropped: non-standard Studio build source) | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/team/agents/hunt.agent.md` | — (not shipped; in git history) |
| agent | `marshal.agent.md` | — (dropped: non-standard Studio build source) | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/team/agents/marshal.agent.md` | — (not shipped; in git history) |
| agent | `palette.agent.md` | — (dropped: non-standard Studio build source) | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/team/agents/palette.agent.md` | — (not shipped; in git history) |
| agent | `prowler.agent.md` | — (dropped: non-standard Studio build source) | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/team/agents/prowler.agent.md` | — (not shipped; in git history) |
| agent | `quartermaster.agent.md` | — (dropped: non-standard Studio build source) | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/team/agents/quartermaster.agent.md` | — (not shipped; in git history) |
| agent | `scribe.agent.md` | — (dropped: non-standard Studio build source) | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/team/agents/scribe.agent.md` | — (not shipped; in git history) |
| agent | `sentinel-a11y.agent.md` | — (dropped: non-standard Studio build source) | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/team/agents/sentinel-a11y.agent.md` | — (not shipped; in git history) |
| agent | `sleuth.agent.md` | — (dropped: non-standard Studio build source) | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/team/agents/sleuth.agent.md` | — (not shipped; in git history) |
| agent | `staff.agent.md` | — (dropped: non-standard Studio build source) | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/team/agents/staff.agent.md` | — (not shipped; in git history) |
| agent | `warden.agent.md` | — (dropped: non-standard Studio build source) | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/team/agents/warden.agent.md` | — (not shipped; in git history) |
| skill | `blueprint` | `component-design` | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/.claude/skills/blueprint` | `plugins/component-design/skills/blueprint` |
| skill | `code-review` | `code-review` | `/Users/mzakay/Desktop/code project/miluim hr/skills/code-review` | `plugins/code-review/skills/code-review` |
| skill | `compass` | `component-design` | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/.claude/skills/compass` | `plugins/component-design/skills/compass` |
| skill | `conductor` | `component-design` | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/.claude/skills/conductor` | `plugins/component-design/skills/conductor` |
| skill | `curator` | `studio-ops` | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/.claude/skills/curator` | `plugins/studio-ops/skills/curator` |
| skill | `foreman` | `component-design` | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/.claude/skills/foreman` | `plugins/component-design/skills/foreman` |
| skill | `gauge` | `component-quality` | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/.claude/skills/gauge` | `plugins/component-quality/skills/gauge` |
| skill | `graphify` | — (dropped: requires external `pip install graphifyy`) | `/Users/mzakay/.claude/skills/graphify` | — (not shipped; in git history) |
| skill | `hunt` | `bug-hunting` | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/.claude/skills/hunt` | `plugins/bug-hunting/skills/hunt` |
| skill | `karpathy-guidelines` | `ai-coding-discipline` | `/Users/mzakay/.claude/skills/karpathy-guidelines` | `plugins/ai-coding-discipline/skills/karpathy-guidelines` |
| skill | `marshal` | `component-quality` | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/.claude/skills/marshal` | `plugins/component-quality/skills/marshal` |
| skill | `palette` | `component-quality` | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/.claude/skills/palette` | `plugins/component-quality/skills/palette` |
| skill | `prowler` | `component-quality` | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/.claude/skills/prowler` | `plugins/component-quality/skills/prowler` |
| skill | `quartermaster` | `studio-ops` | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/.claude/skills/quartermaster` | `plugins/studio-ops/skills/quartermaster` |
| skill | `scribe` | `component-quality` | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/.claude/skills/scribe` | `plugins/component-quality/skills/scribe` |
| skill | `sentinel-a11y` | `component-quality` | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/.claude/skills/sentinel-a11y` | `plugins/component-quality/skills/sentinel-a11y` |
| skill | `skill-qa-agent` | `skill-authoring` | `/Users/mzakay/.claude/skills/skill-qa-agent` | `plugins/skill-authoring/skills/skill-qa-agent` |
| skill | `sleuth` | `bug-hunting` | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/.claude/skills/sleuth` | `plugins/bug-hunting/skills/sleuth` |
| skill | `staff` | `component-quality` | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/.claude/skills/staff` | `plugins/component-quality/skills/staff` |
| skill | `ui-ux-design` | `ux-design` | `/Users/mzakay/.claude/skills/ui-ux-design` | `plugins/ux-design/skills/ui-ux-design` |
| skill | `warden` | `studio-ops` | `/Users/mzakay/Desktop/code project/Mushilu-San-UI/.claude/skills/warden` | `plugins/studio-ops/skills/warden` |

<!-- BEGIN GENERATED: domains (scripts/generate-catalog.py) -->

## Domains → plugins

| Plugin | Skills | Agents |
| ------ | ------ | ------ |
| `ai-coding-discipline` | karpathy-guidelines | — |
| `bug-hunting` | hunt | hunt-cipher, hunt-drift, hunt-echo, hunt-hollow, hunt-lattice, hunt-ledger, hunt-prism, hunt-specter, hunt-tripwire, hunt-vapor |
| `code-review` | code-review | — |
| `debugging` | sleuth | — |
| `mushilu-studio` | blueprint, compass, conductor, curator, foreman, marshal, prowler, quartermaster, scribe, warden | gauge, palette, sentinel-a11y, staff |
| `my-caveman` | caveman | — |
| `ponytail` | ponytail | — |
| `skill-authoring` | skill-qa-agent | — |
| `ux-design` | ui-ux-design | — |

_9 plugins. This table is generated — run `scripts/generate-catalog.py`._

<!-- END GENERATED: domains -->

**Dropped (not in any plugin):** 26 `team/agents/*.agent.md` Studio build sources — preserved in git history and on the Phase 1 merge commit.

