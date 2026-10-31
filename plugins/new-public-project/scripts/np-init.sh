#!/usr/bin/env bash
# Usage: np-init.sh <name> [--type ts|node|python|static] [--desc "text"] [--no-remote]
# Scaffolds a hardened project in ./<name>, creates a PRIVATE GitHub repo, pushes the first commit.
# Protections that need a public repo (free plan) are applied later by np-publish.sh.
set -euo pipefail

T="$(cd "$(dirname "$0")/.." && pwd)/templates"
name="${1:?usage: np-init.sh <name> [--type ts|node|python|static] [--desc text]}"; shift
type=ts desc="" remote=1
while [ $# -gt 0 ]; do
  case "$1" in
    --type) type="$2"; shift 2 ;;
    --desc) desc="$2"; shift 2 ;;
    --no-remote) remote=0; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done
[[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "bad repo name: $name" >&2; exit 2; }
gh auth status >/dev/null 2>&1 || { echo "gh not authenticated: run gh auth login" >&2; exit 1; }
[ ! -e "$name" ] || { echo "./$name already exists" >&2; exit 1; }

case "$type" in
  ts|node) ignore=Node eco=npm lang=javascript-typescript ci=node glob="'**/*.js', '**/*.jsx', '**/*.ts', '**/*.tsx'" ;;
  python)  ignore=Python eco=pip lang=python ci=python glob="'**/*.py'" ;;
  static)  ignore=Node eco="" lang=javascript-typescript ci="" glob="'**/*.js', '**/*.jsx', '**/*.ts', '**/*.tsx'" ;;
  *) echo "bad --type: $type" >&2; exit 2 ;;
esac

owner=$(gh api user --jq .login); uid=$(gh api user --jq .id)
mkdir "$name"; cd "$name"
git init -q -b main
# real email and name never land in commits
git config user.email "$uid+$owner@users.noreply.github.com"
git config user.name "$owner"

cp -R "$T/common/." .
[ -z "$ci" ] || cp "$T/ci/$ci.yml" .github/workflows/ci.yml
if [ -n "$eco" ]; then
  printf '  - package-ecosystem: %s\n    directory: /\n    schedule:\n      interval: weekly\n' "$eco" >> .github/dependabot.yml
fi
{ gh api "gitignore/templates/$ignore" --jq .source; cat "$T/gitignore-extra"; } > .gitignore

# fill placeholders (NAME/OWNER/YEAR/DESC/CODEQL_LANG)
files=$(grep -rlE '\{\{[A-Z_]+\}\}' . --exclude-dir=.git)
for f in $files; do
  OWNER="$owner" NAME="$name" YEAR="$(date +%Y)" DESC="${desc:-$name}" LANG_="$lang" GLOB="$glob" \
    perl -pi -e 's/\{\{OWNER\}\}/$ENV{OWNER}/g; s/\{\{NAME\}\}/$ENV{NAME}/g; s/\{\{YEAR\}\}/$ENV{YEAR}/g; s/\{\{DESC\}\}/$ENV{DESC}/g; s/\{\{CODEQL_LANG\}\}/$ENV{LANG_}/g; s/\{\{CODEQL_GLOB\}\}/$ENV{GLOB}/g' "$f"
done

# pin every "uses: x/y@tag # pin" to a commit SHA
grep -rhoE 'uses: [^ ]+@[^ ]+ # pin' .github/workflows | sort -u | while read -r _ ref _; do
  path=${ref%@*} tag=${ref#*@}
  sha=$(gh api "repos/$(echo "$path" | cut -d/ -f1-2)/commits/$tag" --jq .sha)
  PATH_="$path" TAG="$tag" SHA="$sha" perl -pi -e 's|uses: \Q$ENV{PATH_}\E\@\Q$ENV{TAG}\E # pin|uses: $ENV{PATH_}\@$ENV{SHA} # $ENV{TAG}|' .github/workflows/*.yml
done

# secret-blocking hook, then prove it works before relying on it
mkdir .githooks
cp "$T/githooks/pre-commit" .githooks/pre-commit
chmod +x .githooks/pre-commit
git config core.hooksPath .githooks
printf 'ok\n' > .hooktest
git add .hooktest
.githooks/pre-commit || { echo "hook self-test: normal file blocked" >&2; exit 1; }
printf 'password = "%s"\n' "$(printf 'x%.0s' {1..20})" > .hooktest
git add .hooktest
if .githooks/pre-commit 2>/dev/null; then echo "hook self-test: fake secret NOT blocked" >&2; exit 1; fi
git rm -qf --cached .hooktest; rm .hooktest

git add -A
git commit -q -m "chore: initial project scaffold"
if [ $remote = 0 ]; then echo "Local scaffold only (--no-remote): $(pwd)"; exit 0; fi
gh repo create "$name" --private --description "$desc" --source . --remote origin --push
echo "Created PRIVATE $owner/$name in $(pwd)."
echo "Branch protection needs a public repo on the free plan. Work, then run np-publish.sh."
