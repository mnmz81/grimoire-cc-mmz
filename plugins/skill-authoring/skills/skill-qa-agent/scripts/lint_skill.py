#!/usr/bin/env python3
"""Tier 1 deterministic lint for skills (SKILL.md) and Cursor rules (.mdc).

Computes the script-checkable portion of the QA rubric (~33 of 100 points).
Scripted points never vary run-to-run. Judgment dimensions are graded by the
agent inline (Tier 2) against references/rubric.md — NOT here.

Usage:
    python -m scripts.lint_skill --format skill <path-to-skill-dir-or-SKILL.md>
    python -m scripts.lint_skill --format mdc   <path-to-rule.mdc>

Outputs JSON to stdout. Windows-friendly (pathlib, no hardcoded separators).
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

try:
    from scripts.utils import parse_skill_md, parse_mdc
except ImportError:  # allow direct invocation: python scripts/lint_skill.py
    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
    from scripts.utils import parse_skill_md, parse_mdc

NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")

SKILL_ALLOWED_KEYS = {"name", "description", "metadata"}
MDC_ALLOWED_KEYS = {"description", "alwaysApply", "globs"}

DESC_MIN, DESC_MAX = 40, 700
SKILL_LINE_MAX = 500
MDC_LINE_MAX = 100
REFERENCES_THRESHOLD = 200  # body lines beyond which references/ is expected


def _check(cid, passed, detail, dim, possible, awarded):
    return {
        "id": cid,
        "passed": bool(passed),
        "detail": detail,
        "rubric_dim": dim,
        "points_possible": possible,
        "points_awarded": awarded,
    }


def run_skill_checks(record: dict, base_dir: Path) -> list[dict]:
    checks: list[dict] = []
    fm = record.get("frontmatter", {})
    name = record.get("name", "")
    desc = record.get("description", "")
    body = record.get("body", "")
    lines = record.get("line_count", 0)

    # frontmatter_valid (4)
    keys = set(fm.keys())
    extra = keys - SKILL_ALLOWED_KEYS
    has_required = bool(name) and bool(desc)
    fm_ok = has_required and not extra
    detail = []
    if not has_required:
        detail.append("missing name/description")
    if extra:
        detail.append("unexpected keys: " + ", ".join(sorted(extra)))
    checks.append(_check(
        "frontmatter_valid", fm_ok, "; ".join(detail) or "ok",
        "Governance-consistency", 4, 4 if fm_ok else 0,
    ))

    # name_kebab (4)
    name_ok = bool(NAME_RE.match(name)) and len(name) <= 64
    checks.append(_check(
        "name_kebab", name_ok,
        "ok" if name_ok else f"name '{name}' not kebab-case or >64 chars",
        "Governance-consistency", 4, 4 if name_ok else 0,
    ))

    # description_length (5)
    dlen = len(desc)
    no_angle = "<" not in desc and ">" not in desc
    desc_ok = DESC_MIN <= dlen <= DESC_MAX and no_angle
    detail = f"len={dlen} (want {DESC_MIN}-{DESC_MAX})"
    if not no_angle:
        detail += "; contains < or >"
    checks.append(_check(
        "description_length", desc_ok, detail,
        "Triggering", 5, 5 if desc_ok else 0,
    ))

    # line_count (5)
    lc_ok = lines <= SKILL_LINE_MAX
    checks.append(_check(
        "line_count", lc_ok, f"{lines} lines (max {SKILL_LINE_MAX})",
        "Structure & progressive disclosure", 5, 5 if lc_ok else 0,
    ))

    # references_used (3) — only meaningful for long skills
    refs_dir = base_dir / "references"
    if lines > REFERENCES_THRESHOLD:
        ru_ok = refs_dir.is_dir() and any(refs_dir.iterdir())
        detail = "references/ present" if ru_ok else "long skill but no references/ used"
        awarded = 3 if ru_ok else 0
    else:
        ru_ok = True
        detail = f"n/a (body {lines} <= {REFERENCES_THRESHOLD} lines)"
        awarded = 3
    checks.append(_check(
        "references_used", ru_ok, detail,
        "Structure & progressive disclosure", 3, awarded,
    ))

    # broken_refs (6)
    missing = []
    for ref in record.get("ref_links", []):
        target = (base_dir / ref).resolve()
        if not target.exists():
            missing.append(ref)
    br_ok = not missing
    checks.append(_check(
        "broken_refs", br_ok,
        "ok" if br_ok else "missing: " + ", ".join(missing),
        "Maintainability", 6, 6 if br_ok else 0,
    ))

    # toc_present (6) — headings exist; long skills want a real TOC
    headings = record.get("headings", [])
    if lines > REFERENCES_THRESHOLD:
        toc_ok = len(headings) >= 3
        detail = f"{len(headings)} headings" if toc_ok else "long skill, <3 headings"
    else:
        toc_ok = len(headings) >= 1
        detail = f"{len(headings)} headings"
    checks.append(_check(
        "toc_present", toc_ok, detail,
        "Completeness", 6, 6 if toc_ok else 0,
    ))

    return checks


def run_mdc_checks(record: dict, base_dir: Path) -> list[dict]:
    checks: list[dict] = []
    fm = record.get("frontmatter", {})
    desc = record.get("description", "")
    lines = record.get("line_count", 0)
    always = record.get("always_apply", False)
    globs = record.get("globs", [])

    # frontmatter_valid (5)
    keys = set(fm.keys())
    extra = keys - MDC_ALLOWED_KEYS
    has_desc = bool(desc)
    always_is_bool = isinstance(fm.get("alwaysApply", False), bool)
    fm_ok = has_desc and always_is_bool and not extra
    detail = []
    if not has_desc:
        detail.append("missing description")
    if not always_is_bool:
        detail.append("alwaysApply not boolean")
    if extra:
        detail.append("unexpected keys: " + ", ".join(sorted(extra)))
    checks.append(_check(
        "frontmatter_valid", fm_ok, "; ".join(detail) or "ok",
        "Governance-consistency", 5, 5 if fm_ok else 0,
    ))

    # description_length (5)
    dlen = len(desc)
    desc_ok = DESC_MIN <= dlen <= DESC_MAX
    checks.append(_check(
        "description_length", desc_ok, f"len={dlen} (want {DESC_MIN}-{DESC_MAX})",
        "Triggering", 5, 5 if desc_ok else 0,
    ))

    # alwaysApply_discipline (6) — always-on rules must be narrow; broad always-on is a finding
    if always and globs:
        ad_ok = False
        detail = "alwaysApply:true AND globs set -- contradictory scoping"
    elif always:
        # Always-on is allowed only for genuinely global rules; flag for review but
        # don't auto-fail short, clearly-global rules. Heuristic: penalize if long.
        ad_ok = lines <= MDC_LINE_MAX
        detail = "alwaysApply:true (global rule) -- verify scope is truly universal"
    else:
        ad_ok = True
        detail = "scoped rule (alwaysApply:false)"
    checks.append(_check(
        "alwaysApply_discipline", ad_ok, detail,
        "Triggering", 6, 6 if ad_ok else 0,
    ))

    # globs_valid (4)
    if globs:
        gv_ok = all(isinstance(g, str) and g.strip() for g in globs)
        detail = f"{len(globs)} glob(s)" if gv_ok else "malformed glob entries"
    else:
        gv_ok = True
        detail = "no globs (acceptable)"
    checks.append(_check(
        "globs_valid", gv_ok, detail,
        "Triggering", 4, 4 if gv_ok else 0,
    ))

    # line_count (7)
    lc_ok = lines <= MDC_LINE_MAX
    checks.append(_check(
        "line_count", lc_ok, f"{lines} lines (max {MDC_LINE_MAX})",
        "Structure & progressive disclosure", 7, 7 if lc_ok else 0,
    ))

    # broken_refs (6)
    missing = []
    for ref in record.get("ref_links", []):
        target = (base_dir / ref).resolve()
        if not target.exists():
            missing.append(ref)
    br_ok = not missing
    checks.append(_check(
        "broken_refs", br_ok,
        "ok" if br_ok else "missing: " + ", ".join(missing),
        "Maintainability", 6, 6 if br_ok else 0,
    ))

    return checks


def score(checks: list[dict]) -> tuple[int, int]:
    awarded = sum(c["points_awarded"] for c in checks)
    possible = sum(c["points_possible"] for c in checks)
    return awarded, possible


def lint(path: Path, fmt: str) -> dict:
    errors: list[str] = []
    record: dict = {}
    base_dir: Path

    try:
        if fmt == "skill":
            if path.is_dir():
                skill_dir = path
            elif path.name == "SKILL.md":
                skill_dir = path.parent
            else:
                skill_dir = path
            record = parse_skill_md(skill_dir / "SKILL.md")
            base_dir = skill_dir
            checks = run_skill_checks(record, base_dir)
        else:  # mdc
            record = parse_mdc(path)
            base_dir = path.parent
            checks = run_mdc_checks(record, base_dir)
    except Exception as exc:  # surface parse failure as JSON, don't crash
        return {
            "path": str(path),
            "format": fmt,
            "name": "",
            "checks": [],
            "tier1_points_awarded": 0,
            "tier1_points_possible": 0,
            "errors": [f"{type(exc).__name__}: {exc}"],
        }

    awarded, possible = score(checks)
    return {
        "path": str(path),
        "format": fmt,
        "name": record.get("name", ""),
        "checks": checks,
        "tier1_points_awarded": awarded,
        "tier1_points_possible": possible,
        "errors": errors,
    }


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description="Tier 1 deterministic skill/rule lint.")
    parser.add_argument("--format", choices=["skill", "mdc"], required=True)
    parser.add_argument("path", help="Path to skill dir / SKILL.md (skill) or .mdc file (mdc)")
    args = parser.parse_args(argv)

    result = lint(Path(args.path).expanduser(), args.format)
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return 0 if not result["errors"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
