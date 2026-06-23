#!/usr/bin/env bash
# restructure-r9-consolidate.sh — R9 structural migration.
#
# Consolidates small single-skill plugins into domain plugins so the marketplace has
# fewer, coarser install units (toggle/version by domain, not by individual skill):
#
#   * coding-style  <-  ai-coding-discipline (karpathy-guidelines) + ponytail + my-caveman (caveman)
#   * debugging     <-  absorbs bug-hunting (hunt skill + 10 hunter agents + refs + script)
#
# Skill names and their SKILL.md frontmatter are UNCHANGED, so per-skill triggering is
# unaffected — only the owning plugin (the install/enable/version unit) changes.
#
# Uses `git mv` so history is preserved. Run once from repo root. After running, sync the
# catalog: scripts/generate-catalog.py
#
# Usage: scripts/restructure-r9-consolidate.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

AUTHOR_NAME="Moris Zakay"
AUTHOR_URL="https://github.com/mnmz81"

# ── coding-style: merge three single-skill discipline plugins ──────────────────
mkdir -p plugins/coding-style/.claude-plugin plugins/coding-style/skills
git mv plugins/ai-coding-discipline/skills/karpathy-guidelines plugins/coding-style/skills/karpathy-guidelines
git mv plugins/ponytail/skills/ponytail                         plugins/coding-style/skills/ponytail
git mv plugins/my-caveman/skills/caveman                        plugins/coding-style/skills/caveman
git rm -rq plugins/ai-coding-discipline plugins/ponytail plugins/my-caveman

cat > plugins/coding-style/.claude-plugin/plugin.json <<JSON
{
  "name": "coding-style",
  "version": "1.0.0",
  "description": "Coding-style and output discipline — Karpathy LLM-mistake guardrails (surgical changes, no overcomplication), laziest-senior-dev minimalism (ponytail: YAGNI, stdlib-first, shortest working diff), and caveman output compression. Skills: karpathy-guidelines, ponytail, caveman.",
  "author": { "name": "$AUTHOR_NAME", "url": "$AUTHOR_URL" }
}
JSON

# ── debugging: absorb bug-hunting (whole-repo sweep) alongside sleuth ───────────
mkdir -p plugins/debugging/agents plugins/debugging/references plugins/debugging/scripts
git mv plugins/bug-hunting/skills/hunt        plugins/debugging/skills/hunt
git mv plugins/bug-hunting/agents/*.md        plugins/debugging/agents/
git mv plugins/bug-hunting/references/*.md    plugins/debugging/references/
git mv plugins/bug-hunting/scripts/*.sh       plugins/debugging/scripts/
git rm -rq plugins/bug-hunting

cat > plugins/debugging/.claude-plugin/plugin.json <<JSON
{
  "name": "debugging",
  "version": "1.0.0",
  "description": "Debugging discipline plus whole-repo bug sweeps — systematic root-cause-first fixing (sleuth: investigate before editing, one hypothesis at a time, stop after three failed fixes) and a fan-out of read-only hunters (hunt + 10 hunter agents) that surface bugs across an entire codebase. Skills: sleuth, hunt.",
  "author": { "name": "$AUTHOR_NAME", "url": "$AUTHOR_URL" }
}
JSON

echo "R9 consolidation done. Now run: scripts/generate-catalog.py"
