#!/usr/bin/env python3
"""generate-catalog.py — single source of truth for the marketplace catalog.

The per-plugin `plugins/<name>/.claude-plugin/plugin.json` manifests are authoritative.
This script derives, from those manifests + folder contents:

  * .claude-plugin/marketplace.json   (name, source, description, version, category)
  * the "Domains -> plugins" table in INVENTORY.md (between GENERATED markers)

This removes the old drift class where marketplace.json and INVENTORY.md were hand-edited
and fell out of sync with the actual plugins (e.g. a missing my-caveman, an 8-vs-9 count).

Usage:
  scripts/generate-catalog.py            # rewrite marketplace.json + INVENTORY table
  scripts/generate-catalog.py --check    # verify on-disk files match (CI); non-zero on drift
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PLUGINS_DIR = ROOT / "plugins"
MARKETPLACE = ROOT / ".claude-plugin" / "marketplace.json"
INVENTORY = ROOT / "INVENTORY.md"

OWNER = {"name": "Moris Zakay", "email": "moriszakay42@gmail.com", "url": "https://github.com/mnmz81"}
METADATA = {"description": "Personal skills & agents, organized by domain.", "version": "1.0.0"}
DEFAULT_CATEGORY = "development"

DOMAINS_BEGIN = "<!-- BEGIN GENERATED: domains (scripts/generate-catalog.py) -->"
DOMAINS_END = "<!-- END GENERATED: domains -->"


def load_plugins() -> list[dict]:
    """Read every plugin.json, sorted by name for deterministic output."""
    plugins = []
    for manifest in sorted(PLUGINS_DIR.glob("*/.claude-plugin/plugin.json")):
        data = json.loads(manifest.read_text(encoding="utf-8"))
        plugin_dir = manifest.parent.parent
        skills = sorted(p.name for p in (plugin_dir / "skills").glob("*") if p.is_dir())
        agents = sorted(
            p.stem for p in (plugin_dir / "agents").glob("*.md")
        ) if (plugin_dir / "agents").is_dir() else []
        plugins.append({
            "name": data["name"],
            "version": data["version"],
            "description": data["description"],
            "category": data.get("category", DEFAULT_CATEGORY),
            "dir": plugin_dir.name,
            "skills": skills,
            "agents": agents,
        })
    return plugins


def build_marketplace(plugins: list[dict]) -> str:
    catalog = {
        "name": "grimoire-cc-mmz",
        "owner": OWNER,
        "metadata": METADATA,
        "plugins": [
            {
                "name": p["name"],
                "source": f"./plugins/{p['dir']}",
                "description": p["description"],
                "version": p["version"],
                "category": p["category"],
            }
            for p in plugins
        ],
    }
    return json.dumps(catalog, indent=2, ensure_ascii=False) + "\n"


def build_domains_table(plugins: list[dict]) -> str:
    lines = [
        DOMAINS_BEGIN,
        "",
        "## Domains → plugins",
        "",
        "| Plugin | Skills | Agents |",
        "| ------ | ------ | ------ |",
    ]
    for p in plugins:
        skills = ", ".join(p["skills"]) or "—"
        agents = ", ".join(p["agents"]) or "—"
        lines.append(f"| `{p['name']}` | {skills} | {agents} |")
    lines += ["", f"_{len(plugins)} plugins. This table is generated — run `scripts/generate-catalog.py`._", "", DOMAINS_END]
    return "\n".join(lines)


def splice_inventory(text: str, table: str) -> str:
    """Replace the marked block, or append it if the markers are absent yet."""
    if DOMAINS_BEGIN in text and DOMAINS_END in text:
        return re.sub(
            re.escape(DOMAINS_BEGIN) + r".*?" + re.escape(DOMAINS_END),
            table,
            text,
            flags=re.DOTALL,
        )
    return text.rstrip() + "\n\n" + table + "\n"


def main() -> int:
    check = "--check" in sys.argv[1:]
    plugins = load_plugins()
    if not plugins:
        print("no plugins found under plugins/*/.claude-plugin/plugin.json", file=sys.stderr)
        return 1

    marketplace = build_marketplace(plugins)
    inventory_text = INVENTORY.read_text(encoding="utf-8") if INVENTORY.exists() else ""
    new_inventory = splice_inventory(inventory_text, build_domains_table(plugins))

    if check:
        drift = []
        on_disk = MARKETPLACE.read_text(encoding="utf-8") if MARKETPLACE.exists() else ""
        if on_disk != marketplace:
            drift.append("marketplace.json out of sync with plugin.json manifests")
        # Versions must agree between each plugin.json and its marketplace entry.
        mp = json.loads(marketplace)["plugins"]
        for entry, p in zip(mp, plugins):
            if entry["version"] != p["version"]:
                drift.append(f"{p['name']}: version mismatch")
        if new_inventory != inventory_text:
            drift.append("INVENTORY.md domains table out of sync")
        if drift:
            print("CATALOG DRIFT:\n  - " + "\n  - ".join(drift), file=sys.stderr)
            print("Run: scripts/generate-catalog.py", file=sys.stderr)
            return 1
        print(f"catalog in sync: {len(plugins)} plugins")
        return 0

    MARKETPLACE.parent.mkdir(parents=True, exist_ok=True)
    MARKETPLACE.write_text(marketplace, encoding="utf-8")
    if INVENTORY.exists():
        INVENTORY.write_text(new_inventory, encoding="utf-8")
    print(f"wrote marketplace.json ({len(plugins)} plugins) and INVENTORY domains table")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
