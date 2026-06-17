#!/usr/bin/env bash
# build-plugins.sh — Phase 2: reshape flat skills/ + agents/ into a domain-based
# plugin marketplace. Uses `git mv` to preserve history.
#
# Drops the non-standard team/agents/*.agent.md files (kept in git history / Phase 1).
#
# Usage: scripts/build-plugins.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

AUTHOR_NAME="Moris Zakay"
AUTHOR_URL="https://github.com/mnmz81"
AUTHOR_EMAIL="moriszakay42@gmail.com"

declare -a DOMAINS=(
  component-design
  component-quality
  bug-hunting
  studio-ops
  code-intelligence
  ai-coding-discipline
  skill-authoring
  ux-design
  code-review
)

skills_for() {
  case "$1" in
    component-design)     echo "compass blueprint conductor foreman" ;;
    component-quality)    echo "staff palette sentinel-a11y gauge marshal prowler scribe" ;;
    bug-hunting)          echo "hunt sleuth" ;;
    studio-ops)           echo "quartermaster warden curator" ;;
    code-intelligence)    echo "graphify" ;;
    ai-coding-discipline) echo "karpathy-guidelines" ;;
    skill-authoring)      echo "skill-qa-agent" ;;
    ux-design)            echo "ui-ux-design" ;;
    code-review)          echo "code-review" ;;
  esac
}

desc_for() {
  case "$1" in
    component-design)     echo "Plan and lock a UI component's contract before code — scoping, public API design, and build orchestration for the Mushilu-San Studio pipeline." ;;
    component-quality)    echo "Quality gates for UI components — staff review, token/design discipline, accessibility, bundle budget, unit + browser testing, and docs." ;;
    bug-hunting)          echo "Whole-repo bug sweeps and systematic debugging — a fan-out of read-only hunters plus a root-cause debugger." ;;
    studio-ops)           echo "Studio operations — release engineering, safety-marker hooks, and the learnings/memory log." ;;
    code-intelligence)    echo "Turn any codebase or input into a queryable knowledge graph for architecture and relationship questions." ;;
    ai-coding-discipline) echo "Behavioral guidelines that reduce common LLM coding mistakes — surgical changes and fewer overcomplications." ;;
    skill-authoring)      echo "Audit, grade, and improve Claude Code skills and Cursor rules, and resolve overlap between them." ;;
    ux-design)            echo "UI/UX design intelligence for web and mobile — accessibility, layout, typography, components, and data visualization." ;;
    code-review)          echo "Thorough JavaScript/TypeScript/Python code review across bugs, security, and performance." ;;
  esac
}

echo "== Building plugins =="
for d in "${DOMAINS[@]}"; do
  mkdir -p "plugins/$d/.claude-plugin" "plugins/$d/skills"
  for s in $(skills_for "$d"); do
    [ -d "skills/$s" ] || { echo "  !! missing skill: $s"; exit 1; }
    git mv "skills/$s" "plugins/$d/skills/$s"
    echo "  $d <- skill $s"
  done
  # agents: only bug-hunting gets the 10 generated hunters (the valid CC agents),
  # never the non-standard *.agent.md build sources.
  if [ "$d" = "bug-hunting" ]; then
    mkdir -p "plugins/$d/agents"
    for a in agents/hunt-*.md; do
      case "$a" in *.agent.md) continue ;; esac
      git mv "$a" "plugins/$d/agents/$(basename "$a")"
      echo "  $d <- agent $(basename "$a")"
    done
  fi
  cat > "plugins/$d/.claude-plugin/plugin.json" <<JSON
{
  "name": "$d",
  "version": "1.0.0",
  "description": "$(desc_for "$d")",
  "author": { "name": "$AUTHOR_NAME", "url": "$AUTHOR_URL" }
}
JSON
done

echo "== Dropping non-standard .agent.md build sources =="
git rm -q agents/*.agent.md
for dir in skills agents; do
  [ -d "$dir" ] || continue
  left=$(find "$dir" -type f | wc -l | tr -d ' ')
  [ "$left" -eq 0 ] || { echo "  !! $dir/ still has $left file(s):"; find "$dir" -type f; exit 1; }
  rm -rf "$dir"   # rm -rf tolerates stray .DS_Store that rmdir would choke on
done
echo "  removed empty top-level skills/ and agents/"

echo "== Writing marketplace.json =="
mkdir -p .claude-plugin
{
  echo '{'
  echo '  "name": "grimoire-cc-mmz",'
  echo "  \"owner\": { \"name\": \"$AUTHOR_NAME\", \"email\": \"$AUTHOR_EMAIL\", \"url\": \"$AUTHOR_URL\" },"
  echo '  "metadata": { "description": "Personal skills & agents, organized by domain.", "version": "1.0.0" },'
  echo '  "plugins": ['
  last=$(( ${#DOMAINS[@]} - 1 )); i=0
  for d in "${DOMAINS[@]}"; do
    sep=','; [ "$i" -eq "$last" ] && sep=''
    printf '    { "name": "%s", "source": "./plugins/%s", "description": "%s", "version": "1.0.0", "category": "development" }%s\n' \
      "$d" "$d" "$(desc_for "$d")" "$sep"
    i=$((i+1))
  done
  echo '  ]'
  echo '}'
} > .claude-plugin/marketplace.json

echo "== Done =="
