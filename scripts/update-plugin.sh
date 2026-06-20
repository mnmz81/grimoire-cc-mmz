#!/usr/bin/env bash
# update-plugin.sh — sync the current repo state into Claude Code's local
# marketplace clone and plugin cache so changes take effect on next session.
#
# BRANCH GUARD: only runs on the 'main' branch. Feature branches are blocked
# to prevent incomplete or untested changes from reaching the local plugin system.
#
# Usage: scripts/update-plugin.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

REQUIRED_BRANCH="main"
MARKETPLACE_CLONE="$HOME/.claude/plugins/marketplaces/grimoire-cc-mmz"
PLUGIN_CACHE="$HOME/.claude/plugins/cache/grimoire-cc-mmz"
INSTALLED_PLUGINS="$HOME/.claude/plugins/installed_plugins.json"

# --- Branch guard ---
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "$REQUIRED_BRANCH" ]; then
  echo "ERROR: update-plugin.sh can only run on '$REQUIRED_BRANCH'."
  echo "       Current branch: '$CURRENT_BRANCH'"
  echo "       Merge your changes to $REQUIRED_BRANCH first, then re-run."
  exit 1
fi

# --- Step 1: Regenerate catalog ---
echo "==> Regenerating catalog..."
python3 scripts/generate-catalog.py
echo "    done."

# --- Step 2: Sync into marketplace clone ---
if [ -d "$MARKETPLACE_CLONE" ]; then
  echo "==> Syncing to marketplace clone..."
  rsync -a --delete \
    --exclude='.git' \
    --exclude='.DS_Store' \
    --exclude='node_modules' \
    --exclude='__pycache__' \
    "$ROOT/" "$MARKETPLACE_CLONE/"
  echo "    synced."
else
  echo "    !! marketplace clone not found at $MARKETPLACE_CLONE — skipping."
fi

# --- Step 3: Clear plugin cache ---
if [ -d "$PLUGIN_CACHE" ]; then
  echo "==> Clearing plugin cache..."
  rm -rf "$PLUGIN_CACHE"
  echo "    cleared."
fi

# --- Step 4: Update SHA in installed_plugins.json ---
if [ -f "$INSTALLED_PLUGINS" ]; then
  LOCAL_SHA=$(git rev-parse HEAD 2>/dev/null || echo "local")
  echo "==> Updating installed_plugins.json (sha: $LOCAL_SHA)..."
  python3 -c "
import json, sys
path, sha = sys.argv[1], sys.argv[2]
with open(path) as f:
    data = json.load(f)
n = 0
for key, entries in data.get('plugins', {}).items():
    if '@grimoire-cc-mmz' not in key:
        continue
    for e in entries:
        e['gitCommitSha'] = sha
        n += 1
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
print(f'    updated {n} entries.')
" "$INSTALLED_PLUGINS" "$LOCAL_SHA"
fi

echo ""
echo "==> Done. Restart Claude Code to pick up changes."
