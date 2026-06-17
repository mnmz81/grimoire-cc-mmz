#!/usr/bin/env python3
"""Shared stdlib-only helpers for skill-qa-agent scripts.

No third-party imports (no PyYAML/numpy/sklearn). Frontmatter is parsed with a
small YAML-subset parser that handles the keys skills/.mdc rules actually use:
quoted scalars, `>`/`|` (and `-` chomp variants) block scalars, inline flow
lists (`["a","b"]`), block lists (`- item`), and one level of nested maps
(`metadata:`). Anything fancier is out of scope by design.

Windows-friendly: pathlib everywhere, Path.home(), no hardcoded separators.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
from datetime import datetime
from pathlib import Path

# ---------------------------------------------------------------------------
# Frontmatter parsing (YAML subset)
# ---------------------------------------------------------------------------

_INLINE_LIST_RE = re.compile(r"^\[(.*)\]$")


def _strip_quotes(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in ("'", '"'):
        return value[1:-1]
    return value


def _parse_inline_list(value: str) -> list[str]:
    """Parse a flow list like ["a", "b"] or [a, b] into a list of strings."""
    inner = _INLINE_LIST_RE.match(value.strip())
    if not inner:
        return []
    body = inner.group(1).strip()
    if not body:
        return []
    return [_strip_quotes(part.strip()) for part in body.split(",") if part.strip()]


def _indent_of(line: str) -> int:
    return len(line) - len(line.lstrip(" "))


def parse_frontmatter(text: str) -> tuple[dict, str]:
    """Split text into (frontmatter_dict, body).

    Returns ({}, text) when no `---` delimited frontmatter block is present.
    Supported value shapes per key:
      key: scalar             -> str
      key: "quoted"           -> str (quotes stripped)
      key: >|  (block scalar) -> str (lines joined with spaces)
      key: ["a","b"]          -> list[str]
      key:\n  - a\n  - b      -> list[str]
      key:\n  sub: v          -> dict (one level deep)
      key: true/false         -> bool
    """
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    lines = text.split("\n")
    if not lines or lines[0].strip() != "---":
        return {}, text

    end_idx = None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            end_idx = i
            break
    if end_idx is None:
        return {}, text

    fm_lines = lines[1:end_idx]
    body = "\n".join(lines[end_idx + 1:])
    fm: dict = {}

    i = 0
    n = len(fm_lines)
    while i < n:
        raw = fm_lines[i]
        if not raw.strip() or raw.lstrip().startswith("#"):
            i += 1
            continue
        if _indent_of(raw) != 0:
            # Stray indented line at top level; skip defensively.
            i += 1
            continue
        if ":" not in raw:
            i += 1
            continue

        key, _, rest = raw.partition(":")
        key = key.strip()
        value = rest.strip()

        # Block scalar (>, |, with optional chomp +/-)
        if value in (">", "|", ">-", "|-", ">+", "|+"):
            collected: list[str] = []
            i += 1
            while i < n and (fm_lines[i].strip() == "" or _indent_of(fm_lines[i]) >= 2):
                collected.append(fm_lines[i].strip())
                i += 1
            fm[key] = " ".join(c for c in collected if c).strip()
            continue

        # Inline flow list
        if value.startswith("[") and value.endswith("]"):
            fm[key] = _parse_inline_list(value)
            i += 1
            continue

        # Empty value -> could be block list or nested map
        if value == "":
            i += 1
            block_items: list[str] = []
            nested: dict = {}
            while i < n and (fm_lines[i].strip() == "" or _indent_of(fm_lines[i]) >= 2):
                child = fm_lines[i]
                stripped = child.strip()
                if stripped == "":
                    i += 1
                    continue
                if stripped.startswith("- "):
                    block_items.append(_strip_quotes(stripped[2:].strip()))
                elif ":" in stripped:
                    ckey, _, cval = stripped.partition(":")
                    cval = cval.strip()
                    if cval.startswith("[") and cval.endswith("]"):
                        nested[ckey.strip()] = _parse_inline_list(cval)
                    else:
                        nested[ckey.strip()] = _coerce_scalar(_strip_quotes(cval))
                i += 1
            if block_items:
                fm[key] = block_items
            elif nested:
                fm[key] = nested
            else:
                fm[key] = ""
            continue

        # Plain scalar
        fm[key] = _coerce_scalar(_strip_quotes(value))
        i += 1

    return fm, body


def _coerce_scalar(value: str):
    low = value.lower()
    if low == "true":
        return True
    if low == "false":
        return False
    return value


# ---------------------------------------------------------------------------
# Record extraction
# ---------------------------------------------------------------------------

_STOPWORDS = {
    "the", "a", "an", "and", "or", "to", "of", "in", "on", "for", "with", "use",
    "when", "this", "that", "is", "are", "be", "it", "as", "by", "at", "from",
    "into", "any", "user", "users", "wants", "want", "skill", "rule", "you",
}


def count_body_lines(body: str) -> int:
    return len(body.replace("\r\n", "\n").split("\n"))


def extract_headings(body: str) -> list[str]:
    return [m.group(2).strip() for m in re.finditer(r"^(#{1,6})\s+(.*)$", body, re.MULTILINE)]


def extract_ref_links(body: str) -> list[str]:
    """Return relative resource references mentioned in the body.

    Catches markdown links `[x](references/y.md)` and bare mentions of
    references/ scripts/ assets/ paths. Skips http(s) URLs.
    """
    found: set[str] = set()
    for m in re.finditer(r"\]\(([^)]+)\)", body):
        target = m.group(1).strip()
        if target.startswith(("http://", "https://", "#", "mailto:")):
            continue
        found.add(target.split("#", 1)[0])
    for m in re.finditer(r"(?<![\w/])((?:references|scripts|assets)/[\w./-]+)", body):
        found.add(m.group(1))
    return sorted(p for p in found if p)


def extract_trigger_phrases(description: str) -> list[str]:
    """Pull candidate trigger phrases from a description.

    Splits on 'Use when', then on commas and ' or '. Lowercased, de-duped,
    short fragments dropped.
    """
    if not description:
        return []
    text = description
    phrases: list[str] = []
    parts = re.split(r"[Uu]se when", text)
    tail = parts[-1] if len(parts) > 1 else text
    for chunk in re.split(r",| or ", tail):
        frag = chunk.strip().strip(".").lower()
        if len(frag) >= 4:
            phrases.append(frag)
    seen: set[str] = set()
    out: list[str] = []
    for p in phrases:
        if p not in seen:
            seen.add(p)
            out.append(p)
    return out


def tokenize(text: str) -> list[str]:
    tokens = re.findall(r"[a-z0-9]+", (text or "").lower())
    return [t for t in tokens if t not in _STOPWORDS and len(t) > 1]


def ngrams(tokens: list[str], n: int) -> set[str]:
    if n <= 1:
        return set(tokens)
    return {" ".join(tokens[i:i + n]) for i in range(len(tokens) - n + 1)}


# ---------------------------------------------------------------------------
# Skill / mdc record builders
# ---------------------------------------------------------------------------

def parse_skill_md(path: Path) -> dict:
    """Parse a SKILL.md file into a normalized record dict."""
    text = path.read_text(encoding="utf-8")
    fm, body = parse_frontmatter(text)
    name = str(fm.get("name", "")).strip()
    description = str(fm.get("description", "")).strip()
    metadata = fm.get("metadata", {}) if isinstance(fm.get("metadata"), dict) else {}
    counterpart = metadata.get("counterpart", "") if isinstance(metadata, dict) else ""
    return {
        "format": "skill",
        "name": name,
        "description": description,
        "frontmatter": fm,
        "metadata": metadata,
        "counterpart": counterpart,
        "body": body,
        "line_count": count_body_lines(body),
        "headings": extract_headings(body),
        "ref_links": extract_ref_links(body),
        "trigger_phrases": extract_trigger_phrases(description),
        "path": str(path),
    }


def parse_mdc(path: Path) -> dict:
    """Parse a Cursor .mdc rule into a normalized record dict."""
    text = path.read_text(encoding="utf-8")
    fm, body = parse_frontmatter(text)
    description = str(fm.get("description", "")).strip()
    globs = fm.get("globs", [])
    if isinstance(globs, str):
        globs = [globs] if globs else []
    always = fm.get("alwaysApply", False)
    # .mdc declares its counterpart in the body, not frontmatter.
    cm = re.search(r"counterpart:\s*([\w:-]+)", body)
    counterpart = cm.group(1) if cm else ""
    name = path.stem
    return {
        "format": "mdc",
        "name": name,
        "description": description,
        "frontmatter": fm,
        "globs": globs,
        "always_apply": bool(always),
        "counterpart": counterpart,
        "body": body,
        "line_count": count_body_lines(body),
        "headings": extract_headings(body),
        "ref_links": extract_ref_links(body),
        "trigger_phrases": extract_trigger_phrases(description),
        "path": str(path),
    }


# ---------------------------------------------------------------------------
# Paths & timestamps
# ---------------------------------------------------------------------------

def now_stamp(reference: datetime | None = None) -> str:
    """YYYY-MM-DD-HHMMSS. Pass `reference` in tests for determinism."""
    dt = reference or datetime.now()
    return dt.strftime("%Y-%m-%d-%H%M%S")


def qa_root() -> Path:
    return Path.home() / ".claude" / "skill-qa"


def audit_root() -> Path:
    return qa_root() / "audits"


def history_root() -> Path:
    return qa_root() / "history"


def claude_skills_dir() -> Path:
    return Path.home() / ".claude" / "skills"


def cursor_rules_dir() -> Path:
    return Path.home() / ".cursor" / "rules"


def latest_audit_dir(before: str | None = None) -> Path | None:
    """Return the most recent audit dir (optionally strictly before a stamp)."""
    root = audit_root()
    if not root.is_dir():
        return None
    dirs = sorted((d for d in root.iterdir() if d.is_dir()), key=lambda p: p.name)
    if before:
        dirs = [d for d in dirs if d.name < before]
    return dirs[-1] if dirs else None


# ---------------------------------------------------------------------------
# Summary diffing (trend)
# ---------------------------------------------------------------------------

def diff_summaries(latest: dict, prev: dict | None) -> dict:
    """Compute trend deltas between two summary.json payloads.

    Returns a dict with avg_score delta, per-item score deltas, band
    transitions, new/removed items, and violation/overlap count deltas. When
    `prev` is None, returns a baseline marker.
    """
    if not prev:
        return {"baseline": True, "note": "baseline (no prior audit)"}

    def by_id(summary):
        return {item["id"]: item for item in summary.get("per_item", [])}

    cur = by_id(latest)
    old = by_id(prev)

    score_deltas = []
    band_transitions = []
    for item_id, item in cur.items():
        if item_id in old:
            delta = item.get("score", 0) - old[item_id].get("score", 0)
            if delta:
                score_deltas.append({"id": item_id, "delta": delta})
            if item.get("band") != old[item_id].get("band"):
                band_transitions.append({
                    "id": item_id,
                    "from": old[item_id].get("band"),
                    "to": item.get("band"),
                })
    new_items = sorted(set(cur) - set(old))
    removed_items = sorted(set(old) - set(cur))

    cur_avg = latest.get("totals", {}).get("avg_score", 0)
    old_avg = prev.get("totals", {}).get("avg_score", 0)

    return {
        "baseline": False,
        "avg_score_delta": round(cur_avg - old_avg, 2),
        "score_deltas": score_deltas,
        "band_transitions": band_transitions,
        "new_items": new_items,
        "removed_items": removed_items,
        "governance_violation_delta": (
            len(latest.get("governance_violations", []))
            - len(prev.get("governance_violations", []))
        ),
        "overlap_group_delta": (
            len(latest.get("overlap_groups", []))
            - len(prev.get("overlap_groups", []))
        ),
    }


# ---------------------------------------------------------------------------
# claude -p subprocess wrapper (headless only; Windows-safe, no select())
# ---------------------------------------------------------------------------

def claude_judge(prompt: str, timeout: int = 180, model: str | None = None) -> str:
    """Invoke `claude -p` and return assembled assistant text.

    Used ONLY by the headless scheduled path (score_judge.py). Interactive
    W1-W4 grade inline in the agent's own context. Avoids select.select (not
    usable on Windows pipes) — reads stdout line by line with a wait timeout.
    Strips CLAUDECODE so it can nest inside a Claude Code session.
    """
    env = {k: v for k, v in os.environ.items() if k != "CLAUDECODE"}
    cmd = ["claude", "-p", prompt, "--output-format", "stream-json", "--verbose"]
    if model:
        cmd += ["--model", model]

    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=env,
        text=True,
        encoding="utf-8",
    )
    chunks: list[str] = []
    try:
        out, _err = proc.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        proc.kill()
        out, _err = proc.communicate()
    for line in (out or "").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        # Final result event carries the full text in skill-creator's pattern.
        if event.get("type") == "result" and isinstance(event.get("result"), str):
            return event["result"]
        if event.get("type") == "assistant":
            msg = event.get("message", {})
            for block in msg.get("content", []):
                if isinstance(block, dict) and block.get("type") == "text":
                    chunks.append(block.get("text", ""))
    return "".join(chunks)
