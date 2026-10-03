# Skill-Audit Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix every finding from the 2026-10-03 skill audit of the 19 skills in this repo, ship via one PR, then sync the user's global install from `main`.

**Architecture:** Edits are mostly Markdown prose in `plugins/*/skills/*/SKILL.md` plus agent/reference files. The only code changes are in the bundled `skill-qa-agent` scripts (frontmatter allowlist + plugin-layout scanning), covered by stdlib `unittest`. Every task is verified with `lint_skill.py`, `grep` checks, and the CI-parity commands from `.github/workflows/validate.yml`.

**Tech Stack:** Markdown skills, Python 3 stdlib (skill-qa scripts, `scripts/generate-catalog.py`), bash (`scripts/update-plugin.sh`), `gh` CLI.

**Spec:** Audit results: `~/.claude/skill-qa/audits/2026-10-03-*-grimoire/` (summary.json, lint/*.json) and the audit reply in this session.

## Global Constraints

- Branch: `fix/skill-audit-findings` off `main`. Never commit to `main` directly.
- Snapshot before any write: `~/.claude/skill-qa/history/grimoire-plugins/<timestamp>/` (copy of `plugins/`) and `~/.claude/skill-qa/history/user-skills/<timestamp>/` (before deleting user skills).
- After every SKILL.md edit: `python3 -m scripts.lint_skill --format skill <dir>` (run from `plugins/skill-authoring/skills/skill-qa-agent`) must report `tier1_points_awarded == tier1_points_possible` (33/33) except Quartermaster's known false positive, which Task 8 removes.
- User decisions (locked): rename `code-review` → `triple-lens-review`; precedence = "ask only when ambiguity is blocking, otherwise default + flag"; do not touch `~/.claude/CLAUDE.md`; snapshot then delete duplicate user skills `grimoire-cc-mmz`, `karpathy-guidelines`, `skill-qa-agent`, `ui-ux-design` from `~/.claude/skills/` (keep `graphify`).
- Skill names/frontmatter `name` stay unchanged except the rename above.
- No new dependencies. Stdlib only.
- CI parity before PR: `python3 scripts/generate-catalog.py --check` and `shellcheck plugins/debugging/scripts/open-audit-issues.sh plugins/repo-init/scripts/repo-init.sh`.
- `scripts/update-plugin.sh` only runs on `main` — library sync happens **after** the PR merges.

## Slash-command mapping (used by Tasks 2 and 3)

Plugin skills are invoked as `/<plugin>:<skill>`; agents are not slash-invokable (spawn via `Task`).

| Dead ref | Replace with |
|---|---|
| `/mui-frame` | `/mushilu-studio:compass` |
| `/mui-spec` | `/mushilu-studio:blueprint` |
| `/mui-build` | `/mushilu-studio:foreman` |
| `/mui-test` | `/mushilu-studio:marshal` |
| `/mui-qa` | `/mushilu-studio:prowler` |
| `/mui-ship` | `/mushilu-studio:quartermaster` |
| `/mui-docs` | `/mushilu-studio:scribe` |
| `/mui-guard` | `/mushilu-studio:warden` |
| `/mui-learn` | `/mushilu-studio:curator` |
| `/mui-autopilot` | `/mushilu-studio:conductor` |
| `/mui-investigate` | `/debugging:sleuth` |
| `/mui-hunt` | `/debugging:hunt` |
| `/mui-style` | `the Palette agent (mushilu-studio:palette)` |
| `/mui-a11y` | `the Sentinel-A11y agent (mushilu-studio:sentinel-a11y)` |
| `/mui-review` | `the Staff agent (mushilu-studio:staff)` |
| `/mui-size` | `the Gauge agent (mushilu-studio:gauge)` |

---

### Task 0: Branch + snapshot

**Files:** none in repo.

- [ ] **Step 1:** `git checkout -b fix/skill-audit-findings`
- [ ] **Step 2:** Snapshot:
```bash
TS=$(date +%Y%m%d-%H%M%S); mkdir -p ~/.claude/skill-qa/history/grimoire-plugins/$TS && cp -R plugins ~/.claude/skill-qa/history/grimoire-plugins/$TS/
```
Expected: directory exists and `diff -rq plugins ~/.claude/skill-qa/history/grimoire-plugins/$TS/plugins` prints nothing.

---

### Task 1: skill-qa-agent tooling (lint allowlist + plugin-layout scan)

Fixes: linter rejects valid `argument-hint`/`license`; `inventory.py` can't scan `plugins/*/skills/*`. Done first so later tasks lint cleanly.

**Files:**
- Modify: `plugins/skill-authoring/skills/skill-qa-agent/scripts/lint_skill.py:31`
- Modify: `plugins/skill-authoring/skills/skill-qa-agent/scripts/inventory.py` (`scan`, `build_index`, `main`)
- Modify: `plugins/skill-authoring/skills/skill-qa-agent/references/governance-standards.md:15`
- Modify: `plugins/skill-authoring/skills/skill-qa-agent/SKILL.md` (Scripts list) and `skill-qa.mdc` (same line)
- Create: `plugins/skill-authoring/skills/skill-qa-agent/tests/test_scripts.py`

**Interfaces:**
- Produces: `inventory.py --skill-roots PATH ...` — each root scanned for `*/SKILL.md` and `plugins/*/skills/*/SKILL.md`; items get `"tree": "skill-root"`.

- [ ] **Step 1: Write failing tests**
```python
"""Run: cd plugins/skill-authoring/skills/skill-qa-agent && python3 -m unittest tests.test_scripts -v"""
import json, subprocess, sys, tempfile, unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent

def make_skill(root: Path, name: str, extra: str = "") -> Path:
    d = root / name
    d.mkdir(parents=True)
    (d / "SKILL.md").write_text(
        f"---\nname: {name}\ndescription: Does a thing. Use when the user asks for the thing in a test.\n{extra}---\n\n# T\n\n## A\nbody\n"
    )
    return d

class LintAllowlist(unittest.TestCase):
    def test_argument_hint_and_license_allowed(self):
        with tempfile.TemporaryDirectory() as t:
            d = make_skill(Path(t), "demo", 'argument-hint: "[x]"\nlicense: MIT\n')
            out = subprocess.run([sys.executable, "-m", "scripts.lint_skill", "--format", "skill", str(d)],
                                 cwd=HERE, capture_output=True, text=True).stdout
            fm = next(c for c in json.loads(out)["checks"] if c["id"] == "frontmatter_valid")
            self.assertTrue(fm["passed"], fm.get("detail"))

    def test_unknown_key_still_rejected(self):
        with tempfile.TemporaryDirectory() as t:
            d = make_skill(Path(t), "demo", "bogus: 1\n")
            out = subprocess.run([sys.executable, "-m", "scripts.lint_skill", "--format", "skill", str(d)],
                                 cwd=HERE, capture_output=True, text=True).stdout
            fm = next(c for c in json.loads(out)["checks"] if c["id"] == "frontmatter_valid")
            self.assertFalse(fm["passed"])

class InventorySkillRoots(unittest.TestCase):
    def test_scans_plugin_layout(self):
        with tempfile.TemporaryDirectory() as t:
            make_skill(Path(t) / "plugins" / "p1" / "skills", "alpha")
            make_skill(Path(t), "beta")
            out = subprocess.run([sys.executable, "-m", "scripts.inventory", "--skill-roots", t],
                                 cwd=HERE, capture_output=True, text=True)
            ids = {i["id"] for i in json.loads(out.stdout)["items"]}
            self.assertTrue({"skill:alpha", "skill:beta"} <= ids, out.stderr)

if __name__ == "__main__":
    unittest.main()
```
- [ ] **Step 2:** Run `python3 -m unittest tests.test_scripts -v` → expect 2 FAIL (allowlist, skill-roots), 1 PASS.
- [ ] **Step 3: Implement**
  - `lint_skill.py:31` → `SKILL_ALLOWED_KEYS = {"name", "description", "metadata", "allowed-tools", "argument-hint", "license", "model", "disable-model-invocation", "user-invocable"}`
  - `inventory.py`: add `--skill-roots` (nargs `*`, default `[]`); thread to `scan(project_roots, skill_roots)`; inside `scan`, after the user-tree loop:
```python
    for root in skill_roots:
        for skill_md in sorted(set(root.glob("*/SKILL.md")) | set(root.glob("plugins/*/skills/*/SKILL.md"))):
            item = _skill_item(skill_md.parent)
            if item:
                item["tree"] = "skill-root"
                items.append(item)
```
  and add `str(r)` for each skill root to the `roots` list in `build_index`.
  - governance-standards.md:15 → list the same 9 keys.
  - SKILL.md + skill-qa.mdc Scripts bullet → `inventory.py [--project-roots ...] [--skill-roots ...] [--changed-since-last-audit] [--out P]` — `--skill-roots` scans a repo's `*/SKILL.md` and `plugins/*/skills/*/SKILL.md`.
- [ ] **Step 4:** Rerun tests → 3 PASS. Lint skill-qa-agent → 33/33.
- [ ] **Step 5:** Commit `fix(skill-qa): allow valid frontmatter keys, scan plugin-layout skill roots`.

---

### Task 2: mushilu-studio — dead commands, Conductor, learnings, filler

**Files:** all 10 `plugins/mushilu-studio/skills/*/SKILL.md`, `plugins/mushilu-studio/agents/*.md`, `plugins/mushilu-studio/references/artifacts.md`.

- [ ] **Step 1: Failing check**
```bash
grep -rnE '/mui-[a-z0-9]+' plugins/mushilu-studio | wc -l   # expect > 0 now
```
- [ ] **Step 2: Replace commands** per the mapping table (sed per pair, ordered longest-first so `/mui-a11y` is not clobbered by a shorter match). Header lines like `# Compass — \`/mui-frame\`` become `# Compass — \`/mushilu-studio:compass\``.
- [ ] **Step 3: Conductor** (`conductor/SKILL.md`):
  - Pipeline block: append after Quartermaster `Scribe /mushilu-studio:scribe → docs + reports/<c>.docs.md [skill]`.
  - Worked example: move `Gauge ✅ forms 11.4/12.` into the fan-out line (`Palette ✅ | Sentinel-A11y ⛔ … | Staff ✅ | Gauge ✅ forms 11.4/12`) and add `Scribe ✅ forms page updated.` after Quartermaster.
  - "Decide yourself" bullet → add: `Exception: outward or hard-to-reverse actions — Foreman's commit and Quartermaster's push/PR — always get an explicit user yes first, even on autopilot.`
- [ ] **Step 4: Quartermaster** `How you run` step 3 → `Add a changeset. Show the user the PR title/body and wait for an explicit yes, then push and open the PR.`
- [ ] **Step 5: Foreman** add to "When inputs are thin": `- **Global workflow section not found** (another user's machine, renamed section) → fall back to the 9 steps named in this file's rule line, in that order, and tell the user the canonical source was missing.`
- [ ] **Step 6: Curator** inputs → read both `.mui-team/learnings.md` and `.bug-hunt/learnings.md` (Sleuth's log); graduation removes graduated lines from whichever file held them. Mirror in `references/artifacts.md` learnings row: `every reviewer + the hunt squad (append); Sleuth appends to .bug-hunt/learnings.md` → reader `Curator (both files)`.
- [ ] **Step 7: Remove filler** — delete the `## Why this generalizes` section from all 10 studio skills (keeps them lean; they are Mushilu-specific by design).
- [ ] **Step 8: Verify**
```bash
grep -rnE '/mui-[a-z0-9]+' plugins/mushilu-studio plugins/debugging | wc -l   # expect 0
grep -rn 'Why this generalizes' plugins/mushilu-studio | wc -l              # expect 0
```
Lint all 10 → 33/33 (quartermaster 27/33 until Task 8).
- [ ] **Step 9:** Commit `fix(mushilu-studio): real slash commands, conductor order + confirm gates, unified learnings`.

---

### Task 3: debugging — sleuth + hunt

**Files:** `plugins/debugging/skills/sleuth/SKILL.md`, `plugins/debugging/skills/hunt/SKILL.md`.

- [ ] **Step 1: Sleuth**
  - Replace `` `the project's coding standards (e.g. CLAUDE.md/AGENTS.md, if present)` §Known issues & workarounds `` with `The project's coding standards (CLAUDE.md / AGENTS.md, if present) — especially any "Known issues" section.` and drop the Mushilu-only list in parentheses.
  - `The component under suspicion and its \`.spec.ts\`` → `The module under suspicion and its test file.`
  - Example header `(\`reports/rating.investigation.md\`)` → `(\`.bug-hunt/rating.investigation.md\`)`.
  - Iron Law #4 → `**Keep the blast radius small.** Restrict edits to the failing module while investigating. For a hard lock, use Warden (\`/mushilu-studio:warden freeze <dir>\`) where the project has its hooks.`
  - Replace `## Why this generalizes` paragraph with nothing (filler).
- [ ] **Step 2: Hunt**
  - Persona: `# Bloodhound` → `# Hunt`; `You are **Bloodhound**` → `You are the **hunt** orchestrator`; remaining `Bloodhound` mentions → `hunt`. Same in `conductor`/`curator` (`Bloodhound (/debugging:hunt)` → `the hunt sweep (/debugging:hunt)`).
  - Dedup paragraph → `Deduplicate by \`id\`. Make the result deterministic: process reports in the squad-table order (specter → ledger) and, within a report, top to bottom; keep the first occurrence and append later evidence to it.`
  - Example row path `src/forms/src/slider/slider.ts:88` → `src/widgets/slider.ts:88`.
  - Add one line to the end of "Dedup": `Hunters may append recurring patterns to \`.bug-hunt/learnings.md\`; Curator picks them up.` (matches Curator's claim).
- [ ] **Step 3: Verify** `grep -rn 'Bloodhound' plugins | wc -l` → 0; lint both → 33/33.
- [ ] **Step 4:** Commit `fix(debugging): sleuth path/wording consistency, deterministic hunt dedup`.

---

### Task 4: Rename code-review → triple-lens-review + content fixes

**Files:**
- Move: `plugins/code-review/` → `plugins/triple-lens-review/`; `skills/code-review/` → `skills/triple-lens-review/`
- Modify: `.claude-plugin/plugin.json`, `skills/triple-lens-review/SKILL.md`, `evals/evals.json` (`skill_name`), `.claude-plugin/marketplace.json`, README/INVENTORY via `scripts/generate-catalog.py`

- [ ] **Step 1:** `git mv plugins/code-review plugins/triple-lens-review && git mv plugins/triple-lens-review/skills/code-review plugins/triple-lens-review/skills/triple-lens-review`
- [ ] **Step 2:** `plugin.json` and marketplace entry: `"name": "triple-lens-review"`, `"source": "./plugins/triple-lens-review"`. `evals.json`: `"skill_name": "triple-lens-review"`.
- [ ] **Step 3: SKILL.md**
  - `name: triple-lens-review`
  - description →
```yaml
description: >
  Three-lens code review — bugs/correctness, security, and performance — with
  severity-ranked findings and concrete fixes. Strongest on JavaScript,
  TypeScript, and Python; applies the same lenses to other languages. Use when
  the user asks to review code, check for bugs, audit security, find
  performance issues, or says "review this", "check my code", "any issues
  here", "is this code safe", "optimize this code".
```
  - Body "What to review" intro gains the moved rationale: `Apply all three lenses even if the user names one — issues compound across categories.`
  - Report format: change the outer fence to `~~~markdown` … `~~~` so the inner ``` blocks render.
  - Add under "How to conduct": `5. **Large diffs / PRs** — review changed hunks first, read surrounding code only where a finding depends on it, and say which files you did not open.` and a language line: `Other languages: apply the three lenses; skip the language-specific list.`
  - Heading `# Code Review Skill` → `# Triple-Lens Review`.
- [ ] **Step 4:** `python3 scripts/generate-catalog.py` then `--check` → exit 0. `grep -rn '"code-review"' .claude-plugin plugins` → 0.
- [ ] **Step 5:** Lint → 33/33. Commit `refactor!: rename code-review plugin to triple-lens-review; fix report template fences`.

---

### Task 5: coding-style — caveman, karpathy, ponytail

**Files:** the three `plugins/coding-style/skills/*/SKILL.md`.

- [ ] **Step 1: caveman**
  - Description → drop the URL sentence (keep the credit as a body line `Inspired by https://github.com/juliusbrussee/caveman.`).
  - `allowed-tools: [Read, Grep, Glob, Bash, Edit, Write]` → remove the line (output-style skill needs no tools).
  - Modes: `wenyan` → `` `wenyan` — classical-Chinese-style extreme brevity: drop subjects, particles, and connectives; one clause per idea (prose stays in the user's language). ``
  - Add section:
```markdown
## Example

Normal: "Sure! I took a look, and it seems the issue is that the `user` variable can be null when the session expires, so you'll want to add a check before accessing `user.id`."
Full: "Bug: `user` null after session expiry. Guard before `user.id`."
Ultra: "`user` null on expiry → guard `user.id`."
```
- [ ] **Step 2: karpathy-guidelines** — Section 1 bullet `If something is unclear, stop. Name what's confusing. Ask.` → `If ambiguity would change the result, stop and ask. Otherwise pick the sensible default, state it in one line, and proceed.` Add after the Tradeoff line: `**With ponytail active:** ponytail decides *how much* to build; these rules decide *how carefully*. Both share one rule: ask only when the ambiguity is blocking.`
- [ ] **Step 3: ponytail**
  - Persistence → `Active every response once triggered — no drift back to over-building. Off only on "stop ponytail" / "normal mode". Default: **full**. Switch: \`/ponytail lite|full|ultra\`.`
  - Rule "Never stall on an answer you can default." → append ` Ask only when the ambiguity is blocking (same rule as karpathy-guidelines).`
  - Hardware paragraph → `Physical systems drift (clocks, sensors, servos): leave the calibration knob even if the minimal model doesn't need it.`
- [ ] **Step 4:** Lint all three → 33/33 (ponytail now passes via Task 1 allowlist). Commit `fix(coding-style): caveman example + wenyan, align karpathy/ponytail ask rule`.

---

### Task 6: ux-design — contradictions and triggering

**File:** `plugins/ux-design/skills/ui-ux-design/SKILL.md`

- [ ] **Step 1:** Description →
```yaml
description: "UI/UX design rules for web and mobile interfaces — accessibility, touch targets, layout, typography, color, motion, forms, navigation, charts, and avoiding generic AI-design tells. Use when building, styling, or reviewing a visual interface (page, component, dashboard, form, chart) in any UI framework. Not for backend, API, or infrastructure work."
```
- [ ] **Step 2:** Priority table: reorder rows by impact — CRITICAL (1 Accessibility, 2 Touch), HIGH (3 Performance, 4 Style, 5 Layout, 6 Navigation, 7 AI-Design Tells), MEDIUM (8 Typography & Color, 9 Animation, 10 Forms), LOW (11 Charts). Keep section numbers in headings matching the table.
- [ ] **Step 3:** Contradiction fixes:
  - Animation `Prefer spring/physics-based curves for natural feel` → `Spring/physics curves are fine if critically damped (no overshoot); see the no-bounce rule in AI-Design Tells.`
  - Conflicts `An iOS-style bottom sheet on Android is always wrong` → `An iOS-style action sheet on Android (instead of a Material bottom sheet/dialog) breaks expectations.`
  - Typography `Limit lines to 65–75 characters` → `Limit body lines per Layout (35–60 mobile, 60–75 desktop).`
  - Forms `Auto-dismiss toasts in 3–5s` → `Auto-dismiss informational toasts in 3–5s; never auto-dismiss toasts with actions or errors (WCAG 2.2.1).`
  - `touch-action: manipulation` line → append `(mostly legacy; harmless)`.
- [ ] **Step 4:** Remove unsourced stats: `~40% more mis-taps`, `~7% drop in conversions; 3s causes ~53%`, `15–20% of users` → keep the reason, drop the number (e.g. `smaller targets produce markedly more mis-taps`).
- [ ] **Step 5:** Add after Rule Conflicts:
```markdown
## Project design systems win

If the project has its own tokens/design system (e.g. `--mui-*`, a Tailwind theme, a component library), use it. These rules fill gaps and catch violations; they never override an explicit system choice except on accessibility.

## Example

Request: "Add a delete button to each row of this table."
Apply: danger color + icon + text label (no color-only), ≥44px hit area, confirm dialog with cancel, focus returns to the row after cancel, `aria-label="Delete <row name>"`.
```
- [ ] **Step 6:** Lint → 33/33. Commit `fix(ux-design): resolve rule contradictions, tighten trigger, add example`.

---

### Task 7: repo-init doc/script mismatch

**File:** `plugins/repo-init/skills/repo-init/SKILL.md` (Phase 3)

- [ ] **Step 1:** Replace `require review from code owners (if CODEOWNERS file exists)` with `code-owner review off (a new repo has no CODEOWNERS; enable \`require_code_owner_reviews\` after adding one)` — matches `repo-init.sh:176`.
- [ ] **Step 2:** `grep -n require_code_owner_reviews plugins/repo-init/scripts/repo-init.sh` → `false`; lint → 33/33. Commit `docs(repo-init): match code-owner review doc to script`.

---

### Task 8: Quartermaster broken-ref false positive

**File:** `plugins/mushilu-studio/skills/quartermaster/SKILL.md`

- [ ] **Step 1:** Change the one path-shaped mention `` `scripts/ci-verify.sh` by convention `` → `` the repo's `ci-verify.sh` (conventionally in the repo's scripts folder) `` so the linter no longer resolves it as a bundled file.
- [ ] **Step 2:** Lint → 33/33. Commit `fix(quartermaster): clarify ci-verify.sh lives in target repo`.

---

### Task 9: Re-audit + CI parity + PR

- [ ] **Step 1:** Re-audit:
```bash
cd plugins/skill-authoring/skills/skill-qa-agent
python3 -m scripts.inventory --skill-roots "$OLDPWD" --out "$TMPDIR/inv.json" >/dev/null && for d in "$OLDPWD"/plugins/*/skills/*; do python3 -m scripts.lint_skill --format skill "$d" | python3 -c "import json,sys;d=json.load(sys.stdin);print(d['tier1_points_awarded'],'/',d['tier1_points_possible'])"; done
```
Expected: 19 lines of `33 / 33`. Tier-2 re-grade each changed skill; target all Green, none Amber.
- [ ] **Step 2:** CI parity: `python3 scripts/generate-catalog.py --check` (exit 0), `shellcheck` on the two scripts (clean), `python3 -m unittest tests.test_scripts` (pass).
- [ ] **Step 3:** `git push -u origin fix/skill-audit-findings`; `gh pr create` with summary of tasks 1–8 and before/after bands. Bind via ccd_pr tools.
- [ ] **Step 4:** Stop. User reviews and merges (branch protection requires approval).

---

### Task 10: Post-merge — sync global library (after user merges)

- [ ] **Step 1:** `git checkout main && git pull --ff-only`
- [ ] **Step 2:** `scripts/update-plugin.sh` → regenerates catalog, rsyncs marketplace clone, clears cache, prunes orphan `code-review@grimoire-cc-mmz`.
- [ ] **Step 3:** `claude plugin install triple-lens-review@grimoire-cc-mmz` (or tell the user to run `/plugin install triple-lens-review@grimoire-cc-mmz` if the CLI call isn't available).
- [ ] **Step 4:** Snapshot then delete duplicate user skills:
```bash
TS=$(date +%Y%m%d-%H%M%S); mkdir -p ~/.claude/skill-qa/history/user-skills/$TS
for s in grimoire-cc-mmz karpathy-guidelines skill-qa-agent ui-ux-design; do cp -R ~/.claude/skills/$s ~/.claude/skill-qa/history/user-skills/$TS/; done
diff -rq ~/.claude/skills/skill-qa-agent ~/.claude/skill-qa/history/user-skills/$TS/skill-qa-agent && \
for s in grimoire-cc-mmz karpathy-guidelines skill-qa-agent ui-ux-design; do rm -rf ~/.claude/skills/$s; done
```
Expected: `ls ~/.claude/skills` → `graphify` only.
- [ ] **Step 5:** Verify: `grep -c triple-lens-review ~/.claude/plugins/installed_plugins.json` ≥ 1; marketplace clone contains `plugins/triple-lens-review`. Tell user to restart Claude Code.
