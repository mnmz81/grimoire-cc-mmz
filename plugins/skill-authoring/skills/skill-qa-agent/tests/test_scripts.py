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
