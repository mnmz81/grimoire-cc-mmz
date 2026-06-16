#!/usr/bin/env python3
"""Cheap candidate-overlap detection over a skill-index.json.

Stdlib only (no numpy/sklearn). For each item, build a bag of words from
description + trigger phrases + declared responsibilities, then score every
unordered pair by a blend of unigram and bigram Jaccard similarity. Pairs at
or above --threshold become candidates for Tier-3 LLM adjudication.

Cross-tree aware: each pair is annotated with same_tree and
is_declared_counterpart so the agent can discount expected skill<->mdc twins.

Usage:
    python -m scripts.similarity --index <skill-index.json>
                                 [--threshold 0.30] [--out PATH]
"""

from __future__ import annotations

import argparse
import itertools
import json
import sys
from pathlib import Path

try:
    from scripts.utils import tokenize, ngrams, now_stamp
except ImportError:
    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
    from scripts.utils import tokenize, ngrams, now_stamp


def _bag(item: dict) -> list[str]:
    parts = [item.get("description", "")]
    parts += item.get("trigger_phrases", [])
    parts += item.get("declared_responsibilities", [])
    return tokenize(" ".join(parts))


def _jaccard(a: set, b: set) -> float:
    if not a and not b:
        return 0.0
    inter = len(a & b)
    union = len(a | b)
    return inter / union if union else 0.0


def _is_declared_counterpart(a: dict, b: dict) -> bool:
    """True if either item declares the other as its counterpart."""
    return a.get("counterpart") == b.get("id") or b.get("counterpart") == a.get("id")


def find_pairs(items: list[dict], threshold: float) -> list[dict]:
    profiles = []
    for item in items:
        toks = _bag(item)
        profiles.append({
            "item": item,
            "uni": set(toks),
            "bi": ngrams(toks, 2),
        })

    pairs: list[dict] = []
    for p, q in itertools.combinations(profiles, 2):
        uj = _jaccard(p["uni"], q["uni"])
        bj = _jaccard(p["bi"], q["bi"])
        score = round(0.6 * uj + 0.4 * bj, 4)
        if score < threshold:
            continue
        a, b = p["item"], q["item"]
        declared = _is_declared_counterpart(a, b)
        shared = sorted(p["uni"] & q["uni"])
        pairs.append({
            "a": a["id"],
            "b": b["id"],
            "score": score,
            "unigram_jaccard": round(uj, 4),
            "bigram_jaccard": round(bj, 4),
            "shared_terms": shared[:25],
            "same_tree": a.get("tree") == b.get("tree"),
            "is_declared_counterpart": declared,
            "needs_adjudication": not declared,
        })
    pairs.sort(key=lambda x: x["score"], reverse=True)
    return pairs


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description="Find candidate overlap pairs from a skill index.")
    parser.add_argument("--index", required=True, help="Path to skill-index.json")
    parser.add_argument("--threshold", type=float, default=0.30)
    parser.add_argument("--out", default=None)
    args = parser.parse_args(argv)

    index = json.loads(Path(args.index).expanduser().read_text(encoding="utf-8"))
    items = index.get("items", [])
    pairs = find_pairs(items, args.threshold)

    payload = {
        "generated_at": now_stamp(),
        "threshold": args.threshold,
        "pairs": pairs,
    }
    out_json = json.dumps(payload, indent=2, ensure_ascii=False)
    print(out_json)
    if args.out:
        out = Path(args.out).expanduser()
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(out_json, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
