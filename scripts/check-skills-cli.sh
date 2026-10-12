#!/usr/bin/env bash
# check-skills-cli.sh — assert `npx skills add` discovers every SKILL.md in this repo.
#
# The vercel-labs `skills` CLI finds our skills through .claude-plugin/marketplace.json
# and silently skips any SKILL.md whose frontmatter is not strict YAML. This gate
# catches both: a skipped file, or a discovered count that differs from disk.
#
# Usage: scripts/check-skills-cli.sh [skills-cli-version]   # default: pinned below
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:-1.7.2}"

expected="$(find "$ROOT/plugins" -path '*/skills/*/SKILL.md' | wc -l | tr -d ' ')"
out="$(cd "$ROOT" && DO_NOT_TRACK=1 DISABLE_TELEMETRY=1 npx -y "skills@$VERSION" add . --list 2>&1 \
  | sed -e 's/\x1b\[[0-9;?]*[A-Za-z]//g')"

skipped="$(grep -E 'Skipped' <<<"$out" || true)"
found="$(grep -cE '^│    [a-z0-9][a-z0-9-]*$' <<<"$out" || true)"

if [[ -n $skipped ]]; then
  echo "skills CLI skipped files:" >&2
  echo "$skipped" >&2
  exit 1
fi
if [[ $found -ne $expected ]]; then
  echo "skills@$VERSION discovered $found skills, expected $expected" >&2
  exit 1
fi
echo "skills@$VERSION discovers all $found skills"
