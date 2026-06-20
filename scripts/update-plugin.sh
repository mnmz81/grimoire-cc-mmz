#!/usr/bin/env bash
# update-plugin.sh — regenerate catalog, commit, push, and refresh the local
# Claude Code marketplace clone + plugin cache so changes take effect immediately.
#
# Usage:
#   scripts/update-plugin.sh                    # auto-commit with generated message
#   scripts/update-plugin.sh "commit message"   # custom commit message
#   scripts/update-plugin.sh --catalog-only     # regenerate catalog, no commit/push/refresh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

MARKETPLACE_CLONE="$HOME/.claude/plugins/marketplaces/grimoire-cc-mmz"
PLUGIN_CACHE="$HOME/.claude/plugins/cache/grimoire-cc-mmz"
INSTALLED_PLUGINS="$HOME/.claude/plugins/installed_plugins.json"
CATALOG_ONLY=false
COMMIT_MSG=""

for arg in "$@"; do
  case "$arg" in
    --catalog-only) CATALOG_ONLY=true ;;
    *) COMMIT_MSG="$arg" ;;
  esac
done

# --- Step 1: Regenerate catalog ---
echo "==> Regenerating catalog (marketplace.json + INVENTORY.md)..."
python3 scripts/generate-catalog.py
echo "    done."

if $CATALOG_ONLY; then
  echo "==> --catalog-only: stopping here."
  exit 0
fi

# --- Step 2: Stage and commit ---
echo "==> Staging changes..."
git add -A

if git diff --cached --quiet; then
  echo "    nothing to commit — working tree clean."
else
  if [ -z "$COMMIT_MSG" ]; then
    changed=$(git diff --cached --name-only | head -20)
    COMMIT_MSG="Update plugin: $(echo "$changed" | head -3 | tr '\n' ', ' | sed 's/,$//')"
  fi
  echo "    committing: $COMMIT_MSG"
  git commit -m "$COMMIT_MSG"
fi

# --- Step 3: Push to origin ---
BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "==> Pushing $BRANCH to origin..."
git push origin "$BRANCH"
NEW_SHA=$(git rev-parse HEAD)
echo "    pushed: $NEW_SHA"

# --- Step 4: Update marketplace clone ---
if [ -d "$MARKETPLACE_CLONE/.git" ]; then
  echo "==> Updating marketplace clone at $MARKETPLACE_CLONE..."
  git -C "$MARKETPLACE_CLONE" fetch origin
  git -C "$MARKETPLACE_CLONE" reset --hard "origin/$BRANCH"
  CLONE_SHA=$(git -C "$MARKETPLACE_CLONE" rev-parse HEAD)
  echo "    clone now at: $CLONE_SHA"
else
  echo "    !! marketplace clone not found at $MARKETPLACE_CLONE — skipping."
fi

# --- Step 5: Clear stale plugin caches ---
if [ -d "$PLUGIN_CACHE" ]; then
  echo "==> Clearing plugin cache at $PLUGIN_CACHE..."
  rm -rf "$PLUGIN_CACHE"
  echo "    cleared. Plugins will re-cache on next install/use."
fi

# --- Step 6: Update installed_plugins.json SHA ---
if [ -f "$INSTALLED_PLUGINS" ]; then
  echo "==> Updating gitCommitSha in installed_plugins.json..."
  if command -v python3 &>/dev/null; then
    python3 -c "
import json, sys
path = sys.argv[1]
sha = sys.argv[2]
with open(path) as f:
    data = json.load(f)
updated = 0
for key, entries in data.get('plugins', {}).items():
    if '@grimoire-cc-mmz' not in key:
        continue
    for entry in entries:
        entry['gitCommitSha'] = sha
        updated += 1
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
print(f'    updated {updated} entries to {sha}')
" "$INSTALLED_PLUGINS" "$NEW_SHA"
  else
    echo "    !! python3 not found — skipping SHA update."
  fi
fi

echo ""
echo "==> Done. Restart Claude Code to pick up the changes."
