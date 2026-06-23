#!/usr/bin/env bash
# open-audit-issues.sh — open one GitHub issue per bug-hunt finding, idempotently.
#
# Vendored with the bug-hunting plugin; the `hunt` skill invokes it as
#   ${CLAUDE_PLUGIN_ROOT}/scripts/open-audit-issues.sh --new <ID> <SEVERITY> <CATEGORY> "<TITLE>" "<DESC>"
#
# Project-agnostic: no state file, no hardcoded report paths. Idempotency comes
# from the issue title ("[AUDIT] <ID>:") — if an issue with that prefix already
# exists in any state, the call skips silently. Labels are created on demand.
#
# Requires: gh (authenticated), run from inside the target git repo.

set -euo pipefail

usage() {
  echo "Usage: $0 --new <ID> <SEVERITY> <CATEGORY> \"<TITLE>\" \"<DESC>\"" >&2
  exit 1
}

[ "${1:-}" = "--new" ] || usage
[ "$#" -ge 6 ] || usage

id="$2" severity="$3" category="$4" title="$5" description="$6"

# Ensure the labels this finding needs exist (idempotent; --force updates color).
gh label create "audit"               --color "0075ca" --description "Audit finding"            --force >/dev/null 2>&1 || true
gh label create "severity:$severity"  --color "d73a4a" --description "Severity: $severity"      --force >/dev/null 2>&1 || true
gh label create "category:$category"  --color "c2e0c6" --description "Category: $category"      --force >/dev/null 2>&1 || true

issue_title="[AUDIT] $id: $title"

# Idempotency: skip if an issue with this ID prefix already exists in any state.
count=$(gh issue list --search "in:title \"[AUDIT] $id:\"" --state all --json number --jq 'length' 2>/dev/null || echo 0)
if [ "$count" -gt 0 ]; then
  echo "skip $id — issue already exists"
  exit 0
fi

body="## [AUDIT] $id — $title

**Severity:** $severity
**Category:** $category
**Status:** 🔴 Open — not yet addressed

---

$description"

url=$(gh issue create --title "$issue_title" --body "$body" \
  --label "audit,severity:$severity,category:$category")
echo "created ${url##*/} $id"
