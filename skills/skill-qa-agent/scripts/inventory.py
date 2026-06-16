#!/usr/bin/env python3
"""Scan both skill trees into a unified skill-index.json.

Always scans the user-level Claude skills tree (~/.claude/skills/*/SKILL.md)
and the user-level Cursor rules tree (~/.cursor/rules/*.mdc). Additional
project-level Cursor rule trees can be added via --project-roots (each is a
repo root; <repo>/.cursor/rules/*.mdc is scanned). Default: no project roots.

Usage:
    python -m scripts.inventory [--project-roots PATH ...]
                                [--changed-since-last-audit] [--out PATH]

Outputs JSON to stdout (and to --out if given). Windows-friendly.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

try:
    from scripts.utils import (
        parse_skill_md, parse_mdc, now_stamp,
        claude_skills_dir, cursor_rules_dir, latest_audit_dir,
    )
except ImportError:
    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
    from scripts.utils import (
        parse_skill_md, parse_mdc, now_stamp,
        claude_skills_dir, cursor_rules_dir, latest_audit_dir,
    )


def _bundled_scripts(skill_dir: Path) -> list[str]:
    scripts_dir = skill_dir / "scripts"
    if not scripts_dir.is_dir():
        return []
    return sorted(
        p.name for p in scripts_dir.iterdir()
        if p.is_file() and p.suffix == ".py" and p.name != "__init__.py"
    )


def _declared_responsibilities(record: dict) -> list[str]:
    """Heuristic: leading verbs/phrases of the description before 'Use when'."""
    desc = record.get("description", "")
    head = desc.split("Use when", 1)[0].split("use when", 1)[0].strip().rstrip(".")
    if not head:
        return record.get("trigger_phrases", [])[:5]
    parts = [p.strip().lower() for p in head.replace(";", ",").split(",") if p.strip()]
    return parts[:8]


def _skill_item(skill_dir: Path) -> dict | None:
    md = skill_dir / "SKILL.md"
    if not md.is_file():
        return None
    record = parse_skill_md(md)
    return {
        "id": f"skill:{record['name'] or skill_dir.name}",
        "name": record["name"] or skill_dir.name,
        "format": "skill",
        "tree": "claude-user",
        "path": str(md),
        "description": record["description"],
        "trigger_phrases": record["trigger_phrases"],
        "declared_responsibilities": _declared_responsibilities(record),
        "bundled_scripts": _bundled_scripts(skill_dir),
        "line_count": record["line_count"],
        "counterpart": record.get("counterpart", ""),
        "mtime": md.stat().st_mtime,
    }


def _mdc_item(mdc_path: Path, tree: str) -> dict | None:
    if not mdc_path.is_file():
        return None
    record = parse_mdc(mdc_path)
    return {
        "id": f"mdc:{record['name']}",
        "name": record["name"],
        "format": "mdc",
        "tree": tree,
        "path": str(mdc_path),
        "description": record["description"],
        "trigger_phrases": record["trigger_phrases"],
        "declared_responsibilities": _declared_responsibilities(record),
        "bundled_scripts": [],
        "line_count": record["line_count"],
        "counterpart": record.get("counterpart", ""),
        "mtime": mdc_path.stat().st_mtime,
    }


def scan(project_roots: list[Path]) -> list[dict]:
    items: list[dict] = []

    skills_dir = claude_skills_dir()
    if skills_dir.is_dir():
        for child in sorted(skills_dir.iterdir()):
            if child.is_dir():
                item = _skill_item(child)
                if item:
                    items.append(item)

    rules_dir = cursor_rules_dir()
    if rules_dir.is_dir():
        for mdc in sorted(rules_dir.glob("*.mdc")):
            item = _mdc_item(mdc, "cursor-user")
            if item:
                items.append(item)

    for repo in project_roots:
        proj_rules = repo / ".cursor" / "rules"
        if proj_rules.is_dir():
            tree = f"cursor-project:{repo.name}"
            for mdc in sorted(proj_rules.glob("*.mdc")):
                item = _mdc_item(mdc, tree)
                if item:
                    items.append(item)

    return items


def _load_prev_index() -> dict | None:
    prev_dir = latest_audit_dir()
    if not prev_dir:
        return None
    idx = prev_dir / "skill-index.json"
    if not idx.is_file():
        return None
    try:
        return json.loads(idx.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return None


def compute_changed(items: list[dict], prev: dict | None) -> dict:
    """Annotate which items changed since the last audit (mtime-based)."""
    if not prev:
        return {"reference_audit": None, "changed": [i["id"] for i in items], "removed": []}
    prev_by_id = {i["id"]: i for i in prev.get("items", [])}
    changed = []
    for item in items:
        old = prev_by_id.get(item["id"])
        if old is None or item["mtime"] > old.get("mtime", 0):
            changed.append(item["id"])
    removed = sorted(set(prev_by_id) - {i["id"] for i in items})
    return {
        "reference_audit": prev.get("generated_at"),
        "changed": changed,
        "removed": removed,
    }


def build_index(project_roots: list[Path], changed_since: bool) -> dict:
    items = scan(project_roots)
    roots = [str(claude_skills_dir()), str(cursor_rules_dir())]
    roots += [str(r / ".cursor" / "rules") for r in project_roots]

    changed_block = None
    if changed_since:
        prev = _load_prev_index()
        changed_block = compute_changed(items, prev)
        changed_ids = set(changed_block["changed"])
        items = [i for i in items if i["id"] in changed_ids]

    return {
        "generated_at": now_stamp(),
        "roots_scanned": roots,
        "items": items,
        "changed_since_last": changed_block,
    }


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description="Scan skill/rule trees into skill-index.json.")
    parser.add_argument("--project-roots", nargs="*", default=[],
                        help="Repo roots to also scan for <repo>/.cursor/rules/*.mdc")
    parser.add_argument("--changed-since-last-audit", action="store_true",
                        help="Limit output to items changed since the previous audit")
    parser.add_argument("--out", default=None, help="Also write JSON to this path")
    args = parser.parse_args(argv)

    roots = [Path(r).expanduser() for r in args.project_roots]
    index = build_index(roots, args.changed_since_last_audit)
    payload = json.dumps(index, indent=2, ensure_ascii=False)
    print(payload)
    if args.out:
        out = Path(args.out).expanduser()
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(payload, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
