#!/usr/bin/env python3
"""check-frontmatter.py — every SKILL.md frontmatter must be strict YAML.

Claude Code tolerates loose frontmatter (e.g. an unquoted description containing
"Use when: ..."), but strict parsers such as `npx skills` silently skip those
skills. This gate keeps every skill installable outside Claude Code too.

Usage:
  scripts/check-frontmatter.py          # verify (CI); non-zero if any file fails
  scripts/check-frontmatter.py --fix    # double-quote plain-scalar descriptions that fail

Requires PyYAML (`pip install pyyaml`).
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
FRONTMATTER = re.compile(r"\A---\n(.*?)\n---\n", re.DOTALL)
DESCRIPTION = re.compile(r"^description: (?!['\"|>])(.+)$", re.MULTILINE)


def check(path: Path) -> str | None:
    """Return an error message, or None if the frontmatter is strict YAML with name + description."""
    m = FRONTMATTER.match(path.read_text(encoding="utf-8"))
    if not m:
        return "missing frontmatter block"
    try:
        data = yaml.safe_load(m.group(1))
    except yaml.YAMLError as e:
        return f"YAML error: {str(e).splitlines()[0]}"
    if not isinstance(data, dict):
        return "frontmatter is not a mapping"
    missing = [k for k in ("name", "description") if not isinstance(data.get(k), str) or not data[k].strip()]
    return f"missing/empty: {', '.join(missing)}" if missing else None


def fix(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    m = FRONTMATTER.match(text)
    if not m:
        return
    # JSON string escaping is valid YAML double-quoted scalar syntax.
    head = DESCRIPTION.sub(lambda d: "description: " + json.dumps(d.group(1).rstrip(), ensure_ascii=False), m.group(1), count=1)
    path.write_text(text.replace(m.group(1), head, 1), encoding="utf-8")


def main() -> int:
    do_fix = "--fix" in sys.argv[1:]
    files = sorted(ROOT.glob("plugins/*/skills/*/SKILL.md"))
    failures = []
    for path in files:
        err = check(path)
        if err and do_fix:
            fix(path)
            err = check(path)
            if not err:
                print(f"fixed  {path.relative_to(ROOT)}")
        if err:
            failures.append(f"{path.relative_to(ROOT)}: {err}")
    if failures:
        print("FRONTMATTER ERRORS:\n  - " + "\n  - ".join(failures), file=sys.stderr)
        print("Run: scripts/check-frontmatter.py --fix", file=sys.stderr)
        return 1
    print(f"frontmatter ok: {len(files)} skills")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
