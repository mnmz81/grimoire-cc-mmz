#!/usr/bin/env bash
# vendor-taste-skill.sh — copy upstream leonxlnx/taste-skill skills into
# plugins/taste-skill/ (vendored, not installed). Re-run to sync with upstream.
#
# Usage: scripts/vendor-taste-skill.sh [git-ref]   # default: main
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="https://github.com/leonxlnx/taste-skill"
REF="${1:-main}"
DEST="$ROOT/plugins/taste-skill"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "==> Cloning $REPO@$REF..."
git clone -q --depth 1 --branch "$REF" "$REPO" "$TMP/src"
SHA="$(git -C "$TMP/src" rev-parse HEAD)"

echo "==> Syncing skills into $DEST/skills..."
mkdir -p "$DEST/skills"
rsync -a --delete --exclude='llms.txt' "$TMP/src/skills/" "$DEST/skills/"
cp "$TMP/src/LICENSE" "$DEST/LICENSE"

echo "==> Applying local overrides from $DEST/overrides..."
python3 - "$DEST" <<'PY'
import json, sys
from pathlib import Path

dest = Path(sys.argv[1])
ov = dest / "overrides"
for f in sorted(ov.glob("*.description.txt")) + sorted(ov.glob("*.append.md")):
    folder, kind = f.name.split(".", 1)
    skill = dest / "skills" / folder / "SKILL.md"
    if not skill.exists():
        sys.exit(f"override {f.name}: no skills/{folder}/SKILL.md (upstream renamed?)")
    text = skill.read_text()
    val = f.read_text().strip()
    if kind == "description.txt":
        head, sep, body = text.partition("\n---\n")
        lines = head.splitlines()
        idx = [i for i, l in enumerate(lines) if l.startswith("description:")]
        if not text.startswith("---\n") or not sep or not idx:
            sys.exit(f"override {f.name}: no frontmatter description in {skill}")
        lines[idx[0]] = "description: " + json.dumps(val, ensure_ascii=False)
        text = "\n".join(lines) + sep + body
    else:
        text = text.rstrip("\n") + "\n\n" + val + "\n"
    skill.write_text(text)
    print(f"    {f.name} -> skills/{folder}/SKILL.md")
PY

cat > "$DEST/UPSTREAM.md" <<MD
# Upstream

Vendored from [$REPO]($REPO) (MIT) — commit \`$SHA\` (ref \`$REF\`).

Do not edit \`skills/\` by hand; re-sync with \`scripts/vendor-taste-skill.sh [ref]\`.
Local deltas live in \`overrides/\` and are re-applied on every sync.
MD

echo "    done: $(ls "$DEST/skills" | wc -l | tr -d ' ') skills @ ${SHA:0:7}"
