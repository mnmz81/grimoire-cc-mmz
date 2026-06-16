#!/usr/bin/env bash
# collect.sh — gather scattered Claude Code skills & agents into this repo (Phase 1).
# Lossless: on a destination-name collision, append the source tag instead of overwriting.
# Emits a TSV provenance log to scripts/collected.tsv: TYPE\tNAME\tCAME_FROM\tDEST
#
# Usage: scripts/collect.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DST="$REPO_ROOT/skills"
AGENTS_DST="$REPO_ROOT/agents"
LOG="$REPO_ROOT/scripts/collected.tsv"

mkdir -p "$SKILLS_DST" "$AGENTS_DST"
: > "$LOG"

# --- Skill sources: "tag|path-to-skills-root" (each subdir with SKILL.md is one skill) ---
SKILL_SOURCES=(
  "global|/Users/mzakay/.claude/skills"
  "Mushilu-San-UI|/Users/mzakay/Desktop/code project/Mushilu-San-UI/.claude/skills"
  "miluim-hr|/Users/mzakay/Desktop/code project/miluim hr/skills"
)

# --- Agent sources: "tag|path-to-agents-dir|glob" (each matching file is one agent) ---
AGENT_SOURCES=(
  "Mushilu-San-UI|/Users/mzakay/Desktop/code project/Mushilu-San-UI/.claude/agents|*.md"
  "Mushilu-San-UI-team|/Users/mzakay/Desktop/code project/Mushilu-San-UI/team/agents|*.agent.md"
)

echo "== Collecting skills =="
for entry in "${SKILL_SOURCES[@]}"; do
  tag="${entry%%|*}"; root="${entry#*|}"
  [ -d "$root" ] || { echo "  (skip, missing: $root)"; continue; }
  while IFS= read -r skillmd; do
    src_dir="$(dirname "$skillmd")"
    name="$(basename "$src_dir")"
    dest="$SKILLS_DST/$name"
    if [ -e "$dest" ]; then
      dest="$SKILLS_DST/${name}__${tag}"
      name="${name}__${tag}"
    fi
    cp -R "$src_dir" "$dest"
    printf 'skill\t%s\t%s\t%s\n' "$(basename "$dest")" "$src_dir" "skills/$(basename "$dest")" >> "$LOG"
    echo "  + skill $(basename "$dest")  <- $src_dir"
  done < <(find "$root" -maxdepth 2 -name SKILL.md | sort)
done

echo "== Collecting agents =="
for entry in "${AGENT_SOURCES[@]}"; do
  tag="${entry%%|*}"; rest="${entry#*|}"; dir="${rest%|*}"; glob="${rest##*|}"
  [ -d "$dir" ] || { echo "  (skip, missing: $dir)"; continue; }
  while IFS= read -r f; do
    base="$(basename "$f")"
    dest="$AGENTS_DST/$base"
    if [ -e "$dest" ]; then
      stem="${base%.md}"
      dest="$AGENTS_DST/${stem}__${tag}.md"
    fi
    cp "$f" "$dest"
    printf 'agent\t%s\t%s\t%s\n' "$(basename "$dest")" "$f" "agents/$(basename "$dest")" >> "$LOG"
    echo "  + agent $(basename "$dest")  <- $f"
  done < <(find "$dir" -maxdepth 1 -name "$glob" | sort)
done

echo
echo "== Summary =="
echo "skills: $(grep -c '^skill' "$LOG" || true)"
echo "agents: $(grep -c '^agent' "$LOG" || true)"
