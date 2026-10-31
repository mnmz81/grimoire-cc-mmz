#!/usr/bin/env bash
# Usage: np-publish.sh [--yes]     (run inside the repo)
# Audits, then (with --yes, after the user confirmed) makes the repo public and applies all protections.
# Without --yes it only audits and prints what would happen.
set -euo pipefail

D="$(cd "$(dirname "$0")" && pwd)"
"$D/np-audit.sh"

repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
vis=$(gh repo view --json visibility --jq .visibility)
if [ "${1:-}" != "--yes" ]; then
  echo "Audit passed. $repo is $vis. Rerun with --yes to make it public and apply protections."
  exit 0
fi

[ "$vis" = PUBLIC ] || gh repo edit "$repo" --visibility public --accept-visibility-change-consequences
failed=()
api() { gh api -X "$1" "repos/$repo${2:+/$2}" "${@:3}" >/dev/null || { failed+=("$1 $2"); echo "STEP FAILED: $1 $2" >&2; }; }

# squash-only, auto-delete branches, no wiki/projects/discussions
api PATCH "" -F allow_squash_merge=true -F allow_merge_commit=false -F allow_rebase_merge=false \
  -F delete_branch_on_merge=true -F has_wiki=false -F has_projects=false -F has_discussions=false \
  -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=PR_BODY

# secret scanning + push protection, alerts, auto security PRs, private vulnerability reporting
api PATCH "" --input - <<<'{"security_and_analysis":{"secret_scanning":{"status":"enabled"},"secret_scanning_push_protection":{"status":"enabled"}}}'
api PUT vulnerability-alerts
api PUT automated-security-fixes
api PUT private-vulnerability-reporting

# Actions: read-only token, approve all outside-contributor workflow runs, trusted actions only
api PUT actions/permissions --input - <<<'{"enabled":true,"allowed_actions":"selected"}'
api PUT actions/permissions/selected-actions --input - <<<'{"github_owned_allowed":true,"verified_allowed":true,"patterns_allowed":["gitleaks/*","amannn/*"]}'
api PUT actions/permissions/workflow --input - <<<'{"default_workflow_permissions":"read","can_approve_pull_request_reviews":false}'
api PUT actions/permissions/fork-pr-contributor-approval --input - <<<'{"approval_policy":"all_external_contributors"}'

# required checks = jobs that exist in this repo's workflows
checks='[{"context":"gitleaks"},{"context":"pr-title"}'
[ ! -f .github/workflows/ci.yml ] || checks+=',{"context":"ci"}'
checks+=']'

# main: PR only, 1 approval from code owner, threads resolved, squash, no force-push/delete. Admin bypass via PR only.
has() { gh api "repos/$repo/rulesets" --jq ".[].name" | grep -qx "$1"; }
has protect-main || api POST rulesets --input - <<JSON
{"name":"protect-main","target":"branch","enforcement":"active",
 "conditions":{"ref_name":{"include":["~DEFAULT_BRANCH"],"exclude":[]}},
 "bypass_actors":[{"actor_id":5,"actor_type":"RepositoryRole","bypass_mode":"pull_request"}],
 "rules":[{"type":"deletion"},{"type":"non_fast_forward"},{"type":"required_linear_history"},
  {"type":"pull_request","parameters":{"required_approving_review_count":1,"dismiss_stale_reviews_on_push":true,
   "require_code_owner_review":true,"require_last_push_approval":false,"required_review_thread_resolution":true,
   "allowed_merge_methods":["squash"]}},
  {"type":"required_status_checks","parameters":{"strict_required_status_checks_policy":true,"required_status_checks":$checks}}]}
JSON

# release tags v*: cannot be moved or deleted
has protect-release-tags || api POST rulesets --input - <<'JSON'
{"name":"protect-release-tags","target":"tag","enforcement":"active",
 "conditions":{"ref_name":{"include":["refs/tags/v*"],"exclude":[]}},
 "rules":[{"type":"deletion"},{"type":"non_fast_forward"},{"type":"update"}]}
JSON

echo "$repo is public and protected:"
gh api "repos/$repo/rulesets" --jq '.[] | "  ruleset: \(.name) (\(.enforcement))"'
if [ ${#failed[@]} -gt 0 ]; then
  echo "INCOMPLETE: ${#failed[@]} step(s) failed, repo is public but NOT fully protected:" >&2
  printf "  %s\n" "${failed[@]}" >&2
  echo "Fix permissions, then rerun np-publish.sh --yes (safe to repeat; rulesets may need deleting first)." >&2
  exit 1
fi
