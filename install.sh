#!/usr/bin/env bash
# Symlink grimoire skills into agent skill directories (Claude Code, Codex, Cursor, ...).
#
# Claude Code users: prefer the plugin marketplace (see README) -- it also ships
# the agents, hooks and scripts. This installer links SKILL.md folders only, and
# links instead of copying, so `git pull` updates every installed skill in place.
# Install names come from each SKILL.md frontmatter `name:`.
#
#   ./install.sh --codex                      # link all skills into ~/.agents/skills (Codex & co.)
#   ./install.sh --cursor                     # ... into ~/.cursor/skills
#   ./install.sh --claude                     # ... into ~/.claude/skills
#   ./install.sh --all-agents                 # ... into all three
#   ./install.sh --target DIR                 # ... into any directory (repeatable)
#   ./install.sh --codex --plugin taste-skill # only skills from these plugins (repeatable)
#   ./install.sh --codex caveman ponytail     # only these skills (by install name)
#   ./install.sh --list                       # show install name -> plugin/folder
#   ./install.sh --codex --uninstall          # remove links pointing at this repo
#
# Requires bash 3.2+. No other dependencies.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$ROOT/plugins"

targets=()
plugins=()
wanted=()
mode=install

usage() { awk 'NR>1 { if ($0 !~ /^#/) exit; sub(/^# ?/, ""); print }' "${BASH_SOURCE[0]}"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --claude)     targets+=("$HOME/.claude/skills") ;;
    --codex)      targets+=("$HOME/.agents/skills") ;;
    --cursor)     targets+=("$HOME/.cursor/skills") ;;
    --all-agents) targets+=("$HOME/.claude/skills" "$HOME/.agents/skills" "$HOME/.cursor/skills") ;;
    --target)     [[ $# -ge 2 ]] || { echo "error: --target needs a directory" >&2; exit 2; }
                  targets+=("$2"); shift ;;
    --plugin)     [[ $# -ge 2 ]] || { echo "error: --plugin needs a plugin name" >&2; exit 2; }
                  plugins+=("$2"); shift ;;
    --list)       mode=list ;;
    --uninstall)  mode=uninstall ;;
    -h|--help)    usage; exit 0 ;;
    -*)           echo "error: unknown flag: $1" >&2; exit 2 ;;
    *)            wanted+=("$1") ;;
  esac
  shift
done

if [[ $mode != list && ${#targets[@]} -eq 0 ]]; then
  echo "error: pick a target: --codex, --cursor, --claude, --all-agents or --target DIR" >&2
  exit 2
fi

# in_list <value> <items...> -- true if value is one of items
in_list() {
  local v="$1" i; shift
  for i in "$@"; do [[ $i == "$v" ]] && return 0; done
  return 1
}

# owned_by_repo <symlink> -- true if it resolves into this repo's plugins/
owned_by_repo() {
  local t d
  t="$(readlink "$1")" || return 1
  [[ $t == /* ]] || t="$(dirname "$1")/$t"
  d="$(cd "$(dirname "$t")" 2>/dev/null && pwd -P)" || return 1
  [[ $d/ == "$(cd "$PLUGINS_DIR" && pwd -P)"/* ]]
}

# install_name <SKILL.md> -- frontmatter `name:`, quotes stripped
install_name() {
  awk '
    NR==1 && $0!="---" { exit }
    NR>1 && /^---[[:space:]]*$/ { exit }
    NR>1 && /^name:/ { sub(/^name:[[:space:]]*/, ""); gsub(/^["'\'']|["'\'']$/, ""); print; exit }
  ' "$1"
}

grimoire_plugins_installed() {
  grep -q '@grimoire-cc-mmz' "$HOME/.claude/plugins/installed_plugins.json" 2>/dev/null
}

if [[ $mode == install ]] && in_list "$HOME/.claude/skills" "${targets[@]}" && grimoire_plugins_installed; then
  echo "warn: grimoire plugins are already installed in Claude Code; linking into ~/.claude/skills duplicates them" >&2
fi

found=()
all_names=()
for md in "$PLUGINS_DIR"/*/skills/*/SKILL.md; do
  [[ -f $md ]] || continue
  dir="$(dirname "$md")"
  plugin="$(basename "$(dirname "$(dirname "$dir")")")"
  name="$(install_name "$md")"
  [[ -n $name ]] || name="$(basename "$dir")"
  all_names+=("$name")

  if [[ ${#plugins[@]} -gt 0 ]] && ! in_list "$plugin" "${plugins[@]}"; then continue; fi
  if [[ ${#wanted[@]} -gt 0 ]] && ! in_list "$name" "${wanted[@]}"; then continue; fi
  found+=("$name")
  rel="plugins/$plugin/skills/$(basename "$dir")"

  if [[ $mode == list ]]; then
    printf '%-28s %s\n' "$name" "$rel"
    continue
  fi

  for target in "${targets[@]}"; do
    link="$target/$name"
    if [[ $mode == uninstall ]]; then
      if [[ -L $link ]] && owned_by_repo "$link"; then rm "$link"; echo "removed  $link"; fi
      continue
    fi
    mkdir -p "$target"
    if [[ -L $link ]]; then
      if owned_by_repo "$link"; then
        rm "$link"
      else
        echo "skip     $link (symlink to another install -- remove it first)" >&2
        continue
      fi
    elif [[ -e $link ]]; then
      echo "skip     $link (real file/dir, not a symlink -- move it aside first)" >&2
      continue
    fi
    ln -s "$dir" "$link"
    echo "linked   $link -> $rel"
  done

  if [[ $mode == install ]] && grep -q 'CLAUDE_PLUGIN_ROOT' "$md"; then
    echo "note     $name runs plugin scripts via \${CLAUDE_PLUGIN_ROOT}; full behavior needs the Claude Code plugin" >&2
  fi
done

# Unfiltered uninstall also sweeps stale links (skills renamed or removed upstream).
if [[ $mode == uninstall && ${#plugins[@]} -eq 0 && ${#wanted[@]} -eq 0 ]]; then
  for target in "${targets[@]}"; do
    for link in "$target"/*; do
      if [[ -L $link ]] && owned_by_repo "$link"; then rm "$link"; echo "removed  $link"; fi
    done
  done
fi

missing=()
for w in ${wanted[@]+"${wanted[@]}"}; do
  in_list "$w" ${found[@]+"${found[@]}"} || missing+=("$w")
done
if [[ ${#missing[@]} -gt 0 ]]; then
  for w in "${missing[@]}"; do echo "error: no skill named '$w'" >&2; done
  echo "valid install names:" >&2
  printf '  %s\n' "${all_names[@]}" | sort >&2
  exit 1
fi
if [[ ${#plugins[@]} -gt 0 && ${#found[@]} -eq 0 ]]; then
  echo "error: no skills in plugin(s): ${plugins[*]}" >&2
  exit 1
fi
