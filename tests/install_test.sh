#!/usr/bin/env bash
# Tests for install.sh. Every case runs against throwaway --target directories
# and a fake $HOME, so nothing touches the real agent skill folders.
#
# Usage: tests/install_test.sh

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL="$ROOT/install.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"
mkdir -p "$HOME"

failures=0
expected_count="$(find "$ROOT/plugins" -path '*/skills/*/SKILL.md' | wc -l | tr -d ' ')"

run_test() {
  local name="$1"; shift
  if ( "$@" ); then printf 'ok - %s\n' "$name"
  else printf 'not ok - %s\n' "$name" >&2; failures=$((failures + 1)); fi
}

fail() { printf '  %s\n' "$*" >&2; exit 1; }  # tests run in a subshell

fresh() { local d="$TMP/t$RANDOM$RANDOM"; mkdir -p "$d"; echo "$d"; }

count_links() { find "$1" -maxdepth 1 -type l | wc -l | tr -d ' '; }

test_no_target_is_an_error() {
  local status=0
  "$INSTALL" >/dev/null 2>&1 || status=$?
  [[ $status -eq 2 ]] || fail "expected exit 2, got $status"
}

test_list_shows_every_skill() {
  local n
  n="$("$INSTALL" --list | wc -l | tr -d ' ')"
  [[ $n -eq $expected_count ]] || fail "listed $n, expected $expected_count"
}

test_install_names_are_unique() {
  local dupes
  dupes="$("$INSTALL" --list | awk '{print $1}' | sort | uniq -d)"
  [[ -z $dupes ]] || fail "duplicate install names: $dupes"
}

test_installs_all_and_links_resolve() {
  local t; t="$(fresh)"
  "$INSTALL" --target "$t" >/dev/null 2>&1 || fail "install failed"
  [[ "$(count_links "$t")" -eq $expected_count ]] || fail "linked $(count_links "$t"), expected $expected_count"
  [[ -f $t/design-taste-frontend/SKILL.md ]] || fail "design-taste-frontend/SKILL.md not reachable"
  [[ -f $t/hunt/SKILL.md ]] || fail "hunt/SKILL.md not reachable"
}

test_reinstall_is_idempotent() {
  local t; t="$(fresh)"
  "$INSTALL" --target "$t" >/dev/null 2>&1 || fail "first install failed"
  "$INSTALL" --target "$t" >/dev/null 2>&1 || fail "re-install failed"
  [[ "$(count_links "$t")" -eq $expected_count ]] || fail "link count changed on re-install"
}

test_named_skills_only() {
  local t; t="$(fresh)"
  "$INSTALL" --target "$t" caveman ponytail >/dev/null 2>&1 || fail "install failed"
  [[ "$(count_links "$t")" -eq 2 && -L $t/caveman && -L $t/ponytail ]] || fail "expected only caveman + ponytail"
}

test_plugin_filter() {
  local t n; t="$(fresh)"
  n="$(find "$ROOT/plugins/taste-skill/skills" -name SKILL.md | wc -l | tr -d ' ')"
  "$INSTALL" --target "$t" --plugin taste-skill >/dev/null 2>&1 || fail "install failed"
  [[ "$(count_links "$t")" -eq $n ]] || fail "linked $(count_links "$t"), expected $n"
  [[ ! -e $t/hunt ]] || fail "hunt should not be linked"
}

test_unknown_skill_fails() {
  local t status=0 err; t="$(fresh)"
  err="$("$INSTALL" --target "$t" no-such-skill 2>&1 >/dev/null)" || status=$?
  [[ $status -eq 1 ]] || fail "expected exit 1, got $status"
  [[ $err == *"no skill named 'no-such-skill'"* ]] || fail "missing error message"
}

test_unknown_plugin_fails() {
  local t status=0; t="$(fresh)"
  "$INSTALL" --target "$t" --plugin nope >/dev/null 2>&1 || status=$?
  [[ $status -eq 1 ]] || fail "expected exit 1, got $status"
}

test_foreign_symlink_is_kept() {
  local t other; t="$(fresh)"; other="$(fresh)"
  ln -s "$other" "$t/caveman"
  "$INSTALL" --target "$t" caveman >/dev/null 2>&1
  [[ "$(readlink "$t/caveman")" == "$other" ]] || fail "foreign symlink was replaced"
}

test_real_dir_is_kept() {
  local t; t="$(fresh)"
  mkdir "$t/caveman"; echo keep > "$t/caveman/SKILL.md"
  "$INSTALL" --target "$t" caveman >/dev/null 2>&1
  [[ ! -L $t/caveman && "$(cat "$t/caveman/SKILL.md")" == keep ]] || fail "real dir was touched"
}

test_uninstall_removes_only_owned_links() {
  local t other; t="$(fresh)"; other="$(fresh)"
  "$INSTALL" --target "$t" >/dev/null 2>&1
  ln -s "$other" "$t/foreign"
  ln -s "$ROOT/plugins/coding-style/skills/caveman" "$t/stale-name"
  "$INSTALL" --target "$t" --uninstall >/dev/null 2>&1 || fail "uninstall failed"
  [[ "$(count_links "$t")" -eq 1 && -L $t/foreign ]] || fail "expected only the foreign link to remain"
}

test_filtered_uninstall() {
  local t; t="$(fresh)"
  "$INSTALL" --target "$t" >/dev/null 2>&1
  "$INSTALL" --target "$t" --uninstall caveman >/dev/null 2>&1 || fail "uninstall failed"
  [[ ! -e $t/caveman ]] || fail "caveman still linked"
  [[ "$(count_links "$t")" -eq $((expected_count - 1)) ]] || fail "other links removed too"
}

test_agent_flags_use_home_dirs() {
  "$INSTALL" --all-agents caveman >/dev/null 2>&1 || fail "install failed"
  local d
  for d in .claude/skills .agents/skills .cursor/skills; do
    [[ -L $HOME/$d/caveman ]] || fail "missing $HOME/$d/caveman"
  done
}

test_plugin_root_note() {
  local t err; t="$(fresh)"
  err="$("$INSTALL" --target "$t" hunt 2>&1 >/dev/null)"
  [[ $err == *"hunt runs plugin scripts"* ]] || fail "missing CLAUDE_PLUGIN_ROOT note"
}

run_test "no target is a usage error" test_no_target_is_an_error
run_test "--list shows every skill" test_list_shows_every_skill
run_test "install names are unique" test_install_names_are_unique
run_test "installs every skill with resolvable links" test_installs_all_and_links_resolve
run_test "re-install is idempotent" test_reinstall_is_idempotent
run_test "named skills only" test_named_skills_only
run_test "--plugin filters by plugin" test_plugin_filter
run_test "unknown skill exits 1 with message" test_unknown_skill_fails
run_test "unknown plugin exits 1" test_unknown_plugin_fails
run_test "foreign symlink is not replaced" test_foreign_symlink_is_kept
run_test "real directory is not replaced" test_real_dir_is_kept
run_test "uninstall removes only links owned by this repo" test_uninstall_removes_only_owned_links
run_test "filtered uninstall removes only named skills" test_filtered_uninstall
run_test "--all-agents links into claude/agents/cursor home dirs" test_agent_flags_use_home_dirs
run_test "plugin-root skills print a note" test_plugin_root_note

((failures == 0)) || { echo "$failures test(s) failed" >&2; exit 1; }
