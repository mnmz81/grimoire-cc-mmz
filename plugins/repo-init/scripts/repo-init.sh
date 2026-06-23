#!/usr/bin/env bash
# repo-init.sh — Create & configure a GitHub repo with enterprise-grade defaults
# Usage: repo-init.sh <repo-name> [--type Node] [--private|--public] [--description "..."]
#        [--required-checks "ci,lint"] [--min-approvals 1] [--dry-run]

set -euo pipefail

# ─── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BOLD='\033[1m'; RESET='\033[0m'

info()  { echo -e "${CYAN}▸${RESET} $*"; }
ok()    { echo -e "${GREEN}✔${RESET} $*"; }
warn()  { echo -e "${YELLOW}⚠${RESET} $*"; }
fail()  { echo -e "${RED}✖${RESET} $*" >&2; exit 1; }

# ─── Defaults ─────────────────────────────────────────────────────────────────
REPO_NAME=""
GITIGNORE_TYPE="Node"
VISIBILITY="private"
DESCRIPTION=""
REQUIRED_CHECKS=""
MIN_APPROVALS=1
DRY_RUN=false

# ─── Parse args ───────────────────────────────────────────────────────────────
[[ $# -eq 0 ]] && fail "Usage: repo-init.sh <repo-name> [options]\n  Run with --help for details."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)             GITIGNORE_TYPE="$2"; shift 2 ;;
    --private)          VISIBILITY="private"; shift ;;
    --public)           VISIBILITY="public"; shift ;;
    --description)      DESCRIPTION="$2"; shift 2 ;;
    --required-checks)  REQUIRED_CHECKS="$2"; shift 2 ;;
    --min-approvals)    MIN_APPROVALS="$2"; shift 2 ;;
    --dry-run)          DRY_RUN=true; shift ;;
    --help|-h)
      echo "Usage: repo-init.sh <repo-name> [options]"
      echo ""
      echo "Options:"
      echo "  --type <template>        .gitignore template (Node|Python|Go|Java|Rust|Ruby|CSharp) [Node]"
      echo "  --private                Create private repo (default)"
      echo "  --public                 Create public repo"
      echo "  --description <text>     Repository description"
      echo "  --required-checks <list> Comma-separated CI check names"
      echo "  --min-approvals <n>      Min PR approvals [1]"
      echo "  --dry-run                Preview without executing"
      exit 0
      ;;
    -*)                 fail "Unknown option: $1" ;;
    *)                  REPO_NAME="$1"; shift ;;
  esac
done

[[ -z "$REPO_NAME" ]] && fail "Repository name is required."

# ─── Derive owner/repo ────────────────────────────────────────────────────────
if [[ "$REPO_NAME" == */* ]]; then
  OWNER="${REPO_NAME%%/*}"
  REPO="${REPO_NAME##*/}"
  FULL_NAME="$REPO_NAME"
  ORG_FLAG="--org $OWNER"
else
  OWNER="$(gh api user --jq '.login' 2>/dev/null)" || fail "Cannot determine GitHub username. Run: gh auth login"
  REPO="$REPO_NAME"
  FULL_NAME="$OWNER/$REPO"
  ORG_FLAG=""
fi

# ─── Preflight ────────────────────────────────────────────────────────────────
command -v gh >/dev/null 2>&1 || fail "gh CLI not found. Install: https://cli.github.com"
gh auth status >/dev/null 2>&1 || fail "Not authenticated. Run: gh auth login"

echo ""
echo -e "${BOLD}repo-init${RESET} — Enterprise Repository Setup"
echo -e "────────────────────────────────────────────────"
echo -e "  Repository:    ${BOLD}$FULL_NAME${RESET}"
echo -e "  Visibility:    $VISIBILITY"
echo -e "  .gitignore:    $GITIGNORE_TYPE"
echo -e "  Min approvals: $MIN_APPROVALS"
echo -e "  CI checks:     ${REQUIRED_CHECKS:-none}"
echo -e "  Description:   ${DESCRIPTION:-<none>}"
echo ""

if $DRY_RUN; then
  warn "DRY RUN — no changes will be made."
  echo ""
fi

# ─── Helper: gh api with retry on rate limit ──────────────────────────────────
gh_api() {
  local method="$1"; shift
  local endpoint="$1"; shift
  local attempt=0
  local max_retries=3

  while (( attempt < max_retries )); do
    if gh api --method "$method" "$endpoint" "$@" 2>/dev/null; then
      return 0
    fi
    local exit_code=$?
    attempt=$((attempt + 1))
    if (( attempt < max_retries )); then
      warn "API call failed (attempt $attempt/$max_retries), retrying in $((attempt * 2))s..."
      sleep $((attempt * 2))
    fi
  done
  return 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# Phase 1 — Create Repository
# ═══════════════════════════════════════════════════════════════════════════════
info "Phase 1/5: Creating repository..."

if $DRY_RUN; then
  echo "  gh repo create $FULL_NAME --$VISIBILITY --add-readme --gitignore $GITIGNORE_TYPE"
else
  CREATE_ARGS=(
    "$FULL_NAME"
    "--$VISIBILITY"
    "--add-readme"
    "--gitignore" "$GITIGNORE_TYPE"
    "--clone=false"
  )
  [[ -n "$DESCRIPTION" ]] && CREATE_ARGS+=("--description" "$DESCRIPTION")

  gh repo create "${CREATE_ARGS[@]}" || fail "Failed to create repository."
  sleep 2  # Give GitHub a moment to initialize
  ok "Repository created: $FULL_NAME"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# Phase 2 — Configure Repo Settings
# ═══════════════════════════════════════════════════════════════════════════════
info "Phase 2/5: Configuring repository settings..."

REPO_SETTINGS='{
  "allow_squash_merge": true,
  "allow_merge_commit": false,
  "allow_rebase_merge": false,
  "squash_merge_commit_title": "PR_TITLE",
  "squash_merge_commit_message": "PR_BODY",
  "delete_branch_on_merge": true,
  "has_issues": true,
  "has_projects": true
}'

if $DRY_RUN; then
  echo "  PATCH /repos/$FULL_NAME"
  echo "  → squash merge only, auto-delete branches"
else
  echo "$REPO_SETTINGS" | gh_api PATCH "/repos/$FULL_NAME" --input - \
    || warn "Some repo settings may not have applied (check permissions)."
  ok "Squash merge enforced, auto-delete branches enabled"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# Phase 3 — Branch Protection on 'main'
# ═══════════════════════════════════════════════════════════════════════════════
info "Phase 3/5: Applying branch protection rules on 'main'..."

# Build status checks context array
CHECKS_JSON="[]"
if [[ -n "$REQUIRED_CHECKS" ]]; then
  CHECKS_JSON=$(echo "$REQUIRED_CHECKS" | tr ',' '\n' | jq -R . | jq -s .)
fi

PROTECTION_PAYLOAD=$(cat <<ENDJSON
{
  "required_status_checks": {
    "strict": true,
    "contexts": $CHECKS_JSON
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "required_approving_review_count": $MIN_APPROVALS
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false
}
ENDJSON
)

if $DRY_RUN; then
  echo "  PUT /repos/$FULL_NAME/branches/main/protection"
  echo "  → require PR, $MIN_APPROVALS approval(s), dismiss stale, enforce admins"
  echo "  → require status checks (strict): ${REQUIRED_CHECKS:-none}"
  echo "  → linear history, no force push, no deletion"
else
  echo "$PROTECTION_PAYLOAD" | gh_api PUT "/repos/$FULL_NAME/branches/main/protection" --input - \
    || warn "Branch protection partially applied (some features may require a higher plan)."
  ok "Branch protection applied to 'main'"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# Phase 4 — Security Features
# ═══════════════════════════════════════════════════════════════════════════════
info "Phase 4/5: Enabling security features..."

if $DRY_RUN; then
  echo "  PUT /repos/$FULL_NAME/vulnerability-alerts"
  echo "  PATCH /repos/$FULL_NAME → security_and_analysis.secret_scanning.status=enabled"
else
  # Dependabot vulnerability alerts
  gh_api PUT "/repos/$FULL_NAME/vulnerability-alerts" 2>/dev/null \
    && ok "Dependabot vulnerability alerts enabled" \
    || warn "Dependabot alerts may not be available on this plan."

  # Secret scanning
  SECURITY_PAYLOAD='{
    "security_and_analysis": {
      "secret_scanning": { "status": "enabled" },
      "secret_scanning_push_protection": { "status": "enabled" }
    }
  }'
  echo "$SECURITY_PAYLOAD" | gh_api PATCH "/repos/$FULL_NAME" --input - 2>/dev/null \
    && ok "Secret scanning + push protection enabled" \
    || warn "Secret scanning may require GitHub Advanced Security (available on public repos or GHAS license)."
fi

# ═══════════════════════════════════════════════════════════════════════════════
# Phase 5 — Verification
# ═══════════════════════════════════════════════════════════════════════════════
info "Phase 5/5: Verifying configuration..."

if $DRY_RUN; then
  echo "  (skipped in dry-run mode)"
else
  echo ""
  echo -e "${BOLD}Configuration Summary${RESET}"
  echo "────────────────────────────────────────────────"

  # Repo settings
  REPO_DATA=$(gh api "/repos/$FULL_NAME" 2>/dev/null || echo "{}")
  SQUASH=$(echo "$REPO_DATA" | jq -r '.allow_squash_merge // "unknown"')
  MERGE=$(echo "$REPO_DATA" | jq -r '.allow_merge_commit // "unknown"')
  REBASE=$(echo "$REPO_DATA" | jq -r '.allow_rebase_merge // "unknown"')
  DEL_BRANCH=$(echo "$REPO_DATA" | jq -r '.delete_branch_on_merge // "unknown"')
  VIS=$(echo "$REPO_DATA" | jq -r '.visibility // "unknown"')

  check_mark() { [[ "$1" == "true" ]] && echo -e "${GREEN}✔${RESET}" || echo -e "${RED}✖${RESET}"; }
  inv_check()  { [[ "$1" == "false" ]] && echo -e "${GREEN}✔${RESET}" || echo -e "${RED}✖${RESET}"; }

  echo -e "  $(check_mark "$SQUASH")  Squash merge enabled"
  echo -e "  $(inv_check "$MERGE")  Merge commits disabled"
  echo -e "  $(inv_check "$REBASE")  Rebase merge disabled"
  echo -e "  $(check_mark "$DEL_BRANCH")  Auto-delete branches"
  echo -e "  Visibility: $VIS"

  # Branch protection
  BP_DATA=$(gh api "/repos/$FULL_NAME/branches/main/protection" 2>/dev/null || echo "{}")
  if [[ "$BP_DATA" != "{}" ]]; then
    APPROVALS=$(echo "$BP_DATA" | jq -r '.required_pull_request_reviews.required_approving_review_count // "?"')
    DISMISS=$(echo "$BP_DATA" | jq -r '.required_pull_request_reviews.dismiss_stale_reviews // "?"')
    ENFORCE=$(echo "$BP_DATA" | jq -r '.enforce_admins.enabled // "?"')
    LINEAR=$(echo "$BP_DATA" | jq -r '.required_linear_history.enabled // "?"')
    echo -e "  ${GREEN}✔${RESET}  Branch protection on 'main'"
    echo -e "       Required approvals: $APPROVALS"
    echo -e "       Dismiss stale reviews: $DISMISS"
    echo -e "       Enforce for admins: $ENFORCE"
    echo -e "       Linear history: $LINEAR"
  else
    echo -e "  ${YELLOW}⚠${RESET}  Could not read branch protection (may need a moment to propagate)"
  fi

  echo ""
  echo -e "${GREEN}${BOLD}Done!${RESET} Repository ready at: ${CYAN}https://github.com/$FULL_NAME${RESET}"
fi

echo ""
