---
name: new-public-project
description: >
  Start a new project that will be public on GitHub, secure from the first commit. Scaffolds
  the project locally (LICENSE, SECURITY.md, CODEOWNERS, PR and issue templates, CI with
  gitleaks + CodeQL + PR-title lint, Dependabot, .editorconfig, .claude deny rules for secrets,
  secret-blocking pre-commit hook, noreply git email), creates a PRIVATE repo, and later runs a
  secrets and personal-data audit before flipping it public and applying branch protection
  (PR only, 1 code-owner approval, owner bypass via PR, squash only, no force-push, protected
  release tags), push protection, secret scanning, and locked-down GitHub Actions.
  Use whenever the user wants to start, create, bootstrap or open-source a new project or repo,
  or says "new project", "new repo", "make it public", "publish this repo", "פרויקט חדש",
  "ריפו חדש", "להפוך לציבורי".
argument-hint: "<name> [--type ts|node|python|static] [--desc text]"
---

# new-public-project

Two stages, because on the GitHub free plan branch protection and secret scanning only work on public repos. Work happens in a private repo first, then an audit gates the flip to public.

Scripts live in `${CLAUDE_PLUGIN_ROOT}/scripts/`. Needs `gh` (authenticated), `git`, `perl`; `gitleaks` recommended (`brew install gitleaks`).

## Stage 1: start the project (private)

1. Ask the user for the project name, stack (`ts`, `node`, `python`, `static`), and a one-line description if not given.
2. Run in the folder where the project should live:
   ```bash
   ${CLAUDE_PLUGIN_ROOT}/scripts/np-init.sh <name> --type <stack> --desc "<text>"
   ```
   It creates `./<name>`, scaffolds files, pins every GitHub Action to a commit SHA, installs and self-tests the secret-blocking hook, sets the project's git email to the GitHub noreply address and the commit name to the GitHub username (never the real name), makes the first commit, and creates the PRIVATE repo. Add `--no-remote` for a local-only scaffold.
3. Tell the user the repo is private and protections are not active yet (free plan limit), so they work on branches anyway.

## Stage 2: publish (public)

1. If the site serves users in Israel, run the `il-web-compliance` skill first. Do not publish on a FAIL without the user's explicit OK.
2. From the repo folder run `np-publish.sh` with no flag. It runs `np-audit.sh`: gitleaks on history, tracked secret files, local paths (`/Users/...`), email addresses and Israeli phone numbers (in current files and in every past commit, so a leak deleted later is still caught), non-noreply emails in commit history. Fix every hit before going on.
3. Ask the user, in plain words, to confirm making the repo public. This is the one irreversible step: once public, anything in the history is exposed.
4. Only after a clear yes, run `np-publish.sh --yes`. It makes the repo public and applies:
   - ruleset `protect-main`: PR only, 1 approval from the code owner, stale approvals dismissed, threads resolved, squash only, linear history, no force-push or delete, required checks `gitleaks`, `pr-title` (+ `ci`). Repo admin (the owner) may bypass through a PR, so a force merge stays possible but direct push does not.
   - ruleset `protect-release-tags`: `v*` tags cannot be moved or deleted.
   - secret scanning + push protection, Dependabot alerts and security fixes, private vulnerability reporting.
   - Actions: read-only default token, approval required for all outside-contributor runs, only GitHub-owned, verified and listed actions.
   - squash-merge only, auto-delete merged branches, wiki, projects and discussions off.

## Notes and limits

- `ci` and `codeql` skip their steps until the repo has a `package.json` or source files, so a fresh scaffold passes its required checks.
- If the repo gets a required check from a new workflow, add its job name to the `checks` list in `np-publish.sh` (or edit the ruleset on GitHub).
- Branch protection is not applied while private. Do not invite collaborators before publishing.
- If a protection step fails, `np-publish.sh --yes` keeps going, prints `STEP FAILED` lines, and ends with `INCOMPLETE` and exit 1. The repo is already public then: fix the cause and rerun (an already-created ruleset will report a harmless duplicate error).
- Tested end to end on a throwaway repo: audit, public flip, rulesets, direct push to `main` rejected, and a PR where `gitleaks`, `pr-title`, `ci` and `codeql` all pass. Not tested: the owner force-merge (`gh pr merge --admin`), so try it once on your first real PR.
- Never bypass the pre-commit hook with `--no-verify` unless the user confirms a false positive.
