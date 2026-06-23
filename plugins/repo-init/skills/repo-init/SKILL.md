---
name: repo-init
description: >
  Initialize a new GitHub repository with enterprise-grade defaults: branch protection
  (no direct push to main, require PR + 1 approval, dismiss stale reviews), CI status
  checks required, squash-merge enforced, secret scanning, Dependabot alerts, and
  auto-delete of merged branches. Use whenever the user wants to create a new repo,
  set up a project from scratch, bootstrap a repository, or configure branch protections —
  even if they don't say "enterprise" explicitly.
argument-hint: "<repo-name> [--type Node] [--public] [--required-checks ci,lint]"
license: MIT
---

# repo-init

Create and configure a GitHub repository with enterprise-grade defaults in one shot.

## What it does

1. Creates a new GitHub repo (org or personal)
2. Initializes with `main` branch, README.md, and language-specific `.gitignore`
3. Applies branch protection: no direct push, require PR + 1 approval, dismiss stale reviews
4. Enforces squash merge (linear history), requires CI status checks
5. Enables secret scanning + Dependabot vulnerability alerts
6. Configures auto-delete of feature branches after merge

## Prerequisites

- `gh` CLI installed and authenticated (`gh auth status`)
- `jq` installed (used to build/verify JSON payloads)
- Sufficient permissions: repo admin (or org owner for org repos)
- For Dependabot/secret scanning: repo must be on a plan that supports them (public repos or GitHub Advanced Security)

## Usage

Run the bundled script. It ships with this plugin, so it travels on install:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/repo-init.sh" <repo-name> [options]
```

### Required argument

| Arg | Description |
|-----|-------------|
| `<repo-name>` | Repository name. For org repos use `org/repo-name` format. |

### Options

| Flag | Default | Description |
|------|---------|-------------|
| `--type` | `Node` | `.gitignore` template: `Node`, `Python`, `Go`, `Java`, `Rust`, `Ruby`, `CSharp` |
| `--private` | (set) | Create as private repo. Use `--public` to override. |
| `--public` | — | Create as public repo instead of private. |
| `--description` | `""` | Repo description string. |
| `--required-checks` | `""` | Comma-separated CI check names to require (e.g. `ci,lint,test`). |
| `--min-approvals` | `1` | Minimum PR review approvals before merge. |
| `--dry-run` | — | Print what would happen without making API calls. |

### Examples

```bash
# Personal private Node repo
"${CLAUDE_PLUGIN_ROOT}/scripts/repo-init.sh" my-app

# Org public Python repo with CI checks
"${CLAUDE_PLUGIN_ROOT}/scripts/repo-init.sh" acme-corp/data-pipeline \
  --type Python --public --required-checks "ci,lint" --description "ETL pipeline"

# Dry run to preview
"${CLAUDE_PLUGIN_ROOT}/scripts/repo-init.sh" my-app --dry-run
```

## How it works (step by step)

The script executes 5 phases sequentially. Each phase validates success before proceeding.

### Phase 1 — Create repository
Uses `gh repo create` with `--add-readme` and `--gitignore <template>`. Sets visibility (private default). Sets default branch to `main`.

### Phase 2 — Configure repo settings
Via GitHub REST API (`gh api`):
- Enable squash merge, disable merge commits and rebase merge → enforces linear history
- Enable auto-delete of head branches after PR merge

### Phase 3 — Branch protection on `main`
Applies branch protection ruleset via REST API:
- `required_pull_request_reviews`: min 1 approval, dismiss stale approvals, require review from code owners (if CODEOWNERS file exists)
- `required_status_checks`: strict mode (branch must be up-to-date), contexts from `--required-checks`
- `enforce_admins`: true (admins also bound by rules)
- `restrictions`: null (no push restrictions beyond requiring PR)
- Block direct pushes: the protection ruleset itself prevents direct push — only PRs are accepted

### Phase 4 — Security features
- Enable Dependabot vulnerability alerts via `gh api PUT /repos/{owner}/{repo}/vulnerability-alerts`
- Enable secret scanning via repo settings PATCH (if available on the plan)

### Phase 5 — Verification
Reads back the repo settings and branch protection rules, prints a summary table confirming each setting was applied.

## Adapting for GitLab

The bundled script targets GitHub. For GitLab, the equivalent operations are:

| GitHub | GitLab equivalent |
|--------|-------------------|
| `gh repo create` | `glab repo create` or Projects API |
| Branch protection API | Protected Branches API (`POST /projects/:id/protected_branches`) |
| `required_pull_request_reviews` | `merge_requests_author_approval: false` + approval rules API |
| Dependabot | GitLab Dependency Scanning CI template |
| Secret scanning | GitLab Secret Detection CI template |
| Auto-delete branches | Project setting `remove_source_branch_after_merge: true` |

## Error handling

The script exits on first failure (`set -euo pipefail`). Common failure modes:
- **Not authenticated**: run `gh auth login` first
- **Org permissions**: need admin role to set branch protection
- **Plan limitations**: secret scanning requires GitHub Advanced Security on private repos
- **Rate limits**: script includes retry with backoff for 403/429 responses

## Extending

To add more defaults (e.g., issue templates, PR templates, CODEOWNERS), add a Phase 6 to the script that commits those files via the Contents API or a local clone + push.
