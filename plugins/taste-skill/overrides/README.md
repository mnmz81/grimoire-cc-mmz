# Local overrides

Applied by `scripts/vendor-taste-skill.sh` after every upstream sync, so `skills/` stays a clean upstream copy plus these deltas.

Per skill folder `<folder>` (as in `skills/<folder>/SKILL.md`):

- `<folder>.description.txt` — replaces the frontmatter `description:` (trigger tuning, overlap control).
- `<folder>.append.md` — appended to the end of `SKILL.md` (scope notes, conflict resolution).

Current overrides:

| Folder | Why |
| ------ | --- |
| `output-skill` | Scope to deliverables so it doesn't fight `coding-style:caveman` prose compression. |
| `taste-skill` | Sharpen trigger: aesthetic direction for marketing/portfolio pages; defer dashboards, components, a11y audits to `ux-design:ui-ux-design`. |
| `taste-skill-v1` | Only fire on explicit v1 request so it doesn't double-trigger with v2. |
