#!/usr/bin/env bash
# restructure-studio.sh — R2/R3 structural migration.
#
# Merges the three split Studio plugins (component-design, component-quality, studio-ops)
# into a single workflow-aligned `mushilu-studio` plugin, moves `sleuth` into its own
# `debugging` plugin, and relocates the read-only review/audit stages (palette, staff,
# sentinel-a11y, gauge) from skills/ to agents/ so the conductor can fan them out in parallel.
#
# Idempotent-ish: safe to read; uses `git mv` so history is preserved. Run once from repo root.
#
# Usage: scripts/restructure-studio.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

STUDIO="plugins/mushilu-studio"
mkdir -p "$STUDIO/.claude-plugin" "$STUDIO/skills" "$STUDIO/agents" "$STUDIO/references"

# Skills that stay skills (interactive / stateful / producers).
STUDIO_SKILLS=(
  "component-design/skills/compass"
  "component-design/skills/blueprint"
  "component-design/skills/conductor"
  "component-design/skills/foreman"
  "component-quality/skills/marshal"
  "component-quality/skills/prowler"
  "component-quality/skills/scribe"
  "studio-ops/skills/quartermaster"
  "studio-ops/skills/curator"
  "studio-ops/skills/warden"
)
for src in "${STUDIO_SKILLS[@]}"; do
  name="$(basename "$src")"
  git mv "plugins/$src" "$STUDIO/skills/$name"
  echo "skill  -> $STUDIO/skills/$name"
done

# Read-only review/audit stages -> agents (SKILL.md becomes <name>.md; frontmatter fixed
# afterward by hand). Moved into a temp skills location first, then the .md is relocated.
REVIEW_AGENTS=("staff" "palette" "sentinel-a11y" "gauge")
for name in "${REVIEW_AGENTS[@]}"; do
  git mv "plugins/component-quality/skills/$name/SKILL.md" "$STUDIO/agents/$name.md"
  echo "agent  -> $STUDIO/agents/$name.md"
done

# sleuth -> its own debugging plugin (it is a general debugger, not part of the hunt squad).
mkdir -p "plugins/debugging/.claude-plugin" "plugins/debugging/skills"
git mv "plugins/bug-hunting/skills/sleuth" "plugins/debugging/skills/sleuth"
echo "skill  -> plugins/debugging/skills/sleuth"

# Drop the now-empty old plugin trees (skills/agents already moved out).
for old in component-design component-quality studio-ops; do
  git rm -q "plugins/$old/.claude-plugin/plugin.json"
  # remove any leftover empty dirs (e.g. emptied skills/<name>/ for the converted agents)
  find "plugins/$old" -type d -empty -delete 2>/dev/null || true
  rm -rf "plugins/$old" 2>/dev/null || true
  echo "removed plugins/$old"
done

echo "structural moves complete — now fix agent frontmatter + plugin.json + conductor + catalog"
