#!/usr/bin/env python3
"""Headless Tier 2 rubric grading via `claude -p`.

Used ONLY by the scheduled audit (install_schedule.py), where no interactive
agent is in the loop. Interactive W1-W4 grade inline in the agent's own
context and should NOT call this.

For each item in a skill-index.json, sends the file content + the matching
rubric to `claude -p` and asks for a JSON score per judgment dimension, graded
twice (double-grade protocol). Aggregates with the Tier-1 lint points.

Usage:
    python -m scripts.score_judge --index <skill-index.json>
                                  --lint-dir <dir of *.json from lint_skill>
                                  [--model claude-sonnet-4-6] [--out PATH]

Windows-safe: uses utils.claude_judge (no select.select on pipes).
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

try:
    from scripts.utils import claude_judge, now_stamp
except ImportError:
    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
    from scripts.utils import claude_judge, now_stamp

SKILL_DIR = Path(__file__).resolve().parent.parent
JUDGMENT_DIMS = [
    "Clarity", "Completeness", "Triggering", "Structure & progressive disclosure",
    "Maintainability", "Reusability / generality", "Governance-consistency",
    "Robustness & error handling", "Documentation quality", "Non-redundancy",
]


def _rubric_text(fmt: str) -> str:
    name = "rubric-mdc.md" if fmt == "mdc" else "rubric.md"
    return (SKILL_DIR / "references" / name).read_text(encoding="utf-8")


def _build_prompt(item: dict, file_text: str, rubric: str, lint: dict) -> str:
    dims = "\n".join(f"- {d}" for d in JUDGMENT_DIMS)
    return (
        "You are grading a skill/rule against an anchored rubric. Grade each "
        "dimension 0-10 using the anchors. Grade TWICE independently (pass1, "
        "pass2). Do not re-award points a Tier-1 lint check already failed.\n\n"
        "Return ONLY a JSON object with this exact shape:\n"
        '{"dimensions": {"<dim>": {"pass1": int, "pass2": int}}, "notes": "<short>"}\n\n'
        f"Dimensions to grade:\n{dims}\n\n"
        f"=== RUBRIC ===\n{rubric}\n\n"
        f"=== TIER 1 LINT (already scored, do not change) ===\n{json.dumps(lint)}\n\n"
        f"=== FILE: {item.get('id')} ({item.get('format')}) ===\n{file_text}\n"
    )


def _parse_scores(raw: str) -> dict | None:
    start = raw.find("{")
    end = raw.rfind("}")
    if start < 0 or end <= start:
        return None
    try:
        return json.loads(raw[start:end + 1])
    except json.JSONDecodeError:
        return None


def grade_item(item: dict, lint: dict, model: str | None) -> dict:
    fmt = item.get("format", "skill")
    file_text = Path(item["path"]).read_text(encoding="utf-8")
    prompt = _build_prompt(item, file_text, _rubric_text(fmt), lint)
    raw = claude_judge(prompt, timeout=240, model=model)
    parsed = _parse_scores(raw)

    dims: dict = {}
    deltas: dict = {}
    if parsed and isinstance(parsed.get("dimensions"), dict):
        for dim, scores in parsed["dimensions"].items():
            p1 = int(scores.get("pass1", 0))
            p2 = int(scores.get("pass2", 0))
            delta = abs(p1 - p2)
            dims[dim] = round((p1 + p2) / 2)
            if delta > 2:
                deltas[dim] = delta
    return {
        "id": item["id"],
        "format": fmt,
        "dimensions": dims,
        "double_grade_deltas": deltas,
        "tier1_points": lint.get("tier1_points_awarded", 0),
        "notes": (parsed or {}).get("notes", ""),
        "raw_ok": parsed is not None,
    }


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description="Headless Tier 2 grading via claude -p.")
    parser.add_argument("--index", required=True)
    parser.add_argument("--lint-dir", required=True)
    parser.add_argument("--model", default=None)
    parser.add_argument("--out", default=None)
    args = parser.parse_args(argv)

    index = json.loads(Path(args.index).expanduser().read_text(encoding="utf-8"))
    lint_dir = Path(args.lint_dir).expanduser()
    results = []
    for item in index.get("items", []):
        lint_path = lint_dir / f"{item['id'].replace(':', '_')}.json"
        lint = json.loads(lint_path.read_text(encoding="utf-8")) if lint_path.is_file() else {}
        print(f"grading {item['id']}...", file=sys.stderr)
        results.append(grade_item(item, lint, args.model))

    payload = {"generated_at": now_stamp(), "model": args.model, "results": results}
    out_json = json.dumps(payload, indent=2, ensure_ascii=False)
    print(out_json)
    if args.out:
        out = Path(args.out).expanduser()
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(out_json, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
