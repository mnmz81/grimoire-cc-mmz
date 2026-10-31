#!/usr/bin/env bash
# Usage: np-audit.sh   (run inside a repo)
# Scans tracked files AND every commit in history for secrets and personal data. Exit 1 on any hit.
# History scan passes all commit ids as args, fine up to a few thousand commits.
set -uo pipefail
fail=0
hit() { echo "FAIL: $1" >&2; fail=1; }

if command -v gitleaks >/dev/null; then
  gitleaks detect --no-banner --redact -v >&2 || hit "gitleaks found secrets in history"
else
  echo "WARN: gitleaks not installed, history secret scan skipped (brew install gitleaks)" >&2
fi

bad=$(git ls-files | grep -E '(^|/)(\.dev\.vars|\.env(\..*)?|[^/]*\.(pem|key|p12))$' | grep -v '\.env\.example$' || true)
[ -z "$bad" ] || hit "secret-type files tracked: $bad"

revs=$(git rev-list --all)
x=(':!*lock*' ':!*.min.*' ':!LICENSE')
scan() { # label regex [allowlist-regex]
  out=$({ git grep -InE "$2" -- . "${x[@]}"
          [ -z "$revs" ] || git grep -InE "$2" $revs -- . "${x[@]}" | sed -E 's/^[0-9a-f]{40}://'
        } | sort -u | grep -viE "${3:-^\$a}" || true)
  [ -z "$out" ] || hit "$1 (current files or any commit):"$'\n'"$out"
}
scan "local machine paths" '(/Users/[A-Za-z][A-Za-z0-9._-]*|/home/[A-Za-z][A-Za-z0-9._-]*|[A-Z]:\\Users\\)' '/Users/(runner|you|name|user)([^A-Za-z]|$)|/home/(runner|you|name|user)([^A-Za-z]|$)'
scan "email addresses" '[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}' 'noreply|example\.(com|org)|@types/'
scan "phone numbers" '(^|[^0-9])(\+972[- ]?|0)[2-9][0-9]?[- ]?[0-9]{3}[- ]?[0-9]{4}([^0-9]|$)'

emails=$(git log --all --format='%ae%n%ce' | sort -u | grep -v 'noreply' || true)
[ -z "$emails" ] || hit "non-noreply emails in commit history (rewrite history or start fresh): $emails"

[ $fail -eq 0 ] && echo "Audit passed." || { echo "Audit FAILED. Fix, then rerun." >&2; exit 1; }
